#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

source $(pwd)/scripts/l2/common.sh

# set L2OO or DGF env vars after the deployment
post_deployment_setup_env_vars $(pwd)/.deploy/op-devnet-deployments-${L2_CHAIN_ID}.json $DEVNET_L2OO

# Launch the OP L2
echo "Launching the OP L2..."
docker compose -f docker/docker-compose-l2.yml up -d l2

# Wait for the OP L2 to be available
echo "Waiting for OP L2 to be available..."
wait_up 9545
sleep 5
echo

# Launch the OP Node, Proposer and Batcher
echo "Launching the OP Node, Proposer and Batcher..."
docker compose -f docker/docker-compose-l2.yml up -d op-node op-proposer op-batcher

# Wait for the OP Node to be available
echo "Waiting for OP Node, Proposer and Batcher to be available..."
wait_up 7545
wait_up 7546
wait_up 7547
echo