# OP Chain Deployment (with BTC staking support)

This repo contains:

- commands to deploy an OP-Stack chain with Babylon BTC staking support.
- commands to deploy a local L1 chain to help with development.

This repo is supposed to be used with the `op-chain-deployment` [repo](https://github.com/Snapchain/op-chain-deployment) together, to integrate the BTC staking finality gadget into the deployed OP-Stack chain. For more context, please read [this discussion](https://github.com/ethereum-optimism/specs/discussions/218).

## Fetch and update the submodules

```
git submodule update --init --recursive
```

## Local L1 chain

As a pre-requisite, install and start `kurtosis`. You also need to have `jq` and `yq` installed.

Then set up the network parameters:

```bash
make l1-configure
```

This will generate a new wallet `configs/l1/l1-prefund-wallet.json` and pre-fund it with ETH at genesis. If you don't want to use the auto-generated wallet, you can update the `configs/l1/network_params.yaml` file manually to use your own wallet address.

You can also find the L1 chain ID and RPC ports for the JSON RPC and Beacon API in the `network_params.yaml` file ([reference](https://github.com/ethpandaops/ethereum-package)):

- JSON RPC: `http://localhost:<EL_PORT_START + 2>`
- Beacon API: `http://localhost:<CL_PORT_START + 1>`

Then launch the L1 chain with:

```bash
make l1-launch
```

Then you can verify the L1 chain is running with:

```bash
make l1-verify
```

If you want to remove the L1 chain, you can do so with:

```bash
make l1-remove
```

## Launch OP Stack L2

### Set the environment variables

```bash
cp .env.example .env
cp .env.explorer.example .env.explorer
cp .env.bridge.example .env.bridge
```

Update the `.env` file with the correct values.

- `L1_RPC_URL`: the L1 JSON-RPC URL.
- `L1_BEACON_URL`: the L1 Beacon API that [supports blobs](https://docs.optimism.io/builders/node-operators/management/blobs) (Note: not many RPC providers support this).
- `L1_CHAIN_ID`: the L1 chain ID.
- `L1_FUNDED_PRIVATE_KEY`: this will be used to fund a few L2 admin accounts with ETH.
- `L2_CHAIN_ID`: the L2 chain ID.
- `L2_CHAIN_NAME`: the L2 chain name.
- `BATCH_INBOX_ADDRESS`: the batch inbox address, set by convention to `0xff<version_4_bytes>000...000<chain_id>` (e.g. `0xff00010000000000000000000000000000706114` for chain ID `706114` deployment version `1`).
- `L2_RPC_URL`: the L2 JSON-RPC URL, set to `http://<l2-server-ip>:9545`.
- `L2_EXPLORER_URL`: the L2 explorer URL, set to `http://<l2-server-ip>`.

Update the `.env.explorer` file with the correct values.

- `COMMON_HOST`: the IP address of the server running the L2 components.

Note that you don't need to update the `.env.bridge` file b/c it's set in `make l2-launch`.

### Launch L2 (including the bridge and block explorer)

```bash
make l2-launch
```

after it's up, you can test with:

```bash
make l2-verify
```

You can also verify the L2 chain with:

```bash
cast block latest --rpc-url http://<l2-server-ip>:9545 # (need to have foundry installed)
```

You can also access the explorer at `http://<l2-server-ip>` and bridge UI at `http://<l2-server-ip>:3002/`.

You can also bridge funds from L1 to L2 via the bridge UI.

Here are a few useful commands to restart the L2 components:

```bash
make l2-op-node-restart # only restart l2 op-node
make l2-restart # restart all l2 components
make l2-explorer-restart # restart l2 explorer
make l2-bridge-restart # restart l2 bridge
```
