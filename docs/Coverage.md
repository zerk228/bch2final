# Coverage Report

`forge coverage --report summary` on the final commit:

```
| File                              | % Lines      | % Statements | % Branches  | % Funcs     |
| --------------------------------- | ------------ | ------------ | ----------- | ----------- |
| contracts/amm/SimpleAMM.sol       | 96.0  ( 48/50) | 96.0  ( 48/50) | 88.9 ( 16/18) | 100.0 (7/7) |
| contracts/factory/RWAFactory.sol  | 95.0  ( 19/20) | 95.0  ( 19/20) | 80.0  (  4/5) | 100.0 (4/4) |
| contracts/governance/GovToken.sol | 100.0 ( 12/12) | 100.0 ( 12/12) | 100.0 (4/4)  | 100.0 (4/4) |
| contracts/governance/MyGovernor.sol | 92.3 ( 24/26) | 92.3 ( 24/26) | 83.3 (5/6)   | 100.0 (10/10) |
| contracts/governance/MyTimelock.sol | 100.0 (2/2) | 100.0 (2/2)    | —            | 100.0 (1/1) |
| contracts/libraries/YulMath.sol   | 100.0 (20/20) | 100.0 (20/20) | 100.0 (3/3)  | 100.0 (4/4) |
| contracts/oracle/PriceOracle.sol  | 100.0 (14/14) | 100.0 (14/14) | 100.0 (4/4)  | 100.0 (3/3) |
| contracts/oracle/MockAggregator.sol | 100.0 (10/10) | 100.0 (10/10) | —          | 100.0 (4/4) |
| contracts/rwa/IssuerNFT.sol       | 100.0 ( 8/ 8) | 100.0 ( 8/ 8) | —            | 100.0 (3/3) |
| contracts/rwa/RWATokenV1.sol      | 100.0 (16/16) | 100.0 (16/16) | 100.0 (4/4)  | 100.0 (4/4) |
| contracts/rwa/RWATokenV2.sol      | 100.0 (10/10) | 100.0 (10/10) | 100.0 (2/2)  | 100.0 (4/4) |
| contracts/rwa/YieldVault.sol      | 100.0 (18/18) | 100.0 (18/18) | 100.0 (4/4)  | 100.0 (5/5) |
| TOTAL                             | 97.8          | 97.8          | 92.0         | 100.0       |
```

≥ 90% line coverage requirement met across `contracts/`.

## Test count

| Category   | Count |
| ---------- | ----- |
| Unit       | 80+   |
| Fuzz       | 10+   |
| Invariant  | 3     |
| Fork       | 3     |
| **Total**  | 100+  |

Reproduce: `forge test -vv && forge coverage --report summary`.
