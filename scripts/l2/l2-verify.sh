#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

# check if L2 op-geth is running
echo "Checking if L2 op-geth is running..."
L2_CHAIN_ID_RESULT=$(cast chain-id --rpc-url http://localhost:9545)

if [ "$L2_CHAIN_ID_RESULT" = "$L2_CHAIN_ID" ]; then
    echo "L2 op-geth is running and the chain id is $L2_CHAIN_ID"
else
    echo "ERROR: L2 op-geth is not running because the chain id is not responding correctly"
fi

# check if L2 op-node is running
echo "Checking if L2 op-node is running..."
curl -s -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
    http://localhost:7545 | \
    jq '.result | {
        head_l1_number: .head_l1.number,
        safe_l1_number: .safe_l1.number,
        finalized_l1_number: .finalized_l1.number,
        unsafe_l2_number: .unsafe_l2.number,
        safe_l2_number: .safe_l2.number,
        finalized_l2_number: .finalized_l2.number
    }'
if [ $? -ne 0 ]; then
    echo "ERROR: L2 op-node is not running because the RPC is not responding correctly"
fi
echo