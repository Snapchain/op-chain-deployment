#!/bin/bash
set -euo pipefail

# Path to the .env file
ENV_FILE=$(pwd)/.env


# Path to the rollup.json file
OP_DEPLOY_DIR=$(pwd)/.deploy
ROLLUP_JSON="${OP_DEPLOY_DIR}/rollup.json"

# Path to the OP deployments directory
OP_DEPLOYMENTS_DIR=$(pwd)/optimism/packages/contracts-bedrock/deployments

# List of required environment variables
required_vars=(
    "L1_CHAIN_ID"
    "L1_RPC_URL"
    "L2_CHAIN_ID"
    "L2_RPC_URL"
)

# Check if each required variable is set
for var in "${required_vars[@]}"; do
    if ! grep -q "^$var=" "$ENV_FILE"; then
        echo "$var is not set in .env file. Please set it and run this script again."
        exit 1
    fi
done

echo "Updating .env file for OP Bridge UI..."
# Extract contract addresses from the deployments .json file
L1_STANDARD_BRIDGE_PROXY=$(jq -r '.L1StandardBridgeProxy' "$OP_DEPLOYMENTS_DIR/op-devnet-${L2_CHAIN_ID}.json")
L1_OPTIMISM_PORTAL_PROXY=$(jq -r '.OptimismPortalProxy' "$OP_DEPLOYMENTS_DIR/op-devnet-${L2_CHAIN_ID}.json")
L2_OUTPUT_ORACLE_PROXY=$(jq -r '.L2OutputOracleProxy' "$OP_DEPLOYMENTS_DIR/op-devnet-${L2_CHAIN_ID}.json")

# Update .env file
sed -i "s/^NEXT_PUBLIC_L1_CHAIN_ID=.*/NEXT_PUBLIC_L1_CHAIN_ID=$L1_CHAIN_ID/" "$ENV_FILE"
sed -i "s/^NEXT_PUBLIC_L1_CHAIN_NAME=.*/NEXT_PUBLIC_L1_CHAIN_NAME=$L1_CHAIN_NAME/" "$ENV_FILE"
sed -i "s/^NEXT_PUBLIC_L2_CHAIN_ID=.*/NEXT_PUBLIC_L2_CHAIN_ID=$L2_CHAIN_ID/" "$ENV_FILE"
sed -i "s/^NEXT_PUBLIC_L2_CHAIN_NAME=.*/NEXT_PUBLIC_L2_CHAIN_NAME=$L2_CHAIN_NAME/" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L1_RPC_URL=.*|NEXT_PUBLIC_L1_RPC_URL=$L1_RPC_URL|" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L2_RPC_URL=.*|NEXT_PUBLIC_L2_RPC_URL=$L2_RPC_URL|" "$ENV_FILE"
sed -i "s/^NEXT_PUBLIC_L1_STANDARD_BRIDGE_PROXY=.*/NEXT_PUBLIC_L1_STANDARD_BRIDGE_PROXY=$L1_STANDARD_BRIDGE_PROXY/" "$ENV_FILE"
sed -i "s/^NEXT_PUBLIC_L1_OPTIMISM_PORTAL_PROXY=.*/NEXT_PUBLIC_L1_OPTIMISM_PORTAL_PROXY=$L1_OPTIMISM_PORTAL_PROXY/" "$ENV_FILE"
sed -i "s/^NEXT_PUBLIC_L2_OUTPUT_ORACLE_PROXY=.*/NEXT_PUBLIC_L2_OUTPUT_ORACLE_PROXY=$L2_OUTPUT_ORACLE_PROXY/" "$ENV_FILE"
echo "Updated .env file for OP Bridge UI"
