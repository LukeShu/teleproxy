
all: test build

GUBERNAUT = ./gubernaut
include kubernaut.mk

export KUBECONFIG=${PWD}/cluster.knaut
export PATH:=${PATH}

.PHONY: manifests
manifests: cluster.knaut kubewait
	kubectl apply -f k8s
	./kubewait -f k8s

shell: cluster.knaut
	@exec env -u MAKELEVEL PS1="(dev) [\W]$$ " bash

.PHONY: teleproxy
teleproxy: $(GO_FILES)
	go build cmd/teleproxy/teleproxy.go

build: teleproxy
	sudo chown root:wheel ./teleproxy && sudo chmod u+s ./teleproxy

get:
	go get -t -d ./...

.PHONY: kubewait
kubewait: $(GO_FILES)
	go build cmd/kubewait/kubewait.go

gubernaut: cmd/gubernaut/gubernaut.go FORCE
	go build cmd/gubernaut/gubernaut.go

other-tests:
	go test -v $(shell go list ./... \
		| fgrep -v github.com/datawire/teleproxy/internal/pkg/nat \
		| fgrep -v github.com/datawire/teleproxy/cmd/teleproxy)

nat-tests:
	go test -v -exec sudo github.com/datawire/teleproxy/internal/pkg/nat/

smoke-tests: manifests
	go test -v -exec "sudo env PATH=${PATH} KUBECONFIG=${KUBECONFIG}" github.com/datawire/teleproxy/cmd/teleproxy

sudo-tests: nat-tests smoke-tests

run-tests: sudo-tests other-tests

test-go: get run-tests

test-docker:
	@if [[ "$(shell which docker)-no" != "-no" ]]; then \
		docker build -f scripts/Dockerfile . -t teleproxy-make && \
		docker run --cap-add=NET_ADMIN teleproxy-make nat-tests ; \
	else \
		echo "SKIPPING DOCKER TESTS" ; \
	fi

test: test-go test-docker

format:
	gofmt -w -s cmd internal pkg

run: build
	./teleproxy

clean: cluster.knaut.clean
	rm -f ./teleproxy ./gubernaut

clobber: clean
