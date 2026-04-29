// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {RWATokenV1} from "./RWATokenV1.sol";

contract RWATokenV2 is RWATokenV1 {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bool private _paused;

    event Paused(address indexed by);
    event Unpaused(address indexed by);

    error EnforcedPause();

    function pause() external onlyRole(PAUSER_ROLE) {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function paused() external view returns (bool) {
        return _paused;
    }

    function _update(address from, address to, uint256 value) internal override {
        if (_paused && from != address(0) && to != address(0)) revert EnforcedPause();
        super._update(from, to, value);
    }

    function version() external pure override returns (string memory) {
        return "2.0.0";
    }
}
