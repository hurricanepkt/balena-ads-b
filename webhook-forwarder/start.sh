#!/usr/bin/env bash
set -euo pipefail

WEBHOOK_URL="${WEBHOOK_URL:-https://webhook.site/adsb}"
POLL_INTERVAL="${POLL_INTERVAL:-10}"
SOURCE_NAME="${SOURCE_NAME:-dump1090-fa}"
DUMP1090_URL="${DUMP1090_URL:-http://dump1090-fa:8080/data/aircraft.json}"

if [ -z "$WEBHOOK_URL" ]; then
  echo "WEBHOOK_URL is not set. Exiting."
  exit 1
fi

echo "Forwarding aircraft data from $DUMP1090_URL to $WEBHOOK_URL every ${POLL_INTERVAL}s"

while true; do
  timestamp=$(date -u +%FT%TZ)

  if ! curl -fsS "$DUMP1090_URL" -o /tmp/aircraft.json; then
    echo "Failed to fetch $DUMP1090_URL. Retrying in ${POLL_INTERVAL}s..."
    sleep "$POLL_INTERVAL"
    continue
  fi

  payload=$(jq -n \
    --arg timestamp "$timestamp" \
    --arg source "$SOURCE_NAME" \
    --argfile data /tmp/aircraft.json \
    '{timestamp: $timestamp, source: $source, data: $data}')

  if ! curl -fsS -X POST -H "Content-Type: application/json" -d "$payload" "$WEBHOOK_URL" >/dev/null; then
    echo "Failed to POST to $WEBHOOK_URL"
  fi

  sleep "$POLL_INTERVAL"
done
