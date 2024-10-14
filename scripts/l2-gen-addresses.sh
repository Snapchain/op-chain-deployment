#!/bin/bash
set -euo pipefail

# Set the path to the wallets.sh script
WALLETS_SCRIPT="$(pwd)/optimism/packages/contracts-bedrock/scripts/getting-started/wallets.sh"

# Run the wallets.sh script and capture its output
output=$($WALLETS_SCRIPT)

# Path to the .env file
ENV_FILE="$(pwd)/.env"

# Process the output and update the .env file
echo "$output" | while IFS= read -r line; do
    if [[ $line == export\ GS_* ]]; then
        # Extract variable name and value
        var_name=$(echo "$line" | cut -d'=' -f1 | cut -d' ' -f2)
        var_value=$(echo "$line" | cut -d'=' -f2-)
        
        # Update or add the variable in the .env file
        if grep -q "^$var_name=" "$ENV_FILE"; then
            sed -i.bak "s|^$var_name=.*|$var_name=$var_value|" "$ENV_FILE" && rm "${ENV_FILE}.bak"
        else
            echo "$var_name=$var_value" >> "$ENV_FILE"
        fi
    fi
done

echo "Generated new addresses and updated .env file."

# Function to fund an address
fund_address() {
    local address=$1
    local amount="10ether"

    cast send --private-key "$L1_FUNDED_PRIVATE_KEY" --rpc-url "$L1_RPC_URL" \
        --value "$amount" "$address"
}

# Source the .env file
source "$ENV_FILE"

# Fund the generated addresses
for role in ADMIN BATCHER PROPOSER; do
    address_var="GS_${role}_ADDRESS"
    address="${!address_var}"
    
    if [[ -n "$address" ]]; then
        echo "Funding $role address: $address"
        fund_address "$address"
        echo
    else
        echo "Warning: $role address not found in .env file"
        echo
    fi
done

echo "Funding complete."