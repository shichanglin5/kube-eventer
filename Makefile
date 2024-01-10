all: build

PREFIX?=hub.17usoft.com/lhhdz
FLAGS=
OS?=linux
ARCH?=amd64
ALL_ARCHITECTURES=amd64 arm arm64 ppc64le s390x
ML_PLATFORMS=linux/amd64,linux/arm,linux/arm64,linux/ppc64le,linux/s390x


VERSION?=v1.2.0
GIT_COMMIT:=$(shell git rev-parse --short HEAD)


KUBE_EVENTER_LDFLAGS=-w -X github.com/AliyunContainerService/kube-eventer/version.Version=$(VERSION) -X github.com/AliyunContainerService/kube-eventer/version.GitCommit=$(GIT_COMMIT)

fmt:
	find . -type f -name "*.go" | grep -v "./vendor*" | xargs gofmt -s -w

build:
	#go mod tidy & go mod vendor
	GOOS=$(OS) GOARCH=$(ARCH) CGO_ENABLED=0 go build -ldflags "$(KUBE_EVENTER_LDFLAGS)" -o .wd/docker/kube-eventer  github.com/AliyunContainerService/kube-eventer

sanitize:
	hack/check_gofmt.sh
	hack/run_vet.sh

test-unit: clean sanitize build

ifeq ($(ARCH),amd64)
	GOARCH=$(ARCH) go test --test.short -race ./... $(FLAGS)
else
	GOARCH=$(ARCH) go test --test.short ./... $(FLAGS)
endif

test-unit-cov: clean sanitize build
	hack/coverage.sh

docker-container:
	docker build --platform=$(OS)/$(ARCH) -t $(PREFIX)/kube-eventer-$(ARCH):$(VERSION)-$(GIT_COMMIT)-aliyun -f deploy/Dockerfile .

clean:
	rm -f .wd/docker/kube-eventer

.PHONY: all build sanitize test-unit test-unit-cov docker-container clean fmt

docker-image-build: build
	cd .wd/docker && docker build --platform=$(OS)/$(ARCH) -t $(PREFIX)/kube-eventer-$(ARCH):$(VERSION)-$(GIT_COMMIT) -f Dockerfile .

docker-image-push: docker-image-build
	docker push $(PREFIX)/kube-eventer-$(ARCH):$(VERSION)-$(GIT_COMMIT)
