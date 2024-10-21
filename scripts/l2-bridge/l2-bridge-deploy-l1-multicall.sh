#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

cd "$(pwd)/multicall"
forge build

CHAIN_ID=$(cast chain-id --rpc-url "${L1_RPC_URL}")

DEPLOYED_URL=$(curl https://raw.githubusercontent.com/mds1/multicall/main/deployments.json | grep -A 3 "\"chainId\": ${CHAIN_ID},"  | grep "\"url\":" | awk -F'"' '{print $4}')
if [ ! -z "${DEPLOYED_URL}" ]; then
    # Extract the Ethereum address from the URL
    DEPLOYED_ADDRESS=$(echo "$DEPLOYED_URL" | grep -oE '0x[a-fA-F0-9]{40}')
    if [ -n "$DEPLOYED_ADDRESS" ]; then
        echo "Contract is already deployed. Exiting."
        # Update the .env file with the deployed address
        sed -i.bak "s/^NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=.*/NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=${DEPLOYED_ADDRESS}/" ../.env
        rm ../.env.bak
        exit 0
    else
        echo "No Ethereum address found in the URL"
    fi
fi

# Stream forge output in real-time
forge create --rpc-url "${L1_RPC_URL}" --private-key "${L1_FUNDED_PRIVATE_KEY}" Multicall3 | tee forge_output.log

# Extract the deployed address from the log file
DEPLOYED_ADDRESS=$(grep "Deployed to:" forge_output.log | awk '{print $3}')
rm forge_output.log

# Update the .env.bridge file with the deployed address
sed -i.bak "s/^NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=.*/NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=${DEPLOYED_ADDRESS}/" ../.env.bridge
rm ../.env.bridge.bak

# Update the .env file with the deployed address
sed -i.bak "s/^NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=.*/NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=${DEPLOYED_ADDRESS}/" ../.env
rm ../.env.bak
