# Architecture & Design Document

**Project:** RWA Tokenization Platform (Option C)
**Authors:** Team RWA
**Status:** Final
**Revision:** 1.0

---

## 1. System Context (C4 Level 1)

```
┌─────────────────────────────────────────────────────────────────┐
│                          External Actors                        │
│                                                                 │
│  ┌──────────┐   ┌─────────────┐   ┌──────────┐   ┌──────────┐  │
│  │  Issuer  │   │ Token holder│   │  Voter   │   │  Liquid. │  │
│  │ (KYC'd)  │   │  / Investor │   │ (DAO)    │   │  Provider│  │
│  └────┬─────┘   └──────┬──────┘   └────┬─────┘   └─────┬────┘  │
│       │                │               │               │       │
└───────┼────────────────┼───────────────┼───────────────┼───────┘
        │                │               │               │
┌───────▼────────────────▼───────────────▼───────────────▼───────┐
│                  RWA Tokenization Platform                     │
│                                                                │
│   Mint → Hold → Yield → Swap → Govern                          │
└─────────────────────────┬──────────────────────────────────────┘
                          │
              ┌───────────┼────────────┐
              ▼           ▼            ▼
        ┌──────────┐  ┌──────────┐ ┌──────────┐
        │ Chainlink│  │  L2      │ │ The Graph│
        │ AggrV3   │  │ Sepolia  │ │ subgraph │
        └──────────┘  └──────────┘ └──────────┘
```

Three off-chain dependencies: Chainlink price feed (asset valuation), L2 rollup (cheap execution), and The Graph (read-path indexing).

## 2. Container Diagram

```
                       ┌────────────────────────────┐
                       │      MyGovernor            │
                       │  (Governor + Settings +    │
                       │   CountingSimple + Votes + │
                       │   QuorumFraction + TLCtrl) │
                       └─────────────┬──────────────┘
                                     │ proposer/canceller
                       ┌─────────────▼──────────────┐
                       │      MyTimelock (2d)       │  ─── DEFAULT_ADMIN_ROLE
                       │     TimelockController     │      held by Timelock itself
                       └─┬─────────────┬─────────┬──┘
                         │             │         │
              admin    of│        admin│ of    admin│ of
                         │             │         │
              ┌──────────▼──┐  ┌──────▼────┐  ┌─▼──────────┐
              │RWAToken V1  │  │YieldVault │  │ IssuerNFT  │
              │ (UUPS proxy)│  │ (ERC4626) │  │  (ERC721)  │
              └─────┬───────┘  └────┬──────┘  └────────────┘
                    │ asset          │ asset
                    └──────┬─────────┘
                           ▼
                     ┌──────────┐
                     │SimpleAMM │── token1: GovToken
                     │  x*y=k   │── token0: RWAToken
                     └──────────┘

                     ┌────────────┐
                     │PriceOracle │── feed: ChainlinkAggregator
                     └────────────┘

                     ┌────────────┐
                     │RWAFactory  │── deploys ERC1967Proxy of RWATokenV1
                     │ CREATE/    │
                     │ CREATE2    │
                     └────────────┘
```

## 3. Sequence Diagrams

### 3.1 Mint → Deposit → Yield flow

```
Issuer            RWAToken           Vault            Investor
  │                  │                 │                 │
  │── mint(to,amt) ─►│                 │                 │
  │   (MINTER_ROLE)  │                 │                 │
  │                  │                 │                 │
  │                  │── transfer ────────────────────►  │
  │                                    │                 │
  │                                    │◄── deposit ─────│
  │                                    │── shares ──────►│
  │                                    │                 │
  │                                    │◄── accrueYield──│ (YIELD_ROLE)
  │                                    │   (timelock)    │
  │                                    │                 │
```

### 3.2 propose → vote → queue → execute

```
Voter      Governor     Timelock      Target
  │           │            │             │
  │── prop ──►│            │             │
  │           │   wait votingDelay (~1d) │
  │── vote ──►│            │             │
  │           │   wait votingPeriod (~7d)│
  │── queue ─►│── schedule►│             │
  │           │            │  wait 2d    │
  │── exec ──►│── execute─►│── call ────►│
```

### 3.3 Swap with slippage protection

```
User       AMM         token0       token1
 │          │            │             │
 │─ approve(amm, in) ───►│             │
 │── swap(t0,in,minOut)► │             │
 │          │── pull ───►│             │
 │          │ get reserves              │
 │          │ amountOut = getAmountOut │
 │          │ require >= minOut        │
 │          │── push ──────────────────►│
 │          │ require k_new >= k_old   │
 │          │── Sync event             │
```

## 4. Data Model — Storage Layouts

### 4.1 GovToken

| slot | field                       |
| ---- | --------------------------- |
| 0    | `_balances` (mapping)       |
| 1    | `_allowances` (mapping)     |
| 2    | `_totalSupply`              |
| 3    | `_name`                     |
| 4    | `_symbol`                   |
| —    | inherited Permit / Votes    |

### 4.2 RWATokenV1 (UUPS — namespaced slots only)

OZ 5 namespaced storage (`erc7201`) — no collisions with V2 by design.

| layout                          |
| ------------------------------- |
| `ERC20Upgradeable.Storage`      |
| `AccessControlUpgradeable.Stg`  |
| `UUPSUpgradeable.Storage`       |
| **Owned**: `assetSymbol`, `cap` |

### 4.3 RWATokenV2

Adds `_paused: bool` only — appended after V1's storage, no overlap.

## 5. Trust Assumptions & Access Control

| Role                       | Held by    | Can do                                  |
| -------------------------- | ---------- | --------------------------------------- |
| `RWA.DEFAULT_ADMIN_ROLE`   | Timelock   | Grant/revoke all roles                  |
| `RWA.MINTER_ROLE`          | Issuer NFT | Mint up to cap                          |
| `RWA.UPGRADER_ROLE`        | Timelock   | UUPS upgrade                            |
| `Vault.YIELD_ROLE`         | Timelock   | Push yield into vault                   |
| `Oracle.FEED_ADMIN`        | Timelock   | Change Chainlink feed                   |
| `Timelock.PROPOSER_ROLE`   | Governor   | Queue tx                                |
| `Timelock.EXECUTOR_ROLE`   | `0x0`      | Anyone can execute after delay          |
| `Timelock.CANCELLER_ROLE`  | Governor   | Cancel queued tx                        |

After `Deploy.s.sol`, the deployer EOA holds **no** roles. If the multisig (Timelock proposer set) is compromised, the worst-case is: queue a malicious tx → wait 2 days → execute. Within those 2 days, an honest cancellation via Governor (which can also be a canceller) mitigates. There is no admin backdoor.

## 6. Architecture Decision Records

### ADR-001: UUPS over Transparent Proxy

- **Context:** RWAToken needs upgradeability for compliance changes.
- **Options:** Transparent proxy, UUPS, Beacon.
- **Decision:** UUPS.
- **Consequences:** Smaller proxy bytecode, upgrade gated on `UPGRADER_ROLE` held by Timelock. Risk: forgetting `_disableInitializers()` on impl — mitigated in constructor.

### ADR-002: ERC-4626 with decimals offset

- **Context:** Inflation-attack on initial depositor.
- **Decision:** Use OpenZeppelin v5 ERC4626 with `_decimalsOffset() = 6` to make the share-price manipulation economically irrelevant.
- **Consequences:** Slight rounding loss for tiny depositors; acceptable trade-off.

### ADR-003: AMM written from scratch (not Uniswap-V2 fork)

- **Context:** Course mandates one DeFi primitive from scratch.
- **Decision:** Implement `SimpleAMM` with `getReserves`, fee = 0.3%, `MIN_LIQUIDITY` lock, k-invariant post-check.
- **Consequences:** Smaller surface, easier to audit; not cross-pool routable.

### ADR-004: CREATE + CREATE2 in Factory

- **Context:** Mandatory by § 3.1.
- **Decision:** `deploy(...)` → CREATE; `deploy2(salt, ...)` → CREATE2 with `predictAddress` for off-chain reservation.
- **Consequences:** Predictable addresses across L2s, useful for cross-chain RWA representation.

### ADR-005: 2-day Timelock + 4% quorum

- **Context:** § 3.1 mandate.
- **Decision:** Voting delay 1 day (7200 blocks @ 12s); voting period 7 days (50400 blocks); quorum 4% of past total supply; proposal threshold 1%.
- **Consequences:** Defends against flash-loan governance (Timelock + voting delay) and proposal spam (1% threshold).

## 7. Design Patterns Used

| Pattern                        | Where                                     | Why                              |
| ------------------------------ | ----------------------------------------- | -------------------------------- |
| Factory                        | `RWAFactory`                              | Deploy issuer-specific tokens    |
| UUPS Proxy                     | `RWATokenV1` → `RWATokenV2`               | Compliance-driven upgrades       |
| Checks-Effects-Interactions    | `SimpleAMM.swap`, `YieldVault.deposit`    | Reentrancy avoidance             |
| Access Control (RBAC)          | every privileged contract                 | No EOA backdoors                 |
| Reentrancy Guard               | `SimpleAMM`, `YieldVault`                 | Belt + suspenders on external txs|
| Oracle Adapter                 | `PriceOracle` wraps `IAggregatorV3`       | Swappable feed                   |
| Timelock                       | `MyTimelock`                              | Bounds governance attacks        |

(Seven, exceeding the mandate of five.)
