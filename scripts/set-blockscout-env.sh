#!/bin/bash
set -euo pipefail

echo "Checking the env vars in .env file..."
# Path to the rollup.json file
OP_DEPLOY_DIR=$1
ROLLUP_JSON="${OP_DEPLOY_DIR}/rollup.json"

# Path to the .env file
ENV_FILE=$2

# Path to the OP deployments directory
OP_DEPLOYMENTS_DIR=$3/packages/contracts-bedrock/deployments

# List of required environment variables
required_vars=(
    "L1_RPC_URL"
    "L1_BEACON_URL"
    "L2_RPC_URL"
    "L1_SYSTEM_CONFIG_CONTRACT"
    "DISABLE_BEACON_BLOB_FETCHER"
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

# Check if DISABLE_BEACON_BLOB_FETCHER in the .env file is false
if grep -q "^DISABLE_BEACON_BLOB_FETCHER=false" "$ENV_FILE"; then
    # Extract L1 block number and l2_time from rollup.json
    L1_BLOCK_NUMBER=$(jq -r '.genesis.l1.number' "$ROLLUP_JSON")
    L2_TIME=$(jq -r '.genesis.l2_time' "$ROLLUP_JSON")

    # Get the slot number of the L1 block
    L1_SLOT_NUMBER=$(curl -s "${L1_BEACON_URL}/eth/v1/beacon/headers/${L1_BLOCK_NUMBER}" \
    | jq -r '.data.header.message.slot')

    sed -i "s/^L2_BEACON_BLOB_FETCHER_REFERENCE_SLOT=.*/L2_BEACON_BLOB_FETCHER_REFERENCE_SLOT=$L1_SLOT_NUMBER/" "$ENV_FILE"
    sed -i "s/^L2_BEACON_BLOB_FETCHER_REFERENCE_TIMESTAMP=.*/L2_BEACON_BLOB_FETCHER_REFERENCE_TIMESTAMP=$L2_TIME/" "$ENV_FILE"
fi

echo "Updated .env file for Blockscout"