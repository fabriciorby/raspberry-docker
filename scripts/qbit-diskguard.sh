#!/bin/sh
# Stops downloading torrents in qBittorrent when free space on the torrent disk
# drops below MIN_FREE_GB, and starts the ones it stopped again once free space
# is back above RESUME_FREE_GB. Seeding torrents are left alone (they don't grow).

set -u

QBIT_URL="${QBIT_URL:-http://localhost:8080}"
API="$QBIT_URL/api/v2"
WATCH_PATH="${WATCH_PATH:-/data/torrents}"
MIN_FREE_GB="${MIN_FREE_GB:-10}"
RESUME_FREE_GB="${RESUME_FREE_GB:-15}"
INTERVAL="${INTERVAL:-30}"
STATE=/state/stopped-hashes
COOKIES=/tmp/cookies

log() { echo "$(date '+%F %T') $*"; }

login() {
  if [ -z "${QBITTORRENT_USERNAME:-}" ]; then
    log "WARN: QBITTORRENT_USERNAME is empty"
    return 1
  fi
  curl -fsS -c "$COOKIES" --referer "$QBIT_URL" \
    --data-urlencode "username=$QBITTORRENT_USERNAME" \
    --data-urlencode "password=${QBITTORRENT_PASSWORD:-}" \
    "$API/auth/login" >/dev/null
  # qBittorrent 5.2+ answers 204 with no body, older versions "Ok.": check for the session cookie
  grep -q SID "$COOKIES" 2>/dev/null
}

# Calls the API, logging in again once if the session expired
api() {
  curl -fsS -b "$COOKIES" --referer "$QBIT_URL" "$@" 2>/dev/null && return 0
  login && curl -fsS -b "$COOKIES" --referer "$QBIT_URL" "$@"
}

# Free space available to non-root users (what qBittorrent can use), in GB
free_gb() { df -Pk "$WATCH_PATH" | awk 'NR==2 { print int($4 / 1048576) }'; }

# Hashes of torrents that are downloading or about to (queued, stalled, checking...)
downloading_hashes() {
  api "$API/torrents/info" | tr '{' '\n' | awk '
    /"state":"(downloading|stalledDL|metaDL|forcedMetaDL|queuedDL|forcedDL|checkingDL|allocating)"/ {
      if (match($0, /"hash":"[0-9a-f]+"/)) print substr($0, RSTART + 8, RLENGTH - 9)
    }'
}

join_hashes() { tr '\n' '|' | sed 's/|$//'; }

mkdir -p /state
touch "$STATE"
login || log "WARN: login failed, check QBITTORRENT_USERNAME/QBITTORRENT_PASSWORD"
log "Watching $WATCH_PATH: stop below ${MIN_FREE_GB}GB, start again above ${RESUME_FREE_GB}GB"

while true; do
  free=$(free_gb)
  if [ -z "$free" ]; then
    log "WARN: could not read free space on $WATCH_PATH"
  elif [ "$free" -lt "$MIN_FREE_GB" ]; then
    # Checked every loop so torrents added while low on space get stopped too
    hashes=$(downloading_hashes)
    if [ -n "$hashes" ]; then
      if api --data-urlencode "hashes=$(echo "$hashes" | join_hashes)" "$API/torrents/stop" >/dev/null; then
        { cat "$STATE"; echo "$hashes"; } | sort -u > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"
        log "Free space ${free}GB < ${MIN_FREE_GB}GB: stopped $(echo "$hashes" | wc -l) downloading torrent(s)"
      else
        log "ERROR: failed to stop torrents"
      fi
    fi
  elif [ "$free" -ge "$RESUME_FREE_GB" ] && [ -s "$STATE" ]; then
    if api --data-urlencode "hashes=$(join_hashes < "$STATE")" "$API/torrents/start" >/dev/null; then
      log "Free space ${free}GB >= ${RESUME_FREE_GB}GB: started $(wc -l < "$STATE") torrent(s) again"
      : > "$STATE"
    else
      log "ERROR: failed to start torrents"
    fi
  fi
  sleep "$INTERVAL"
done
