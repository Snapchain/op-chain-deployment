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
# set babylon_finality_gadget_rpc in rollup.json
if [ -z "$BBN_FINALITY_GADGET_RPC" ]; then
    echo "Setting babylon_finality_gadget_rpc with empty value in rollup.json"
else
    echo "Setting babylon_finality_gadget_rpc with value $BBN_FINALITY_GADGET_RPC in rollup.json"
fi

sed -i.bak 's|"babylon_finality_gadget_rpc":.*|"babylon_finality_gadget_rpc": "'"$BBN_FINALITY_GADGET_RPC"'"|' $ROLLUP_CONFIG
rm $ROLLUP_CONFIG.bak

# get the babylon_finality_gadget_rpc from rollup.json
FG_URL_IN_ROLLUP=$(jq -r '.babylon_finality_gadget_rpc' $ROLLUP_CONFIG)
if [ "$FG_URL_IN_ROLLUP" != "$BBN_FINALITY_GADGET_RPC" ]; then
    echo "ERROR: value mismatch - rollup.json: babylon_finality_gadget_rpc($FG_URL_IN_ROLLUP), .env: BBN_FINALITY_GADGET_RPC($BBN_FINALITY_GADGET_RPC)"
    exit 1
fi

# Start the OP Node
echo "Starting the OP Node..."
docker compose -f docker/docker-compose-l2.yml up -d op-node