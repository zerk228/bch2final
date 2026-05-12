# 1-Page Proposal — Team RWA — Option C

## Scenario

Option C — **RWA Tokenization Platform**: an ERC-20 asset-backed token (UUPS upgradeable), an ERC-4626 yield vault, a Chainlink price feed with staleness check, role-gated minting via an `IssuerNFT` license, a constant-product AMM, and DAO governance over issuer onboarding + protocol parameters.

## Motivation

RWA tokenization is the simplest of the five scenarios to explain and to defend at Q&A: a small surface of business actions (`mint → deposit → swap`) with role-gating that maps directly to the OZ Governor + Timelock template. All § 3 mandatory components fit naturally without manufactured stubs.

## Team and Ownership

| Member  | Owns                                            |
| ------- | ----------------------------------------------- |
| M1      | RWAToken (V1/V2 UUPS), IssuerNFT, YieldVault, Factory |
| M2      | AMM, Oracle, YulMath, The Graph subgraph        |
| M3      | Governor, Timelock, Frontend, CI/CD, Audit doc  |

## High-Level Architecture

```
GovToken (ERC20Votes+Permit)──► Governor ─► Timelock(2d) ─► admin of every contract
                                                            │
RWATokenV1 (UUPS) ◄── ERC1967Proxy ── deployed via RWAFactory (CREATE/CREATE2)
   │
   ├── YieldVault (ERC-4626)
   ├── SimpleAMM (x*y=k, 0.3% fee, LP-token)   ─► PriceOracle (Chainlink + staleness)
   └── IssuerNFT (ERC-721 license)
```

Indexed by a subgraph (mints, swaps, liquidity, proposals, votes). Frontend reads votes from contract + proposals from The Graph.

## Milestones (mapped to course schedule)

| W6  | Repo + proposal + scenario approval                              |
| W7  | Compiling contracts, GovToken/Timelock/Governor wired, first tests  |
| W8  | RWAToken UUPS, YieldVault, Factory, AMM done, ≥ 50% coverage     |
| W9  | Oracle, subgraph live, deploy to Arbitrum Sepolia, verified       |
| W10 | Audit report, gas report, frontend, demo video, final defence    |

## Risk Register

| Risk                              | Mitigation                                        |
| --------------------------------- | ------------------------------------------------- |
| Slither flagging Yul              | Wrap Yul in named library, document each opcode   |
| Coverage < 90 %                   | Foundry CI gate on every PR                       |
| Governance not end-to-end testable| `Governance.t.sol` runs full propose→execute      |
| L2 verification failure           | Use `forge verify-contract` via `--verify` in deploy |
