#!/bin/sh
# ============================================================
#  SSClash-Go memory tuning for OpenWrt (procd)
#
#  Adds Go runtime limits to the SSClash service:
#    GOGC       — how often the garbage collector runs (default 100)
#    GOMEMLIMIT — soft memory limit for the Go runtime
#
#  Idea: F5GO-Mihomo-stuff (MIT)
#  https://github.com/F5GO/F5GO-Mihomo-stuff
#
#  Usage:
#    ./memory-limit.sh              # auto: GOGC=75, limit = 25% RAM (64..256 MiB)
#    ./memory-limit.sh 50 96MiB     # explicit values
#    ./memory-limit.sh --dry-run    # show what would be done, change nothing
#    ./memory-limit.sh --restore    # restore the original init script
#
#  OpenWrt only: procd_append_param is used. On Keenetic the init script
#  is SysV-style (/opt/etc/init.d/S99ssclash) and this script does not apply.
#
#  GOMEMLIMIT is a SOFT limit: it does not cap RSS, it only tells the Go
#  runtime when to start collecting more aggressively.
# ============================================================

set -u

INIT="${SSCLASH_INIT:-/etc/init.d/ssclash}"
BACKUP="$INIT.bak"
TMP="$(mktemp 2>/dev/null || echo /tmp/ssclash-mem.$$)"
DRY_RUN=0
RESTORE=0
GOGC_VALUE=""
GOMEMLIMIT_VALUE=""

usage() {
    sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --restore) RESTORE=1 ;;
        --help|-h) usage ;;
        *) ;;
    esac
done

# positional arguments (after flags) are GOGC and GOMEMLIMIT
POS=0
for arg in "$@"; do
    case "$arg" in
        --*) continue ;;
        *)
            POS=$((POS + 1))
            if [ "$POS" -eq 1 ]; then GOGC_VALUE="$arg"; fi
            if [ "$POS" -eq 2 ]; then GOMEMLIMIT_VALUE="$arg"; fi
            ;;
    esac
done

if [ ! -f "$INIT" ]; then
    echo "ERROR: init script not found: $INIT"
    echo "       This script is for OpenWrt with SSClash-Go installed."
    exit 1
fi

if ! grep -q 'SSCLASH_ROOT' "$INIT"; then
    echo "ERROR: $INIT does not look like the SSClash-Go init script"
    echo "       (SSCLASH_ROOT not found)."
    exit 1
fi

if [ "$RESTORE" -eq 1 ]; then
    if [ ! -f "$BACKUP" ]; then
        echo "ERROR: backup not found: $BACKUP"
        exit 1
    fi
    if [ "$(id -u)" != "0" ] && [ "$DRY_RUN" -eq 0 ]; then
        echo "ERROR: run as root."
        exit 1
    fi
    echo "Restoring $INIT from $BACKUP"
    [ "$DRY_RUN" -eq 1 ] && { echo "(dry-run) nothing changed"; exit 0; }
    cp "$BACKUP" "$INIT" || exit 1
    "$INIT" restart
    echo "Done. Memory limits removed."
    exit 0
fi

# ---- auto values -------------------------------------------------
MEM_TOTAL_KB="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)"
MEM_TOTAL_MB=$(( ${MEM_TOTAL_KB:-0} / 1024 ))

if [ -z "$GOGC_VALUE" ]; then
    GOGC_VALUE=75
fi

if [ -z "$GOMEMLIMIT_VALUE" ]; then
    AUTO_MB=$(( MEM_TOTAL_MB / 4 ))
    [ "$AUTO_MB" -lt 64 ] && AUTO_MB=64
    [ "$AUTO_MB" -gt 256 ] && AUTO_MB=256
    [ "$MEM_TOTAL_MB" -eq 0 ] && AUTO_MB=128
    GOMEMLIMIT_VALUE="${AUTO_MB}MiB"
fi

case "$GOMEMLIMIT_VALUE" in
    *MiB|*GiB|*KiB|*B) ;;
    *[!0-9]*) echo "ERROR: bad GOMEMLIMIT value: $GOMEMLIMIT_VALUE (use e.g. 128MiB)"; exit 1 ;;
    *) GOMEMLIMIT_VALUE="${GOMEMLIMIT_VALUE}MiB" ;;
esac

echo "========================================"
echo " SSClash-Go memory tuning"
echo "========================================"
echo " init:       $INIT"
echo " RAM:        ${MEM_TOTAL_MB} MiB"
echo " GOGC:       $GOGC_VALUE"
echo " GOMEMLIMIT: $GOMEMLIMIT_VALUE"
echo

if [ "$DRY_RUN" -eq 0 ] && [ "$(id -u)" != "0" ]; then
    echo "ERROR: run as root."
    exit 1
fi

if [ "$DRY_RUN" -eq 0 ]; then
    if [ ! -f "$BACKUP" ]; then
        cp "$INIT" "$BACKUP" || { echo "ERROR: backup failed"; exit 1; }
        echo "Backup: $BACKUP"
    else
        echo "Backup already exists: $BACKUP"
    fi
fi

# ---- remove previous lines, insert new pair after SSCLASH_ROOT ----
grep -v -E 'procd_append_param env (GOGC|GOMEMLIMIT)=' "$INIT" > "$TMP" || exit 1

awk -v gogc="$GOGC_VALUE" -v gomem="$GOMEMLIMIT_VALUE" '
    /procd_set_param env SSCLASH_ROOT/ {
        print
        print "\tprocd_append_param env GOGC=\"" gogc "\""
        print "\tprocd_append_param env GOMEMLIMIT=\"" gomem "\""
        next
    }
    { print }
' "$TMP" > "$TMP.new" || exit 1

echo "Changes:"
diff -u "$INIT" "$TMP.new" 2>/dev/null | sed -n '3,$p'
echo

if [ "$DRY_RUN" -eq 1 ]; then
    echo "(dry-run) nothing changed"
    rm -f "$TMP" "$TMP.new"
    exit 0
fi

mv "$TMP.new" "$INIT" || exit 1
chmod 755 "$INIT"
rm -f "$TMP"

echo "Restarting SSClash..."
"$INIT" restart || { echo "ERROR: restart failed"; exit 1; }

sleep 5

PID="$(pgrep -f '^/opt/clash/bin/clash ' 2>/dev/null | head -n 1)"
if [ -z "$PID" ]; then
    echo "WARNING: mihomo process not detected yet; settings will apply on next start."
    exit 0
fi

echo "mihomo PID: $PID"
echo "Environment:"
tr '\0' '\n' < "/proc/$PID/environ" 2>/dev/null | grep -E '^(GOGC|GOMEMLIMIT)=' || true
echo
echo "Memory:"
grep -E 'VmRSS' "/proc/$PID/status" 2>/dev/null || true
free -m 2>/dev/null | head -n 2
echo
echo "Done. To undo: $0 --restore"
