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
	swiftlint

lint-fix:
	swiftlint --fix

format-check:
	find Sources Tests -name "*.swift" | xargs swift-format --mode diff

format:
	find Sources Tests -name "*.swift" | xargs swift-format --mode write --in-place
