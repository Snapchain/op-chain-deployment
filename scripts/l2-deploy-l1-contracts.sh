#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

# Check L1_CHAIN_ID. For local development, we don't want to use 900 or 1337 b/c there are special
# logic here: https://github.com/ethereum-optimism/optimism/blob/f58f1f56dc7e7cc3cad82973a9ed0c1b22c5356f/packages/contracts-bedrock/scripts/deploy/Deploy.s.sol#L978
# Since we don't run `make pre-devnet`, it won't generate `op-program/bin/prestate-proof.json`. So the code will throw
# here if 900 or 1337 is the L1 chain ID: https://github.com/ethereum-optimism/optimism/blob/f58f1f56dc7e7cc3cad82973a9ed0c1b22c5356f/packages/contracts-bedrock/scripts/deploy/Deploy.s.sol#L996C74-L996C108
# The reason we don't want to run `make pre-devnet` is because it takes a very long time to compile.
# The command runs `make op-program` and `make cannon` which takes long to compile. Since we don't
# enable fault proofs, we don't need op-program either. So adding this check as a tmp workaround.
if [[ "$L1_CHAIN_ID" == "900" || "$L1_CHAIN_ID" == "1337" ]]; then
    echo "Error: L1_CHAIN_ID cannot be 900 or 1337"
    exit 1
fi

# Go to the OP contracts directory
OP_CONTRACTS_DIR=$1/packages/contracts-bedrock
echo "OP_CONTRACTS_DIR: $OP_CONTRACTS_DIR"
cd $OP_CONTRACTS_DIR

# Install contracts dependencies
echo "Installing the dependencies for the smart contracts..."
just install
echo

FACTORY_DEPLOYER_ADDRESS="0x3fAB184622Dc19b6109349B94811493BF2a45362"
FACTORY_ADDRESS="0x4e59b44847b379578588920cA78FbF26c0B4956C"
# raw tx data for deploying Create2Factory contract to L1
FACTORY_DEPLOYER_CODE="0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222"
# Check if the Create2Factory contract is already deployed
echo "Checking if the Create2Factory contract is already deployed..."
CREATE2_FACTORY_SIZE=$(cast codesize $FACTORY_ADDRESS --rpc-url $L1_RPC_URL)
echo "CREATE2_FACTORY_SIZE: $CREATE2_FACTORY_SIZE"
if [ "$CREATE2_FACTORY_SIZE" == "69" ]; then
  echo "Create2Factory contract is already deployed. Skipping the deployment..."
else
  echo "Create2Factory contract is not deployed. Deploying the Create2Factory contract..."
  cast publish --rpc-url $L1_RPC_URL $FACTORY_DEPLOYER_CODE
fi

# Deploy the L1 contracts
echo "Deploying the L1 contracts..."
DEPLOYMENT_OUTFILE=${OP_CONTRACTS_DIR}/deployments/op-devnet-${L2_CHAIN_ID}.json \
  DEPLOY_CONFIG_PATH=${OP_CONTRACTS_DIR}/deploy-config/op-devnet-${L2_CHAIN_ID}.json \
  forge script $OP_CONTRACTS_DIR/scripts/deploy/Deploy.s.sol:Deploy \
  --private-key "$GS_ADMIN_PRIVATE_KEY" \
  --broadcast --rpc-url "$L1_RPC_URL" --slow
echo