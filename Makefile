# Go minimum version check.
GO_MIN_VERSION := 11000 # 1.10
GO_VERSION_CHECK := \
  $(shell expr \
    $(shell go version | \
      awk '{print $$3}' | \
      cut -do -f2 | \
      sed -e 's/\.\([0-9][0-9]\)/\1/g' -e 's/\.\([0-9]\)/0\1/g' -e 's/^[0-9]\{3,4\}$$/&00/' \
    ) \>= $(GO_MIN_VERSION) \
  )

# Default Go linker flags.
GO_LDFLAGS ?= -ldflags="-s -w"



# Build files.
CLONE   := ./bin/hello/main

.PHONY: build
build: check-go $(CLONE)

$(CLONE):
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo $(GO_LDFLAGS) $(BUILDARGS) -o $@ ./cmd/hello/main.go
	chmod +x ./bin/hello/main

.PHONY: package
package:
	@echo "packaging application"

.PHONY: test
test: check-go vet
	go test $(TESTARGS) ./...

.PHONY: vet
vet: check-go
	go vet $(VETARGS) ./...

.PHONY: coverage
coverage: check-go
	@$(MAKE) test TESTARGS="-coverprofile=coverage.out"
	@go tool cover -html=coverage.out
	@rm -f coverage.out

.PHONY: clean
clean:
	@rm -rf ./bin

.PHONY: dep-ensure
dep-ensure:
	dep ensure --update

.PHONY: check-go
check-go:
ifeq ($(GO_VERSION_CHECK),0)
	$(error go1.10 or higher is required)
endif


FGT := $(GOPATH)/bin/fgt
$(FGT):
	go get github.com/GeertJohan/fgt


LINTFLAGS:=-min_confidence 1.1

GOLINT := $(GOPATH)/bin/golint
$(GOLINT):
	go get github.com/golang/lint/golint

$(PKGS): $(GOLINT) $(FGT)
	@echo "LINTING"
	@$(FGT) $(GOLINT) $(LINTFLAGS) $(GOPATH)/src/$@/*.go
	@echo "VETTING"
	@go vet -v $@
	@echo "TESTING"
	@go test -v $@

.PHONY: lint
lint: vendor | $(PKGS) $(GOLINT) # ❷
	@cd $(BASE) && ret=0 && for pkg in $(PKGS); do \
	    test -z "$$($(GOLINT) $$pkg | tee /dev/stderr)" || ret=1 ; \
	done ; exit $$ret

#DOCKER_REPO := docker.artifactory.a.intuit.com/personal/gfulton
#GIT_SHA := $(shell git rev-parse --verify HEAD)
#docker: build
#	@echo $(GIT_SHA)
#	chmod +x ./bin/git/clone/main
#	docker build --no-cache -t clone -f Dockerfile ./bin/git/clone
#	docker tag clone $(DOCKER_REPO)/clone:$(GIT_SHA)
#	docker push $(DOCKER_REPO)/clone:$(GIT_SHA)

