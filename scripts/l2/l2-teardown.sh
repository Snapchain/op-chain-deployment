#!/bin/bash
set -euo pipefail

# Path to the .env file
ENV_FILE="$(pwd)/.env"

# Source the .env file
source "$ENV_FILE"

# Get L1 funded address from priv key
L1_FUNDED_ADDRESS=$(cast wallet address --private-key "$L1_FUNDED_PRIVATE_KEY")

# Function to send out funds from an address
drain_address() {
    local address=$1
    local private_key=$2

    # Get existing balance
    balance=$(cast balance --rpc-url "$L1_RPC_URL" "$address")
    echo "Existing balance: $balance"

    if [[ "$balance" == "0" ]]; then
        echo "Balance is 0, skipping..."
        return
    fi

    # Estimate gas
    gas_price=$(cast gas-price --rpc-url "$L1_RPC_URL")
    gas_units=30000
    gas_cost=$(awk -v gp="$gas_price" -v gu="$gas_units" 'BEGIN { printf "%.0f", gp * gu }')
    gas_cost_with_buffer=$(awk -v gc="$gas_cost" 'BEGIN { printf "%.0f", gc * 1.5 }')
    echo "Gas cost (+50% buffer): $gas_cost_with_buffer"

    # Send out funds if amount is greater than 0
    amount=$(awk -v b="$balance" -v gcb="$gas_cost_with_buffer" 'BEGIN { printf "%.0f", b - gcb }')
    if [[ "$amount" -gt 0 ]]; then
        echo "Sending out $amount to $L1_FUNDED_ADDRESS"

        # Try up to 3 times with increasing gas price
        for i in {1..3}; do
            if [[ $i -gt 1 ]]; then
                # Increase gas price by 50% for each retry
                gas_price=$(awk -v gp="$gas_price" 'BEGIN { printf "%.0f", gp * 1.5 }')
                gas_cost=$(awk -v gp="$gas_price" -v gu="$gas_units" 'BEGIN { printf "%.0f", gp * gu }')
                gas_cost_with_buffer=$(awk -v gc="$gas_cost" 'BEGIN { printf "%.0f", gc * 1.5 }')
                amount=$(awk -v b="$balance" -v gcb="$gas_cost_with_buffer" 'BEGIN { printf "%.0f", b - gcb }')
                echo "Retry $i: Increasing gas price to $gas_price"
            fi
            
            if cast send --private-key "$private_key" --rpc-url "$L1_RPC_URL" \
                --value "$amount" "$L1_FUNDED_ADDRESS" --gas-limit "$gas_units" \
                --gas-price "$gas_price" 2>/dev/null; then
                echo "Transaction successful"
                return 0
            fi
            
            echo "Transaction failed, waiting before retry..."
            sleep 5
        done
        echo "Failed to send transaction after 3 attempts"
        return 1
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