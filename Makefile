############################
## Env 
############################

# TODO: check if this could cause namespace collisions
# TODO: it may be safer to $(eval include $(CURDIR)/.env) in each of the scripts that need it
include .env
include .env.explorer
include .env.bridge
# make all variables in the Makefile available to child processes
export


############################
## L1 
############################

## Kurtosis local L1
KURTOSIS_LOCAL_L1_ENCLAVE_NAME=kurtosis-local-l1
KURTOSIS_LOCAL_L1_ARGS_FILE=configs/l1/network_params.yaml

## Configure the local L1 chain. Generate a prefunded wallet and update the network_params.yaml file
l1-configure:
	@$(CURDIR)/scripts/l1/l1-configure.sh
.PHONY: l1-configure

## Launch a local L1 chain with kurtosis and ethereum-package
l1-launch:
	@kurtosis run --enclave $(KURTOSIS_LOCAL_L1_ENCLAVE_NAME) github.com/ethpandaops/ethereum-package --args-file $(KURTOSIS_LOCAL_L1_ARGS_FILE)
	sleep 45
	@$(MAKE) l1-verify
.PHONY: l1-launch

## Verify the local L1 chain is running
l1-verify:
	@$(CURDIR)/scripts/l1/l1-verify.sh $(KURTOSIS_LOCAL_L1_ARGS_FILE)
.PHONY: l1-verify

## Remove the local L1 chain
l1-remove:
	@kurtosis enclave rm -f $(KURTOSIS_LOCAL_L1_ENCLAVE_NAME)
.PHONY: l1-remove


############################
## L2
############################

## Launch the OP chain
l2-launch: l2-gen-addresses l2-prepare l2-start l2-verify
	@$(MAKE) l2-bridge-deploy-l1-multicall
	@$(MAKE) l2-bridge-start
	@$(MAKE) l2-explorer-start
.PHONY: l2-launch

## Stop the OP chain (removes the .deploy directory and the op-chain-deployment volume)
l2-stop:
	@$(CURDIR)/scripts/l2/l2-stop.sh
	@$(MAKE) l2-explorer-stop
.PHONY: l2-stop

## Generate addresses for the L2 and update the .env file
l2-gen-addresses:
	@$(CURDIR)/scripts/l2/l2-gen-addresses.sh
.PHONY: l2-gen-addresses

## Prepare for running the OP chain
l2-prepare:
	@$(eval export IMPL_SALT := $(shell openssl rand -hex 32))
	@$(CURDIR)/scripts/l2/l2-generate-deploy-config.sh $(CURDIR)/optimism
	@$(CURDIR)/scripts/l2/l2-deploy-l1-contracts.sh $(CURDIR)/optimism
	@$(CURDIR)/scripts/l2/l2-generate-l2-config.sh $(CURDIR)/optimism $(CURDIR)/.deploy
.PHONY: l2-prepare

## Start the OP chain core components (op-node, op-geth, proposer, batcher)
l2-start:
	@$(CURDIR)/scripts/l2/l2-start.sh $(CURDIR)/optimism
.PHONY: l2-start

## Verify the OP chain is running
l2-verify:
	@$(CURDIR)/scripts/l2/l2-verify.sh
.PHONY: l2-verify


############################
## L2 Bridge UI
############################

## Deploy the multicall contract
l2-bridge-deploy-l1-multicall:
	@$(CURDIR)/scripts/l2-bridge/l2-bridge-deploy-l1-multicall.sh
.PHONY: l2-bridge-deploy-l1-multicall

## Launch the OP Bridge UI
l2-bridge-start:
	@$(CURDIR)/scripts/l2-bridge/l2-bridge-set-env.sh
	@docker compose up -d op-bridge-ui
.PHONY: l2-bridge-start

## Stop the OP Bridge UI
l2-bridge-stop:
	@docker compose down op-bridge-ui
.PHONY: l2-bridge-stop


############################
## L2 Explorer
############################

## Launch the OP chain explorer
l2-explorer-start:
	@$(CURDIR)/scripts/l2-blockscout/l2-blockscout-set-env.sh
	docker compose -f docker/docker-compose-l2-explorer.yml up -d backend-db stats-db
	sleep 5
	docker compose -f docker/docker-compose-l2-explorer.yml up -d backend frontend stats smart-contract-verifier visualizer sig-provider visualizer-proxy proxy
.PHONY: l2-explorer-start

## Stop the OP chain explorer and remove the volumes
l2-explorer-stop: ## Stops all explorer services
	docker compose -f docker/docker-compose-l2-explorer.yml stop proxy visualizer-proxy sig-provider visualizer smart-contract-verifier stats frontend backend stats-db backend-db
	docker compose -f docker/docker-compose-l2-explorer.yml rm -f proxy visualizer-proxy sig-provider visualizer smart-contract-verifier stats frontend backend stats-db backend-db
.PHONY: l2-explorer-stop

## Show running services for the OP chain explorer
l2-explorer-ps:
	docker compose -f docker/docker-compose-l2-explorer.yml ps
.PHONY: l2-explorer-ps

## Show logs for the OP chain explorer
l2-explorer-logs:
	docker compose -f docker/docker-compose-l2-explorer.yml logs -f
.PHONY: l2-explorer-logs
