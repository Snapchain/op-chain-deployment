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

# Start the OP Node
echo "Starting the OP Node..."
docker compose -f docker/docker-compose-l2.yml up -d op-node