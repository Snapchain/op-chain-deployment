#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

cd "$(pwd)/multicall"
forge build

# Stream forge output in real-time
forge create --rpc-url "${L1_RPC_URL}" --private-key "${L1_FUNDED_PRIVATE_KEY}" Multicall3 | tee forge_output.log

# Extract the deployed address from the log file
DEPLOYED_ADDRESS=$(grep "Deployed to:" forge_output.log | awk '{print $3}')
rm forge_output.log

# Update the .env file with the deployed address
sed -i.bak "s/^NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=.*/NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=${DEPLOYED_ADDRESS}/" ../.env
rm ../.env.bak
