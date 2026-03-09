API_URL ?= http://127.0.0.1:8081

.PHONY: run web analyze test deps backend-up backend-stop

deps:
	@flutter pub get

backend-up:
	@API_URL=$(API_URL) BACKEND_ROOT="$$(cd .. && pwd)" ./ensure_mobileapi.sh

backend-stop:
	@if [ -f .mobileapi.pid ]; then \
		kill "$$(cat .mobileapi.pid)" 2>/dev/null || true; \
		rm -f .mobileapi.pid; \
		echo "mobileapi stopped"; \
	else \
		echo "mobileapi pid file not found"; \
	fi

run: backend-up deps
	@flutter run -d linux --dart-define=MOBILE_API_BASE_URL=$(API_URL)

web: backend-up deps
	@flutter run -d chrome --dart-define=MOBILE_API_BASE_URL=$(API_URL)

analyze:
	@flutter analyze

test:
	@flutter test
