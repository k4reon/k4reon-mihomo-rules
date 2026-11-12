#!/bin/sh
# ============================================================
#  SSClash-Go memory tuning for OpenWrt (procd)
#
#  Добавляет Go-рантайму SSClash переменные:
#    GOGC       — как часто запускать сборщик мусора (по умолчанию 100)
#    GOMEMLIMIT — мягкий лимит памяти Go
#
#  Идея: F5GO-Mihomo-stuff (MIT)
#  https://github.com/F5GO/F5GO-Mihomo-stuff
#
#  Запуск (обычно без аргументов — дальше скрипт спрашивает):
#    sh memory-limit.sh
#
#  Неинтерактивные варианты:
#    sh memory-limit.sh --yes            # применить рекомендуемые
#    sh memory-limit.sh 50 96MiB         # свои значения
#    sh memory-limit.sh --dry-run        # показать diff, ничего не менять
#    sh memory-limit.sh --restore        # вернуть исходный init-скрипт
#
#  Только OpenWrt: на Keenetic другой init-скрипт.
#  GOMEMLIMIT — мягкий лимит: он не ограничивает RSS жёстко.
# ============================================================

set -u

INIT="${SSCLASH_INIT:-/etc/init.d/ssclash}"
BACKUP="$INIT.bak"
TMP="$(mktemp 2>/dev/null || echo "/tmp/ssclash-mem.$$")"

DRY_RUN=0
RESTORE=0
ASSUME_YES=0
EXPLICIT=0
GOGC_VALUE=""
GOMEMLIMIT_VALUE=""

say() { printf '%s\n' "$*"; }
warn() { printf 'ВНИМАНИЕ: %s\n' "$*"; }
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

[ -f "$INIT" ] || die "не найден $INIT. Скрипт для OpenWrt с установленным SSClash-Go."
grep -q 'SSCLASH_ROOT' "$INIT" || die "$INIT не похож на init-скрипт SSClash-Go."

MEM_KB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)"
MEM_MB=$(( ${MEM_KB:-0} / 1024 ))
[ "$MEM_MB" -eq 0 ] && MEM_MB=0

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

# ---------------- apply / restore ----------------

show_diff() {
    grep -v -E 'procd_append_param env (GOGC|GOMEMLIMIT)=' "$INIT" > "$TMP" || die "не удалось прочитать $INIT"
    awk -v gogc="$GOGC_VALUE" -v gomem="$GOMEMLIMIT_VALUE" '
        /procd_set_param env SSCLASH_ROOT/ {
            print
            print "\tprocd_append_param env GOGC=\"" gogc "\""
            print "\tprocd_append_param env GOMEMLIMIT=\"" gomem "\""
            next
        }
        { print }
    ' "$TMP" > "$TMP.new" || die "не удалось подготовить изменения"
    diff -u "$INIT" "$TMP.new" 2>/dev/null | sed -n '3,$p'
}

apply_values() {
    say ""
    say "Будет применено:"
    say "  GOGC       = $GOGC_VALUE"
    say "  GOMEMLIMIT = $GOMEMLIMIT_VALUE"
    say ""

    if [ "$DRY_RUN" -eq 1 ]; then
        say "Изменения (dry-run, файл не меняется):"
        show_diff
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

    grep -v -E 'procd_append_param env (GOGC|GOMEMLIMIT)=' "$INIT" > "$TMP" || die "не удалось прочитать $INIT"
    awk -v gogc="$GOGC_VALUE" -v gomem="$GOMEMLIMIT_VALUE" '
        /procd_set_param env SSCLASH_ROOT/ {
            print
            print "\tprocd_append_param env GOGC=\"" gogc "\""
            print "\tprocd_append_param env GOMEMLIMIT=\"" gomem "\""
            next
        }
        { print }
    ' "$TMP" > "$TMP.new" || die "не удалось подготовить изменения"

    mv "$TMP.new" "$INIT" || die "не удалось записать $INIT"
    chmod 755 "$INIT"
    rm -f "$TMP"

    say "Перезапуск SSClash..."
    "$INIT" restart || die "перезапуск не удался."

    sleep 5
    PID="$(pgrep -f '^/opt/clash/bin/clash ' 2>/dev/null | head -n 1)"
    if [ -z "$PID" ]; then
        warn "процесс mihomo ещё не виден. Настройки применятся при следующем старте."
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
    say "Перезапуск SSClash..."
    "$INIT" restart || die "перезапуск не удался."
    say "Готово: настройка памяти убрана."
}

# ---------------- non-interactive paths ----------------

if [ "$RESTORE" -eq 1 ]; then
    restore_values
    exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
    apply_values
    exit 0
fi

if [ "$ASSUME_YES" -eq 1 ] || [ "$EXPLICIT" -ge 2 ]; then
    apply_values
    exit 0
fi

# не терминал и нет флагов — ничего не меняем
if [ ! -t 0 ]; then
    say "SSClash-Go memory tuning"
    say "Рекомендуется: GOGC=$GOGC_VALUE, GOMEMLIMIT=$GOMEMLIMIT_VALUE"
    say ""
    say "Запустите интерактивно (в терминале) или укажите:"
    say "  sh $0 --yes"
    say "  sh $0 50 96MiB"
    exit 0
fi

# ---------------- interactive menu ----------------

say "========================================"
say " SSClash-Go: настройка памяти"
say "========================================"
say " ОЗУ роутера:  $MEM_MB MiB"
say " Рекомендуется: GOGC=$GOGC_VALUE, GOMEMLIMIT=$GOMEMLIMIT_VALUE"
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
