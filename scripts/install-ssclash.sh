#!/bin/sh
# ============================================================
#  SSClash: установка SSClash-Go или SSClash 4 (OpenWrt)
#
#  Сам определяет ветку OpenWrt и архитектуру:
#    23.05 / 24.10  -> opkg, .ipk
#    25.12          -> apk, .apk
#    архитектура    -> aarch64 (arm64)
#
#  SSClash 4 ставится из зеркала в этом репозитории (GPL-2.0).
#  SSClash-Go — только по официальным ссылкам через зеркала-прокси
#  (лицензия запрещает перепубликацию), с проверкой sha256.
#  Ядро Mihomo ставится отдельным шагом и общее для обеих версий.
#
#  Запуск (дальше скрипт спросит):
#    sh install-ssclash.sh
#
#  Без вопросов:
#    sh install-ssclash.sh --go --yes     # SSClash-Go
#    sh install-ssclash.sh --ss4 --yes    # SSClash 4
#    sh install-ssclash.sh --go --client --yes   # только клиент
#    sh install-ssclash.sh --go --core --yes     # только ядро
#    sh install-ssclash.sh --status       # состояние
#    sh install-ssclash.sh --dry-run      # только план
#    sh install-ssclash.sh --ss4 --uninstall
#
#  Сервис SSClash 4 после установки остаётся выключенным:
#  включите его в LuCI -> Services -> SSClash.
# ============================================================

set -u

DRY_RUN=0
ASSUME_YES=0
STATUS_ONLY=0
UNINSTALL=0
VARIANT=""
MODE="full"
FROM_DIR=""

say() { printf '%s\n' "$*"; }
die() { printf 'ОШИБКА: %s\n' "$*"; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)   DRY_RUN=1 ;;
        --yes|-y)    ASSUME_YES=1 ;;
        --status)    STATUS_ONLY=1 ;;
        --uninstall) UNINSTALL=1 ;;
        --go)        VARIANT="go" ;;
        --ss4)       VARIANT="ss4" ;;
        --client)    MODE="client" ;;
        --core)      MODE="core" ;;
        --from)      FROM_DIR="${2:-}"; shift ;;
        --from=*)    FROM_DIR="${1#*=}" ;;
        --help|-h)
            sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) die "неизвестный аргумент: $1" ;;
    esac
    shift
done

# ---------------- версии и адреса --------------------------------

GO_VER="7.7.1"
GO_TAG="v7.7.1"
GO_SHA="4175a529360acabb3e99e921537119c3be5eace94837d6a7c19bc45904d3718e"
GO_SVC_SHA="c6115883f3ddab30de168d71468450431ca9d38021eae39b309b7f1383315768"

SS4_VER="4.7.1"
SS4_TAG="v4.7.1"
SS4_APK="luci-app-ssclash-4.7.1-r1.apk"
SS4_IPK="luci-app-ssclash_4.7.1-r1_all.ipk"
SS4_APK_SHA="e8d4f416654792e7541442eb91b751c38d534448301e0c8706bf6f5c6d18074d"
SS4_IPK_SHA="b61c19cd752013208e50107359ad782560b46e554045985e7a2cc3e0182d11f5"

CORE_VER="v1.19.34"
CORE_FILE="mihomo-linux-arm64-v1.19.34.gz"
CORE_SHA="daaf78a6240a282cdfd75bcbf98fe321f6bd52765cc29e79f344191198f0b50f"

REPO="https://github.com/k4reon/k4reon-mihomo-rules"
RAW_BASE="https://raw.githubusercontent.com/k4reon/k4reon-mihomo-rules/main"
JSD_BASE="https://cdn.jsdelivr.net/gh/k4reon/k4reon-mihomo-rules@main"
GO_BASE="https://github.com/zerolabnet/SSClash-Go/releases/download/$GO_TAG"
SS4_BASE="https://github.com/zerolabnet/SSClash/releases/download/$SS4_TAG"
CORE_BASE="https://github.com/MetaCubeX/mihomo/releases/download/$CORE_VER"
PROXIES="https://ghproxy.net/ https://gh-proxy.com/ https://ghfast.top/"

CLASH_DIR="/opt/clash"
CLASH_BIN="$CLASH_DIR/bin/clash"

# ---------------- окружение --------------------------------------

[ -f /etc/openwrt_release ] || die "не похоже на OpenWrt."
. /etc/openwrt_release

case "$DISTRIB_RELEASE" in
    23.05*|24.10*) ;;
    25.12*) ;;
    *) die "поддерживаются OpenWrt 23.05, 24.10 и 25.12 (у вас $DISTRIB_RELEASE)." ;;
esac

case "$DISTRIB_ARCH" in
    aarch64*) ARCH="arm64" ;;
    *) die "пока поддерживается только aarch64/arm64 (у вас $DISTRIB_ARCH)." ;;
esac

PM=""
if command -v apk >/dev/null 2>&1; then
    PM="apk"
elif command -v opkg >/dev/null 2>&1; then
    PM="opkg"
else
    die "не найден apk или opkg."
fi

if [ "$PM" = "apk" ]; then
    SS4_FILE="$SS4_APK"
    SS4_SHA="$SS4_APK_SHA"
else
    SS4_FILE="$SS4_IPK"
    SS4_SHA="$SS4_IPK_SHA"
fi

# ---------------- helpers ----------------------------------------

fetch() {
    # fetch <output> <url> [<url> ...]
    out="$1"; shift
    for url in "$@"; do
        rm -f "$out"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL --connect-timeout 15 --max-time 300 -o "$out" "$url" 2>/dev/null \
                && [ -s "$out" ] && return 0
        else
            wget -q -T 60 -O "$out" "$url" 2>/dev/null \
                && [ -s "$out" ] && return 0
        fi
    done
    rm -f "$out"
    return 1
}

fetch_github() {
    # fetch_github <output> <https://github.com/...>
    out="$1"; url="$2"
    set -- "$url"
    for p in $PROXIES; do set -- "$@" "$p$url"; done
    fetch "$out" "$@"
}

check_sha() {
    actual="$(sha256sum "$1" 2>/dev/null | awk '{print $1}')"
    [ "$actual" = "$2" ] || die "не совпала контрольная сумма: $1"
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

go_installed() { [ -x /opt/clash/bin/ssclash ]; }
ss4_installed() { pkg_installed luci-app-ssclash; }

service_running() {
    ubus call service list "{\"name\":\"$1\"}" 2>/dev/null | grep -q '"running": true'
}

go_version() {
    [ -x /opt/clash/bin/ssclash ] || return 0
    v="$(/opt/clash/bin/ssclash version 2>/dev/null | head -n1)"
    case "$v" in
        *version=*) v="${v#*version=}" ;;
        *) v="$(printf '%s' "$v" | grep -o 'v[0-9][0-9.]*' | head -n1)" ;;
    esac
    printf '%s' "$v"
}

core_version() {
    [ -x "$CLASH_BIN" ] || return 0
    "$CLASH_BIN" -v 2>/dev/null | grep -o 'v[0-9][0-9.]*' | head -n1
}

ask_yes() {
    # ask_yes <вопрос>
    [ "$ASSUME_YES" -eq 1 ] && return 0
    [ -t 0 ] || return 1
    printf '%s [y/N]: ' "$1"
    read ans
    case "$ans" in
        y|Y|yes|да|Да) return 0 ;;
        *) return 1 ;;
    esac
}

free_mb() {
    df "$1" 2>/dev/null | awk 'NR==2 { printf "%d", $4 / 1024 }'
}

stop_go() {
    [ -x /etc/init.d/ssclash ] && /etc/init.d/ssclash stop >/dev/null 2>&1
    sleep 1
    if pidof clash >/dev/null 2>&1; then
        kill $(pidof clash) 2>/dev/null
        sleep 2
        pidof clash >/dev/null 2>&1 && kill -9 $(pidof clash) 2>/dev/null
        sleep 1
    fi
}

stop_ss4() {
    [ -x /etc/init.d/clash ] && /etc/init.d/clash stop >/dev/null 2>&1
    sleep 1
    if pidof clash >/dev/null 2>&1; then
        kill $(pidof clash) 2>/dev/null
        sleep 2
        pidof clash >/dev/null 2>&1 && kill -9 $(pidof clash) 2>/dev/null
        sleep 1
    fi
}

install_deps() {
    say "Зависимости..."
    if [ "$PM" = "apk" ]; then
        apk update >/dev/null 2>&1 || true
        apk add kmod-nft-tproxy kmod-tun ca-bundle wget-ssl curl tar >/dev/null 2>&1 \
            || apk add kmod-nft-tproxy kmod-tun ca-bundle wget-ssl tar >/dev/null 2>&1 \
            || say "  (часть зависимостей не установилась — проверьте apk)"
    else
        opkg update >/dev/null 2>&1 || true
        opkg install kmod-nft-tproxy kmod-tun ca-bundle wget-ssl curl tar >/dev/null 2>&1 \
            || opkg install kmod-nft-tproxy kmod-tun ca-bundle wget-ssl tar >/dev/null 2>&1 \
            || say "  (часть зависимостей не установилась — проверьте opkg)"
    fi
}

make_dirs() {
    mkdir -p "$CLASH_DIR/bin" "$CLASH_DIR/.ssclash" "$CLASH_DIR/local-rules" \
        "$CLASH_DIR/rule-providers" "$CLASH_DIR/proxy-providers" \
        "$CLASH_DIR/subscriptions" "$CLASH_DIR/ui"
}

install_core() {
    gz="$1"
    say ""
    say "Ядро Mihomo $CORE_VER..."
    gzip -t "$gz" || { say "Архив ядра повреждён."; return 1; }
    gunzip -c "$gz" > /tmp/clash.new || { say "Не удалось распаковать ядро."; return 1; }
    chmod 755 /tmp/clash.new
    /tmp/clash.new -v >/dev/null 2>&1 || {
        say "Новое ядро не запускается — оставляю старое."
        rm -f /tmp/clash.new
        return 1
    }

    make_dirs
    if [ -x "$CLASH_BIN" ]; then
        cp "$CLASH_BIN" "$CLASH_BIN.old" 2>/dev/null || true
    fi
    mv /tmp/clash.new "$CLASH_BIN" || { say "Не удалось заменить ядро."; return 1; }
    say "  установлено: $("$CLASH_BIN" -v 2>/dev/null | head -n1)"
    return 0
}

# ---------------- проверка состояния -----------------------------

show_status() {
    say ""
    say "Устройство: $(cat /tmp/sysinfo/model 2>/dev/null || echo '?')"
    say "OpenWrt $DISTRIB_RELEASE, $ARCH, $PM"
    say ""
    say "SSClash-Go:"
    if go_installed; then
        say "  клиент: установлен ($(go_version))"
        if [ -x /etc/init.d/ssclash ]; then
            /etc/init.d/ssclash enabled >/dev/null 2>&1 && say "  автозапуск: включён" || say "  автозапуск: выключен"
            service_running ssclash && say "  служба: запущена" || say "  служба: не запущена"
        fi
    else
        say "  клиент: не установлен"
    fi
    say ""
    say "SSClash 4:"
    if ss4_installed; then
        say "  пакет: установлен ($(pkg_version luci-app-ssclash))"
        if [ -x /etc/init.d/clash ]; then
            /etc/init.d/clash enabled >/dev/null 2>&1 && say "  автозапуск: включён" || say "  автозапуск: выключен"
            service_running clash && say "  служба: запущена" || say "  служба: не запущена"
        fi
    else
        say "  пакет: не установлен"
    fi
    say ""
    say "Ядро Mihomo:"
    if [ -x "$CLASH_BIN" ]; then
        say "  установлено: $(core_version)"
        say "  файл: $CLASH_BIN"
    else
        say "  не установлено"
    fi
    say ""
}

# ---------------- SSClash-Go -------------------------------------

remove_ss4_for_go() {
    ss4_installed || return 0
    say ""
    say "Установлен SSClash 4. Вместе с SSClash-Go они не работают."
    if [ "$DRY_RUN" -eq 0 ]; then
        if ! ask_yes "Удалить SSClash 4 и продолжить?"; then
            say "Отменено."
            return 1
        fi
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        say "[dry-run] удалить SSClash 4"
        return 0
    fi
    stop_ss4
    [ -x /etc/init.d/clash ] && /etc/init.d/clash disable >/dev/null 2>&1
    if [ "$PM" = "apk" ]; then
        apk del luci-app-ssclash >/dev/null 2>&1 || true
    else
        opkg remove luci-app-ssclash >/dev/null 2>&1 || true
    fi
    rm -f /etc/init.d/clash
    say "SSClash 4 удалён."
    return 0
}

install_go() {
    mode="${1:-full}"
    say ""
    if ! remove_ss4_for_go; then return 1; fi

    if [ "$DRY_RUN" -eq 1 ]; then
        say "Будет установлено:"
        case "$mode" in
            client) say "  только клиент SSClash-Go $GO_VER" ;;
            core)   say "  только ядро Mihomo $CORE_VER" ;;
            *)      say "  SSClash-Go $GO_VER и ядро Mihomo $CORE_VER" ;;
        esac
        say "  источник: официальный релиз + зеркала-прокси, sha256"
        say "  служба: /etc/init.d/ssclash"
        return 0
    fi

    [ "$(id -u)" = "0" ] || { say "Нужны права root."; return 1; }

    box=$(free_mb /overlay)
    [ -n "$box" ] && [ "$box" -lt 90 ] && {
        say "Мало места во флеш-памяти: ${box} МБ, нужно около 90 МБ."
        return 1
    }

    install_deps

    tmp_bin="/tmp/ssclash-linux-$ARCH"
    tmp_svc="/tmp/ssclash-openwrt-service.tar.gz"
    tmp_gz="/tmp/$CORE_FILE"

    need_client=0
    need_core=0
    case "$mode" in
        client) need_client=1 ;;
        core)   need_core=1 ;;
        *)      need_client=1; need_core=1 ;;
    esac

    if [ "$need_client" -eq 1 ]; then
        say ""
        say "Загрузка SSClash-Go $GO_VER..."
        if [ -n "$FROM_DIR" ] && [ -f "$FROM_DIR/ssclash-linux-$ARCH" ]; then
            cp "$FROM_DIR/ssclash-linux-$ARCH" "$tmp_bin" || return 1
        else
            fetch_github "$tmp_bin" "$GO_BASE/ssclash-linux-$ARCH" \
                || { say "Не удалось скачать клиент."; return 1; }
        fi
        check_sha "$tmp_bin" "$GO_SHA"

        say "Загрузка init-скрипта..."
        if [ -n "$FROM_DIR" ] && [ -f "$FROM_DIR/ssclash-openwrt-service.tar.gz" ]; then
            cp "$FROM_DIR/ssclash-openwrt-service.tar.gz" "$tmp_svc" || return 1
        else
            fetch_github "$tmp_svc" "$GO_BASE/ssclash-openwrt-service.tar.gz" \
                || { say "Не удалось скачать service bundle."; return 1; }
        fi
        check_sha "$tmp_svc" "$GO_SVC_SHA"
    fi

    if [ "$need_core" -eq 1 ]; then
        say "Загрузка ядра Mihomo..."
        if [ -n "$FROM_DIR" ] && [ -f "$FROM_DIR/$CORE_FILE" ]; then
            cp "$FROM_DIR/$CORE_FILE" "$tmp_gz" || return 1
        else
            fetch_github "$tmp_gz" "$CORE_BASE/$CORE_FILE" \
                || { say "Не удалось скачать ядро."; return 1; }
        fi
        check_sha "$tmp_gz" "$CORE_SHA"
        say "sha256: совпали"
    fi

    say "Остановка службы..."
    stop_go

    make_dirs
    if [ "$need_client" -eq 1 ]; then
        cur="$(go_version)"
        if [ -x /opt/clash/bin/ssclash ]; then
            cp /opt/clash/bin/ssclash "/opt/clash/bin/ssclash.$cur.bak" 2>/dev/null || true
        fi
        cp "$tmp_bin" /opt/clash/bin/ssclash || { say "Не удалось установить клиент."; return 1; }
        chmod 755 /opt/clash/bin/ssclash
        tar -xzf "$tmp_svc" -C / || { say "Не удалось распаковать init-скрипт."; return 1; }
        chmod 755 /etc/init.d/ssclash
        rm -f "$tmp_bin" "$tmp_svc"
    fi

    if [ "$need_core" -eq 1 ]; then
        install_core "$tmp_gz" || return 1
        rm -f "$tmp_gz"
    fi

    /etc/init.d/ssclash enable >/dev/null 2>&1 || true
    /etc/init.d/ssclash start >/dev/null 2>&1 || true
    sleep 3

    say ""
    if pidof ssclash >/dev/null 2>&1; then
        say "Готово: SSClash-Go $GO_VER, ядро $CORE_VER."
        say "Веб-интерфейс: http://<IP>:9091"
    else
        say "Пакет установлен, но служба не запустилась — проверьте logread."
    fi
    return 0
}

remove_go() {
    if ! go_installed && [ ! -x /etc/init.d/ssclash ]; then
        say "SSClash-Go не установлен."
        return 0
    fi
    say ""
    say "ВНИМАНИЕ: будет удалён SSClash-Go (клиент и служба)."
    say "Конфиг /opt/clash не затрагивается."
    if [ "$DRY_RUN" -eq 0 ] && ! ask_yes "Продолжить?"; then say "Отменено."; return 1; fi

    if [ "$DRY_RUN" -eq 1 ]; then
        say "[dry-run] остановить и удалить /etc/init.d/ssclash и /opt/clash/bin/ssclash"
        return 0
    fi

    stop_go
    [ -x /etc/init.d/ssclash ] && /etc/init.d/ssclash disable >/dev/null 2>&1
    rm -f /etc/init.d/ssclash /opt/clash/bin/ssclash
    say "SSClash-Go удалён."

    if [ -d "$CLASH_DIR" ] && ask_yes "Удалить /opt/clash (конфиг, подписки, ядро)?"; then
        [ "$DRY_RUN" -eq 1 ] || rm -rf "$CLASH_DIR"
        say "Каталог /opt/clash удалён."
    fi
    return 0
}

# ---------------- SSClash 4 --------------------------------------

remove_go_for_ss4() {
    go_installed || return 0
    say ""
    say "Установлен SSClash-Go. Вместе с SSClash 4 они не работают."
    if [ "$DRY_RUN" -eq 0 ]; then
        if ! ask_yes "Удалить SSClash-Go и продолжить?"; then
            say "Отменено."
            return 1
        fi
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
        say "[dry-run] удалить SSClash-Go"
        return 0
    fi
    stop_go
    [ -x /etc/init.d/ssclash ] && /etc/init.d/ssclash disable >/dev/null 2>&1
    rm -f /etc/init.d/ssclash /opt/clash/bin/ssclash
    say "SSClash-Go удалён."
    return 0
}

install_ss4() {
    mode="${1:-full}"
    say ""
    if ! remove_go_for_ss4; then return 1; fi

    if [ "$DRY_RUN" -eq 1 ]; then
        say "Будет установлено:"
        if [ "$mode" = "core" ]; then
            say "  только ядро Mihomo $CORE_VER"
        else
            say "  SSClash 4 $SS4_VER ($SS4_FILE) и ядро Mihomo $CORE_VER"
            say "  служба останется выключенной до настройки в LuCI"
        fi
        say "  источник: зеркало в репозитории + официальный релиз"
        return 0
    fi

    [ "$(id -u)" = "0" ] || { say "Нужны права root."; return 1; }

    box=$(free_mb /overlay)
    [ -n "$box" ] && [ "$box" -lt 90 ] && {
        say "Мало места во флеш-памяти: ${box} МБ, нужно около 90 МБ."
        return 1
    }

    install_deps

    tmp_pkg="/tmp/$SS4_FILE"
    tmp_gz="/tmp/$CORE_FILE"

    if [ "$mode" != "core" ]; then
        say ""
        say "Загрузка SSClash 4 $SS4_VER..."
        if [ -n "$FROM_DIR" ] && [ -f "$FROM_DIR/$SS4_FILE" ]; then
            cp "$FROM_DIR/$SS4_FILE" "$tmp_pkg" || return 1
        else
            fetch "$tmp_pkg" \
                "$JSD_BASE/third_party/ssclash4/$SS4_FILE" \
                "$RAW_BASE/third_party/ssclash4/$SS4_FILE" \
                "$REPO/raw/main/third_party/ssclash4/$SS4_FILE" \
                "$SS4_BASE/$SS4_FILE" \
                || { say "Не удалось скачать пакет SSClash 4."; return 1; }
        fi
        check_sha "$tmp_pkg" "$SS4_SHA"
    fi

    say "Загрузка ядра Mihomo..."
    if [ -n "$FROM_DIR" ] && [ -f "$FROM_DIR/$CORE_FILE" ]; then
        cp "$FROM_DIR/$CORE_FILE" "$tmp_gz" || return 1
    else
        fetch_github "$tmp_gz" "$CORE_BASE/$CORE_FILE" \
            || { say "Не удалось скачать ядро."; return 1; }
    fi
    check_sha "$tmp_gz" "$CORE_SHA"
    say "sha256: совпали"

    was_running=0
    service_running clash && was_running=1
    stop_ss4
    stop_go

    if [ "$mode" != "core" ]; then
        say "Установка пакета..."
        if [ "$PM" = "apk" ]; then
            apk add --allow-untrusted "$tmp_pkg" || { say "apk add не удался."; return 1; }
        else
            opkg install "$tmp_pkg" || { say "opkg install не удался."; return 1; }
        fi
        rm -f "$tmp_pkg"
    fi

    install_core "$tmp_gz" || return 1
    rm -f "$tmp_gz"

    if [ "$mode" = "core" ] && [ "$was_running" -eq 1 ]; then
        [ -x /etc/init.d/clash ] && /etc/init.d/clash start >/dev/null 2>&1 || true
    else
        if [ -x /etc/init.d/clash ]; then
            /etc/init.d/clash stop >/dev/null 2>&1 || true
            /etc/init.d/clash disable >/dev/null 2>&1 || true
        fi
    fi

    rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
    /etc/init.d/rpcd restart >/dev/null 2>&1 || true
    /etc/init.d/uhttpd reload >/dev/null 2>&1 || true

    say ""
    if [ "$mode" = "core" ]; then
        say "Готово: ядро Mihomo $CORE_VER."
    else
        say "Готово: SSClash 4 $SS4_VER, ядро $CORE_VER."
        say "Откройте LuCI → Services → SSClash и запустите службу."
    fi
    return 0
}

remove_ss4() {
    if ! ss4_installed && [ ! -x /etc/init.d/clash ]; then
        say "SSClash 4 не установлен."
        return 0
    fi
    say ""
    say "ВНИМАНИЕ: будет удалён пакет luci-app-ssclash и init-скрипт."
    say "Конфиг /opt/clash не затрагивается."
    if [ "$DRY_RUN" -eq 0 ] && ! ask_yes "Продолжить?"; then say "Отменено."; return 1; fi

    if [ "$DRY_RUN" -eq 1 ]; then
        say "[dry-run] остановить службу и удалить luci-app-ssclash"
        return 0
    fi

    stop_ss4
    [ -x /etc/init.d/clash ] && /etc/init.d/clash disable >/dev/null 2>&1
    if [ "$PM" = "apk" ]; then
        apk del luci-app-ssclash >/dev/null 2>&1 || true
    else
        opkg remove luci-app-ssclash >/dev/null 2>&1 || true
    fi
    rm -f /etc/init.d/clash
    rm -rf /tmp/luci-indexcache* /tmp/luci-modulecache
    /etc/init.d/rpcd restart >/dev/null 2>&1 || true
    /etc/init.d/uhttpd reload >/dev/null 2>&1 || true
    say "SSClash 4 удалён."

    if [ -d "$CLASH_DIR" ] && ask_yes "Удалить /opt/clash (конфиг, подписки, ядро)?"; then
        rm -rf "$CLASH_DIR"
        say "Каталог /opt/clash удалён."
    fi
    return 0
}

# ---------------- сценарии ---------------------------------------

if [ "$STATUS_ONLY" -eq 1 ]; then
    show_status
    exit 0
fi

if [ "$UNINSTALL" -eq 1 ]; then
    case "$VARIANT" in
        go)  remove_go; exit $? ;;
        ss4) remove_ss4; exit $? ;;
        "")
            if go_installed && ! ss4_installed; then remove_go; exit $?
            elif ss4_installed && ! go_installed; then remove_ss4; exit $?
            else
                say "Уточните, что удалять: --go или --ss4."
                exit 1
            fi
            ;;
    esac
fi

if [ -n "$VARIANT" ]; then
    if [ "$VARIANT" = "go" ]; then
        install_go "$MODE"; exit $?
    else
        install_ss4 "$MODE"; exit $?
    fi
fi

if [ "$ASSUME_YES" -eq 1 ] || [ "$DRY_RUN" -eq 1 ]; then
    say "Укажите версию: --go или --ss4."
    exit 1
fi

if [ ! -t 0 ]; then
    say "SSClash: установка"
    say "Запустите интерактивно или укажите: sh $0 --go --yes | --ss4 --yes"
    exit 0
fi

say "========================================"
say " SSClash: установка и обновление"
say "========================================"
say " устройство: $(cat /tmp/sysinfo/model 2>/dev/null || echo '?')"
say " OpenWrt $DISTRIB_RELEASE, $DISTRIB_ARCH"
if go_installed; then
    say " установлено: SSClash-Go $(go_version) (ядро $(core_version))"
elif ss4_installed; then
    say " установлено: SSClash 4 $(pkg_version luci-app-ssclash) (ядро $(core_version))"
else
    say " установлено: ничего (ядро $(core_version))"
fi

while :; do
    say ""
    say "Что установить?"
    say "  1) SSClash-Go — новая версия, веб-интерфейс :9091"
    say "  2) SSClash 4 — LuCI, Services → SSClash"
    say "  0) Выйти"
    printf 'Выбор: '
    read choice

    case "$choice" in
        1|"") run_go_menu=1; break ;;
        2)     run_go_menu=0; break ;;
        0)     say "Выход."; exit 0 ;;
        *)     say "Введите 1, 2 или 0." ;;
    esac
done

if [ "$run_go_menu" = "1" ]; then
    while :; do
        say ""
        say "SSClash-Go"
        say "  версия: $GO_VER, ядро Mihomo $CORE_VER"
        say "  установлено: $(go_version)"
        say ""
        say "  1) Установить / обновить всё"
        say "  2) Обновить только клиент"
        say "  3) Обновить только ядро Mihomo"
        say "  4) Проверить состояние"
        say "  5) Удалить SSClash-Go"
        say "  0) Назад"
        printf 'Выбор: '
        read choice
        case "$choice" in
            ""|1) install_go full ;;
            2)    install_go client ;;
            3)    install_go core ;;
            4)    show_status ;;
            5)    remove_go ;;
            0)    break ;;
            *)    say "Введите 1–5 или 0." ;;
        esac
    done
else
    while :; do
        say ""
        say "SSClash 4"
        say "  версия: $SS4_VER, ядро Mihomo $CORE_VER"
        say "  установлено: $(pkg_version luci-app-ssclash)"
        say ""
        say "  1) Установить / обновить"
        say "  2) Обновить только ядро Mihomo"
        say "  3) Проверить состояние"
        say "  4) Удалить SSClash 4"
        say "  0) Назад"
        printf 'Выбор: '
        read choice
        case "$choice" in
            ""|1) install_ss4 full ;;
            2)    install_ss4 core ;;
            3)    show_status ;;
            4)    remove_ss4 ;;
            0)    break ;;
            *)    say "Введите 1–4 или 0." ;;
        esac
    done
fi
