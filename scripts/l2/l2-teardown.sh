#!/bin/bash
set -euo pipefail

# Path to the .env file
ENV_FILE="$(pwd)/.env"

# Source the .env file
source "$ENV_FILE"

# Function to send out funds from an address
drain_address() {
    local address=$1
    local private_key=$2

    # Get existing balance
    balance=$(cast balance --rpc-url "$L2_RPC_URL" "$address")
    echo "Existing balance: $balance"

    if [[ "$balance" == "0" ]]; then
        echo "Balance is 0, skipping..."
        return
    fi

    # Estimate gas
    gas_cost=$(cast estimate --rpc-url "$L2_RPC_URL" \
        --from "$address" \
        --value "$balance" \
        "$L1_FUNDED_ADDRESS" | \
        xargs cast --to-eth --pad 18)
    
    # Add 20% buffer
    gas_cost_with_buffer=$(echo "$gas_cost * 1.2" | bc)
    amount=$(echo "$balance - $gas_cost_with_buffer" | bc)

    # Send out funds if amount is greater than 0
    if [[ "$amount" -gt 0 ]]; then
        echo "Sending out $amount to $L1_FUNDED_ADDRESS"
        cast send --private-key "$private_key" --rpc-url "$L2_RPC_URL" \
            --value "$amount" "$L1_FUNDED_ADDRESS"
    else
        echo "Gas cost exceeds balance, skipping..."
    fi
}

# Fund the generated addresses
for role in ADMIN BATCHER PROPOSER; do
    address_var="GS_${role}_ADDRESS"
    private_key_var="GS_${role}_PRIVATE_KEY"
    address="${!address_var}"
    private_key="${!private_key_var}"

    if [[ -n "$address" ]]; then
        echo "Draining $role address: $address"
        drain_address "$address" "$private_key"
        echo
    else
        echo "Warning: $role address not found in .env file"
        echo
    fi
done

echo "Draining complete."