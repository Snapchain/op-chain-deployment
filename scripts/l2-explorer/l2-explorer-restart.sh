#!/bin/bash
set -euo pipefail

# Source the .env.explorer file
set -a
source $(pwd)/.env
source $(pwd)/.env.explorer
set +a

# Stop services
echo "Stopping the OP chain explorer services..."
docker compose -f docker/docker-compose-l2-explorer.yml stop backend frontend stats smart-contract-verifier visualizer sig-provider visualizer-proxy proxy

# Start services
echo "Starting the OP chain explorer services..."
docker compose -f docker/docker-compose-l2-explorer.yml up -d backend frontend stats smart-contract-verifier visualizer sig-provider visualizer-proxy proxy