#!/bin/bash
set -euo pipefail

# Load environment variables from the top-level .env file
set -a
source $(pwd)/.env
set +a

# Run the Optimism Monorepo's config.sh script
# which will generate the getting-started.json configuration file
echo "Generating deployment configuration for OP L2..."
OP_CONTRACTS_DIR=$1/packages/contracts-bedrock
${OP_CONTRACTS_DIR}/scripts/getting-started/config.sh
# Check if the config.sh script failed
if [ $? -ne 0 ]; then
    echo "Failed to run config.sh script"
    exit 1
fi

# Check optional environment variables
DEVNET_L2OO=${DEVNET_L2OO:-true}
if [ "$DEVNET_L2OO" = true ]; then
  USE_FAULT_PROOFS=false
else
  USE_FAULT_PROOFS=true
fi
BATCH_INBOX_ADDRESS=${BATCH_INBOX_ADDRESS:-0xff00000000000000000000000000000000042069}
FINALIZATION_PERIOD_SECONDS=${FINALIZATION_PERIOD_SECONDS:-12}
ENABLE_GOVERNANCE=${ENABLE_GOVERNANCE:-true}

# Create the config file with the additional fields, e.g. useFaultProofs
GETTING_STARTED_OUTFILE=${OP_CONTRACTS_DIR}/deploy-config/getting-started.json
DEPLOY_CONFIG_PATH=${OP_CONTRACTS_DIR}/deploy-config/op-devnet-${L2_CHAIN_ID}.json
jq -s '.[0] * .[1]' ${GETTING_STARTED_OUTFILE} <(echo "{
  \"useFaultProofs\": ${USE_FAULT_PROOFS},
  \"batchInboxAddress\": \"${BATCH_INBOX_ADDRESS}\",
  \"finalizationPeriodSeconds\": ${FINALIZATION_PERIOD_SECONDS},
  \"enableGovernance\": ${ENABLE_GOVERNANCE}
}") > ${DEPLOY_CONFIG_PATH}
rm ${GETTING_STARTED_OUTFILE}
echo "Deployment configuration generated at ${DEPLOY_CONFIG_PATH}"
echo