#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

cd "$(pwd)/multicall"
forge build

# TODO: check if the contract is already deployed. skip if it is
# - use cast to get the chain id using L1_RPC_URL
# - curl https://raw.githubusercontent.com/mds1/multicall/main/deployments.json
# - check if the chain id is in the deployments.json file
CHAIN_ID=$(cast chain-id --rpc-url "${L1_RPC_URL}")

DEPLOYED_ADDRESS=$(curl https://raw.githubusercontent.com/mds1/multicall/main/deployments.json | grep "chainId" | awk -F '[:,]' '{print $2}' | grep -w "${CHAIN_ID}")
if [ ! -z "${DEPLOYED_ADDRESS}" ]; then
    echo "Contract is already deployed. Exiting."
    exit 0
fi

# Stream forge output in real-time
forge create --rpc-url "${L1_RPC_URL}" --private-key "${L1_FUNDED_PRIVATE_KEY}" Multicall3 | tee forge_output.log

# Extract the deployed address from the log file
DEPLOYED_ADDRESS=$(grep "Deployed to:" forge_output.log | awk '{print $3}')
rm forge_output.log

# Update the .env file with the deployed address
sed -i.bak "s/^NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=.*/NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=${DEPLOYED_ADDRESS}/" ../.env
rm ../.env.bak
