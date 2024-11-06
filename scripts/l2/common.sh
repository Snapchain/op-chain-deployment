#!/bin/bash
set -euo pipefail

# function to wait for a port to be available
wait_up() {
    local port=$1
    local retries=10
    local wait_time=1

    for i in $(seq 1 $retries); do
        if nc -z localhost $port; then
            echo "Port $port is available"
            return 0
        fi
        echo "Attempt $i: Port $port is not available yet. Waiting $wait_time seconds..."
        sleep $wait_time
    done

    echo "Error: Port $port did not become available after $retries attempts"
    return 1
}

# function to setup the env vars after the deployment
post_deployment_setup_env_vars() {
    local deployment_file=$1
    local devnet_l2oo=${2:-true}

    if [ ! -f "$deployment_file" ]; then
        echo "Error: Deployment file not found at $deployment_file"
        return 1
    fi

    if [ "$devnet_l2oo" = true ]; then
        export L2OO_ADDRESS=$(jq -r .L2OutputOracleProxy < "$deployment_file")
        if [ -z "$L2OO_ADDRESS" ]; then
            echo "Error: L2OutputOracleProxy address not found in deployment file"
            return 1
        fi
    else
        export DGF_ADDRESS=$(jq -r .DisputeGameFactoryProxy < "$deployment_file")
        if [ -z "$DGF_ADDRESS" ]; then
            echo "Error: DisputeGameFactoryProxy address not found in deployment file"
            return 1
        fi
        export DG_TYPE=254
        export PROPOSAL_INTERVAL=12s
    fi

    return 0
}