# Copyright 2018 Datawire. All rights reserved.

all: build check
.PHONY: all

GUBERNAUT = ./gubernaut
include kubernaut.mk
include common.mk

pkg = github.com/datawire/teleproxy
bins = gubernaut kubewait teleproxy
dirs = cmd internal pkg
pkgs = $(sort $(addprefix $(pkg)/,$(patsubst %/,%,$(dir $(shell git ls-files -- $(dirs))))))

GO = GOPATH=$(CURDIR)/.go-workspace GOBIN=$(CURDIR) go

DOCKER_IMAGE = teleproxy-make
DOCKER = $(if $(shell type docker 2>/dev/null),docker,true)

export KUBECONFIG = $(CURDIR)/cluster.knaut

# Build
build: $(bins)
.PHONY: build

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
clean: $(addsuffix .clean,$(wildcard *.knaut))
	rm -f -- $(bins)
	rm -rf -- .go-workspace/pkg
.PHONY: clean

# Check
check: check-nat check-teleproxy check-other check-docker
.PHONY: check

test-cluster: $(KUBECONFIG) kubewait
	kubectl apply -f k8s
	./kubewait -f k8s
.PHONY: test-cluster

docker-image: build
	$(DOCKER) build -f scripts/Dockerfile . -t $(DOCKER_IMAGE)
.PHONY: docker-image

check-nat:
	$(GO) test -v -exec sudo $(pkg)/internal/pkg/nat
check-teleproxy: test-cluster $(KUBECONFIG)
	$(GO) test -v -exec "sudo env PATH=$$PATH KUBECONFIG=$$KUBECONFIG" $(pkg)/cmd/teleproxy
check-other:
	$(GO) test -v $(filter-out $(pkg)/internal/pkg/nat $(pkg)/cmd/teleproxy,$(pkgs))
check-docker: docker-image
	$(DOCKER) run --rm --cap-add=NET_ADMIN $(DOCKER_IMAGE) make check-nat.tap
	$(DOCKER) image rm $(DOCKER_IMAGE)
.PHONY: check-%

# Misc
shell: $(KUBECONFIG)
	@exec env -u MAKELEVEL PS1="(dev) [\W]$$ " bash
.PHONY: shell

format:
	gofmt -w -s $(dirs)
.PHONY: format

run: build
	./teleproxy
.PHONY: run

GUBERNAUT = ./gubernaut
include kubernaut.mk
