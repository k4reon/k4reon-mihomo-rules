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
#  Запуск (дальше скрипт спросит):
#    sh tailscale-install.sh
#
#  Без вопросов:
#    sh tailscale-install.sh --yes
#    sh tailscale-install.sh --dry-run    # только показать план
#
#  Только OpenWrt. Скрипт идемпотентен: уже созданные интерфейс,
#  зона и forwarding не дублируются.
# ============================================================

set -u

DRY_RUN=0
ASSUME_YES=0

say() { printf '%s\n' "$*"; }
die() { printf 'ОШИБКА: %s\n' "$*"; exit 1; }

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y)  ASSUME_YES=1 ;;
        --help|-h)
            sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
    esac
done

[ -f /etc/openwrt_release ] || die "не похоже на OpenWrt."
[ "$(id -u)" = "0" ] || [ "$DRY_RUN" -eq 1 ] || die "нужны права root."

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
    say "  2) Только настроить интерфейс/firewall"
    say "  0) Выйти"
    printf 'Выбор [1]: '
    read choice

    case "$choice" in
        ""|1) install_pkg; configure; break ;;
        2)    configure; break ;;
        0)    say "Выход."; exit 0 ;;
        *)    say "Введите 1, 2 или 0." ;;
    esac
done

say ""
say "Дальше подключитесь сами: tailscale up"
