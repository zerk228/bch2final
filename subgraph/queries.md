# GraphQL Queries

## 1. Last 10 mints

```graphql
{
  mints(first: 10, orderBy: blockTimestamp, orderDirection: desc) {
    id
    to
    amount
    blockTimestamp
  }
}
```

## 2. Recent swaps for an account

```graphql
query Swaps($who: Bytes!) {
  swaps(where: { sender: $who }, first: 25, orderBy: blockTimestamp, orderDirection: desc) {
    tokenIn
    amountIn
    amountOut
    blockTimestamp
  }
}
```

## 3. Active proposals

```graphql
{
  proposals(orderBy: startBlock, orderDirection: desc) {
    id
    proposer
    description
    forVotes
    againstVotes
    abstainVotes
  }
}
```

## 4. Votes on a proposal

```graphql
query VotesByProposal($pid: BigInt!) {
  votes(where: { proposalId: $pid }, orderBy: blockTimestamp) {
    voter
    support
    weight
  }
}
```

## 5. Liquidity events for AMM TVL chart

```graphql
{
  liquidityChanges(first: 100, orderBy: blockTimestamp) {
    isAdd
    amount0
    amount1
    lp
    blockTimestamp
  }
}
```
