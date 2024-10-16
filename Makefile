include .env
# Define GOPATH
# TODO: is this needed?
export GOPATH := $(HOME)/go
export PATH := $(HOME)/.just:$(HOME)/.foundry/bin:/usr/local/go/bin:$(GOPATH)/bin:$(PATH)
# makes all variables in the Makefile available to child processes
export

# Kurtosis local L1
KURTOSIS_LOCAL_L1_ENCLAVE_NAME=kurtosis-local-l1
KURTOSIS_LOCAL_L1_ARGS_FILE=configs/network_params.yaml

## Prepare for running the OP chain on the Sepolia testnet
prepare-op-chain:
	@$(MAKE) -C $(CURDIR)/optimism submodules
	@$(eval export IMPL_SALT := $(shell openssl rand -hex 32))
	$(eval include $(CURDIR)/.env)
	@$(CURDIR)/scripts/generate-deploy-config.sh $(CURDIR)/optimism
	@$(CURDIR)/scripts/deploy-l1-contracts.sh $(CURDIR)/optimism
	@$(CURDIR)/scripts/generate-l2-config.sh $(CURDIR)/optimism $(CURDIR)/.deploy
.PHONY: prepare-op-chain

## Common logic for starting/restarting OP chain on Sepolia
OP_BEDROCK_DIR := $(CURDIR)/optimism/packages/contracts-bedrock
launch-op-chain:
	@$(CURDIR)/scripts/launch-l2.sh $(CURDIR)/optimism
	sleep 10
	mv $(OP_BEDROCK_DIR)/deployments/op-devnet-${L2_CHAIN_ID}.json $(CURDIR)/.deploy/op-devnet-deployments-${L2_CHAIN_ID}.json
	mv $(OP_BEDROCK_DIR)/deploy-config/op-devnet-${L2_CHAIN_ID}.json $(CURDIR)/.deploy/op-devnet-deploy-config-${L2_CHAIN_ID}.json
	## false represents the OP chain is deployed on the Sepolia testnet, not local L1
	@$(CURDIR)/scripts/verify-op-devnet.sh
.PHONY: launch-op-chain

verify-op-devnet:
	@$(CURDIR)/scripts/verify-op-devnet.sh
.PHONY: verify-op-devnet

## Clean up the deployment directory
clean-deploy-dir:
	@rm -rf $(CURDIR)/.deploy
.PHONY: clean-deploy-dir

## Start the OP chain
start-op-chain: prepare-op-chain launch-op-chain
.PHONY: start-op-chain

## Deploy the multicall contract
deploy-multicall:
	cd $(CURDIR)/multicall && \
	forge build && \
	FORGE_OUTPUT=$$(forge create --rpc-url ${L1_RPC_URL} --private-key ${L1_FUNDED_PRIVATE_KEY} Multicall3) && \
	echo "$$FORGE_OUTPUT" && \
	DEPLOYED_ADDRESS=$$(echo "$$FORGE_OUTPUT" | grep "Deployed to:" | awk '{print $$3}') && \
	sed -i.bak "s/^NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=.*/NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=$$DEPLOYED_ADDRESS/" ../.env && \
	rm ../.env.bak
.PHONY: deploy-multicall

## Launch the OP Bridge UI
launch-op-bridge-ui:
	@$(CURDIR)/scripts/set-bridge-ui-env.sh
	@$(eval include $(CURDIR)/.env)
	@docker compose -f $(CURDIR)/bridge-ui/docker-compose.yml up -d
.PHONY: launch-op-bridge-ui

## Stop the OP Bridge UI
stop-op-bridge-ui:
	@docker compose -f $(CURDIR)/bridge-ui/docker-compose.yml down
.PHONY: stop-op-bridge-ui

## Launch a local L1 chain with kurtosis and ethereum-package
l1-launch:
	$(eval include $(CURDIR)/.env)
	@kurtosis run --enclave $(KURTOSIS_LOCAL_L1_ENCLAVE_NAME) github.com/ethpandaops/ethereum-package --args-file $(KURTOSIS_LOCAL_L1_ARGS_FILE)
	sleep 45
	@$(MAKE) l1-verify
.PHONY: l1-launch

l1-configure:
	@$(CURDIR)/scripts/l1-configure.sh
.PHONY: l1-configure

l1-verify:
	@$(CURDIR)/scripts/l1-verify.sh $(KURTOSIS_LOCAL_L1_ARGS_FILE)
.PHONY: l1-verify

## Remove the local L1 chain
l1-remove:
	@kurtosis enclave rm -f $(KURTOSIS_LOCAL_L1_ENCLAVE_NAME)
.PHONY: l1-remove

## Generate addresses for the L2 and update the .env file
l2-gen-addresses:
	@$(CURDIR)/scripts/l2-gen-addresses.sh
.PHONY: l2-gen-addresses
