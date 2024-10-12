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
	@$(CURDIR)/scripts/generate-l2-config.sh $(CURDIR)/optimism
.PHONY: prepare-op-chain

## Common logic for starting/restarting OP chain on Sepolia
_launch-op-chain:
	@$(CURDIR)/scripts/launch-l2.sh $(CURDIR)/optimism
	sleep 10
	## false represents the OP chain is deployed on the Sepolia testnet, not local L1
	@$(CURDIR)/scripts/verify-op-devnet.sh false
.PHONY: _launch-op-chain

verify-op-devnet:
	@$(CURDIR)/scripts/verify-op-devnet.sh false
.PHONY: verify-op-devnet

## Start the OP chain on the Sepolia testnet
start-op-chain-sepolia: prepare-op-chain _launch-op-chain-sepolia
.PHONY: start-op-chain-sepolia

## Launch a local L1 chain with kurtosis and ethereum-package
kurtosis-launch-l1:
	$(eval include $(CURDIR)/.env)
	@kurtosis run --enclave $(KURTOSIS_LOCAL_L1_ENCLAVE_NAME) github.com/ethpandaops/ethereum-package --args-file $(KURTOSIS_LOCAL_L1_ARGS_FILE)
	sleep 45
	@$(CURDIR)/scripts/verify-l1-kurtosis.sh $(KURTOSIS_LOCAL_L1_ARGS_FILE)
.PHONY: kurtosis-launch-l1

## Remove the local L1 chain
kurtosis-remove-l1:
	@kurtosis enclave rm -f $(KURTOSIS_LOCAL_L1_ENCLAVE_NAME)
.PHONY: kurtosis-remove-l1
