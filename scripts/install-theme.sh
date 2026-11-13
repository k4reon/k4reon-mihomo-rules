#!/bin/sh
# ============================================================
#  Proton2025: тема LuCI и личный брендинг страницы входа
#
#  Что делает:
#    1) ставит пакет luci-theme-proton2025 (apk или opkg)
#       из зеркала в этом репозитории;
#    2) скачивает логотип и кладёт его в UCI (data URI);
#    3) включает брендинг входа: логотип + название k4reon.com;
#    4) применяет оформление: тёмная тема, оранжевый акцент,
#       анимация circuit, без фонового узора;
#    5) переключает LuCI на тему и перезапускает rpcd/uhttpd.
#
#  Запуск (дальше скрипт спросит):
#    sh install-theme.sh
#
#  Без вопросов:
#    sh install-theme.sh --yes        # тема + брендинг
#    sh install-theme.sh --branding   # только брендинг
#    sh install-theme.sh --status     # состояние
#    sh install-theme.sh --dry-run    # только показать план
#
#  Только OpenWrt. Скрипт идемпотентен: повторный запуск ничего
#  не дублирует, а только приводит настройки к нужным.
#
#  Тема: luci-theme-proton2025 (ChesterGoodiny), Apache-2.0.
#  Зеркало и лицензии: third_party/proton2025/.
# ============================================================

set -u

DRY_RUN=0
ASSUME_YES=0
STATUS_ONLY=0
BRANDING_ONLY=0

say() { printf '%s\n' "$*"; }
die() { printf 'ОШИБКА: %s\n' "$*"; exit 1; }

for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=1 ;;
        --yes|-y)    ASSUME_YES=1 ;;
        --status)    STATUS_ONLY=1 ;;
        --branding)  BRANDING_ONLY=1 ;;
        --help|-h)
            sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
    esac
done

# ---------------- настройки зеркала ------------------------------

THEME_VER="1.4.5"
REPO="https://github.com/k4reon/k4reon-mihomo-rules"
RAW_BASE="https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main"
JSD_BASE="https://cdn.jsdelivr.net/gh/k4reon/k4reon-mihomo-rules@main"
UPSTREAM="https://github.com/ChesterGoodiny/luci-theme-proton2025/releases/download/v1.4.5"

APK_FILE="luci-theme-proton2025-1.4.5-r1.apk"
IPK_FILE="luci-theme-proton2025_1.4.5_all.ipk"
APK_SHA="b54c41f364adb35f40e4b813f22e06d0ac6f369746adf81f20a5003001533941"
IPK_SHA="e7ea52058a59c4ec7a026f40b200e9e0ce54ae8c61df53e0cc3464375f6ca419"

LOGO_PATH="docs/images/login-logo.png"
LOGO_SHA="a34c8d64f9119d96455d7118eb976568453fdd894ee7e8000d88dcdcfdbd502a"
LOGO_NAME="k4reon.com"

[ -f /etc/openwrt_release ] || die "не похоже на OpenWrt."
[ "$(id -u)" = "0" ] || [ "$DRY_RUN" -eq 1 ] || [ "$STATUS_ONLY" -eq 1 ] \
    || die "нужны права root."

PM=""
if command -v apk >/dev/null 2>&1; then
    PM="apk"
elif command -v opkg >/dev/null 2>&1; then
    PM="opkg"
else
    die "не найден apk или opkg."
fi

if [ "$PM" = "apk" ]; then
    PKG_FILE="$APK_FILE"
    PKG_SHA="$APK_SHA"
else
    PKG_FILE="$IPK_FILE"
    PKG_SHA="$IPK_SHA"
fi

# ---------------- helpers ----------------------------------------

download() {
    # download <output> <url> [<url> ...]
    out="$1"; shift
    for url in "$@"; do
        rm -f "$out"
        if wget -q -T 25 -O "$out" "$url" 2>/dev/null && [ -s "$out" ]; then
            # Иногда вместо файла прилетает HTML-страница ошибки.
            if head -c 200 "$out" | grep -qi '<html'; then
                continue
            fi
            return 0
        fi
    done
    rm -f "$out"
    return 1
}

check_sha() {
    # check_sha <file> <expected>
    actual="$(sha256sum "$1" 2>/dev/null | awk '{print $1}')"
    [ "$actual" = "$2" ] || die "не совпала контрольная сумма: $1"
}

installed_ver() {
    if [ "$PM" = "apk" ]; then
        apk list -I 2>/dev/null \
            | sed -n 's/^luci-theme-proton2025-\([0-9][0-9.]*\)-.*/\1/p' \
            | head -n1
    else
        opkg list-installed 2>/dev/null \
            | awk '$1 == "luci-theme-proton2025" { print $3 }' \
            | head -n1
    fi
}

theme_active() {
    [ "$(uci -q get luci.main.mediaurlbase 2>/dev/null)" = "/luci-static/proton2025" ]
}

show_status() {
    say ""
    if [ -n "$(installed_ver)" ]; then
        say "Proton2025: установлена ($(installed_ver))"
    else
        say "Proton2025: не установлена"
    fi

    if theme_active; then
        say "  активная тема: proton2025"
    else
        say "  активная тема: $(uci -q get luci.main.mediaurlbase 2>/dev/null || echo 'не задана')"
    fi

    if [ "$(uci -q get proton2025.settings.login_branding 2>/dev/null)" = "1" ]; then
        say "  брендинг входа: включён"
    else
        say "  брендинг входа: выключен"
    fi

    name="$(uci -q get proton2025.settings.login_name 2>/dev/null)"
    [ -n "$name" ] && say "  название: $name"

    logo_size="$(uci -q get proton2025.settings.login_logo 2>/dev/null | wc -c | tr -d ' ')"
    if [ "${logo_size:-0}" -gt 0 ]; then
        say "  логотип: $logo_size байт (data URI)"
    else
        say "  логотип: не задан"
    fi

    say "  акцент: $(uci -q get proton2025.settings.accent 2>/dev/null || echo '-')"
    say "  анимация входа: $(uci -q get proton2025.settings.login_animation 2>/dev/null || echo '-')"
    say ""
}

# ---------------- установка пакета -------------------------------

install_theme() {
    say ""
    ver="$(installed_ver)"
    if [ "$ver" = "$THEME_VER" ]; then
        say "Пакет уже установлен: $ver — установка не нужна."
        return 0
    fi

    say "Пакет: $PKG_FILE"
    if [ "$DRY_RUN" -eq 1 ]; then
        say "[dry-run] скачать $PKG_FILE из зеркала и установить через $PM"
        return 0
    fi

    tmp="/tmp/$PKG_FILE"
    say "Загрузка..."
    download "$tmp" \
        "$JSD_BASE/third_party/proton2025/$PKG_FILE" \
        "$RAW_BASE/third_party/proton2025/$PKG_FILE" \
        "$REPO/raw/main/third_party/proton2025/$PKG_FILE" \
        "$UPSTREAM/$PKG_FILE" \
        || die "не удалось скачать пакет ни из одного источника."

    check_sha "$tmp" "$PKG_SHA"
    say "sha256: совпала"

    say "Установка через $PM..."
    if [ "$PM" = "apk" ]; then
        apk add --allow-untrusted "$tmp" || die "apk add не удался."
    else
        opkg install "$tmp" || die "opkg install не удался."
    fi
    rm -f "$tmp"
    say "Пакет установлен."
}

# ---------------- брендинг ---------------------------------------

apply_branding() {
    say ""
    if [ -z "$(installed_ver)" ] && [ "$DRY_RUN" -eq 0 ]; then
        say "Тема не установлена — сначала пункт 1."
        return 1
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        say "[dry-run] скачать логотип $LOGO_PATH, проверить sha256"
        say "[dry-run] uci set proton2025.settings.login_logo='data:image/png;base64,...'"
        say "[dry-run] uci set proton2025.settings.login_name='$LOGO_NAME'"
        say "[dry-run] включить брендинг, тёмную тему, оранжевый акцент, circuit"
        return 0
    fi

    tmp_logo="/tmp/theme-logo.png"
    say "Загрузка логотипа..."
    download "$tmp_logo" \
        "$JSD_BASE/$LOGO_PATH" \
        "$RAW_BASE/$LOGO_PATH" \
        "$REPO/raw/main/$LOGO_PATH" \
        || die "не удалось скачать логотип."

    check_sha "$tmp_logo" "$LOGO_SHA"

    command -v ucode >/dev/null 2>&1 \
        || die "ucode не найден (нужен для base64)."

    cat > /tmp/theme-brand.uc <<'EOF'
import { readfile } from 'fs';
import { cursor } from 'uci';

const png = readfile('/tmp/theme-logo.png');
if (png == null) { printf("Не могу прочитать /tmp/theme-logo.png\n"); die(); }

const logo = 'data:image/png;base64,' + b64enc(png);
const uci = cursor();
uci.load('proton2025');

uci.set('proton2025', 'settings', 'login_logo', logo);
uci.set('proton2025', 'settings', 'login_branding', '1');
uci.set('proton2025', 'settings', 'login_name', 'k4reon.com');
uci.set('proton2025', 'settings', 'login_logo_only', '0');
uci.set('proton2025', 'settings', 'mode', 'dark');
uci.set('proton2025', 'settings', 'accent', 'orange');
uci.set('proton2025', 'settings', 'login_animation', 'circuit');
uci.set('proton2025', 'settings', 'background_pattern', 'none');
uci.commit('proton2025');

printf("Логотип в UCI: %d байт\n", length(logo));
EOF

    ucode /tmp/theme-brand.uc || die "не удалось записать настройки темы."
    rm -f /tmp/theme-brand.uc /tmp/theme-logo.png
    return 0
}

activate_theme() {
    say ""
    if [ "$(uci -q get luci.main.mediaurlbase 2>/dev/null)" != "/luci-static/proton2025" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            say "[dry-run] переключить LuCI на proton2025"
            return 0
        fi
        uci set luci.main.mediaurlbase='/luci-static/proton2025'
    fi
    if [ "$(uci -q get luci.themes.Proton2025 2>/dev/null)" != "/luci-static/proton2025" ]; then
        [ "$DRY_RUN" -eq 1 ] || uci set luci.themes.Proton2025='/luci-static/proton2025'
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        say "[dry-run] uci commit luci; перезапуск rpcd/uhttpd"
        return 0
    fi
    uci commit luci
    /etc/init.d/rpcd restart
    /etc/init.d/uhttpd reload || /etc/init.d/uhttpd restart
    say "LuCI переключён на Proton2025."
}

# ---------------- сценарии ---------------------------------------

if [ "$STATUS_ONLY" -eq 1 ]; then
    show_status
    exit 0
fi

if [ "$BRANDING_ONLY" -eq 1 ]; then
    if apply_branding; then
        say ""
        say "Готово. Откройте страницу входа и нажмите Ctrl+F5."
        exit 0
    fi
    exit 1
fi

if [ "$ASSUME_YES" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    install_theme
    apply_branding || exit 1
    activate_theme
    say ""
    say "Готово. Откройте страницу входа и нажмите Ctrl+F5."
    exit 0
fi

if [ ! -t 0 ]; then
    say "Proton2025: установка темы и брендинга"
    say "Запустите интерактивно или укажите: sh $0 --yes"
    exit 0
fi

say "========================================"
say " Proton2025: тема и брендинг"
say "========================================"
say " версия: $THEME_VER"
say " пакет: $PM"
show_status

while :; do
    say "Что сделать?"
    say "  1) Установить тему и брендинг"
    say "  2) Только брендинг (логотип и название)"
    say "  3) Проверить состояние"
    say "  0) Выйти"
    printf 'Выбор: '
    read choice

    case "$choice" in
        ""|1)
            install_theme
            apply_branding || continue
            activate_theme
            say ""
            say "Готово. Откройте страницу входа и нажмите Ctrl+F5."
            break
            ;;
        2)
            if apply_branding; then
                say ""
                say "Готово. Откройте страницу входа и нажмите Ctrl+F5."
            fi
            continue
            ;;
        3) show_status; continue ;;
        0) say "Выход."; exit 0 ;;
        *) say "Введите 1, 2, 3 или 0." ;;
    esac
done
