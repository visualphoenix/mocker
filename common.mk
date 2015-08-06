SHELL := /bin/bash
GIT_SHA := $(shell git rev-parse --short HEAD)
UNAME_S := $(shell uname -s)
ID_U := $(shell id -u)
DIND := $(shell test -f /.dockerinit && echo "true" || echo "false")
DEBUG_OUTPUT ?= @
.SUFFIXES:
MAKEFLAGS += --no-builtin-rules
ARTIFACT := false
SUDO :=
ifneq ($(UNAME_S),Darwin)
  ifneq ($(ID_U),0)
    ifneq ($(DIND),true)
      SUDO := sudo
    endif
  endif
endif
XARGS := xargs -r
ifeq ($(UNAME_S),Darwin)
  XARGS := xargs
endif
DOCKER := $(SUDO) docker

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
