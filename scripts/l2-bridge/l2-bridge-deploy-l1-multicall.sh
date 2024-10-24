#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

# Path to the .env.bridge file
ENV_FILE=$(pwd)/.env.bridge

echo "Checking if multicall contract is already deployed..."
CHAIN_ID=$(cast chain-id --rpc-url "${L1_RPC_URL}")
DEPLOYED_URL=$(curl -s https://raw.githubusercontent.com/mds1/multicall/main/deployments.json | jq -r ".[] | select(.chainId == $CHAIN_ID) | .url")
if [ ! -z "${DEPLOYED_URL}" ]; then
    # Extract the Ethereum address from the URL
    echo "Extracting multicall contract address from the deployed URL..."
    DEPLOYED_ADDRESS=$(echo "$DEPLOYED_URL" | grep -oE '0x[a-fA-F0-9]{40}')
    if [ -n "$DEPLOYED_ADDRESS" ]; then
        echo "Contract is already deployed. Exiting."
        # Update the .env.bridge file with the deployed address
        sed -i.bak "s/^NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=.*/NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=${DEPLOYED_ADDRESS}/" $ENV_FILE
        rm $ENV_FILE.bak
        echo "Updated $ENV_FILE file with the deployed multicall contract address ${DEPLOYED_ADDRESS}"
        exit 0
    else
        echo "No Ethereum address found in the URL"
    fi
fi

echo "Building multicall contract..."
cd "$(pwd)/multicall"
forge build

echo "Deploying multicall contract..."
# Stream forge output in real-time
forge create --rpc-url "${L1_RPC_URL}" --private-key "${L1_FUNDED_PRIVATE_KEY}" Multicall3 | tee forge_output.log

# Extract the deployed address from the log file
echo "Extracting multicall contract address from the log file..."
DEPLOYED_ADDRESS=$(grep "Deployed to:" forge_output.log | awk '{print $3}')
rm forge_output.log

# Update the .env.bridge file with the deployed address
sed -i.bak "s/^NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=.*/NEXT_PUBLIC_L1_MULTICALL3_ADDRESS=${DEPLOYED_ADDRESS}/" $ENV_FILE
rm $ENV_FILE.bak
echo "Updated $ENV_FILE file with the new deployed multicall contract address ${DEPLOYED_ADDRESS}"