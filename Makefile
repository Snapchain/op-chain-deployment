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
## Note: we need to wait long enough for the L1 chain to run and produce at least one block,
## after some testing, 45s is a safe number.
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
	@$(CURDIR)/scripts/l2/l2-start.sh
.PHONY: l2-start

## Verify the OP chain is running
l2-verify:
	@$(CURDIR)/scripts/l2/l2-verify.sh
.PHONY: l2-verify

## Restart the OP Node
l2-op-node-restart:
	@$(CURDIR)/scripts/l2/l2-op-node-restart.sh
.PHONY: l2-op-node-restart

## Restart the OP chain
l2-restart:
	@docker compose -f docker/docker-compose-l2.yml stop l2 op-node op-proposer op-batcher
	@$(CURDIR)/scripts/l2/l2-start.sh
.PHONY: l2-restart

## Teardown the OP chain
l2-teardown:
	@$(CURDIR)/scripts/l2/l2-teardown.sh
.PHONY: l2-teardown

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
	@docker compose -f docker/docker-compose-l2.yml up -d op-bridge-ui
.PHONY: l2-bridge-start

## Stop the OP Bridge UI
l2-bridge-stop:
	@docker compose -f docker/docker-compose-l2.yml down op-bridge-ui
.PHONY: l2-bridge-stop

## Restart the OP Bridge UI
l2-bridge-restart:
	@$(CURDIR)/scripts/l2-bridge/l2-bridge-restart.sh
.PHONY: l2-bridge-restart

############################
## L2 Explorer
############################

## Launch the OP chain explorer
l2-explorer-start:
	@$(CURDIR)/scripts/l2-explorer/l2-explorer-start.sh
.PHONY: l2-explorer-start

## Restart the OP chain explorer (without deleting the volumes)
l2-explorer-restart:
	@$(CURDIR)/scripts/l2-explorer/l2-explorer-restart.sh
.PHONY: l2-explorer-restart

## Stop the OP chain explorer and remove the volumes
l2-explorer-stop: ## Stops all explorer services
	docker compose -f docker/docker-compose-l2-explorer.yml stop proxy visualizer-proxy sig-provider visualizer smart-contract-verifier stats frontend backend stats-db backend-db
	docker compose -f docker/docker-compose-l2-explorer.yml rm -f proxy visualizer-proxy sig-provider visualizer smart-contract-verifier stats frontend backend stats-db backend-db
.PHONY: l2-explorer-stop

## Show running services for the OP chain explorer
l2-explorer-ps:
	docker compose -f docker/docker-compose-l2-explorer.yml ps --format "table {{.ID}}\t{{.Name}}\t{{.Status}}\t{{.Ports}}"
.PHONY: l2-explorer-ps

## Show logs for the OP chain explorer
l2-explorer-logs:
	docker compose -f docker/docker-compose-l2-explorer.yml logs -f
.PHONY: l2-explorer-logs

l2-proxy-setup:
	@$(CURDIR)/scripts/l2/proxy-setup.sh
.PHONY: l2-proxy-setup
