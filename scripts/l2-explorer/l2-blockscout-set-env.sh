#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

# Path to the .explorer.env file
ENV_FILE=$(pwd)/.env.explorer

# Path to the rollup.json file
OP_DEPLOY_DIR=$(pwd)/.deploy
ROLLUP_JSON="${OP_DEPLOY_DIR}/rollup.json"
# Path to the OP deployments directory
OP_DEPLOYMENTS_JSON_PATH=$(pwd)/.deploy/op-devnet-deployments-${L2_CHAIN_ID}.json

echo "Updating .explorer.env file for Blockscout..."
# Extract l1_system_config_address from rollup.json
L1_SYSTEM_CONFIG_ADDRESS=$(jq -r '.l1_system_config_address' "$ROLLUP_JSON")

# Extract L2OutputOracleProxy from the deployments .json file
OUTPUT_ORACLE_ADDRESS=$(jq -r '.L2OutputOracleProxy' "$OP_DEPLOYMENTS_JSON_PATH")

# Update .explorer.env file
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|^L1_SYSTEM_CONFIG_CONTRACT=.*|L1_SYSTEM_CONFIG_CONTRACT=$L1_SYSTEM_CONFIG_ADDRESS|" "$ENV_FILE"
    sed -i '' "s|^L1_OUTPUT_ORACLE_CONTRACT=.*|L1_OUTPUT_ORACLE_CONTRACT=$OUTPUT_ORACLE_ADDRESS|" "$ENV_FILE"
else
    # Linux and others
    sed -i "s|^L1_SYSTEM_CONFIG_CONTRACT=.*|L1_SYSTEM_CONFIG_CONTRACT=$L1_SYSTEM_CONFIG_ADDRESS|" "$ENV_FILE"
    sed -i "s|^L1_OUTPUT_ORACLE_CONTRACT=.*|L1_OUTPUT_ORACLE_CONTRACT=$OUTPUT_ORACLE_ADDRESS|" "$ENV_FILE"
fi
echo "Updated .explorer.env file for Blockscout"