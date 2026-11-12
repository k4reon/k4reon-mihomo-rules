#!/bin/sh
# ============================================================
#  SSClash memory tuning for OpenWrt (procd)
#
#  Поддерживает два варианта:
#    - SSClash-Go  -> /etc/init.d/ssclash  (env SSCLASH_ROOT)
#    - SSClash 4   -> /etc/init.d/clash    (LuCI-приложение)
#
#  Добавляет Go-рантайму переменные:
#    GOGC       — как часто запускать сборщик мусора (по умолчанию 100)
#    GOMEMLIMIT — мягкий лимит памяти Go
#
#  Запуск (дальше скрипт спросит):
#    sh memory-limit.sh
#
#  Без вопросов:
#    sh memory-limit.sh --yes
#    sh memory-limit.sh 50 96MiB
#    sh memory-limit.sh --dry-run
#    sh memory-limit.sh --restore
#
#  Только OpenWrt (procd). GOMEMLIMIT — мягкий лимит, не жёсткий RSS.
# ============================================================

set -u

DRY_RUN=0
RESTORE=0
ASSUME_YES=0
EXPLICIT=0
GOGC_VALUE=""
GOMEMLIMIT_VALUE=""
KIND=""
INIT=""
BACKUP=""
TMP="$(mktemp 2>/dev/null || echo "/tmp/ssclash-mem.$$")"

say() { printf '%s\n' "$*"; }
die() { printf 'ОШИБКА: %s\n' "$*"; exit 1; }

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --restore) RESTORE=1 ;;
        --yes|-y)  ASSUME_YES=1 ;;
        --help|-h)
            sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        --*) ;;
        *)
            if [ -z "$GOGC_VALUE" ]; then
                GOGC_VALUE="$arg"
            elif [ -z "$GOMEMLIMIT_VALUE" ]; then
                GOMEMLIMIT_VALUE="$arg"
            fi
            EXPLICIT=$((EXPLICIT + 1))
            ;;
    esac
done

# ---- определяем вариант SSClash ---------------------------------
CANDIDATE="${SSCLASH_INIT:-}"
if [ -n "$CANDIDATE" ]; then
    [ -f "$CANDIDATE" ] || die "не найден $CANDIDATE"
else
    if [ -f /etc/init.d/ssclash ]; then
        CANDIDATE=/etc/init.d/ssclash
    elif [ -f /etc/init.d/clash ]; then
        CANDIDATE=/etc/init.d/clash
    else
        die "не найден init-скрипт SSClash (/etc/init.d/ssclash или /etc/init.d/clash)."
    fi
fi

INIT="$CANDIDATE"
BACKUP="$INIT.bak"

if grep -q 'SSCLASH_ROOT' "$INIT"; then
    KIND="SSClash-Go"
    ANCHOR="procd_set_param env SSCLASH_ROOT"
elif grep -q 'procd_set_param command' "$INIT"; then
    KIND="SSClash 4"
    ANCHOR="procd_set_param command"
else
    die "$INIT не похож на init-скрипт SSClash."
fi

# ---- значения ----------------------------------------------------
MEM_KB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)"
MEM_MB=$(( ${MEM_KB:-0} / 1024 ))

if [ -z "$GOMEMLIMIT_VALUE" ]; then
    AUTO_MB=$(( MEM_MB / 4 ))
    [ "$AUTO_MB" -lt 64 ] && AUTO_MB=64
    [ "$AUTO_MB" -gt 256 ] && AUTO_MB=256
    [ "$MEM_MB" -eq 0 ] && AUTO_MB=128
    GOMEMLIMIT_VALUE="${AUTO_MB}MiB"
fi
[ -z "$GOGC_VALUE" ] && GOGC_VALUE=75

case "$GOMEMLIMIT_VALUE" in
    *MiB|*GiB|*KiB|*B) ;;
    *[!0-9]*) die "неверное значение GOMEMLIMIT: $GOMEMLIMIT_VALUE (например, 128MiB)" ;;
    *) GOMEMLIMIT_VALUE="${GOMEMLIMIT_VALUE}MiB" ;;
esac

case "$GOGC_VALUE" in
    *[!0-9]*|"") die "неверное значение GOGC: $GOGC_VALUE (целое число, например 75)" ;;
esac

if [ "$MEM_MB" -ge 512 ]; then
    REC_SHORT="обычно не требуется"
    REC_DETAIL="Памяти достаточно, настройка не обязательна."
elif [ "$MEM_MB" -ge 192 ]; then
    REC_SHORT="можно применить"
    REC_DETAIL="Если mihomo заметно разрастается или есть просадки."
else
    REC_SHORT="рекомендуется"
    REC_DETAIL="Памяти мало: mihomo может занимать её заметную часть."
fi

# ---- изменение ---------------------------------------------------

build_new() {
    grep -v -E 'procd_append_param env (GOGC|GOMEMLIMIT)=' "$INIT" > "$TMP" \
        || die "не удалось прочитать $INIT"

    if [ "$KIND" = "SSClash-Go" ]; then
        awk -v anchor="$ANCHOR" -v gogc="$GOGC_VALUE" -v gomem="$GOMEMLIMIT_VALUE" '
            index($0, anchor) {
                print
                print "\tprocd_append_param env GOGC=\"" gogc "\""
                print "\tprocd_append_param env GOMEMLIMIT=\"" gomem "\""
                next
            }
            { print }
        ' "$TMP" > "$TMP.new" || die "не удалось подготовить изменения"
    else
        awk -v anchor="$ANCHOR" -v gogc="$GOGC_VALUE" -v gomem="$GOMEMLIMIT_VALUE" '
            index($0, anchor) && !done {
                print
                print "\tprocd_append_param env GOGC=\"" gogc "\""
                print "\tprocd_append_param env GOMEMLIMIT=\"" gomem "\""
                done = 1
                next
            }
            { print }
        ' "$TMP" > "$TMP.new" || die "не удалось подготовить изменения"
    fi

    PREVIEW="	procd_append_param env GOGC=\"$GOGC_VALUE\"
	procd_append_param env GOMEMLIMIT=\"$GOMEMLIMIT_VALUE\""
}

apply_values() {
    build_new

    say ""
    say "Вариант:      $KIND"
    say "init:         $INIT"
    say "ОЗУ роутера:  $MEM_MB MiB"
    say "GOGC:         $GOGC_VALUE"
    say "GOMEMLIMIT:   $GOMEMLIMIT_VALUE"
    say ""
    say "Будет добавлено:"
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

    say "Перезапуск $KIND..."
    "$INIT" restart || die "перезапуск не удался."

    sleep 5
    PID="$(pgrep -f '^/opt/clash/bin/clash ' 2>/dev/null | head -n 1)"
    if [ -z "$PID" ]; then
        say "Процесс mihomo ещё не виден, настройки применятся при следующем старте."
        return 0
    fi

    say ""
    say "Готово. mihomo PID: $PID"
    say "Переменные:"
    tr '\0' '\n' < "/proc/$PID/environ" 2>/dev/null | grep -E '^(GOGC|GOMEMLIMIT)=' || true
    say "Память:"
    grep -E 'VmRSS' "/proc/$PID/status" 2>/dev/null || true
    free -m 2>/dev/null | head -n 2
    say ""
    say "Откатить: sh $0 --restore"
}

restore_values() {
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
    say "Перезапуск $KIND..."
    "$INIT" restart || die "перезапуск не удался."
    say "Готово: настройка памяти убрана."
}

# ---- ветки запуска ---------------------------------------------

if [ "$RESTORE" -eq 1 ]; then
    restore_values
    exit 0
fi

if [ "$DRY_RUN" -eq 1 ] || [ "$ASSUME_YES" -eq 1 ] || [ "$EXPLICIT" -ge 2 ]; then
    apply_values
    exit 0
fi

if [ ! -t 0 ]; then
    say "SSClash: настройка памяти ОЗУ"
    say "Вариант:      $KIND"
    say "ОЗУ роутера:  $MEM_MB MiB"
    say "Рекомендуется: GOGC=$GOGC_VALUE, GOMEMLIMIT=$GOMEMLIMIT_VALUE"
    say ""
    say "Запустите интерактивно или укажите:"
    say "  sh $0 --yes"
    say "  sh $0 50 96MiB"
    exit 0
fi

# ---- интерактивное меню ---------------------------------------

say "========================================"
say " SSClash: настройка памяти ОЗУ"
say "========================================"
say " Вариант:      $KIND"
say " init:         $INIT"
say " ОЗУ роутера:  $MEM_MB MiB"
say " Совет:        $REC_SHORT"
say " $REC_DETAIL"
say ""
while :; do
    say "Что сделать?"
    say "  1) Применить рекомендуемые значения"
    say "  2) Указать свои значения"
    say "  3) Откатить (убрать настройку)"
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
            apply_values
            break
            ;;
        2)
            printf 'GOGC (по умолчанию 75): '
            read g
            [ -n "$g" ] && GOGC_VALUE="$g"
            printf 'GOMEMLIMIT (по умолчанию %s): ' "$GOMEMLIMIT_VALUE"
            read m
            [ -n "$m" ] && GOMEMLIMIT_VALUE="$m"
            apply_values
            break
            ;;
        3)
            restore_values
            break
            ;;
        0)
            say "Выход."
            exit 0
            ;;
        *)
            say "Введите 1, 2, 3 или 0."
            ;;
    esac
done
