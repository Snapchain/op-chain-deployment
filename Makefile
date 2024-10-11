include .env
# Define GOPATH
# TODO: is this needed?
export GOPATH := $(HOME)/go
export PATH := $(HOME)/.just:$(HOME)/.foundry/bin:/usr/local/go/bin:$(GOPATH)/bin:$(PATH)
# makes all variables in the Makefile available to child processes
export

DOCKER := $(shell which docker)
# TODO: we can just use $(CURDIR) instead of this
GIT_TOPLEVEL := $(shell git rev-parse --show-toplevel)

## Prepare for running the OP chain on the Sepolia testnet
prepare-op-chain:
	@$(MAKE) -C $(CURDIR)/optimism submodules
	@$(eval export IMPL_SALT := $(shell openssl rand -hex 32))
	$(eval include $(CURDIR)/.env)
	@$(CURDIR)/scripts/generate-deploy-config.sh $(CURDIR)/optimism
	@$(CURDIR)/scripts/deploy-l1-contracts.sh $(CURDIR)/optimism
	@$(CURDIR)/scripts/generate-l2-config.sh $(CURDIR)/optimism $(CURDIR)/optimism
.PHONY: prepare-op-chain

## Common logic for starting/restarting OP chain on Sepolia
_launch-op-chain:
	@$(CURDIR)/scripts/launch-l2.sh $(CURDIR)/optimism
	sleep 10
	## false represents the OP chain is deployed on the Sepolia testnet, not local L1
	@$(CURDIR)/scripts/verify-op-devnet.sh false
.PHONY: _launch-op-chain

