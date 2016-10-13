SHELL := /bin/bash
UNAME_S := $(shell uname -s)
DOCKER_VERSION := $(shell docker --version | awk '{gsub(/,.*/,""); print $$3}')
DOCKER_MINOR_VERSION := $(shell echo '$(DOCKER_VERSION)' | awk -F'.' '{print $$2}')
DEBUG_OUTPUT ?= @

MAKEFLAGS += --no-builtin-rules
.SUFFIXES :=
.DEFAULT_GOAL := build
.PHONY := clean build package push tag init image-name run-dev-ev1 run-dev-wc1 launch-to-prod test-jira-user-pass

# Use sudo if the docker socket isnt writable by the current user
SUDO := $(shell (test -f /.dockerinit || test -w /var/run/docker.sock) && echo || echo sudo)

SED_I := sed -i''

# Handle linux/osx differences
XARGS := xargs -r
FIND_DEPTH := maxdepth
ifeq ($(UNAME_S),Darwin)
	XARGS := xargs
	FIND_DEPTH := depth
endif

# Docker variables
DOCKER := $(SUDO) docker
DOCKER_FORCE_TAG :=
ifeq ($(shell test $(DOCKER_MINOR_VERSION) -lt 9; echo $$?),0)
	DOCKER_FORCE_TAG := -f
endif

ARTIFACT := false

DOCKER_OPTS        ?=
DOCKER_OPTS        +=

DOCKER_PACKAGE_OPTS ?=

DOCKER_CREATE_OPTS ?=
DOCKER_CREATE_OPTS += --restart=always

DOCKER_RUN_OPTS    ?=
DOCKER_RUN_OPTS    += -d

BUILD_FILES        ?=
BUILD_FILES        += Dockerfile Makefile

.DEFAULT_GOAL := build

check-docker:
	@if [ -z $$(which docker) ]; then \
	  echo "Missing \`docker\` client which is required for development"; \
	  exit 2; \
	fi

define docker-clean
	$(DOCKER) $(DOCKER_OPTS) ps -aq --filter='name=$1' | $(SUDO) $(XARGS) docker $(DOCKER_OPTS) rm -f -v 
endef

clean-exited:
	$(DOCKER) $(DOCKER_OPTS) ps -aq --no-trunc --filter='exited=0' | $(SUDO) $(XARGS) docker $(DOCKER_OPTS) rm -f -v


.PHONY += check-docker
