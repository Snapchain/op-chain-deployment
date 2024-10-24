#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

if [ -z "$L2_RPC_URL" ]; then
    echo "L2_RPC_URL is not set in the .env file"
    exit 1
fi

# Path to the .env.bridge file
ENV_FILE=$(pwd)/.env.bridge
# Path to the rollup.json file
OP_DEPLOY_DIR=$(pwd)/.deploy
ROLLUP_JSON="${OP_DEPLOY_DIR}/rollup.json"
# Path to the OP deployments directory
OP_DEPLOYMENTS_JSON_PATH=$(pwd)/.deploy/op-devnet-deployments-${L2_CHAIN_ID}.json

echo "Updating .env.bridge file for OP Bridge UI..."
# Extract contract addresses from the deployments .json file
L1_STANDARD_BRIDGE_PROXY=$(jq -r '.L1StandardBridgeProxy' "$OP_DEPLOYMENTS_JSON_PATH")
L1_OPTIMISM_PORTAL_PROXY=$(jq -r '.OptimismPortalProxy' "$OP_DEPLOYMENTS_JSON_PATH")
L2_OUTPUT_ORACLE_PROXY=$(jq -r '.L2OutputOracleProxy' "$OP_DEPLOYMENTS_JSON_PATH")

# Update .env.bridge file
sed -i "s|^NEXT_PUBLIC_L1_CHAIN_ID=.*|NEXT_PUBLIC_L1_CHAIN_ID=$L1_CHAIN_ID|" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L1_CHAIN_NAME=.*|NEXT_PUBLIC_L1_CHAIN_NAME=\"$L1_CHAIN_NAME\"|" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L2_CHAIN_ID=.*|NEXT_PUBLIC_L2_CHAIN_ID=$L2_CHAIN_ID|" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L2_CHAIN_NAME=.*|NEXT_PUBLIC_L2_CHAIN_NAME=\"$L2_CHAIN_NAME\"|" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L1_RPC_URL=.*|NEXT_PUBLIC_L1_RPC_URL=$L1_RPC_URL|" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L2_RPC_URL=.*|NEXT_PUBLIC_L2_RPC_URL=$L2_RPC_URL|" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L1_STANDARD_BRIDGE_PROXY=.*|NEXT_PUBLIC_L1_STANDARD_BRIDGE_PROXY=$L1_STANDARD_BRIDGE_PROXY|" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L1_OPTIMISM_PORTAL_PROXY=.*|NEXT_PUBLIC_L1_OPTIMISM_PORTAL_PROXY=$L1_OPTIMISM_PORTAL_PROXY|" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L2_OUTPUT_ORACLE_PROXY=.*|NEXT_PUBLIC_L2_OUTPUT_ORACLE_PROXY=$L2_OUTPUT_ORACLE_PROXY|" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L1_EXPLORER_URL=.*|NEXT_PUBLIC_L1_EXPLORER_URL=$L1_EXPLORER_URL|" "$ENV_FILE"
sed -i "s|^NEXT_PUBLIC_L2_EXPLORER_URL=.*|NEXT_PUBLIC_L2_EXPLORER_URL=$L2_EXPLORER_URL|" "$ENV_FILE"
# TODO: we should change this when fault proof is enabled
sed -i "s|^NEXT_PUBLIC_DISPUTE_GAME_FACTORY_PROXY=.*|NEXT_PUBLIC_DISPUTE_GAME_FACTORY_PROXY=|" "$ENV_FILE"

echo "Updated .env.bridge file for OP Bridge UI"
