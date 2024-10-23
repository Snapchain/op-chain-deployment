#!/bin/bash

set -e

# Run the l2-blockscout-set-env.sh script
"$(pwd)/scripts/l2-explorer/l2-blockscout-set-env.sh"

# Source the .env.explorer file
set -a
source $(pwd)/.env
source $(pwd)/.env.explorer
set +a

# Stop services
docker compose -f "$(dirname "$0")/../../docker/docker-compose-l2-explorer.yml" stop backend frontend stats smart-contract-verifier visualizer sig-provider visualizer-proxy proxy

# Start services
docker compose -f "$(dirname "$0")/../../docker/docker-compose-l2-explorer.yml" up -d backend frontend stats smart-contract-verifier visualizer sig-provider visualizer-proxy proxy