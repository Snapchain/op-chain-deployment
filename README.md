# OP Chain Deployment

## Setup environment variables

```
cp .env.example .env
cp .env.explorer.example .env.explorer
cp .env.bridge.example .env.bridge
```

### Fetch and update the submodules

```
git submodule update --init --recursive
```

### Update the environment variables

Update environment variables in the `.env` files.

## Local L1 chain

### Setup the network parameters

```bash
make l1-configure
```

**Note:** It will generate a new wallet `configs/l1/l1-prefund-wallet.json` and update the `configs/l1/network_params.yaml` file with the address to use for the prefunded account. You can update the `configs/l1/network_params.yaml` file manually to use an existing wallet.

### Launch with kurtosis and ethereum-package

```bash
make l1-launch
```

### Remove the local L1 chain

```bash
make l1-remove
```

**Note:** If you launch the local L1 chain with kurtosis, you must set the following environment variables with the values from the `configs/network_params_geth_lighthouse.yaml` file:

- Update the `L1_CHAIN_ID` with the value of the `network_id` in the `network_params` section
- Update the `L1_RPC_URL` to `http://localhost:<EL_PORT_START + 2>`, where `EL_PORT_START` is the value of `public_port_start` in the `el` section
- Update the `L1_BEACON_URL` to `http://localhost:<CL_PORT_START + 1>`, where `CL_PORT_START` is the value of `public_port_start` in the `cl` section

## Launch OP Stack L2

### Set the environment variables

```bash
cp .env.example .env
cp .env.explorer.example .env.explorer
cp .env.bridge.example .env.bridge
```

For the local L1, the L1 chain ID and pre-funded account private key can be retrieved from the L1 server (see steps above).
- `L1_CHAIN_ID`
- `L1_FUNDED_PRIVATE_KEY`

Keep empty string before the Finality Gadget is up. After the Finality Gadget is up, please update this value and restart the L2 op-node.
- `BBN_FINALITY_GADGET_RPC`

### Launch L2

```bash
make l2-launch
```

after it's up, you can test with:

```bash
make l2-verify # on the L2 server
cast block latest --rpc-url http://<l2-server-ip>:9545 # from anywhere
```

You can also access the explorer at http://<l2-server-ip>:3001/ and bridge UI at http://<l2-server-ip>:3002/

### Restart L2

TODO: add the command to restart the L2