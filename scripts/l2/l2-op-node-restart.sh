#!/bin/bash
set -euo pipefail

# Source the .env file
set -a
source $(pwd)/.env
set +a

# Stop the OP Node
echo "Stopping the OP Node..."
docker compose -f docker/docker-compose-l2.yml stop op-node

# Start the OP Node
echo "Starting the OP Node..."
docker compose -f docker/docker-compose-l2.yml up -d op-node