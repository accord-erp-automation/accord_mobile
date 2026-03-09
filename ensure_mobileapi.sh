#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$SCRIPT_DIR"
BACKEND_ROOT="${BACKEND_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
API_URL="${API_URL:-http://127.0.0.1:8081}"
PID_FILE="$APP_ROOT/.mobileapi.pid"
LOG_FILE="$APP_ROOT/.mobileapi.log"

if curl -fsS "$API_URL/healthz" >/dev/null 2>&1; then
	echo "mobileapi already running at $API_URL"
	exit 0
fi

echo "Starting mobileapi from $BACKEND_ROOT"
(
	cd "$BACKEND_ROOT"
	nohup go run ./cmd/mobileapi >"$LOG_FILE" 2>&1 &
	echo $! >"$PID_FILE"
)

for _ in $(seq 1 40); do
	if curl -fsS "$API_URL/healthz" >/dev/null 2>&1; then
		echo "mobileapi ready at $API_URL"
		exit 0
	fi
	sleep 0.5
done

echo "mobileapi failed to start; see $LOG_FILE" >&2
exit 1
