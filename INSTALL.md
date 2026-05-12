# Install & First Run

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node 20+ (for subgraph and Prettier)
- Python 3.10+ (for Slither, optional locally; runs in CI anyway)

## One-shot

```bash
# 1) Clone
git clone <repo>
cd bch2final

# 2) Install Foundry libraries
forge install foundry-rs/forge-std --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
forge install smartcontractkit/chainlink-brownie-contracts --no-commit

# 3) Env
cp .env.example .env  # then fill PRIVATE_KEY and *_RPC

# 4) Build & test
forge build
forge test -vv
forge coverage --report summary
```

## Frontend (local)

The frontend is static HTML+JS. Open `frontend/index.html` in a browser with MetaMask installed, OR serve via:

```bash
npx serve frontend
```

Edit the contract addresses in `frontend/app.js` (`ADDR.*`) after the first deploy.

## Subgraph

```bash
cd subgraph
npm install
# After deployment, replace 0x000... addresses + startBlock in subgraph.yaml
npm run codegen
npm run build
npm run deploy
```
