IMG_NAME ?= ghcr.io/darkowlzz/olm-bundle
IMG_TAG ?= test
IMG = $(IMG_NAME):$(IMG_TAG)

OPM=bin/opm
OPM_VERSION=v1.14.2
YQ=bin/yq
YQ_VERSION=3.4.0
ARCH=amd64

docker-build: opm
	docker build -t ${IMG} \
		--build-arg USER_ID=$(shell id -u) \
		--build-arg GROUP_ID=$(shell id -g) \
		-f Dockerfile-dev \
		.

opm:
	@mkdir -p bin
	@if [ ! -f $(OPM) ]; then \
		curl -Lo $(OPM) https://github.com/operator-framework/operator-registry/releases/download/${OPM_VERSION}/linux-${ARCH}-opm ;\
		chmod +x $(OPM) ;\
	fi

yq:
	@mkdir -p bin
	@if [ ! -f $(YQ) ]; then \
		curl -Lo $(YQ) https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH} ;\
		chmod +x $(YQ) ;\
	fi

test: opm yq
	./test.sh
