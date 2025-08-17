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
	@echo "🔍 Running SwiftLint..."
	@if ! command -v swiftlint >/dev/null 2>&1; then \
		echo "❌ SwiftLint not found. Please install it with: brew install swiftlint"; \
		exit 1; \
	fi
	swiftlint
	@echo "✅ Linting complete."

lint-fix:
	swiftlint --fix

format-check:
	@echo "🔍 Checking code formatting with swift-format..."
	@if ! command -v swift-format >/dev/null 2>&1; then \
		echo "❌ swift-format not found. Please install it with: brew install swift-format"; \
		exit 1; \
	fi
	@if [ -z "$$(find Sources Tests -name '*.swift' 2>/dev/null)" ]; then \
		echo "⚠️  No Swift files found in Sources or Tests. Skipping format check."; \
	else \
		if find Sources Tests -name "*.swift" | xargs swift-format --mode diff 2>/dev/null | grep -q .; then \
			echo "❌ Code formatting issues found. Run 'make format' to fix them."; \
			find Sources Tests -name "*.swift" | xargs swift-format --mode diff; \
			exit 1; \
		else \
			echo "✅ Code formatting is correct."; \
		fi \
	fi

format:
	@echo "🎨 Formatting code with swift-format..."
	@if ! command -v swift-format >/dev/null 2>&1; then \
		echo "❌ swift-format not found. Please install it with: brew install swift-format"; \
		exit 1; \
	fi
	@if [ -z "$$(find Sources Tests -name '*.swift' 2>/dev/null)" ]; then \
		echo "⚠️  No Swift files found in Sources or Tests. Skipping formatting."; \
		exit 0; \
	else \
		find Sources Tests -name "*.swift" | xargs swift-format --mode write --in-place; \
		echo "✅ Code formatting complete."; \
	fi
