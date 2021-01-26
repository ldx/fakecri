NAME=$(shell basename $(TOP_DIR))
OWNER_NAME=$(shell cd $(TOP_DIR)/.. && basename $(pwd))

GIT_VERSION=$(shell git describe --dirty)
CURRENT_TIME=$(shell date +%Y%m%d%H%M%S)

TOP_DIR=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
PKG_SRC=$(shell find $(TOP_DIR)pkg -type f -name "*.go")
CMD_SRC=$(shell find $(TOP_DIR)cmd/$(NAME) -type f -name "*.go")
MODULE_FILES=go.mod go.sum

LD_VERSION_FLAGS=-X main.BuildVersion=$(GIT_VERSION) -X main.BuildTime=$(CURRENT_TIME)
LDFLAGS=-ldflags "$(LD_VERSION_FLAGS)"

BINARIES=$(NAME)

all: $(BINARIES) $(MODULE_FILES)

$(NAME): $(PKG_SRC) $(CMD_SRC)
	go build $(LDFLAGS) -o $(TOP_DIR)$(NAME) $(TOP_DIR)cmd/$(NAME)/$(NAME).go

test: $(NAME)
	go test ./...

DKR ?= docker
REGISTRY_REPO ?= $(OWNER_NAME)/$(NAME)
IMAGE_TAG=$(GIT_VERSION)
ifneq ($(findstring -,$(GIT_VERSION)),)
IMAGE_DEV_OR_LATEST=dev
else
IMAGE_DEV_OR_LATEST=latest
endif

img: $(BINARIES)
	@echo "Checking if IMAGE_TAG is set" && test -n "$(IMAGE_TAG)"
	$(DKR) build -t $(REGISTRY_REPO):$(IMAGE_TAG) \
		-t $(REGISTRY_REPO):$(IMAGE_DEV_OR_LATEST) .

login-img:
	@echo "Checking if REGISTRY_USER is set" && test -n "$(REGISTRY_USER)"
	@echo "Checking if REGISTRY_PASSWORD is set" && test -n "$(REGISTRY_PASSWORD)"
	@$(DKR) login -u "$(REGISTRY_USER)" -p "$(REGISTRY_PASSWORD)" "$(REGISTRY_REPO)"

push-img: img
	@echo "Checking if IMAGE_TAG is set" && test -n "$(IMAGE_TAG)"
	$(DKR) push $(REGISTRY_REPO):$(IMAGE_TAG)
	$(DKR) push $(REGISTRY_REPO):$(IMAGE_DEV_OR_LATEST)

clean:
	rm -f $(BINARIES)

.PHONY: all clean
