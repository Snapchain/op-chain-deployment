include .env
# Define GOPATH
# TODO: is this needed?
export GOPATH := $(HOME)/go
export PATH := $(HOME)/.just:$(HOME)/.foundry/bin:/usr/local/go/bin:$(GOPATH)/bin:$(PATH)
# makes all variables in the Makefile available to child processes
export

## Start the OP chain
start-op-chain: l2-prepare l2-launch
.PHONY: start-op-chain

## Generate addresses for the L2 and update the .env file
l2-gen-addresses:
	@$(CURDIR)/scripts/l2-gen-addresses.sh
.PHONY: l2-gen-addresses

## Prepare for running the OP chain
l2-prepare:
	@$(eval export IMPL_SALT := $(shell openssl rand -hex 32))
	@$(CURDIR)/scripts/generate-deploy-config.sh $(CURDIR)/optimism
	@$(CURDIR)/scripts/deploy-l1-contracts.sh $(CURDIR)/optimism
	@$(CURDIR)/scripts/generate-l2-config.sh $(CURDIR)/optimism $(CURDIR)/.deploy
.PHONY: l2-prepare

## Launch the OP chain core components (op-node, op-geth, proposer, batcher)
l2-launch:
	@$(CURDIR)/scripts/launch-l2.sh $(CURDIR)/optimism
.PHONY: l2-launch

## Verify the OP chain is running
l2-verify:
	@$(CURDIR)/scripts/l2-verify.sh
.PHONY: l2-verify

## Deploy the multicall contract
l2-bridge-deploy-l1-multicall:
	@$(CURDIR)/scripts/l2-bridge-deploy-l1-multicall.sh
.PHONY: l2-bridge-deploy-l1-multicall

## Launch the OP Bridge UI
l2-bridge-start:
	@$(CURDIR)/scripts/set-bridge-ui-env.sh
	@docker compose up -d op-bridge-ui
.PHONY: l2-bridge-start

## Stop the OP Bridge UI
l2-bridge-stop:
	@docker compose down op-bridge-ui
.PHONY: l2-bridge-stop

####### Local L1 #######

## Kurtosis local L1
KURTOSIS_LOCAL_L1_ENCLAVE_NAME=kurtosis-local-l1
KURTOSIS_LOCAL_L1_ARGS_FILE=configs/network_params.yaml

## Configure the local L1 chain. Generate a prefunded wallet and update the network_params.yaml file
l1-configure:
	@$(CURDIR)/scripts/l1-configure.sh
.PHONY: l1-configure

## Launch a local L1 chain with kurtosis and ethereum-package
l1-launch:
	$(eval include $(CURDIR)/.env)
	@kurtosis run --enclave $(KURTOSIS_LOCAL_L1_ENCLAVE_NAME) github.com/ethpandaops/ethereum-package --args-file $(KURTOSIS_LOCAL_L1_ARGS_FILE)
	sleep 45
	@$(MAKE) l1-verify
.PHONY: l1-launch

## Verify the local L1 chain is running
l1-verify:
	@$(CURDIR)/scripts/l1-verify.sh $(KURTOSIS_LOCAL_L1_ARGS_FILE)
.PHONY: l1-verify

## Remove the local L1 chain
l1-remove:
	@kurtosis enclave rm -f $(KURTOSIS_LOCAL_L1_ENCLAVE_NAME)
.PHONY: l1-remove

