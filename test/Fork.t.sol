// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {PriceOracle, IAggregatorV3} from "../contracts/oracle/PriceOracle.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ForkTest is Test {
    address constant USDC_MAINNET = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant UNIV2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function _forkOrSkip() internal returns (bool ok) {
        string memory rpc = vm.envOr("MAINNET_RPC", string(""));
        if (bytes(rpc).length == 0) return false;
        try vm.createSelectFork(rpc) {
            return true;
        } catch {
            return false;
        }
    }

    function test_Fork_USDC_Symbol() public {
        if (!_forkOrSkip()) return;
        (bool ok, bytes memory data) = USDC_MAINNET.staticcall(abi.encodeWithSignature("symbol()"));
        assertTrue(ok);
        string memory s = abi.decode(data, (string));
        assertEq(s, "USDC");
    }

    function test_Fork_ChainlinkETHFeed() public {
        if (!_forkOrSkip()) return;
        PriceOracle oracle = new PriceOracle(IAggregatorV3(ETH_USD_FEED), 86400, address(this));
        (uint256 price, uint8 decimals) = oracle.getPrice();
        assertGt(price, 0);
        assertEq(decimals, 8);
    }

    function test_Fork_UniV2RouterFactory() public {
        if (!_forkOrSkip()) return;
        (bool ok, bytes memory data) = UNIV2_ROUTER.staticcall(abi.encodeWithSignature("factory()"));
        assertTrue(ok);
        address factory = abi.decode(data, (address));
        assertTrue(factory != address(0));
    }
}
