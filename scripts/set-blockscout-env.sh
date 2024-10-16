#!/bin/bash
set -euo pipefail

echo "Checking the env vars in .env file..."
# Path to the rollup.json file
OP_DEPLOY_DIR=$(pwd)/.deploy
ROLLUP_JSON="${OP_DEPLOY_DIR}/rollup.json"

# Path to the .env file
ENV_FILE=$(pwd)/.env

# Path to the OP deployments directory
OP_DEPLOYMENTS_DIR=$(pwd)/optimism/packages/contracts-bedrock/deployments

# List of required environment variables
required_vars=(
    "L1_RPC_URL"
    "L1_BEACON_URL"
    "L2_RPC_URL"
    "L1_SYSTEM_CONFIG_CONTRACT"
)

# Check if each required variable is set
for var in "${required_vars[@]}"; do
    if ! grep -q "^$var=" "$ENV_FILE"; then
        echo "$var is not set in .env file. Please set it and run this script again."
        exit 1
    fi
done

echo "Updating .env file for Blockscout..."
# Extract l1_system_config_address from rollup.json
L1_SYSTEM_CONFIG_ADDRESS=$(jq -r '.l1_system_config_address' "$ROLLUP_JSON")

# Extract L2OutputOracleProxy from the deployments .json file
OUTPUT_ORACLE_ADDRESS=$(jq -r '.L2OutputOracleProxy' "$OP_DEPLOYMENTS_DIR/sepolia-devnet-${L2_CHAIN_ID}.json")

# Update .env file
sed -i "s/^L1_SYSTEM_CONFIG_CONTRACT=.*/L1_SYSTEM_CONFIG_CONTRACT=$L1_SYSTEM_CONFIG_ADDRESS/" "$ENV_FILE"
sed -i "s/^L1_OUTPUT_ORACLE_CONTRACT=.*/L1_OUTPUT_ORACLE_CONTRACT=$OUTPUT_ORACLE_ADDRESS/" "$ENV_FILE"
echo "Updated .env file for Blockscout"