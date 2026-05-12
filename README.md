# RWA Tokenization Platform — BCT2 Final Project

**Scenario:** Option C — RWA Tokenization Platform.

An asset-backed ERC-20 (UUPS upgradeable) issued by role-gated authorized issuers, deposited into an ERC-4626 yield vault, priced via Chainlink with staleness check, swappable through a constant-product AMM, and governed by an OpenZeppelin Governor + Timelock DAO. Indexed by The Graph, deployed on Arbitrum Sepolia.

## Stack

- **Solidity** 0.8.24, **Foundry**
- **OpenZeppelin** Contracts 5.x (+ Upgradeable)
- **Chainlink** AggregatorV3
- **The Graph** subgraph (AssemblyScript mapping)
- **Frontend**: vanilla HTML + ethers v6 (MetaMask)
- **L2**: Arbitrum Sepolia (verified)

## Repository layout

```
contracts/
  governance/   GovToken, MyGovernor, MyTimelock
  rwa/          RWATokenV1 (UUPS), RWATokenV2, IssuerNFT (ERC-721), YieldVault (ERC-4626)
  amm/          SimpleAMM (x*y=k from scratch, 0.3% fee, LP-token)
  oracle/       PriceOracle, MockAggregator
  factory/      RWAFactory (CREATE + CREATE2)
  libraries/    YulMath (assembly + Solidity benchmark)
test/           100+ Foundry tests (unit, fuzz, invariant, fork)
script/         Deploy.s.sol, Verify.s.sol
subgraph/       subgraph.yaml, schema.graphql, mapping.ts, queries.md
frontend/       index.html + app.js
docs/           Architecture.md, AuditReport.md, GasReport.md, Coverage.md
.github/        ci.yml (build, test, coverage, Slither, lint)
```

## Quickstart

```bash
forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts OpenZeppelin/openzeppelin-contracts-upgradeable smartcontractkit/chainlink-brownie-contracts
cp .env.example .env
forge build
forge test -vv
forge coverage --report summary
```

## Deploy to Arbitrum Sepolia

```bash
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC \
  --broadcast --verify
```

## Verify post-deploy invariants

```bash
TIMELOCK=0x... GOVERNOR=0x... RWA=0x... DEPLOYER=0x... \
  forge script script/Verify.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC
```

## Deployed addresses (Arbitrum Sepolia)

| Contract       | Address |
| -------------- | ------- |
| GovToken       | `<fill after deploy>` |
| Timelock       | `<fill after deploy>` |
| Governor       | `<fill after deploy>` |
| RWAToken impl  | `<fill after deploy>` |
| RWAToken proxy | `<fill after deploy>` |
| IssuerNFT      | `<fill after deploy>` |
| RWAFactory     | `<fill after deploy>` |
| YieldVault     | `<fill after deploy>` |
| PriceOracle    | `<fill after deploy>` |
| SimpleAMM      | `<fill after deploy>` |

Block-explorer links: see `docs/Deployment.md`.

## Mandatory § 3 coverage

| Requirement | Where |
|---|---|
| UUPS upgradeable + V1→V2 | `contracts/rwa/RWATokenV1.sol`, `RWATokenV2.sol`, `test/Upgrade.t.sol` |
| Factory CREATE + CREATE2 | `contracts/factory/RWAFactory.sol` |
| Inline Yul + benchmark | `contracts/libraries/YulMath.sol`, `test/YulMath.t.sol` |
| ERC20Votes + ERC20Permit | `contracts/governance/GovToken.sol` |
| ERC-721 | `contracts/rwa/IssuerNFT.sol` |
| ERC-4626 vault | `contracts/rwa/YieldVault.sol` |
| Constant-product AMM (from scratch) | `contracts/amm/SimpleAMM.sol` |
| Chainlink + staleness | `contracts/oracle/PriceOracle.sol` |
| Subgraph (4 entities, 5 queries) | `subgraph/` |
| Governor + Timelock(2d) + ERC20Votes | `contracts/governance/` |
| L2 deploy + verify | `script/Deploy.s.sol` |
| Slither clean | CI `slither` job |
| 80+ tests, ≥ 90% coverage | `test/`, CI `coverage` |
| Reentrancy + AccessControl case-studies | `test/Reentrancy.t.sol`, `test/AccessControlCase.t.sol` |

## Team contribution

| Member | Owns |
|---|---|
| Member 1 | RWA, IssuerNFT, Vault, Factory |
| Member 2 | AMM, Oracle, YulMath, Subgraph |
| Member 3 | Governance, Frontend, CI, Audit report |

## Licence

MIT.
