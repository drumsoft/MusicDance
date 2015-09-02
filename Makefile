PROJECT_ROOT := $(shell pwd)

.PHONY: all build run present

all: output build

build:
	processing-java --build --sketch=$(PROJECT_ROOT)/MusicDanceB --output=$(PROJECT_ROOT)/output --force

run:
	processing-java --run --sketch=$(PROJECT_ROOT)/MusicDanceB --output=$(PROJECT_ROOT)/output --force

present:
	processing-java --present --sketch=$(PROJECT_ROOT)/MusicDanceB --output=$(PROJECT_ROOT)/output --force

output:
	mkdir output
