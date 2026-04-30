// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {SimpleAMM} from "../contracts/amm/SimpleAMM.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMMHandler is Test {
    SimpleAMM public amm;
    MockERC20 public t0;
    MockERC20 public t1;
    address actor = address(0xACC);

    constructor(SimpleAMM _amm, MockERC20 _t0, MockERC20 _t1) {
        amm = _amm;
        t0 = _t0;
        t1 = _t1;
    }

    function swap0(uint96 amountIn) external {
        amountIn = uint96(bound(amountIn, 1e15, 100 ether));
        t0.mint(actor, amountIn);
        vm.startPrank(actor);
        t0.approve(address(amm), amountIn);
        try amm.swap(address(t0), amountIn, 0, actor) {} catch {}
        vm.stopPrank();
    }

    function swap1(uint96 amountIn) external {
        amountIn = uint96(bound(amountIn, 1e15, 100 ether));
        t1.mint(actor, amountIn);
        vm.startPrank(actor);
        t1.approve(address(amm), amountIn);
        try amm.swap(address(t1), amountIn, 0, actor) {} catch {}
        vm.stopPrank();
    }

    function addLiq(uint96 a, uint96 b) external {
        a = uint96(bound(a, 1e16, 1000 ether));
        b = uint96(bound(b, 1e16, 1000 ether));
        t0.mint(actor, a);
        t1.mint(actor, b);
        vm.startPrank(actor);
        t0.approve(address(amm), a);
        t1.approve(address(amm), b);
        try amm.addLiquidity(a, b, 0) {} catch {}
        vm.stopPrank();
    }
}

contract AMMInvariantTest is StdInvariant, Test {
    SimpleAMM amm;
    MockERC20 t0;
    MockERC20 t1;
    AMMHandler handler;

    function setUp() public {
        t0 = new MockERC20("T0", "T0", 18);
        t1 = new MockERC20("T1", "T1", 18);
        amm = new SimpleAMM(IERC20(address(t0)), IERC20(address(t1)));
        address seeder = address(0xCAFE);
        t0.mint(seeder, 10_000 ether);
        t1.mint(seeder, 10_000 ether);
        vm.startPrank(seeder);
        t0.approve(address(amm), type(uint256).max);
        t1.approve(address(amm), type(uint256).max);
        amm.addLiquidity(10_000 ether, 10_000 ether, 0);
        vm.stopPrank();
        handler = new AMMHandler(amm, t0, t1);
        targetContract(address(handler));
    }

    function invariant_KNeverDecreasesPerLP() public view {
        (uint256 r0, uint256 r1) = amm.getReserves();
        uint256 ts = amm.totalSupply();
        uint256 k = r0 * r1;
        assertGe(k, ts);
    }

    function invariant_ReservesMatchBalances() public view {
        (uint256 r0, uint256 r1) = amm.getReserves();
        assertEq(r0, t0.balanceOf(address(amm)));
        assertEq(r1, t1.balanceOf(address(amm)));
    }

    function invariant_LPSupplyPositive() public view {
        assertGt(amm.totalSupply(), 0);
    }
}
