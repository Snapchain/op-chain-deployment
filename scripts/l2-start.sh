#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

wait_up() {
    local port=$1
    local retries=10
    local wait_time=1

    for i in $(seq 1 $retries); do
        if nc -z localhost $port; then
            echo "Port $port is available"
            return 0
        fi
        echo "Attempt $i: Port $port is not available yet. Waiting $wait_time seconds..."
        sleep $wait_time
    done

    echo "Error: Port $port did not become available after $retries attempts"
    return 1
}

# set the needed environment variable
echo "Setting the needed environment variable..."
DEPLOYMENT_OUTFILE=$1/packages/contracts-bedrock/deployments/op-devnet-${L2_CHAIN_ID}.json
if [ "$DEVNET_L2OO" = true ]; then
  export L2OO_ADDRESS=$(jq -r .L2OutputOracleProxy < ${DEPLOYMENT_OUTFILE})
else
  export DGF_ADDRESS=$(jq -r .DisputeGameFactoryProxy < ${DEPLOYMENT_OUTFILE})
  # these two values are from the bedrock-devnet
  export DG_TYPE=254
  export PROPOSAL_INTERVAL=12s
fi
if [ "$DEVNET_ALTDA" = true ]; then
  export ALTDA_ENABLED=true
  export DA_TYPE=calldata
else
  export ALTDA_ENABLED=false
  export DA_TYPE=blobs
fi
if [ "$GENERIC_ALTDA" = true ]; then
  export ALTDA_GENERIC_DA=true
  export ALTDA_SERVICE=true
else
  export ALTDA_GENERIC_DA=false
  export ALTDA_SERVICE=false
fi
echo

# Launch the OP L2
echo "Launching the OP L2..."
docker compose -f docker-compose.yml up -d l2

# Wait for the OP L2 to be available
echo "Waiting for OP L2 to be available..."
wait_up 9545
sleep 5
echo

# Launch the OP Node, Proposer and Batcher
echo "Launching the OP Node, Proposer and Batcher..."
docker compose -f docker-compose.yml up -d op-node op-proposer op-batcher

# Wait for the OP Node to be available
echo "Waiting for OP Node, Proposer and Batcher to be available..."
wait_up 7545
wait_up 7546
wait_up 7547
echo

sleep 10
OP_BEDROCK_DIR=$(pwd)/optimism/packages/contracts-bedrock
mv ${OP_BEDROCK_DIR}/deployments/op-devnet-${L2_CHAIN_ID}.json $(pwd)/.deploy/op-devnet-deployments-${L2_CHAIN_ID}.json
mv ${OP_BEDROCK_DIR}/deploy-config/op-devnet-${L2_CHAIN_ID}.json $(pwd)/.deploy/op-devnet-deploy-config-${L2_CHAIN_ID}.json