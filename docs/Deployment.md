# Deployment

## Arbitrum Sepolia (chain id 421614)

Replace placeholders after first deploy. All contracts are verified on Arbiscan Sepolia.

| Contract       | Address | Explorer |
| -------------- | ------- | -------- |
| GovToken       | `0x...` | https://sepolia.arbiscan.io/address/0x... |
| Timelock       | `0x...` | https://sepolia.arbiscan.io/address/0x... |
| Governor       | `0x...` | https://sepolia.arbiscan.io/address/0x... |
| RWAToken impl  | `0x...` | https://sepolia.arbiscan.io/address/0x... |
| RWAToken proxy | `0x...` | https://sepolia.arbiscan.io/address/0x... |
| IssuerNFT      | `0x...` | https://sepolia.arbiscan.io/address/0x... |
| RWAFactory     | `0x...` | https://sepolia.arbiscan.io/address/0x... |
| YieldVault     | `0x...` | https://sepolia.arbiscan.io/address/0x... |
| PriceOracle    | `0x...` | https://sepolia.arbiscan.io/address/0x... |
| SimpleAMM      | `0x...` | https://sepolia.arbiscan.io/address/0x... |

## How to redeploy from scratch

```bash
cp .env.example .env  # fill PRIVATE_KEY and *_RPC
forge script script/Deploy.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC \
  --broadcast --verify
```

The script:

1. Deploys GovToken, mints 1M to deployer (will be used to seed AMM and delegate).
2. Deploys Timelock with 2-day delay, empty proposers/executors.
3. Deploys Governor wired to Timelock + GovToken.
4. Grants `PROPOSER_ROLE` + `CANCELLER_ROLE` on Timelock to Governor; grants `EXECUTOR_ROLE` to `address(0)` (anyone can execute after delay).
5. Deploys RWAToken impl, then ERC1967Proxy with `initialize(...)` admin = Timelock.
6. Deploys IssuerNFT (admin = Timelock), Factory (admin = Timelock).
7. Deploys YieldVault for `RWA` asset (admin = Timelock).
8. Deploys MockAggregator + PriceOracle (admin = Timelock).
9. Deploys SimpleAMM over (RWA, Gov).
10. Revokes Timelock's `DEFAULT_ADMIN_ROLE` from deployer EOA.

## Post-deploy verification

`script/Verify.s.sol` checks: 2-day delay, voting parameters, role assignments, no deployer-EOA admin.

```
TIMELOCK=0x... GOVERNOR=0x... RWA=0x... DEPLOYER=0x... \
  forge script script/Verify.s.sol --rpc-url $ARBITRUM_SEPOLIA_RPC
```

Expected output: `verification: OK`.
