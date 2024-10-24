#!/bin/bash
set -euo pipefail

# Stop the OP chain containers
docker compose -f "$(pwd)/docker/docker-compose-l2.yml" down

# Remove the .deploy directory
rm -rf "$(pwd)/.deploy"

# Remove the op-chain-deployment volume
docker volume ls --filter name=op-chain-deployment --format='{{.Name}}' | xargs -r docker volume rm