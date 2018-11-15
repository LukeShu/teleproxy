# Copyright 2018 Datawire. All rights reserved.

# Turn off .INTERMEDIATE file removal by marking all files as
# SECONDARY.  .INTERMEDIATE file removal is a space-saving hack from a
# time when drives were small; on modern computers with plenty of
# storage, it causes nothing but headaches.
#
# https://news.ycombinator.com/item?id=16486331
.SECONDARY:

# If a rule errors, remove the target it was building.  This prevents
# outdated/incomplete results of failed runs from tainting future
# runs.  The only reason .DELETE_ON_ERROR is off by default is for
# historical compatibility.
#
# If for some reason this behavior is not desired for a specific
# target, mark that target as .PRECIOUS.
.DELETE_ON_ERROR:

# Sometimes we have a file-target that we want Make to always try to
# re-generate (such as compiling a Go program; we would like to let
# `go install` decide whether it is up-to-date or not, rather than
# trying to teach Make how to do that).  We could mark it as .PHONY,
# but that tells make that "this isn't a "this isn't a real file that
# I expect to ever exist", which has a several implications for Make,
# most of which we don't want.  Instead, we can have them *depend* on
# a .PHONY target (which we'll name "FORCE"), so that they are always
# considered out-of-date by Make, but without being .PHONY themselves.
.PHONY: FORCE
