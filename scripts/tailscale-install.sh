#!/bin/sh
# ============================================================
#  Tailscale: установка и настройка на OpenWrt
#
#  Делает то же, что вручную:
#    1) ставит пакет tailscale (apk или opkg);
#    2) создаёт интерфейс network.tailscale (proto none, device tailscale0);
#    3) создаёт зону firewall tailscale:
#         input ACCEPT, output ACCEPT, forward REJECT,
#         masq 1, mtu_fix 1, network tailscale;
#    4) создаёт forwarding tailscale -> wan;
#    5) применяет настройки и перезапускает сеть/firewall.
#
#  Подключение к tailnet скрипт не делает — после настройки выполните
#  tailscale up вручную (или подключитесь как обычно по SSH).
#
#  Дополнительно: настройка памяти Tailscale (GOGC/GOMEMLIMIT/GODEBUG)
#  и остановка с logout.
#
#  Запуск (дальше скрипт спросит):
#    sh tailscale-install.sh
#
#  Без вопросов:
#    sh tailscale-install.sh --yes         # установить и настроить
#    sh tailscale-install.sh --dry-run     # только показать план
#    sh tailscale-install.sh --status      # состояние (включая память)
#    sh tailscale-install.sh --mem         # только память: RSS и ОЗУ
#    sh tailscale-install.sh --tune        # настроить память
#    sh tailscale-install.sh --tune-restore  # вернуть init-скрипт
#    sh tailscale-install.sh --stop --yes  # остановить и logout
#
#  Только OpenWrt. Скрипт идемпотентен: уже созданные интерфейс,
#  зона и forwarding не дублируются.
# ============================================================

set -u

DRY_RUN=0
ASSUME_YES=0
STATUS_ONLY=0
STOP_ONLY=0
TUNE_ONLY=0
TUNE_RESTORE=0
MEM_ONLY=0

say() { printf '%s\n' "$*"; }
die() { printf 'ОШИБКА: %s\n' "$*"; exit 1; }

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y)  ASSUME_YES=1 ;;
        --status)  STATUS_ONLY=1 ;;
        --mem)     MEM_ONLY=1 ;;
        --stop)    STOP_ONLY=1 ;;
        --tune)    TUNE_ONLY=1 ;;
        --tune-restore) TUNE_RESTORE=1 ;;
        --help|-h)
            sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
    esac
done

[ -f /etc/openwrt_release ] || die "не похоже на OpenWrt."
[ "$(id -u)" = "0" ] || [ "$DRY_RUN" -eq 1 ] || [ "$STATUS_ONLY" -eq 1 ] || [ "$MEM_ONLY" -eq 1 ] || die "нужны права root."

PM=""
if command -v apk >/dev/null 2>&1; then
    PM="apk"
elif command -v opkg >/dev/null 2>&1; then
    PM="opkg"
else
    die "не найден apk или opkg."
fi

# ---------------- установка --------------------------------------

install_pkg() {
    if command -v tailscale >/dev/null 2>&1 && [ -x /usr/sbin/tailscaled ]; then
        say "Tailscale уже установлен: $(tailscale version 2>/dev/null | head -n1)"
        return 0
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        say "[dry-run] $PM update"
        if [ "$PM" = "apk" ]; then
            say "[dry-run] apk add tailscale"
        else
            say "[dry-run] opkg update && opkg install tailscale"
        fi
        return 0
    fi

    say "Установка пакета tailscale через $PM..."
    if [ "$PM" = "apk" ]; then
        apk update || die "apk update не удался."
        apk add tailscale || die "apk add tailscale не удался."
    else
        opkg update || die "opkg update не удался."
        opkg install tailscale || die "opkg install tailscale не удался."
    fi

    command -v tailscale >/dev/null 2>&1 || die "после установки tailscale не найден."
    say "Установлено: $(tailscale version 2>/dev/null | head -n1)"

    /etc/init.d/tailscale enable || true
    /etc/init.d/tailscale start || true
}

# ---------------- UCI: интерфейс и firewall ----------------------

find_zone() {
    uci show firewall 2>/dev/null | sed -n "s/^firewall\.\([^.=]*\)\.name='tailscale'$/\1/p" | head -n1
}

find_forwarding() {
    uci show firewall 2>/dev/null | sed -n "s/^firewall\.\([^.=]*\)\.src='tailscale'$/\1/p" | head -n1
}

mem_report() {
    [ -n "${1:-}" ] && say "$1"
    TS_PID="$(pidof tailscaled 2>/dev/null | awk '{print $1}')"
    if [ -n "$TS_PID" ]; then
        TS_RSS="$(awk '/^VmRSS:/ {print $2}' "/proc/$TS_PID/status" 2>/dev/null)"
        if [ -n "$TS_RSS" ]; then
            say "  tailscaled (pid $TS_PID): $((TS_RSS / 1024)) MiB RSS"
        else
            say "  tailscaled (pid $TS_PID): RSS недоступен"
        fi
    else
        say "  tailscaled: не запущен"
    fi
    awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {
        if (t > 0) printf "  ОЗУ: свободно %d MiB из %d MiB\n", a/1024, t/1024
    }' /proc/meminfo 2>/dev/null
}

mem_tuned() {
    grep -q 'procd_append_param env GOMEMLIMIT=' /etc/init.d/tailscale 2>/dev/null
}

check_status() {
    say ""
    if command -v tailscale >/dev/null 2>&1 && [ -x /usr/sbin/tailscaled ]; then
        say "Tailscale: установлен ($(tailscale version 2>/dev/null | head -n1))"

        if /etc/init.d/tailscale enabled >/dev/null 2>&1; then
            say "  автозапуск: включён"
        else
            say "  автозапуск: выключен"
        fi

        if pidof tailscaled >/dev/null 2>&1; then
            say "  процесс: запущен (pid $(pidof tailscaled | awk '{print $1}'))"
        else
            say "  процесс: не запущен"
        fi

        if uci -q get network.tailscale >/dev/null 2>&1; then
            say "  интерфейс network.tailscale: есть"
        else
            say "  интерфейс network.tailscale: нет"
        fi

        Z="$(find_zone)"
        if [ -n "$Z" ]; then
            say "  зона firewall tailscale: есть ($Z)"
        else
            say "  зона firewall tailscale: нет"
        fi

        F="$(find_forwarding)"
        if [ -n "$F" ]; then
            say "  forwarding tailscale -> wan: есть ($F)"
        else
            say "  forwarding tailscale -> wan: нет"
        fi

        if mem_tuned; then
            LIM="$(sed -n 's/.*GOMEMLIMIT="\{0,1\}\([^" ]*\)"\{0,1\}.*/\1/p' /etc/init.d/tailscale | head -n1)"
            say "  память: настроена (GOMEMLIMIT=$LIM)"
        else
            say "  память: не настроена"
        fi

        if pidof tailscaled >/dev/null 2>&1; then
            mem_report
        fi

        ST="$(tailscale status --peers=false 2>/dev/null | head -n 1)"
        case "$ST" in
            "")                say "  tailnet: не подключён" ;;
            Logged\ out*)      say "  tailnet: не подключён (Logged out)" ;;
            *)                 say "  tailnet: подключён — $ST" ;;
        esac
    else
        say "Tailscale: не установлен"
        say "  Установить: пункт 1."
    fi
    say ""
}

if [ "$STATUS_ONLY" -eq 1 ]; then
    check_status
    exit 0
fi

if [ "$MEM_ONLY" -eq 1 ]; then
    say ""
    say "Память Tailscale:"
    mem_report
    if mem_tuned; then
        LIM="$(sed -n 's/.*GOMEMLIMIT="\{0,1\}\([^" ]*\)"\{0,1\}.*/\1/p' /etc/init.d/tailscale | head -n1)"
        say "  настройка: применена (GOMEMLIMIT=$LIM)"
    else
        say "  настройка: не применена"
    fi
    say ""
    exit 0
fi

stop_and_logout() {
    say ""
    if ! command -v tailscale >/dev/null 2>&1; then
        say "Tailscale не установлен — останавливать нечего."
        return 1
    fi

    say "ВНИМАНИЕ: Tailscale будет остановлен и выполнен logout."
    say "Устройство пропадёт из tailnet до следующего 'tailscale up'."
    if [ "$ASSUME_YES" -eq 0 ]; then
        if [ ! -t 0 ]; then
            say "Нужно подтверждение: запустите интерактивно или добавьте --yes."
            return 1
        fi
        printf 'Продолжить? [y/N]: '
        read ans
        case "$ans" in
            y|Y|yes|да|Да) ;;
            *) say "Отменено."; return 1 ;;
        esac
    fi

    [ "$(id -u)" = "0" ] || die "нужны права root."

    say "Logout..."
    tailscale logout 2>/dev/null || say "  (logout не выполнен: возможно, уже выполнен)"

    say "Остановка службы..."
    /etc/init.d/tailscale stop || say "  служба не остановлена"

    sleep 2
    if pidof tailscaled >/dev/null 2>&1; then
        say "Процесс всё ещё запущен (pid $(pidof tailscaled | awk '{print $1}'))."
    else
        say "Tailscale остановлен, logout выполнен."
    fi
    say ""
    return 0
}

if [ "$STOP_ONLY" -eq 1 ]; then
    if stop_and_logout; then
        exit 0
    else
        exit 1
    fi
fi

configure() {
    say ""
    say "Настройка интерфейса и firewall:"

    if uci -q get network.tailscale >/dev/null 2>&1; then
        say "  network.tailscale: уже есть"
    else
        say "  network.tailscale: создать (proto none, device tailscale0)"
        if [ "$DRY_RUN" -eq 0 ]; then
            uci set network.tailscale=interface
        fi
    fi
    if [ "$DRY_RUN" -eq 0 ]; then
        uci set network.tailscale.proto='none'
        uci set network.tailscale.device='tailscale0'
        uci set network.tailscale.multipath='off'
    fi

    ZONE="$(find_zone)"
    if [ -n "$ZONE" ]; then
        say "  зона firewall tailscale: уже есть ($ZONE)"
    else
        say "  зона firewall tailscale: создать"
        if [ "$DRY_RUN" -eq 0 ]; then
            ZONE="$(uci add firewall zone)"
        fi
    fi
    if [ "$DRY_RUN" -eq 0 ]; then
        uci set firewall."$ZONE".name='tailscale'
        uci set firewall."$ZONE".input='ACCEPT'
        uci set firewall."$ZONE".output='ACCEPT'
        uci set firewall."$ZONE".forward='REJECT'
        uci set firewall."$ZONE".masq='1'
        uci set firewall."$ZONE".mtu_fix='1'
        uci -q delete firewall."$ZONE".network
        uci add_list firewall."$ZONE".network='tailscale'
    fi

    FWD="$(find_forwarding)"
    if [ -n "$FWD" ]; then
        say "  forwarding tailscale -> wan: уже есть ($FWD)"
    else
        say "  forwarding tailscale -> wan: создать"
        if [ "$DRY_RUN" -eq 0 ]; then
            FWD="$(uci add firewall forwarding)"
        fi
    fi
    if [ "$DRY_RUN" -eq 0 ]; then
        uci set firewall."$FWD".src='tailscale'
        uci set firewall."$FWD".dest='wan'
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        say ""
        say "[dry-run] uci commit network; uci commit firewall"
        say "[dry-run] /etc/init.d/network reload; /etc/init.d/firewall reload"
        return 0
    fi

    uci commit network || die "uci commit network не удался."
    uci commit firewall || die "uci commit firewall не удался."

    say "Применение: network reload, firewall reload..."
    /etc/init.d/network reload
    /etc/init.d/firewall reload
    say "Готово."
}

# ---------------- память -----------------------------------------

TUNE_INIT="/etc/init.d/tailscale"
TUNE_BACKUP="$TUNE_INIT.bak"

tune_calc() {
    MEM_KB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)"
    tune_mem=$(( ${MEM_KB:-0} / 1024 ))
    TUNE_MEM_MB="$tune_mem"
    auto=$(( tune_mem / 4 ))
    [ "$auto" -lt 64 ] && auto=64
    [ "$auto" -gt 256 ] && auto=256
    [ "$tune_mem" -eq 0 ] && auto=128
    TUNE_LIMIT="${auto}MiB"
}

tune_apply() {
    say ""
    [ -f "$TUNE_INIT" ] || { say "Не найден $TUNE_INIT — сначала установите Tailscale."; return 1; }
    grep -q 'TS_DEBUG_FIREWALL_MODE' "$TUNE_INIT" || { say "$TUNE_INIT не похож на init-скрипт Tailscale."; return 1; }

    tune_calc
    TMP="$(mktemp 2>/dev/null || echo "/tmp/tailscale-tune.$$")"

    grep -v -E 'procd_append_param env (GOMEMLIMIT|GODEBUG)=' "$TUNE_INIT" > "$TMP" \
        || { say "Не удалось прочитать $TUNE_INIT."; return 1; }

    if grep -q 'procd_append_param env TS_NO_LOGS_NO_SUPPORT=' "$TMP"; then
        PREVIEW="  procd_append_param env GOMEMLIMIT=$TUNE_LIMIT
  procd_append_param env GODEBUG=madvdontneed=1"
        awk -v gomem="$TUNE_LIMIT" '
            /procd_append_param env TS_NO_LOGS_NO_SUPPORT=/ {
                print
                print "  procd_append_param env GOMEMLIMIT=" gomem
                print "  procd_append_param env GODEBUG=madvdontneed=1"
                next
            }
            { print }
        ' "$TMP" > "$TMP.new" || { say "Не удалось подготовить изменения."; rm -f "$TMP"; return 1; }
    else
        PREVIEW="  # Disable logging to log.tailscale.com
  procd_append_param env TS_NO_LOGS_NO_SUPPORT=true
  procd_append_param env GOMEMLIMIT=$TUNE_LIMIT
  procd_append_param env GODEBUG=madvdontneed=1"
        awk -v gomem="$TUNE_LIMIT" '
            /procd_set_param env TS_DEBUG_FIREWALL_MODE=/ {
                print
                print ""
                print "  # Disable logging to log.tailscale.com"
                print "  procd_append_param env TS_NO_LOGS_NO_SUPPORT=true"
                print "  procd_append_param env GOMEMLIMIT=" gomem
                print "  procd_append_param env GODEBUG=madvdontneed=1"
                next
            }
            { print }
        ' "$TMP" > "$TMP.new" || { say "Не удалось подготовить изменения."; rm -f "$TMP"; return 1; }
    fi

    say "ОЗУ роутера: $TUNE_MEM_MB MiB"
    say "GOMEMLIMIT: $TUNE_LIMIT"
    say ""
    say "Сейчас:"
    mem_report
    say ""
    say "Будет добавлено:"
    printf '%s\n' "$PREVIEW"
    say ""

    if [ "$DRY_RUN" -eq 1 ]; then
        say "(dry-run) файл не меняется"
        rm -f "$TMP" "$TMP.new"
        return 0
    fi

    [ "$(id -u)" = "0" ] || { say "Нужны права root."; return 1; }

    if [ ! -f "$TUNE_BACKUP" ]; then
        cp "$TUNE_INIT" "$TUNE_BACKUP" || { say "Не удалось создать бэкап."; return 1; }
        say "Бэкап: $TUNE_BACKUP"
    fi

    mv "$TMP.new" "$TUNE_INIT" || { say "Не удалось записать $TUNE_INIT."; return 1; }
    chmod 755 "$TUNE_INIT"
    rm -f "$TMP"

    say "Перезапуск Tailscale..."
    /etc/init.d/tailscale restart || { say "Перезапуск не удался."; return 1; }

    sleep 4
    say ""
    say "После перезапуска:"
    mem_report
    if [ -n "$TS_PID" ]; then
        say "  переменные:"
        tr '\0' '\n' < "/proc/$TS_PID/environ" 2>/dev/null | grep -E '^(GOMEMLIMIT|GODEBUG)=' | sed 's/^/    /' || true
    fi
    say ""
    say "GOMEMLIMIT — мягкий лимит: RSS может быть выше, но память"
    say "будет возвращаться ОС активнее. Сравните «Сейчас» и «После»."
    say ""
    return 0
}

tune_restore() {
    say ""
    [ -f "$TUNE_BACKUP" ] || { say "Бэкап не найден: $TUNE_BACKUP"; return 1; }
    if [ "$ASSUME_YES" -eq 0 ]; then
        if [ ! -t 0 ]; then
            say "Нужно подтверждение: запустите интерактивно или добавьте --yes."
            return 1
        fi
        printf 'Вернуть исходный init-скрипт? [y/N]: '
        read ans
        case "$ans" in
            y|Y|yes|да|Да) ;;
            *) say "Отменено."; return 1 ;;
        esac
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        say "(dry-run) файл не меняется"
        return 0
    fi
    [ "$(id -u)" = "0" ] || { say "Нужны права root."; return 1; }
    cp "$TUNE_BACKUP" "$TUNE_INIT" || { say "Не удалось восстановить."; return 1; }
    say "Перезапуск Tailscale..."
    /etc/init.d/tailscale restart || true
    say "Готово: настройка памяти убрана."
    return 0
}

if [ "$TUNE_ONLY" -eq 1 ]; then
    if tune_apply; then exit 0; else exit 1; fi
fi

if [ "$TUNE_RESTORE" -eq 1 ]; then
    if tune_restore; then exit 0; else exit 1; fi
fi

# ---------------- меню -------------------------------------------

if [ "$ASSUME_YES" -eq 1 ]; then
    install_pkg
    configure
    say ""
    say "Дальше подключитесь сами: tailscale up"
    exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
    say "Tailscale: установка и настройка (dry-run)"
    install_pkg
    configure
    exit 0
fi

if [ ! -t 0 ]; then
    say "Tailscale: установка и настройка"
    say "Запустите интерактивно или укажите: sh $0 --yes"
    exit 0
fi

say "========================================"
say " Tailscale: установка и настройка"
say "========================================"
say " init: /etc/init.d/tailscale"
say " пакет: $PM"
if command -v tailscale >/dev/null 2>&1; then
    say " статус: установлен ($(tailscale version 2>/dev/null | head -n1))"
else
    say " статус: не установлен"
fi
say ""

while :; do
    say "Что сделать?"
    say "  1) Установить Tailscale и настроить интерфейс/firewall"
    say "  2) Проверить состояние и память"
    say "  3) Настроить память (покажет до и после)"
    say "  4) Вернуть исходный init-скрипт (память)"
    say "  5) Остановить Tailscale и выйти (logout)"
    say "  0) Выйти"
    printf 'Выбор: '
    read choice

    case "$choice" in
        ""|1)
            install_pkg
            configure
            say ""
            say "Дальше подключитесь сами: tailscale up"
            break
            ;;
        2)    check_status; continue ;;
        3)    tune_apply; continue ;;
        4)    tune_restore; continue ;;
        5)    if stop_and_logout; then break; else continue; fi ;;
        0)    say "Выход."; exit 0 ;;
        *)    say "Введите 1–5 или 0." ;;
    esac
done
