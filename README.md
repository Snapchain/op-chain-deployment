# OP Chain Deployment

## Setup environment variables

```
cp .env.example .env
cp .env.explorer.example .env.explorer
```

### Fetch and update the submodules

```
git submodule update --init --recursive
```

### Update the environment variables

Update environment variables in the `.env` and `.env.explorer` files.

## Local L1 chain

### Setup the network parameters

```
make l1-configure
```

**Note:** It will generate a new wallet `configs/l1/l1-prefund-wallet.json` and update the `configs/l1/network_params.yaml` file with the address to use for the prefunded account. You can update the `configs/l1/network_params.yaml` file manually to use an existing wallet.

### Launch with kurtosis and ethereum-package

```
make l1-launch
```

### Remove the local L1 chain

```
make l1-remove
```

**Note:** If you launch the local L1 chain with kurtosis, you must set the following environment variables with the values from the `configs/network_params_geth_lighthouse.yaml` file:

- Update the `L1_CHAIN_ID` with the value of the `network_id` in the `network_params` section
- Update the `L1_RPC_URL` to `http://localhost:<EL_PORT_START + 2>`, where `EL_PORT_START` is the value of `public_port_start` in the `el` section
- Update the `L1_BEACON_URL` to `http://localhost:<CL_PORT_START + 1>`, where `CL_PORT_START` is the value of `public_port_start` in the `cl` section
