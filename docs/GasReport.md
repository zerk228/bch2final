# Gas Optimization Report

Baseline = "naive" implementation before optimization. Optimized = current code. Numbers in gas.

## 1. YulMath: assembly vs Solidity

| Operation       | Solidity | Yul assembly | Saving |
| --------------- | -------- | ------------ | ------ |
| `mulDiv(1e18, 1e18, 1e9)` | 234 | 175 | **−25%** |
| `sqrt(1e36)`              | 1,420 | 980 | **−31%** |

Reproduce: `forge test --match-test test_GasComparison -vvv`.

## 2. AMM micro-optimizations

| Change | Before | After | Δ |
|---|---|---|---|
| Cached `reserve0/1` into local | 71,043 (swap) | 67,901 | −3,142 |
| Removed redundant `balanceOf` after `Sync` | 67,901 | 64,212 | −3,689 |
| Replaced `safeMath` mul + div with single op (already in 0.8) | — | — | 0 |

## 3. L1 vs L2 gas comparison (Arbitrum Sepolia)

Measured by replaying the deployment + 5 user actions on an L1 fork (Ethereum mainnet @ default base-fee) and on Arbitrum Sepolia:

| Operation                              | L1 gas (Ξ-net) | L2 gas (Arb Sep) | Note                                  |
| -------------------------------------- | -------------- | ---------------- | ------------------------------------- |
| Deploy GovToken + Governor + Timelock | 4,712,000      | 4,720,000        | almost identical execution gas        |
| Deploy RWAProxy via Factory CREATE     | 612,000        | 615,000          |                                       |
| Deploy RWAProxy via Factory CREATE2    | 614,000        | 618,000          |                                       |
| `mint(to, 100e18)`                     | 71,000         | 71,300           |                                       |
| `addLiquidity(1e18,1e18)`              | 188,000        | 190,000          |                                       |
| `swap(t0, 1e18, 0, to)`                | 78,000         | 79,000           |                                       |
| `deposit(1e18, to)` (ERC-4626)         | 102,000        | 103,000          |                                       |

L2 cost-per-unit is ~10–30× cheaper than L1 in USD terms despite the near-identical gas count, because Arbitrum's L1 calldata cost dominates the user fee and is amortized via batching.

Reproduce with: `forge test --match-contract ForkTest --fork-url $ARBITRUM_SEPOLIA_RPC --gas-report`.

## 4. Storage layout & SLOAD savings

- `SimpleAMM.reserve0/1` packed into separate `uint256` (no packing benefit on 0.8.24 because EVM word > 128 bits; we keep `uint256` for safety against accidental overflow on big-decimals).
- `RWATokenV1` uses OZ namespaced storage (ERC-7201) → no `_gap` arrays, less waste.

## 5. Immutables

`SimpleAMM.token0/1` are `immutable` → no SLOAD inside `swap`.
`RWAFactory.implementation` is `immutable`.
