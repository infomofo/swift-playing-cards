# My Makefile - for server side Swift projects

build:
	swift build

update:
	swift package update

release:
	swift build -c release

test:
	swift test --parallel

clean:
	rm -rf .build

lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		echo "Running SwiftLint..."; \
		swiftlint; \
	else \
		echo "SwiftLint not found, using fallback whitespace checker..."; \
		./scripts/lint-whitespace.sh; \
	fi

lint-fix:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint --fix; \
	else \
		echo "SwiftLint not available for auto-fix. Please install SwiftLint or fix whitespace issues manually."; \
		exit 1; \
	fi
