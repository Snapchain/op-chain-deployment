# OP Chain Deployment


## Setup environment variables

```
cp .env.example .env
```

### Fetch and update the submodules

```
git submodule update --init --recursive
```

### Generate addresses

```
make generate-addresses
```

### Update the environment variables

Copy the the addresses generated in the [Generate addresses](#generate-addresses) section and update the `.env` file with them.

## Local L1 chain

### Setup the network parameters

```
cp configs/network_params.yaml.example configs/network_params.yaml
```

Update the `prefunded_accounts` section in the `configs/network_params.yaml` file with the addresses generated in the [Generate addresses](#generate-addresses) section.

### Launch with kurtosis and ethereum-package

```
make kurtosis-launch-l1
```

### Remove the local L1 chain

```
make kurtosis-remove-l1
```

**Note:** If you launch the local L1 chain with kurtosis, you must set the following environment variables with the values from the `configs/network_params_geth_lighthouse.yaml` file:

* Update the `L1_CHAIN_ID` with the value of the `network_id` in the `network_params` section
* Update the `L1_RPC_URL` to `http://localhost:<EL_PORT_START + 2>`, where `EL_PORT_START` is the value of `public_port_start` in the `el` section
* Update the `L1_BEACON_URL` to `http://localhost:<CL_PORT_START + 1>`, where `CL_PORT_START` is the value of `public_port_start` in the `cl` section