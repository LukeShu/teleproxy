# Copyright 2018 Datawire. All rights reserved.

# Makefile snippet to manage kubernaut.io clusters using Gubernaut.
#
### Reference:
#
# Inputs:
#   - Variable: GUBERNAUT ?= gubernaut
# Outputs:
#   - Target       : `%.knaut`
#   - .PHONY Target: `%.knaut.clean`
#
# Creating the NAME.knaut creates the Kubernaut claim.  The file may
# be used as a KUBECONFIG file.
#
# Calling the NAME.knaut.clean file releases the claim, and removes
# the NAME.knaut file.
#
# The GUBERNAUT variable may be used to adjust the gubernaut command
# called; by default it looks up 'gubernaut' in $PATH.
#
### Quickstart:
#
#  1. Put this file in your source tree and include it from your
#     Makefile, e.g.:
#
#     ...
#     include kubernaut.mk
#     ...
#
#     Set the GUBERNAUT variable before including it, if you would
#     like to use a different path than looking up 'gubernaut' in
#     $PATH.
#
#  2. Run `make foo.knaut` to (re)acquire a cluster.
#
#  3. Use `kubectl -kubeconfig foo.knaut ...` to use a cluster.
#
#  4. Run `make foo.knaut.clean` to release the cluster.
#
#  5. If you care, the claim name is in foo.knaut.claim. This will use
#     a UUID if the CI environment variable is set.
#
#  6. Incorporate <blah>.knaut[.clean] targets into your Makefile as
#     needed
#
#     tests: test-cluster.knaut
#             KUBECONFIG=test-cluster.knaut py.test ...
#
#     clean: test-cluster.knaut.clean

GUBERNAUT ?= gubernaut

# Only add a dependency on the the gubernaut binary if GUBERNAUT is
# set to a path; don't add the dependency if we'll be finding it via
# ${PATH}.
_GUBERNAUT_DEP = $(if $(findstring /,$(GUBERNAUT)),$(GUBERNAUT))

%.knaut.claim:
	echo $(subst /,_,$*)-$${USER}-$$(uuidgen) > $@

%.knaut: %.knaut.claim $(_GUBERNAUT_DEP)
	$(GUBERNAUT) -release "$$(cat $<)"
	$(GUBERNAUT) -claim "$$(cat $<)" -output $@ >/dev/null

%.knaut.clean: $(_GUBERNAUT_DEP)
	[ ! -e $*.knaut.claim ] || $(GUBERNAUT) -release "$$(cat $*.knaut.claim)"
	rm -f -- $*.knaut $*.knaut.claim
.PHONY: %.knaut.clean

# We want sane .INTERMEDIATE file behavior, since .knaut and
# .knaut.claim files are likely to be automatically considered
# .INTERMEDIATE.
include $(dir $(lastword $(MAKEFILE_LIST)))/common.mk
