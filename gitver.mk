ifeq (, $(shell which git))
 $(error "No git in $(PATH). Install git.")
endif

ifneq ($(shell echo `git rev-parse --is-inside-work-tree`),true)
 $(error "Not in a git repository.")
endif

TOPDIR := $(shell cd $(CURDIR) ; git rev-parse --show-toplevel)
GIT_SHA := $(shell git rev-parse --short HEAD || echo unknown)
NCOMMITS := $(shell echo `git rev-list HEAD | wc -l`)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
SBRANCH := $(shell echo $(BRANCH) | sed 's@^\([a-zA-Z]*\).*@\1@g')

VERSION := $(shell cat $(CURDIR)/VERSION 2>/dev/null || cat $(TOPDIR)/VERSION 2>/dev/null || echo 0.0.0)
ifeq ($(SBRANCH),master)
  PACKAGE_VERSION    := $(NCOMMITS).$(GIT_SHA)
else ifeq ($(SBRANCH),develop)
  PACKAGE_VERSION  :=0.1.$(NCOMMITS).dev.$(GIT_SHA)
else ifeq ($(SBRANCH),feature)
  PACKAGE_VERSION  :=0.0.$(NCOMMITS).feat.$(GIT_SHA)
else ifeq ($(SBRANCH),release)
  PACKAGE_VERSION  :=0.1.$(NCOMMITS).rc.$(GIT_SHA)
else
  PACKAGE_VERSION  :=0.0.0.$(NCOMMITS).unk.$(GIT_SHA)
endif
