#!/bin/sh
# ============================================================
#  roamd: роуминг Wi-Fi и Mesh для OpenWrt
#
#  Ставит пакеты из зеркала в этом репозитории, без подключения
#  чужого репозитория и без обращения к GitHub Releases напрямую
#  (если не сработало зеркало — только тогда пробует оригинал).
#
#  Что делает:
#    1) определяет ветку OpenWrt (24.10 или 25.12) и архитектуру;
#    2) качает roamd, luci-app-roamd и русский перевод;
#    3) сверяет sha256 по манифесту;
#    4) ставит пакеты штатным apk/opkg;
#    5) включает и перезапускает службу roamd.
#
#  Запуск (дальше скрипт спросит):
#    sh install-mesh.sh
#
#  Без вопросов:
#    sh install-mesh.sh --yes        # установить / обновить
#    sh install-mesh.sh --status     # состояние
#    sh install-mesh.sh --uninstall  # удалить (с подтверждением)
#    sh install-mesh.sh --dry-run    # только показать план
#
#  Только OpenWrt 24.10 и 25.12.
#  Зеркало: third_party/roamd/ (Apache-2.0, автор Ground-Zerro).
# ============================================================

set -u

DRY_RUN=0
ASSUME_YES=0
STATUS_ONLY=0
UNINSTALL=0

say() { printf '%s\n' "$*"; }
die() { printf 'ОШИБКА: %s\n' "$*"; exit 1; }

for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=1 ;;
        --yes|-y)    ASSUME_YES=1 ;;
        --status)    STATUS_ONLY=1 ;;
        --uninstall) UNINSTALL=1 ;;
        --help|-h)
            sed -n '2,31p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
    esac
done

# ---------------- настройки зеркала ------------------------------

ROAMD_VER="1.2.0"
REPO="https://github.com/k4reon/k4reon-mihomo-rules"
RAW_BASE="https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main"
JSD_BASE="https://cdn.jsdelivr.net/gh/k4reon/k4reon-mihomo-rules@main"
UPSTREAM="https://github.com/Ground-Zerro/roamd/releases/download/v1.2.0-r1"

[ -f /etc/openwrt_release ] || die "не похоже на OpenWrt."
[ "$(id -u)" = "0" ] || [ "$DRY_RUN" -eq 1 ] || [ "$STATUS_ONLY" -eq 1 ] \
    || die "нужны права root."

. /etc/openwrt_release
case "$DISTRIB_RELEASE" in
    24.10*) BRANCH="24.10" ;;
    25.12*) BRANCH="25.12" ;;
    *) die "поддерживаются только OpenWrt 24.10 и 25.12 (у вас $DISTRIB_RELEASE)." ;;
esac
ARCH="$DISTRIB_ARCH"
[ -n "$ARCH" ] || die "не удалось определить архитектуру."

PM=""
if command -v apk >/dev/null 2>&1; then
    PM="apk"
elif command -v opkg >/dev/null 2>&1; then
    PM="opkg"
else
    die "не найден apk или opkg."
fi

if [ "$PM" = "apk" ]; then
    CORE_FILE="$BRANCH-$ARCH-roamd-$ROAMD_VER-r2.apk"
    APP_FILE="$BRANCH-$ARCH-luci-app-roamd-$ROAMD_VER-r1.apk"
    I18N_FILE="$BRANCH-$ARCH-luci-i18n-roamd-ru-$ROAMD_VER-r1.apk"
else
    CORE_FILE="$BRANCH-$ARCH-roamd_${ROAMD_VER}-r2_$ARCH.ipk"
    APP_FILE="$BRANCH-$ARCH-luci-app-roamd_${ROAMD_VER}-r1_all.ipk"
    I18N_FILE="$BRANCH-$ARCH-luci-i18n-roamd-ru_${ROAMD_VER}-r1_all.ipk"
fi

CORE_VER="$ROAMD_VER-r2"
APP_VER="$ROAMD_VER-r1"
I18N_VER="$ROAMD_VER-r1"

# ---------------- helpers ----------------------------------------

download() {
    # download <output> <url> [<url> ...]
    out="$1"; shift
    for url in "$@"; do
        rm -f "$out"
        if wget -q -T 25 -O "$out" "$url" 2>/dev/null && [ -s "$out" ]; then
            if head -c 200 "$out" | grep -qi '<html'; then
                continue
            fi
            return 0
        fi
    done
    rm -f "$out"
    return 1
}

fetch_sums() {
    SUMS="/tmp/roamd-SHA256SUMS"
    download "$SUMS" \
        "$JSD_BASE/third_party/roamd/SHA256SUMS" \
        "$RAW_BASE/third_party/roamd/SHA256SUMS" \
        "$REPO/raw/main/third_party/roamd/SHA256SUMS"
}

check_sha() {
    # check_sha <file> <name>
    expected="$(awk -v n="$2" '$2 == n { print $1 }' "$SUMS" 2>/dev/null)"
    [ -n "$expected" ] || die "в манифесте нет $2 — зеркало неполное."
    actual="$(sha256sum "$1" 2>/dev/null | awk '{print $1}')"
    [ "$actual" = "$expected" ] || die "не совпала контрольная сумма: $2"
}

pkg_installed() {
    if [ "$PM" = "apk" ]; then
        apk list -I 2>/dev/null | grep -q "^$1-[0-9]"
    else
        opkg list-installed 2>/dev/null | grep -q "^$1 "
    fi
}

pkg_version() {
    if [ "$PM" = "apk" ]; then
        apk list -I 2>/dev/null \
            | sed -n "s/^$1-\([0-9][^ ]*\) .*/\1/p" \
            | head -n1
    else
        opkg list-installed 2>/dev/null \
            | sed -n "s/^$1 - \(.*\)$/\1/p" \
            | head -n1
    fi
}

conflicts() {
    for p in usteer dawn; do
        pkg_installed "$p" || continue
        say ""
        say "На устройстве установлен $p — он тоже управляет роумингом."
        say "Вместе с roamd они будут мешать друг другу."
        say "Удалите $p и повторите установку."
        return 1
    done
    return 0
}

show_status() {
    say ""
    say "roamd:"
    if pkg_installed roamd; then
        say "  пакет: установлен ($(pkg_version roamd))"
    else
        say "  пакет: не установлен"
    fi

    if pkg_installed luci-app-roamd; then
        say "  LuCI-приложение: установлено"
    else
        say "  LuCI-приложение: нет"
    fi

    if pkg_installed luci-i18n-roamd-ru; then
        say "  русский перевод: установлен"
    else
        say "  русский перевод: нет"
    fi

    if [ -x /etc/init.d/roamd ]; then
        if /etc/init.d/roamd enabled >/dev/null 2>&1; then
            say "  автозапуск: включён"
        else
            say "  автозапуск: выключен"
        fi
        if pidof roamd >/dev/null 2>&1; then
            say "  служба: запущена"
        else
            say "  служба: не запущена"
        fi
    else
        say "  служба: нет init-скрипта"
    fi

    if [ -f /etc/config/roamd ]; then
        say "  конфиг: /etc/config/roamd"
        say "  предпочитаемый диапазон: $(uci -q get roamd.global.prefer_band || echo '-') ГГц"
    else
        say "  конфиг: ещё не создан"
    fi
    say ""
}

# ---------------- загрузка и установка ---------------------------

fetch_pkg() {
    # fetch_pkg <file> -> /tmp/<file>
    name="$1"
    tmp="/tmp/$name"
    say "  $name"
    download "$tmp" \
        "$JSD_BASE/third_party/roamd/$BRANCH/$name" \
        "$RAW_BASE/third_party/roamd/$BRANCH/$name" \
        "$REPO/raw/main/third_party/roamd/$BRANCH/$name" \
        "$UPSTREAM/$name" \
        || return 1
    check_sha "$tmp" "$name"
    return 0
}

install_pkgs() {
    # install_pkgs <mode: full|i18n>
    mode="${1:-full}"

    space="$(df /overlay 2>/dev/null | awk 'NR==2 { print $4 }')"
    if [ -n "$space" ] && [ "$space" -lt 2048 ]; then
        say "Мало места во флеш-памяти: $((space / 1024)) МБ, нужно ≥ 2 МБ."
        return 1
    fi

    conflicts || return 1

    say ""
    say "Устройство: $(cat /tmp/sysinfo/model 2>/dev/null || echo '?')"
    say "OpenWrt $DISTRIB_RELEASE, $ARCH, пакетный менеджер: $PM"
    say ""

    if [ "$mode" = "i18n" ]; then
        if pkg_installed luci-i18n-roamd-ru; then
            say "Русский перевод уже установлен."
            return 0
        fi
        need="$I18N_FILE"
    else
        need=""
        [ "$(pkg_version roamd)" = "$CORE_VER" ] || need="$need $CORE_FILE"
        [ "$(pkg_version luci-app-roamd)" = "$APP_VER" ] || need="$need $APP_FILE"
        [ "$(pkg_version luci-i18n-roamd-ru)" = "$I18N_VER" ] || need="$need $I18N_FILE"
        need="${need# }"
        if [ -z "$need" ]; then
            say "Уже установлено: roamd $CORE_VER, LuCI и перевод — обновлять нечего."
            return 0
        fi
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        say "Будет скачано из зеркала:"
        for f in $need; do say "  $f"; done
        say ""
        say "Будет выполнено:"
        if [ "$PM" = "apk" ]; then
            say "  apk add --allow-untrusted <пакеты>"
        else
            say "  opkg install <пакеты>"
        fi
        say "  /etc/init.d/roamd enable && /etc/init.d/roamd restart"
        return 0
    fi

    fetch_sums || die "не удалось скачать манифест SHA256SUMS."
    say "Загрузка пакетов:"
    files=""
    for f in $need; do
        fetch_pkg "$f" || die "не удалось скачать $f ни из одного источника."
        files="$files /tmp/$f"
    done

    say ""
    say "Контрольные суммы: совпали"
    say "Обновление списков пакетов..."
    if [ "$PM" = "apk" ]; then
        apk update >/dev/null 2>&1 || say "  (apk update не удался — продолжаем)"
    else
        opkg update >/dev/null 2>&1 || say "  (opkg update не удался — продолжаем)"
    fi
    say "Установка..."

    if [ "$PM" = "apk" ]; then
        # shellcheck disable=SC2086
        apk add --allow-untrusted $files || die "apk add не удался."
    else
        # shellcheck disable=SC2086
        opkg install $files || die "opkg install не удался."
    fi

    rm -f $files "$SUMS"

    /etc/init.d/roamd enable >/dev/null 2>&1 || true
    /etc/init.d/roamd restart >/dev/null 2>&1 || true

    say ""
    say "Установлено: roamd $(pkg_version roamd)"
    say "Откройте LuCI → Сеть → Роуминг Wi-Fi."
    if ! pkg_installed luci-i18n-roamd-ru; then
        say "Русский перевод можно добавить пунктом 2."
    fi
    return 0
}

# ---------------- удаление --------------------------------------

uninstall_roamd() {
    say ""
    if ! pkg_installed roamd && ! pkg_installed luci-app-roamd; then
        say "roamd не установлен — удалять нечего."
        return 0
    fi

    say "ВНИМАНИЕ: будут удалены roamd, LuCI-приложение и перевод."
    say "Настройки Wi-Fi и сам конфиг /etc/config/roamd не затрагиваются"
    say "(конфиг спросим отдельно)."
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

    if [ "$DRY_RUN" -eq 1 ]; then
        say "[dry-run] удалить пакеты roamd, luci-app-roamd, luci-i18n-roamd-ru"
        return 0
    fi

    /etc/init.d/roamd stop >/dev/null 2>&1 || true
    /etc/init.d/roamd disable >/dev/null 2>&1 || true

    if [ "$PM" = "apk" ]; then
        apk del roamd luci-app-roamd luci-i18n-roamd-ru 2>/dev/null || true
    else
        opkg remove roamd luci-app-roamd luci-i18n-roamd-ru 2>/dev/null || true
    fi

    if [ -f /etc/config/roamd ]; then
        if [ "$ASSUME_YES" -eq 0 ] && [ -t 0 ]; then
            printf 'Удалить конфиг /etc/config/roamd? [y/N]: '
            read ans
            case "$ans" in
                y|Y|yes|да|Да) rm -f /etc/config/roamd; say "Конфиг удалён." ;;
                *) say "Конфиг оставлен." ;;
            esac
        else
            say "Конфиг оставлен: /etc/config/roamd"
        fi
    fi

    rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
    /etc/init.d/uhttpd reload >/dev/null 2>&1 || true

    say ""
    if pkg_installed roamd; then
        say "Пакет roamd всё ещё установлен — проверьте вывод выше."
        return 1
    fi
    say "roamd удалён."
    return 0
}

# ---------------- сценарии ---------------------------------------

if [ "$STATUS_ONLY" -eq 1 ]; then
    say "Устройство: $(cat /tmp/sysinfo/model 2>/dev/null || echo '?')"
    say "OpenWrt $DISTRIB_RELEASE, $ARCH, $PM"
    show_status
    exit 0
fi

if [ "$UNINSTALL" -eq 1 ]; then
    if uninstall_roamd; then exit 0; else exit 1; fi
fi

if [ "$ASSUME_YES" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    install_pkgs full || exit 1
    say ""
    say "Готово."
    exit 0
fi

if [ ! -t 0 ]; then
    say "roamd: установка и удаление"
    say "Запустите интерактивно или укажите: sh $0 --yes"
    exit 0
fi

say "========================================"
say " roamd: роуминг Wi-Fi"
say "========================================"
say " устройство: $(cat /tmp/sysinfo/model 2>/dev/null || echo '?')"
say " OpenWrt $DISTRIB_RELEASE, $ARCH"
say " пакет: $PM"
if pkg_installed roamd; then
    say " статус: установлен $(pkg_version roamd)"
else
    say " статус: не установлен"
fi

while :; do
    say ""
    say "Что сделать?"
    say "  1) Установить / обновить roamd"
    say "  2) Доустановить русский перевод"
    say "  3) Проверить состояние"
    say "  4) Удалить roamd"
    say "  0) Выйти"
    printf 'Выбор: '
    read choice

    case "$choice" in
        ""|1) install_pkgs full; continue ;;
        2)    install_pkgs i18n; continue ;;
        3)    show_status; continue ;;
        4)    uninstall_roamd; continue ;;
        0)    say "Выход."; exit 0 ;;
        *)    say "Введите 1, 2, 3, 4 или 0." ;;
    esac
done
