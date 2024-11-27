#!/bin/bash
set -euo pipefail

# Parse the YAML file and extract the required values
YAML_FILE=$1
NETWORK_ID=$(yq '.network_params.network_id' "$YAML_FILE" | tr -d '"')
EL_PORT_START=$(yq '.port_publisher.el.public_port_start' "$YAML_FILE")
CL_PORT_START=$(yq '.port_publisher.cl.public_port_start' "$YAML_FILE")

# Extract prefunded addresses
PREFUNDED_ACCOUNTS=$(yq -r '.network_params.prefunded_accounts' "$YAML_FILE" | jq -r 'keys[]')
PREFUNDED_ACCOUNTS_ARRAY=()
while IFS= read -r line; do
    PREFUNDED_ACCOUNTS_ARRAY+=("$line")
done <<< "$PREFUNDED_ACCOUNTS"

# Calculate the actual ports
L1_RPC_PORT=$((EL_PORT_START + 2))
L1_BEACON_PORT=$((CL_PORT_START + 1))

# L1 RPC endpoint
L1_RPC_URL="http://localhost:$L1_RPC_PORT"

# L1 Beacon endpoint
L1_BEACON_URL="http://localhost:$L1_BEACON_PORT"

# Expected Chain ID
EXPECTED_CHAIN_ID=$NETWORK_ID

# Check if L1 execution client is running
echo "Checking if L1 execution client is running..."
L1_CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
    $L1_RPC_URL | jq -r '.result')

if [ -n "$L1_CHAIN_ID" ]; then
    DECIMAL_CHAIN_ID=$((16#${L1_CHAIN_ID#0x}))
    if [ "$DECIMAL_CHAIN_ID" = "$EXPECTED_CHAIN_ID" ]; then
        echo "L1 execution client is running. Chain ID: $DECIMAL_CHAIN_ID"
    else
        echo "Error: L1 execution client is running, but with unexpected Chain ID: $DECIMAL_CHAIN_ID (expected: $EXPECTED_CHAIN_ID)"
        exit 1
    fi
else
    echo "Error: L1 execution client is not responding correctly"
    exit 1
fi

# Check if L1 beacon node is running
echo "Checking if L1 beacon node is running..."
BEACON_RESPONSE=$(curl -s -X GET "$L1_BEACON_URL/eth/v2/beacon/blocks/1" -H "accept: application/json")

if echo "$BEACON_RESPONSE" | jq -e '.data' > /dev/null; then
    echo "L1 beacon node is running and responding"
else
    echo "Error: L1 beacon node is not responding correctly"
    exit 1
fi

# Get latest block number
LATEST_BLOCK=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    $L1_RPC_URL | jq -r '.result')

echo "Latest block number: $((16#${LATEST_BLOCK#0x}))"

# Check the balance of the prefunded accounts
echo "Checking the balance of the prefunded accounts..."
for ACCOUNT in "${PREFUNDED_ACCOUNTS_ARRAY[@]}"; do
    ETH_BALANCE_WEI=$(curl -s -X POST -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["'$ACCOUNT'", "latest"],"id":1}' \
        $L1_RPC_URL | jq -r '.result')
    ETH_BALANCE=$(echo "$ETH_BALANCE_WEI" | awk '{ printf "%.18f", $1 / (10^18) }')
    echo "Balance of $ACCOUNT: $ETH_BALANCE ETH"
done

echo "L1 chain is running and operational"