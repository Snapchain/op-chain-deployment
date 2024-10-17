#!/usr/bin/env bash



# Generate wallet
wallet=$(cast wallet new)

# Grab wallet address
address=$(echo "$wallet" | awk '/Address/ { print $2 }')

# Grab wallet private key
key=$(echo "$wallet" | awk '/Private key/ { print $3 }')

# Save the wallet address and private key to a json file
echo "{\"address\": \"$address\", \"key\": \"$key\"}" > configs/l1-prefund-wallet.json

# Create the network_params.yaml file if it doesn't exist
cp configs/network_params.yaml.example configs/network_params.yaml

# Replace the placeholder address with the new address
# This works on both Linux and MacOS
sed -i.bak "s/0xADDRESS/$address/g" configs/network_params.yaml && rm configs/network_params.yaml.bak
