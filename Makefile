MF := $(shell python -c 'import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))'  $(CURDIR)/$(lastword $(MAKEFILE_LIST)) )
MAKEDIR := $(shell dirname $(MF))
BASEDIR := $(shell cd $(MAKEDIR) ; git rev-parse --show-toplevel)

-include $(BASEDIR)/common.mk
-include $(CURDIR)/module.mk

NAME               ?= 
VERSION            ?= 
PACKAGE_VERSION    ?= 
MAINTAINER         ?= 
DESCRIPTION        ?= 
ARCHITECTURE       ?= 

TAG                 = $(VERSION)-$(PACKAGE_VERSION)
CONTAINER_NAME      = $(shell echo '$(NAME)-$(TAG)' | sed 's@/@-@g')
PACKAGE_NAME        = $(shell echo '$(NAME)' | sed 's@/@-@g')
REPOSITORY         ?=

PACKAGE_IMAGE      ?=

DOCKER_OPTS        +=
DOCKER_CREATE_OPTS +=
DOCKER_RUN_OPTS    +=

BUILD_FILES        +=

clean: clean-package clean-docker
	-( [ -f .dockerbuild ] && rm -rf .dockerbuild || true )

clean-package:
	rm -rf target

clean-docker:
	$(call docker-clean,$(CONTAINER_NAME))

check-repository: check-docker
	if [ -z '$(REPOSITORY)' ] ; then echo "REPOSITORY unset. Can't tag for upstream" ; exit 1 ; fi

check-latest: check-docker
	$(DOCKER) $(DOCKER_OPTS) images | grep $(NAME) | grep latest &>/dev/null || ( [ -f .dockerbuild ] && rm -rf .dockerbuild || true )

images: check-docker
	$(DOCKER) $(DOCKER_OPTS) images

package: check-docker build-docker clean-package
ifneq ($(PACKAGE_IMAGE),)
	$(DOCKER) $(DOCKER_OPTS) pull $(PACKAGE_IMAGE)
	( $(DOCKER) $(DOCKER_OPTS) run -a stdout -a stderr --rm \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e NAME='$(NAME)' \
	-e TAG='$(TAG)' \
	-e VERSION='$(VERSION)' \
	-e PACKAGE_NAME='$(PACKAGE_NAME)' \
	-e PACKAGE_VERSION='$(PACKAGE_VERSION)' \
	-e CONTAINER_NAME='$(CONTAINER_NAME)' \
	-e REPOSITORY='$(REPOSITORY)' \
	-e MAINTAINER='$(MAINTAINER)' \
	-e DESCRIPTION='$(DESCRIPTION)' \
	-e ARCHITECTURE='$(ARCHITECTURE)' \
	-e DOCKER_CREATE_OPTS='$(DOCKER_CREATE_OPTS)' \
	-e DOCKER_RUN_OPTS='$(DOCKER_RUN_OPTS)' \
	 $(DOCKER_PACKAGE_OPTS) \
	$(PACKAGE_IMAGE) ) | tar xzf -
endif

tag: check-docker check-repository
	$(DOCKER) $(DOCKER_OPTS) tag $(DOCKER_FORCE_TAG) $(NAME):$(TAG) $(REPOSITORY)/$(NAME):latest
	$(DOCKER) $(DOCKER_OPTS) tag $(DOCKER_FORCE_TAG) $(NAME):$(TAG) $(REPOSITORY)/$(NAME):$(TAG)

push: check-docker tag
	$(DOCKER) $(DOCKER_OPTS) push $(REPOSITORY)/$(NAME):$(TAG)
	$(DOCKER) $(DOCKER_OPTS) push $(REPOSITORY)/$(NAME):latest

shell: check-docker build-docker 
	$(DOCKER) $(DOCKER_OPTS) run \
		 -it --rm \
		$(NAME):$(TAG) \
		bash

run: check-docker clean-docker build-docker
	$(DOCKER) $(DOCKER_OPTS) run \
		$(DOCKER_RUN_OPTS) \
		--name $(CONTAINER_NAME) \
		$(NAME):$(TAG)

build-docker: check-latest .dockerbuild

build: check-docker build-docker

.dockerbuild: $(BUILD_FILES)
	$(MAKE) clean-docker;
	$(DOCKER) $(DOCKER_OPTS) build --force-rm -t $(NAME):$(TAG) .
	$(DOCKER) $(DOCKER_OPTS) tag $(DOCKER_FORCE_TAG) $(NAME):$(TAG) $(NAME):latest
	$(DOCKER) $(DOCKER_OPTS) images -qf 'dangling=true' | tr '\n' ' ' | $(SUDO) $(XARGS) docker $(DOCKER_OPTS) rmi
	touch $@;

.PHONY += clean-docker clean clean-package docker-shell run
-include $(CURDIR)/rules.mk
.PHONY: $(.PHONY)
