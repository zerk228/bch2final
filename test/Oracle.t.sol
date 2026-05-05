// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {PriceOracle, IAggregatorV3} from "../contracts/oracle/PriceOracle.sol";
import {MockAggregator} from "../contracts/oracle/MockAggregator.sol";

contract OracleTest is Test {
    PriceOracle oracle;
    MockAggregator agg;
    address admin = address(0xA11CE);
    address alice = address(0xA);

    function setUp() public {
        agg = new MockAggregator(8, 2000e8);
        oracle = new PriceOracle(IAggregatorV3(address(agg)), 3600, admin);
    }

    function test_GetPriceFreshAnswer() public {
        (uint256 p, uint8 d) = oracle.getPrice();
        assertEq(p, 2000e8);
        assertEq(d, 8);
    }

    function test_RevertWhen_PriceStale() public {
        vm.warp(block.timestamp + 1 hours + 1);
        vm.expectRevert();
        oracle.getPrice();
    }

    function test_RevertWhen_PriceZero() public {
        agg.setAnswer(0);
        vm.expectRevert();
        oracle.getPrice();
    }

    function test_RevertWhen_PriceNegative() public {
        agg.setAnswer(-1);
        vm.expectRevert();
        oracle.getPrice();
    }

    function test_RevertWhen_IncompleteRound() public {
        agg.setAnswer(1500e8);
        agg.setAnsweredInRound(0);
        vm.expectRevert();
        oracle.getPrice();
    }

    function test_SetFeed_Admin() public {
        MockAggregator newAgg = new MockAggregator(8, 1800e8);
        vm.prank(admin);
        oracle.setFeed(IAggregatorV3(address(newAgg)), 600);
        (uint256 p,) = oracle.getPrice();
        assertEq(p, 1800e8);
        assertEq(oracle.maxStaleness(), 600);
    }

    function test_RevertWhen_NonAdminSetsFeed() public {
        vm.expectRevert();
        vm.prank(alice);
        oracle.setFeed(IAggregatorV3(address(agg)), 100);
    }

    function test_FreshAnswerPassesAtMaxAge() public {
        vm.warp(block.timestamp + 3600);
        (uint256 p,) = oracle.getPrice();
        assertEq(p, 2000e8);
    }
}
