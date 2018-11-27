FROM golang:1.10.1-alpine
RUN apk --no-cache add make iptables sudo git

COPY . .
# This symlink was excluded from the context, because (some versions
# of?) Docker get thrown in to an infinite loop by it.  So exclude it
# and re-create it manually.
RUN ln -sT ../../../.. .go-workspace/src/github.com/datawire/teleproxy

ENTRYPOINT [ "make" ]
