import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  Mint as MintEvent,
  Burn as BurnEvent,
  Swap as SwapEvent,
  LiquidityChange,
  Proposal,
  Vote as VoteEvent,
} from "../generated/schema";
import { Minted, Burned } from "../generated/RWAToken/RWATokenV1";
import { Swap as SwapEv, Mint as MintEv, Burn as BurnEv } from "../generated/SimpleAMM/SimpleAMM";
import { ProposalCreated, VoteCast } from "../generated/Governor/MyGovernor";

export function handleMint(event: Minted): void {
  const e = new MintEvent(event.transaction.hash.concatI32(event.logIndex.toI32()));
  e.to = event.params.to;
  e.amount = event.params.amount;
  e.blockNumber = event.block.number;
  e.blockTimestamp = event.block.timestamp;
  e.transactionHash = event.transaction.hash;
  e.save();
}

export function handleBurn(event: Burned): void {
  const e = new BurnEvent(event.transaction.hash.concatI32(event.logIndex.toI32()));
  e.from = event.params.from;
  e.amount = event.params.amount;
  e.blockNumber = event.block.number;
  e.blockTimestamp = event.block.timestamp;
  e.transactionHash = event.transaction.hash;
  e.save();
}

export function handleSwap(event: SwapEv): void {
  const e = new SwapEvent(event.transaction.hash.concatI32(event.logIndex.toI32()));
  e.sender = event.params.sender;
  e.tokenIn = event.params.tokenIn;
  e.amountIn = event.params.amountIn;
  e.amountOut = event.params.amountOut;
  e.to = event.params.to;
  e.blockNumber = event.block.number;
  e.blockTimestamp = event.block.timestamp;
  e.transactionHash = event.transaction.hash;
  e.save();
}

export function handleAddLiq(event: MintEv): void {
  const e = new LiquidityChange(event.transaction.hash.concatI32(event.logIndex.toI32()));
  e.sender = event.params.sender;
  e.amount0 = event.params.amount0;
  e.amount1 = event.params.amount1;
  e.lp = event.params.lp;
  e.isAdd = true;
  e.blockNumber = event.block.number;
  e.blockTimestamp = event.block.timestamp;
  e.transactionHash = event.transaction.hash;
  e.save();
}

export function handleRemoveLiq(event: BurnEv): void {
  const e = new LiquidityChange(event.transaction.hash.concatI32(event.logIndex.toI32()));
  e.sender = event.params.sender;
  e.amount0 = event.params.amount0;
  e.amount1 = event.params.amount1;
  e.lp = event.params.lp;
  e.isAdd = false;
  e.blockNumber = event.block.number;
  e.blockTimestamp = event.block.timestamp;
  e.transactionHash = event.transaction.hash;
  e.save();
}

export function handleProposalCreated(event: ProposalCreated): void {
  const p = new Proposal(event.params.proposalId.toString());
  p.proposer = event.params.proposer;
  p.description = event.params.description;
  p.startBlock = event.params.voteStart;
  p.endBlock = event.params.voteEnd;
  p.forVotes = BigInt.zero();
  p.againstVotes = BigInt.zero();
  p.abstainVotes = BigInt.zero();
  p.save();
}

export function handleVoteCast(event: VoteCast): void {
  const v = new VoteEvent(event.transaction.hash.concatI32(event.logIndex.toI32()));
  v.voter = event.params.voter;
  v.proposalId = event.params.proposalId;
  v.support = event.params.support;
  v.weight = event.params.weight;
  v.blockTimestamp = event.block.timestamp;
  v.save();

  const p = Proposal.load(event.params.proposalId.toString());
  if (p != null) {
    if (event.params.support == 0) p.againstVotes = p.againstVotes.plus(event.params.weight);
    else if (event.params.support == 1) p.forVotes = p.forVotes.plus(event.params.weight);
    else p.abstainVotes = p.abstainVotes.plus(event.params.weight);
    p.save();
  }
}
