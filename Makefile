IMAGE_NAME ?= agents-image
PLATFORMS ?= linux/amd64,linux/arm64

.PHONY: all ubuntu ubi alpine buildx-ubuntu buildx-ubi buildx-alpine buildx-all

all: ubuntu ubi alpine

ubuntu:
	docker build -t $(IMAGE_NAME) .

ubi:
	docker build -f Dockerfile.ubi -t $(IMAGE_NAME):ubi .

alpine:
	docker build -f Dockerfile.alpine -t $(IMAGE_NAME):alpine .

buildx-all: buildx-ubuntu buildx-ubi buildx-alpine

buildx-ubuntu:
	docker buildx build --platform $(PLATFORMS) -t $(IMAGE_NAME) .

buildx-ubi:
	docker buildx build --platform $(PLATFORMS) -f Dockerfile.ubi -t $(IMAGE_NAME):ubi .

buildx-alpine:
	docker buildx build --platform $(PLATFORMS) -f Dockerfile.alpine -t $(IMAGE_NAME):alpine .
