# Copyright 2018 Datawire. All rights reserved.

all: test build

GUBERNAUT = ./gubernaut
include kubernaut.mk
include common.mk

pkg = github.com/datawire/teleproxy
bins = gubernaut kubewait teleproxy
dirs = cmd internal pkg
pkgs = $(sort $(addprefix $(pkg)/,$(patsubst %/,%,$(dir $(shell git ls-files -- $(dirs))))))

GO = GOPATH=$(CURDIR)/.go-workspace GOBIN=$(CURDIR) go

export KUBECONFIG=${PWD}/cluster.knaut
export PATH:=${PATH}

# Build
build: $(bins)
	sudo chown root:wheel ./teleproxy && sudo chmod u+s ./teleproxy

# Having multiple `go install`s going at once can corrupt
# `$(GOPATH)/pkg`.  Setting .NOTPARALLEL is simpler than mucking with
# multi-target pattern rules.
.NOTPARALLEL:
$(bins): %: get FORCE
	$(GO) install $(pkg)/cmd/$@

get:
	$(GO) get -t -d ./...
.PHONY: get

# Clean
clean: cluster.knaut.clean
	rm -f $(bins)

clobber: clean

# Check
test: test-go test-docker
test-go: get run-tests
run-tests: sudo-tests other-tests
sudo-tests: nat-tests smoke-tests

.PHONY: manifests
manifests: cluster.knaut kubewait
	kubectl apply -f k8s
	./kubewait -f k8s

nat-tests:
	$(GO) test -v -exec sudo github.com/datawire/teleproxy/internal/pkg/nat/
smoke-tests: manifests
	$(GO) test -v -exec "sudo env PATH=${PATH} KUBECONFIG=${KUBECONFIG}" github.com/datawire/teleproxy/cmd/teleproxy
other-tests:
	$(GO) test -v $(shell printf '%s\n' $(pkgs) \
		| fgrep -v github.com/datawire/teleproxy/internal/pkg/nat \
		| fgrep -v github.com/datawire/teleproxy/cmd/teleproxy)
test-docker:
	@if [[ "$(shell which docker)-no" != "-no" ]]; then \
		docker build -f scripts/Dockerfile . -t teleproxy-make && \
		docker run --cap-add=NET_ADMIN teleproxy-make nat-tests ; \
	else \
		echo "SKIPPING DOCKER TESTS" ; \
	fi

# Misc
shell: cluster.knaut
	@exec env -u MAKELEVEL PS1="(dev) [\W]$$ " bash

format:
	gofmt -w -s $(dirs)

run: build
	./teleproxy
