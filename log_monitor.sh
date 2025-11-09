#!/usr/bin/env bash
#
# log_monitor.sh - basic log scanner and notifier (search patterns or follow)
#
# Usage:
#   ./log_monitor.sh -p 'ERROR|failed' [-f] [-l /var/log/syslog] [-n N]

set -euo pipefail
IFS=$'\n\t'

PATTERN=""
FOLLOW="false"
LOGFILE=""
NUM=50

while getopts ":p:fl:n:h" opt; do
  case $opt in
    p) PATTERN="$OPTARG" ;;
    f) FOLLOW="true" ;;
    l) LOGFILE="$OPTARG" ;;
    n) NUM="$OPTARG" ;;
    h) echo "Usage: $0 -p PATTERN [-f] [-l logfile] [-n N]"; exit 0 ;;
    \?) echo "Invalid option -$OPTARG"; exit 1 ;;
  esac
done

if [ -z "$PATTERN" ]; then
  echo "Please provide a pattern to search for with -p" >&2
  exit 1
fi

# try common log files if none provided
if [ -z "$LOGFILE" ]; then
  if [ -f /var/log/syslog ]; then LOGFILE=/var/log/syslog
  elif [ -f /var/log/messages ]; then LOGFILE=/var/log/messages
  elif command -v journalctl >/dev/null 2>&1; then
    echo "Using journalctl as source (systemd)."
    if [ "$FOLLOW" = "true" ]; then
      journalctl -f | grep --line-buffered -E "$PATTERN"
      exit 0
    else
      journalctl -n "$NUM" | grep -E "$PATTERN" || true
      exit 0
    fi
  else
    echo "No log source found. Provide -l /path/to/logfile" >&2
    exit 1
  fi
fi

if [ "$FOLLOW" = "true" ]; then
echo "DEBUG: FOLLOW=$FOLLOW, LOGFILE=$LOGFILE, PATTERN=$PATTERN"
  echo "Following $LOGFILE for pattern: $PATTERN"
  tail -n 0 -f "$LOGFILE" | grep --line-buffered -E "$PATTERN"
else
  echo "Searching last $NUM lines of $LOGFILE for pattern: $PATTERN"
  tail -n "$NUM" "$LOGFILE" | grep -E "$PATTERN" || echo "No matches found."
fi

