#!/bin/bash
set -euo pipefail

# Set the path to the wallets.sh script
WALLETS_SCRIPT="$(pwd)/optimism/packages/contracts-bedrock/scripts/getting-started/wallets.sh"
TEARDOWN_SCRIPT="$(pwd)/scripts/l2/l2-teardown.sh"

# Run the wallets.sh script and capture its output
output=$($WALLETS_SCRIPT)

# Path to the .env file
ENV_FILE="$(pwd)/.env"

# Source the .env file
source "$ENV_FILE"

# Check if any addresses already exist in the .env file
check_addresses_exist() {
  for role in ADMIN BATCHER PROPOSER; do
    address_var="GS_${role}_ADDRESS"
    private_key_var="GS_${role}_PRIVATE_KEY"
    address="${!address_var}"
    private_key="${!private_key_var}"

    if [[ -n "$address" ]] || [[ -n "$private_key" ]]; then
      return 0
    fi
  done
  return 1
}

# If addresses already exist, first backup the .env file and run teardown
if check_addresses_exist; then
  echo "Addresses already exist in .env file. Backing up and running teardown."
  timestamp=$(date +%s)
  cp "$ENV_FILE" "$ENV_FILE.bak-$timestamp"
  "$TEARDOWN_SCRIPT"
  echo "Teardown complete."
fi

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

# Function to check address balance
check_address_balance() {
  local address=$1

  cast balance "$address" --rpc-url "$L1_RPC_URL"
}

# Function to fund an address
fund_address() {
    local address=$1
    local amount=$2

    cast send --private-key "$L1_FUNDED_PRIVATE_KEY" --rpc-url "$L1_RPC_URL" \
        --value "$amount" "$address"
}

# Update the .env file with the new addresses
source "$ENV_FILE"

# Fund the generated addresses
for role in ADMIN BATCHER PROPOSER; do
    address_var="GS_${role}_ADDRESS"
    address="${!address_var}"
    
    if [[ -n "$address" ]]; then
        balance=$(check_address_balance "$address")
        if [[ "$balance" == "0" ]]; then
            # fund 0.1 ETH for ADMIN, use L1_FUND_AMOUNT for BATCHER and PROPOSER
            if [[ "$role" == "ADMIN" ]]; then
                amount="0.1ether"
            else
                amount="$L1_FUND_AMOUNT"
            fi
            echo "Funding $role address: $address with amount $amount"
            fund_address "$address" "$amount"
            echo
        else
            echo "Error: $role address already funded: $address"
            exit 1
        fi
    else
        echo "Warning: $role address not found in .env file"
        echo
    fi
done

echo "Funding complete."