#!/bin/bash
set -euo pipefail

# Run the l2-blockscout-set-env.sh script
$(pwd)/scripts/l2-explorer/l2-blockscout-set-env.sh

# Source the .env.explorer file
set -a
source $(pwd)/.env
source $(pwd)/.env.explorer
set +a

# Start the first set of services
echo "Starting the OP chain explorer database services..."
docker compose -f docker/docker-compose-l2-explorer.yml up -d backend-db stats-db

# Wait for 5 seconds
sleep 5

# Start the second set of services
echo "Starting the OP chain explorer services..."
docker compose -f docker/docker-compose-l2-explorer.yml up -d backend frontend stats smart-contract-verifier visualizer sig-provider visualizer-proxy proxy