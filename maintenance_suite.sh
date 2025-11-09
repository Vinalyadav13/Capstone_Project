#!/usr/bin/env bash
#
# maintenance_suite.sh - simple menu to run maintenance scripts in this project
#
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while true; do
  cat <<EOF
===============================================
Bash Maintenance Suite
Location: $SCRIPT_DIR
Choose an option:
  1) Run backup.sh
  2) Run update_clean.sh
  3) Run log_monitor.sh (interactive)
  4) Show logs directory
  5) Install cron job examples (will not enable without user confirmation)
  6) Exit
===============================================
EOF
  read -rp "Option> " opt
  case "$opt" in
    1)
      read -rp "Source path to backup: " s
      read -rp "Backup root directory: " d
      read -rp "Retain days (default 7): " r
      r=${r:-7}
      "$SCRIPT_DIR/backup.sh" -s "$s" -d "$d" -r "$r"
      ;;
    2)
      read -rp "Run update_clean.sh now? (y/N): " yn
      if [[ "$yn" =~ ^[Yy] ]]; then
        "$SCRIPT_DIR/update_clean.sh"
      else
        echo "Cancelled."
      fi
      ;;
    3)
      read -rp "Enter pattern to search (e.g. ERROR|failed): " p
      read -rp "Follow? (y/N): " f
      if [[ "$f" =~ ^[Yy] ]]; then
        "$SCRIPT_DIR/log_monitor.sh" -p "$p" -f
      else
        read -rp "Number of lines to scan (default 50): " n
        n=${n:-50}
        "$SCRIPT_DIR/log_monitor.sh" -p "$p" -n "$n"
      fi
      ;;
    4)
      ls -lh "${HOME}/.maintenance/logs" || echo "No logs yet."
      ;;
    5)
      cat <<CRON_SAMPLE
# Sample cron entries (add with crontab -e)
# Daily backup at 02:30 (adjust paths):
# 30 2 * * * /path/to/maintenance/backup.sh -s /home/user/projects -d /media/backup_drive/projects_backup -r 14 >> /home/user/.maintenance/logs/cron_backup.log 2>&1

# Weekly system update on Sunday at 03:00:
# 0 3 * * 0 /path/to/maintenance/update_clean.sh -y >> /home/user/.maintenance/logs/cron_update.log 2>&1
CRON_SAMPLE
      ;;
    6) echo "Goodbye."; exit 0 ;;
    *) echo "Invalid option" ;;
  esac
done
