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

# Development targets with optimizations for CI/CD
build-ci:
	swift build --product PlayingCard --configuration release --verbose

test-ci:
	swift test --parallel --verbose
