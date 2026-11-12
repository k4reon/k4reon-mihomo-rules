#!/bin/sh
# ============================================================
#  Tailscale tuning for OpenWrt (procd)
#
#  Добавляет в init-скрипт Tailscale, после строки
#  procd_set_param env TS_DEBUG_FIREWALL_MODE=...
#  следующие параметры:
#
#    procd_append_param env TS_NO_LOGS_NO_SUPPORT=true   # не отправлять логи на log.tailscale.com
#    procd_append_param env GOMEMLIMIT=35MiB             # мягкий лимит памяти Go
#    procd_append_param env GODEBUG=madvdontneed=1       # возврат памяти ОС (для старых Go)
#
#  Скрипт идемпотентен: повторный запуск не создаёт дубликатов.
#
#  Запуск (дальше скрипт спросит):
#    sh tailscale-tune.sh
#
#  Без вопросов:
#    sh tailscale-tune.sh --yes
#    sh tailscale-tune.sh --dry-run
#    sh tailscale-tune.sh --restore
#
#  Только OpenWrt (procd). GOMEMLIMIT — мягкий лимит, не жёсткий RSS.
# ============================================================

set -u

INIT="${TAILSCALE_INIT:-/etc/init.d/tailscale}"
BACKUP="$INIT.bak"
TMP="$(mktemp 2>/dev/null || echo "/tmp/tailscale-tune.$$")"

DRY_RUN=0
RESTORE=0
ASSUME_YES=0

say() { printf '%s\n' "$*"; }
die() { printf 'ОШИБКА: %s\n' "$*"; exit 1; }

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --restore) RESTORE=1 ;;
        --yes|-y)  ASSUME_YES=1 ;;
        --help|-h)
            sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
    esac
done

[ -f "$INIT" ] || die "не найден $INIT. Скрипт для OpenWrt с установленным Tailscale."
grep -q 'TS_DEBUG_FIREWALL_MODE' "$INIT" || die "$INIT не похож на init-скрипт Tailscale (нет TS_DEBUG_FIREWALL_MODE)."

# ---- рекомендация по объёму ОЗУ ---------------------------------
MEM_KB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)"
MEM_MB=$(( ${MEM_KB:-0} / 1024 ))

if [ "$MEM_MB" -ge 512 ]; then
    TS_REC="обычно не требуется: памяти достаточно."
elif [ "$MEM_MB" -ge 192 ]; then
    TS_REC="рекомендуется: Tailscale занимает ~100 МБ."
else
    TS_REC="обязательно: Tailscale занимает слишком большую часть ОЗУ."
fi

# ---- изменение -------------------------------------------------

build_new() {
    grep -v -E 'procd_append_param env (GOMEMLIMIT|GODEBUG)=' "$INIT" > "$TMP" \
        || die "не удалось прочитать $INIT"

    if grep -q 'procd_append_param env TS_NO_LOGS_NO_SUPPORT=' "$TMP"; then
        # строка про логи уже есть — просто добавляем после неё
        PREVIEW="  procd_append_param env GOMEMLIMIT=35MiB
  procd_append_param env GODEBUG=madvdontneed=1"
        awk '
            /procd_append_param env TS_NO_LOGS_NO_SUPPORT=/ {
                print
                print "  procd_append_param env GOMEMLIMIT=35MiB"
                print "  procd_append_param env GODEBUG=madvdontneed=1"
                next
            }
            { print }
        ' "$TMP" > "$TMP.new" || die "не удалось подготовить изменения"
    else
        PREVIEW="  # Disable logging to log.tailscale.com
  procd_append_param env TS_NO_LOGS_NO_SUPPORT=true
  procd_append_param env GOMEMLIMIT=35MiB
  procd_append_param env GODEBUG=madvdontneed=1"
        awk '
            /procd_set_param env TS_DEBUG_FIREWALL_MODE=/ {
                print
                print ""
                print "  # Disable logging to log.tailscale.com"
                print "  procd_append_param env TS_NO_LOGS_NO_SUPPORT=true"
                print "  procd_append_param env GOMEMLIMIT=35MiB"
                print "  procd_append_param env GODEBUG=madvdontneed=1"
                next
            }
            { print }
        ' "$TMP" > "$TMP.new" || die "не удалось подготовить изменения"
    fi
}

apply_changes() {
    build_new

    say "Будет добавлено в $INIT:"
    say ""
    printf '%s\n' "$PREVIEW"
    say ""

    if [ "$DRY_RUN" -eq 1 ]; then
        say "(dry-run) файл не меняется"
        rm -f "$TMP" "$TMP.new"
        return 0
    fi

    [ "$(id -u)" = "0" ] || die "нужны права root."

    if [ ! -f "$BACKUP" ]; then
        cp "$INIT" "$BACKUP" || die "не удалось создать бэкап $BACKUP"
        say "Бэкап: $BACKUP"
    else
        say "Бэкап уже есть: $BACKUP"
    fi

    mv "$TMP.new" "$INIT" || die "не удалось записать $INIT"
    chmod 755 "$INIT"
    rm -f "$TMP"

    say "Перезапуск Tailscale..."
    "$INIT" restart || die "перезапуск не удался."

    sleep 4
    PID="$(pgrep -f 'tailscaled' 2>/dev/null | head -n 1)"
    say ""
    if [ -n "$PID" ]; then
        say "tailscaled PID: $PID"
        say "Переменные окружения:"
        tr '\0' '\n' < "/proc/$PID/environ" 2>/dev/null | grep -E '^(TS_NO_LOGS_NO_SUPPORT|GOMEMLIMIT|GODEBUG)=' || true
        say "Память:"
        grep -E 'VmRSS' "/proc/$PID/status" 2>/dev/null || true
    else
        say "tailscaled пока не найден (проверьте: pgrep -af tailscaled)."
    fi
    say ""
    say "Откатить: sh $0 --restore"
}

restore_changes() {
    [ -f "$BACKUP" ] || die "бэкап не найден: $BACKUP"
    say "Вернуть исходный init-скрипт из $BACKUP?"
    if [ "$ASSUME_YES" -eq 0 ] && [ -t 0 ]; then
        printf 'Откатить? [y/N]: '
        read ans
        case "$ans" in
            y|Y|yes|да|Да) ;;
            *) say "Отменено."; return 0 ;;
        esac
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        say "(dry-run) файл не меняется"
        return 0
    fi
    [ "$(id -u)" = "0" ] || die "нужны права root."
    cp "$BACKUP" "$INIT" || die "не удалось восстановить $INIT"
    say "Перезапуск Tailscale..."
    "$INIT" restart || die "перезапуск не удался."
    say "Готово: настройки убраны."
}

# ---- ветки запуска ---------------------------------------------

if [ "$RESTORE" -eq 1 ]; then
    restore_changes
    exit 0
fi

if [ "$DRY_RUN" -eq 1 ] || [ "$ASSUME_YES" -eq 1 ]; then
    apply_changes
    exit 0
fi

if [ ! -t 0 ]; then
    say "Tailscale tuning"
    say "ОЗУ роутера:   $MEM_MB MiB"
    say "Совет:         $TS_REC"
    say "Добавит: TS_NO_LOGS_NO_SUPPORT=true, GOMEMLIMIT=35MiB, GODEBUG=madvdontneed=1"
    say ""
    say "Запустите интерактивно или укажите:"
    say "  sh $0 --yes"
    exit 0
fi

# ---- интерактивное меню ---------------------------------------

say "========================================"
say " Tailscale: настройка"
say "========================================"
say " init: $INIT"
say " ОЗУ роутера: $MEM_MB MiB"
say " Совет: $TS_REC"
say ""
while :; do
    say "Что сделать?"
    say "  1) Применить (без логов, GOMEMLIMIT=35MiB, GODEBUG)"
    say "  2) Откатить"
    say "  0) Выйти"
    printf 'Выбор [1]: '
    read choice
    case "$choice" in
        ""|1)
            printf 'Применить? [Y/n]: '
            read ans
            case "$ans" in
                n|N|no|нет) say "Отменено."; continue ;;
            esac
            apply_changes
            break
            ;;
        2)
            restore_changes
            break
            ;;
        0)
            say "Выход."
            exit 0
            ;;
        *)
            say "Введите 1, 2 или 0."
            ;;
    esac
done
