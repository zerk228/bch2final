// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

interface IAggregatorV3 {
    function decimals() external view returns (uint8);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract PriceOracle is AccessControl {
    bytes32 public constant FEED_ADMIN = keccak256("FEED_ADMIN");

    IAggregatorV3 public feed;
    uint256 public maxStaleness;

    event FeedUpdated(address indexed feed, uint256 maxStaleness);

    error StalePrice(uint256 updatedAt);
    error InvalidPrice(int256 answer);
    error IncompleteRound();

    constructor(IAggregatorV3 _feed, uint256 _maxStaleness, address admin) {
        feed = _feed;
        maxStaleness = _maxStaleness;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FEED_ADMIN, admin);
        emit FeedUpdated(address(_feed), _maxStaleness);
    }

    function setFeed(IAggregatorV3 _feed, uint256 _maxStaleness) external onlyRole(FEED_ADMIN) {
        feed = _feed;
        maxStaleness = _maxStaleness;
        emit FeedUpdated(address(_feed), _maxStaleness);
    }

    function getPrice() external view returns (uint256 price, uint8 decimals) {
        (uint80 roundId, int256 answer,, uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();
        if (answer <= 0) revert InvalidPrice(answer);
        if (answeredInRound < roundId) revert IncompleteRound();
        if (block.timestamp - updatedAt > maxStaleness) revert StalePrice(updatedAt);
        price = uint256(answer);
        decimals = feed.decimals();
    }
}
