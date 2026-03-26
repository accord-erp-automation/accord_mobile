#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

flutter pub get
API_URL="${MOBILE_API_BASE_URL:-https://core.wspace.sbs}"
flutter run -d linux --dart-define=MOBILE_API_BASE_URL="$API_URL"
