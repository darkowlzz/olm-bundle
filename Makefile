IMG ?= darkowlzz/olm-bundle:test

OPM=bin/opm
OPM_VERSION=v1.14.2
ARCH=amd64

docker-build: opm
	docker build -t ${IMG} \
		--build-arg USER_ID=$(shell id -u) \
		--build-arg GROUP_ID=$(shell id -g) \
		.

opm:
	mkdir -p bin
	@if [ ! -f $(OPM) ]; then \
		curl -Lo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/${OPM_VERSION}/linux-${ARCH}-opm ;\
		chmod +x $(OPM) ;\
	fi
