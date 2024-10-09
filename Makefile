include .env
# Define GOPATH
# TODO: is this needed?
export GOPATH := $(HOME)/go
# Add Foundry the PATH
# TODO: why is just in the path?
export PATH := $(HOME)/.just:$(HOME)/.foundry/bin:/usr/local/go/bin:$(GOPATH)/bin:$(PATH)
export

DOCKER := $(shell which docker)
# TODO: we can just use $(CURDIR) instead of this
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

## Prepare for running the OP chain on the Sepolia testnet
prepare-op-chain:
	@$(eval export IMPL_SALT := $(shell openssl rand -hex 32))
	$(eval include $(CURDIR)/.env)
	@$(CURDIR)/scripts/generate-deploy-config.sh $(CURDIR)/optimism
	@$(CURDIR)/scripts/deploy-l1-contracts.sh $(CURDIR)/optimism
	@$(CURDIR)/scripts/generate-l2-config.sh $(CURDIR)/optimism $(CURDIR)/optimism
.PHONY: prepare-op-chain
