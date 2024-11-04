#!/bin/bash
set -euo pipefail

# Run the l2-bridge-set-env.sh script
$(pwd)/scripts/l2-bridge/l2-bridge-set-env.sh

# Source the .env file
set -a
source $(pwd)/.env.bridge
set +a

# Stop the OP Bridge UI
echo "Stopping the OP Bridge UI..."
docker compose -f docker/docker-compose-l2.yml stop op-bridge-ui

# Start the OP Bridge UI
echo "Starting the OP Bridge UI..."
docker compose -f docker/docker-compose-l2.yml up -d op-bridge-ui