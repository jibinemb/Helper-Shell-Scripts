#!/bin/bash
#=========================================================
# RAM Tracking & High-Memory Process Reporting Script
# - Collects top memory-consuming processes every minute
# - Generates high-memory report for yesterday at 00:02
# - Preserves column alignment by using a fixed TIMESTAMP width
#=========================================================

set -euo pipefail
set -x  # Debug mode (comment out if too verbose)

#----------------------------------------
# Configuration
#----------------------------------------
BASE_DIR="/home/itops/ram_tracking"
LOG_DIR="/home/itops/ram_logs"
mkdir -p "$BASE_DIR" "$LOG_DIR"

DATE_NOW=$(date +'%Y%m%d%H%M')   # e.g. 202510241557 (12 chars)
DATE_TODAY=$(date +'%Y%m%d')
DATE_YESTERDAY=$(date -d "yesterday" +'%Y%m%d')

# Files
MEMLOGFILE="$LOG_DIR/mem_status_${DATE_TODAY}.log"
YESTERDAY_MEMLOG="$LOG_DIR/mem_status_${DATE_YESTERDAY}.log"
REPORTFILE="$LOG_DIR/high_mem_processes_${DATE_YESTERDAY}.log"

# Fixed width for TIMESTAMP prefix: 12 digits + ":" + space = 14 chars
TS_WIDTH=14   # used with printf "%-14s%s\n"

#----------------------------------------
# Step 1: Create log file with aligned header if missing
#----------------------------------------
if [ ! -f "$MEMLOGFILE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating new log file: $MEMLOGFILE"
    header_line=$(ps aux | head -1)                         # "USER PID %CPU %MEM ..." from ps
    printf "%-${TS_WIDTH}s%s\n" "TIMESTAMP:" "$header_line" > "$MEMLOGFILE"
fi

#----------------------------------------
# Step 2: Append top 15 memory-consuming processes with aligned prefix
#----------------------------------------
ps aux --sort=-%mem | head -n 16 | tail -n 15 | while IFS= read -r line; do
    printf "%-${TS_WIDTH}s%s\n" "${DATE_NOW}:" "$line" >> "$MEMLOGFILE"
done

#----------------------------------------
# Step 3: Generate high-memory report for yesterday (00:02 only)
#----------------------------------------
CURRENT_HOUR=$(date +'%H')
CURRENT_MINUTE=$(date +'%M')

if [[ "$CURRENT_HOUR" -eq 0 && "$CURRENT_MINUTE" -eq 2 ]]; then
    if [ -f "$YESTERDAY_MEMLOG" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Generating high-memory report from $YESTERDAY_MEMLOG"
        rm -f "$REPORTFILE" "$REPORTFILE.tmp"

        # Add header (preserve alignment)
        head -1 "$YESTERDAY_MEMLOG" > "$REPORTFILE"

        # Filter processes >5% memory (excluding mysql)
        # Note: ps header contains columns, actual %MEM in lines is 4th column for our logs (after TIMESTAMP removed)
        # We filter the original YESTERDAY_MEMLOG by removing TIMESTAMP header and checking the 4th field.
        grep -vE "TIMESTAMP|mysqld" "$YESTERDAY_MEMLOG" | \
            awk '{ if ($4+0 > 5.0) print $0 }' > "$REPORTFILE.tmp"

        # Extract unique commands and print last occurrence (keeps the full original line)
        awk '{for(i=11;i<=NF;i++) printf $i " "; print ""}' "$REPORTFILE.tmp" | sort -u | \
        while IFS= read -r cmd; do
            grep -F "$cmd" "$REPORTFILE.tmp" | tail -1
        done >> "$REPORTFILE"

        rm -f "$REPORTFILE.tmp"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Yesterday’s log not found: $YESTERDAY_MEMLOG — skipping report."
    fi
fi

