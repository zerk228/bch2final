// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SimpleAMM} from "../contracts/amm/SimpleAMM.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AMMTest is Test {
    SimpleAMM amm;
    MockERC20 t0;
    MockERC20 t1;
    address alice = address(0xA);
    address bob = address(0xB);

    function setUp() public {
        t0 = new MockERC20("Token0", "T0", 18);
        t1 = new MockERC20("Token1", "T1", 18);
        amm = new SimpleAMM(IERC20(address(t0)), IERC20(address(t1)));
        t0.mint(alice, 1_000_000 ether);
        t1.mint(alice, 1_000_000 ether);
        t0.mint(bob, 1_000_000 ether);
        t1.mint(bob, 1_000_000 ether);
        vm.startPrank(alice);
        t0.approve(address(amm), type(uint256).max);
        t1.approve(address(amm), type(uint256).max);
        vm.stopPrank();
        vm.startPrank(bob);
        t0.approve(address(amm), type(uint256).max);
        t1.approve(address(amm), type(uint256).max);
        vm.stopPrank();
    }

    function _seed() internal {
        vm.prank(alice);
        amm.addLiquidity(1000 ether, 1000 ether, 0);
    }

    function test_TokensImmutable() public view {
        assertEq(address(amm.token0()), address(t0));
        assertEq(address(amm.token1()), address(t1));
    }

    function test_RevertWhen_IdenticalTokens() public {
        vm.expectRevert(SimpleAMM.IdenticalTokens.selector);
        new SimpleAMM(IERC20(address(t0)), IERC20(address(t0)));
    }

    function test_RevertWhen_ZeroAddress() public {
        vm.expectRevert(SimpleAMM.ZeroAddress.selector);
        new SimpleAMM(IERC20(address(0)), IERC20(address(t1)));
    }

    function test_AddInitialLiquidity() public {
        vm.prank(alice);
        (uint256 a0, uint256 a1, uint256 lp) = amm.addLiquidity(1000 ether, 1000 ether, 0);
        assertEq(a0, 1000 ether);
        assertEq(a1, 1000 ether);
        assertGt(lp, 0);
    }

    function test_AddProportionalLiquidity() public {
        _seed();
        vm.prank(bob);
        (uint256 a0, uint256 a1,) = amm.addLiquidity(500 ether, 500 ether, 0);
        assertEq(a0, 500 ether);
        assertEq(a1, 500 ether);
    }

    function test_RemoveLiquidity() public {
        _seed();
        uint256 lp = amm.balanceOf(alice);
        vm.prank(alice);
        (uint256 a0, uint256 a1) = amm.removeLiquidity(lp, 0, 0, alice);
        assertGt(a0, 0);
        assertGt(a1, 0);
    }

    function test_SwapToken0For1() public {
        _seed();
        uint256 before = t1.balanceOf(bob);
        vm.prank(bob);
        uint256 out = amm.swap(address(t0), 100 ether, 0, bob);
        assertEq(t1.balanceOf(bob) - before, out);
        assertGt(out, 0);
    }

    function test_SwapToken1For0() public {
        _seed();
        uint256 before = t0.balanceOf(bob);
        vm.prank(bob);
        uint256 out = amm.swap(address(t1), 100 ether, 0, bob);
        assertEq(t0.balanceOf(bob) - before, out);
    }

    function test_RevertWhen_SwapInvalidToken() public {
        _seed();
        vm.expectRevert(SimpleAMM.InvalidToken.selector);
        vm.prank(bob);
        amm.swap(address(0xdead), 1 ether, 0, bob);
    }

    function test_RevertWhen_SlippageExceeded() public {
        _seed();
        vm.expectRevert(SimpleAMM.SlippageExceeded.selector);
        vm.prank(bob);
        amm.swap(address(t0), 100 ether, 1_000_000 ether, bob);
    }

    function test_RevertWhen_ZeroAmountIn() public {
        _seed();
        vm.expectRevert(SimpleAMM.InsufficientInputAmount.selector);
        vm.prank(bob);
        amm.swap(address(t0), 0, 0, bob);
    }

    function test_FeeChargedOnSwap() public {
        _seed();
        uint256 amtIn = 100 ether;
        uint256 reserve = 1000 ether;
        uint256 out = amm.getAmountOut(amtIn, reserve, reserve);
        uint256 noFee = (amtIn * reserve) / (reserve + amtIn);
        assertLt(out, noFee);
    }

    function test_RemoveLiquiditySlippageRevert() public {
        _seed();
        uint256 lp = amm.balanceOf(alice);
        vm.expectRevert(SimpleAMM.SlippageExceeded.selector);
        vm.prank(alice);
        amm.removeLiquidity(lp, 1e30, 0, alice);
    }

    function testFuzz_SwapPreservesK(uint96 amountIn) public {
        _seed();
        amountIn = uint96(bound(amountIn, 1e15, 100 ether));
        (uint256 r0, uint256 r1) = amm.getReserves();
        uint256 kBefore = r0 * r1;
        vm.prank(bob);
        amm.swap(address(t0), amountIn, 0, bob);
        (uint256 r0a, uint256 r1a) = amm.getReserves();
        assertGe(r0a * r1a, kBefore);
    }

    function testFuzz_AddRemoveSymmetric(uint96 amount) public {
        amount = uint96(bound(amount, 1e15, 100_000 ether));
        vm.startPrank(alice);
        (,, uint256 lp) = amm.addLiquidity(amount, amount, 0);
        (uint256 a0, uint256 a1) = amm.removeLiquidity(lp, 0, 0, alice);
        vm.stopPrank();
        assertApproxEqAbs(a0, amount, amount / 100 + 1000);
        assertApproxEqAbs(a1, amount, amount / 100 + 1000);
    }

    function testFuzz_GetAmountOutMonotonic(uint96 a, uint96 b) public {
        a = uint96(bound(a, 1, 1e20));
        b = uint96(bound(b, uint256(a) + 1, uint256(a) + 1e20));
        uint256 outA = amm.getAmountOut(a, 1e22, 1e22);
        uint256 outB = amm.getAmountOut(b, 1e22, 1e22);
        assertLe(outA, outB);
    }
}
