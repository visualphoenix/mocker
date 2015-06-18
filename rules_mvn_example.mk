.PHONY      += check-builder
BUILD_FILES += module.mk rules.mk

check-latest: check-builder
check-builder:
	$(DOCKER) $(DOCKER_OPTS) images | grep visualphoenix/alpine-maven | grep latest &>/dev/null || ( [ -d target ] && rm -rf target || true )

.dockerbuild: | target
target: $(shell find src -type f) pom.xml module.mk rules.mk
	$(DOCKER) $(DOCKER_OPTS) run --rm -w /src -v $(CURDIR):/src -v /tmp/.m2:/root/.m2 visualphoenix/alpine-maven mvn package
