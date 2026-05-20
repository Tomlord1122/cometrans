SHELL := /bin/zsh
VERSION ?= $(shell cat version.txt)

.PHONY: build test coverage release dmg icon

build:
	swift build

test:
	swift test

coverage:
	./scripts/test_coverage.sh

dmg:
	VERSION=$(VERSION) ./build_dmg.sh

release:
	./scripts/release.sh $(VERSION)

icon:
	./Resources/generate_icon.sh
