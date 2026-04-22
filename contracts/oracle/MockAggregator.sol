// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IAggregatorV3} from "./PriceOracle.sol";

contract MockAggregator is IAggregatorV3 {
    uint8 public override decimals;
    int256 private _answer;
    uint256 private _updatedAt;
    uint80 private _roundId;
    uint80 private _answeredInRound;

    constructor(uint8 _decimals, int256 initial) {
        decimals = _decimals;
        _answer = initial;
        _updatedAt = block.timestamp;
        _roundId = 1;
        _answeredInRound = 1;
    }

    function setAnswer(int256 a) external {
        _answer = a;
        _updatedAt = block.timestamp;
        _roundId += 1;
        _answeredInRound = _roundId;
    }

    function setUpdatedAt(uint256 t) external {
        _updatedAt = t;
    }

    function setAnsweredInRound(uint80 r) external {
        _answeredInRound = r;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (_roundId, _answer, _updatedAt, _updatedAt, _answeredInRound);
    }
}
