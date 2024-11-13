#!/bin/bash
set -euo pipefail

# Source the .env file
set -a
source $(pwd)/.env
set +a

source $(pwd)/scripts/l2/common.sh

# Stop the OP Node
echo "Stopping the OP Node..."
docker compose -f docker/docker-compose-l2.yml stop op-node

# set L2OO or DGF env vars
post_deployment_setup_env_vars $(pwd)/.deploy/op-devnet-deployments-${L2_CHAIN_ID}.json $DEVNET_L2OO

ROLLUP_CONFIG=$(pwd)/.deploy/rollup.json
# set babylonFinalityGadgetRpc in rollup.json
if [ "$BBN_FINALITY_GADGET_RPC" != "" ]; then
    echo "Setting babylonFinalityGadgetRpc in rollup.json with value: $BBN_FINALITY_GADGET_RPC"
    sed -i.bak 's|"babylonFinalityGadgetRpc":.*|"babylonFinalityGadgetRpc": "'"$BBN_FINALITY_GADGET_RPC"'"|' $ROLLUP_CONFIG
    rm $ROLLUP_CONFIG.bak
else
    echo "BBN_FINALITY_GADGET_RPC is not set in the .env file. If the Finality Gadget is up, please set it to the gRPC URL and try again."
    exit 1
fi

# get the babylonFinalityGadgetRpc from rollup.json
FG_URL_IN_ROLLUP=$(jq -r '.babylonFinalityGadgetRpc' $ROLLUP_CONFIG)
if [ "$FG_URL_IN_ROLLUP" != "$BBN_FINALITY_GADGET_RPC" ]; then
    echo "babylonFinalityGadgetRpc in rollup.json ($FG_URL_IN_ROLLUP) is not equal to the value in .env ($BBN_FINALITY_GADGET_RPC)"
    exit 1
fi

# Start the OP Node
echo "Starting the OP Node..."
docker compose -f docker/docker-compose-l2.yml up -d op-node