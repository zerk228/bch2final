# Final Presentation — Slide Outline

Convert this to PDF (e.g., pandoc, Marp, or PowerPoint export) for the submission deliverable.

---

## Slide 1 — Title

RWA Tokenization Platform
Option C — Team RWA
BCT2 Final Project

## Slide 2 — Problem

Off-chain real-world assets (gold, real estate) cannot move on a DEX. We tokenize them under an authorized issuer, vault them for yield, and govern the whole stack with a DAO.

## Slide 3 — Architecture

(C4 container diagram from `docs/Architecture.md`.)

## Slide 4 — Smart-Contract Stack

- UUPS RWAToken V1 → V2 upgrade
- IssuerNFT (ERC-721 license)
- YieldVault (ERC-4626 + ReentrancyGuard)
- SimpleAMM (from scratch, x*y=k, 0.3% fee)
- PriceOracle (Chainlink + staleness)
- RWAFactory (CREATE + CREATE2)
- YulMath (inline assembly + Solidity benchmark)
- Governor + Timelock(2d) + ERC20Votes

## Slide 5 — Governance flow

propose → 1-day delay → 7-day vote → queue → 2-day timelock → execute

## Slide 6 — Security

- Slither clean (0 High / 0 Medium)
- 100+ tests, ≥ 90% line coverage
- 2 reproduced case studies (Reentrancy, AccessControl)
- No tx.origin, no transfer/send, SafeERC20 everywhere

## Slide 7 — Gas

- L2 deploy = 4.7M gas total
- Yul mulDiv 25% cheaper than Solidity
- Full L1 vs L2 table in `GasReport.md`

## Slide 8 — Indexing & Frontend

- 4 entities, 5 documented queries
- Frontend: MetaMask connect, balances, voting power, swap, deposit, proposal voting from The Graph

## Slide 9 — Live Demo

1. Connect MetaMask to Arbitrum Sepolia.
2. Swap RWA → GOV.
3. Deposit to vault.
4. Vote on a queued proposal.
5. Show subgraph response.

## Slide 10 — Q&A
