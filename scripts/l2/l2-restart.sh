#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

# Stop the OP Geth, OP Node, Proposer and Batcher
echo "Stopping the OP Geth, OP Node, Proposer and Batcher..."
docker compose -f docker/docker-compose-l2.yml stop l2 op-node op-proposer op-batcher

# Start the OP Geth, OP Node, Proposer and Batcher
echo "Starting the OP Geth, OP Node, Proposer and Batcher..."
docker compose -f docker/docker-compose-l2.yml up -d l2 op-node op-proposer op-batcher