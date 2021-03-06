VERSION := $(shell git describe --always)
BUILD := $(shell git rev-parse --short HEAD)
PROJECTNAME := $(shell basename "$(PWD)")

# Use linker flags to provide version/build settings
LDFLAGS=-ldflags "-X=main.Version=$(VERSION) -X=main.Build=$(BUILD)"

# Redirect error output to a file, so we can show it in development mode.
STDERR := /tmp/.$(PROJECTNAME)-stderr.txt

# PID file will keep the process id of the server
PID := /tmp/.$(PROJECTNAME).pid

# Make is verbose in Linux. Make it silent.
MAKEFLAGS += --silent

all: clean build start

## start: Start in development mode. Auto-starts when code changes.
start: start-server

## restart
restart: restart-server

## stop: Stop development mode.
stop: stop-server

start-server: stop-server
	@echo "  >  starting $(PROJECTNAME) service"
	@./$(PROJECTNAME) 2>&1 & echo $$! > $(PID)
	@cat $(PID) | sed "/^/s/^/  \>  PID: /"
	@echo "  >  start finish"

stop-server:
	@echo "  >  stoping $(PROJECTNAME) service"
	@-touch $(PID)
	@-kill `cat $(PID)` 2> /dev/null || true
	@-rm $(PID)
	@echo "  >  stop finish"

restart-server: stop-server start-server

## build: Compile the binary.
build:
	@-touch $(STDERR)
	@-rm $(STDERR)
	@-$(MAKE) -s go-build 2> $(STDERR)
	@cat $(STDERR) | sed -e '1s/.*/\nError:\n/'  | sed 's/make\[.*/ /' | sed "/^/s/^/     /" 1>&2

## clean: Clean build files. Runs `go clean` internally.
clean:
	@-rm $(PROJECTNAME) 2> /dev/null
	@-$(MAKE) go-clean

go-build:
	@echo "  >  Building binary..."
	@go build $(LDFLAGS)
	@echo "  >  Building finish"

go-install:
	@go install

go-clean:
	@echo "  >  Cleaning build cache"
	@go clean
	@echo "  >  Clean finish"

.PHONY: help

help: Makefile
	@echo
	@echo " Choose a command run in "$(PROJECTNAME)":"
	@echo
	@sed -n 's/^##//p' $< | column -t -s ':' |  sed -e 's/^/ /'
	@echo