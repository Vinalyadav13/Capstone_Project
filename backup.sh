#!/usr/bin/env bash
#
# backup.sh - simple, safe file/directory backup using rsync
#
# Usage:
#   ./backup.sh -s /path/to/source -d /path/to/backup_root [-r 7] [-e 'pattern1,pattern2'] [-h]

set -euo pipefail
IFS=$'\n\t'

show_help() {
  cat <<EOF
backup.sh - Backup files/directories using rsync (timestamped snapshots)

Usage:
  $0 -s SOURCE -d BACKUP_ROOT [-r RETAIN_DAYS] [-e EXCLUDE_LIST] [-h]

Options:
  -s SOURCE         Path to file or directory to backup (required)
  -d BACKUP_ROOT    Directory where backups will be stored (required)
  -r RETAIN_DAYS    Number of days to keep backups (default: 7)
  -e EXCLUDE_LIST   Comma-separated exclude patterns for rsync (optional)
  -h                Show this help and exit
EOF
}

# Defaults
RETAIN_DAYS=7
EXCLUDE=""

while getopts ":s:d:r:e:h" opt; do
  case $opt in
    s) SOURCE="$OPTARG" ;;
    d) BACKUP_ROOT="$OPTARG" ;;
    r) RETAIN_DAYS="$OPTARG" ;;
    e) EXCLUDE="$OPTARG" ;;
    h) show_help; exit 0 ;;
    \?) echo "Invalid option -$OPTARG" >&2; show_help; exit 1 ;;
  esac
done

if [ -z "${SOURCE-}" ] || [ -z "${BACKUP_ROOT-}" ]; then
  echo "Error: SOURCE and BACKUP_ROOT are required." >&2
  show_help
  exit 1
fi

TIMESTAMP=$(date +%Y%m%dT%H%M%S)
BACKUP_DIR="${BACKUP_ROOT%/}/backup_${TIMESTAMP}"
LOG_DIR="${HOME}/.maintenance/logs"
mkdir -p "$BACKUP_DIR" "$LOG_DIR"
LOGFILE="$LOG_DIR/backup_$(date +%Y%m%d).log"

echo "Starting backup of '$SOURCE' -> '$BACKUP_DIR'"
RSYNC_OPTS=(--archive --compress --human-readable --partial --progress --stats)

# Build exclude args if provided
EXCLUDE_ARGS=()
if [ -n "$EXCLUDE" ]; then
  IFS=',' read -r -a patterns <<< "$EXCLUDE"
  for p in "${patterns[@]}"; do
    EXCLUDE_ARGS+=(--exclude="$p")
  done
fi



if command -v rsync >/dev/null 2>&1; then
  echo "Using rsync for backup..." | tee -a "$LOGFILE"
  rsync "${RSYNC_OPTS[@]}" "${EXCLUDE_ARGS[@]}" "$SOURCE" "$BACKUP_DIR" 2>&1 | tee -a "$LOGFILE"
else
  echo "rsync not found — using cp instead." | tee -a "$LOGFILE"
  cp -r "$SOURCE"/* "$BACKUP_DIR"/ 2>&1 | tee -a "$LOGFILE"
fi


echo "Backup completed. Log: $LOGFILE"
