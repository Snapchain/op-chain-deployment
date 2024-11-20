#!/bin/bash
set -euo pipefail

# Set the path to the wallets.sh script
WALLETS_SCRIPT="$(pwd)/optimism/packages/contracts-bedrock/scripts/getting-started/wallets.sh"

# Run the wallets.sh script and capture its output
output=$($WALLETS_SCRIPT)

# Path to the .env file
ENV_FILE="$(pwd)/.env"

# Check if addresses already exist in the .env file
check_addresses_exist() {
  for role in ADMIN BATCHER PROPOSER; do
    if grep -q "^GS_${role}_ADDRESS=" "$ENV_FILE" || \
        grep -q "^GS_${role}_PRIVATE_KEY=" "$ENV_FILE"; then
      return 0
    fi
  done
  return 1
}

if check_addresses_exist; then
  echo "Error: Addresses or private keys already exist in .env file. Please remove them first."
  exit 1
else
  # If not, process the output and update the .env file
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
fi

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

# Source the .env file
source "$ENV_FILE"

# Fund the generated addresses
for role in ADMIN BATCHER PROPOSER; do
    address_var="GS_${role}_ADDRESS"
    address="${!address_var}"
    
    if [[ -n "$address" ]]; then
        local balance=$(check_address_balance "$address")
        if [[ "$balance" == "0" ]]; then
            echo "Funding $role address: $address with amount $L1_FUND_AMOUNT"
            fund_address "$address" "$L1_FUND_AMOUNT"
            echo
        else
            echo "$role address: $address already funded"
            echo
        fi
    else
        echo "Warning: $role address not found in .env file"
        echo
    fi
done

echo "Funding complete."