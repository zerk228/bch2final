// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {YieldVault} from "../contracts/rwa/YieldVault.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract YieldVaultTest is Test {
    YieldVault vault;
    MockERC20 asset;
    address admin = address(0xA11CE);
    address alice = address(0xA);
    address bob = address(0xB);

    function setUp() public {
        asset = new MockERC20("USD Coin", "USDC", 6);
        vault = new YieldVault(IERC20(address(asset)), admin);
        asset.mint(alice, 1_000_000e6);
        asset.mint(bob, 1_000_000e6);
        asset.mint(admin, 1_000_000e6);
        vm.prank(alice);
        asset.approve(address(vault), type(uint256).max);
        vm.prank(bob);
        asset.approve(address(vault), type(uint256).max);
        vm.prank(admin);
        asset.approve(address(vault), type(uint256).max);
    }

    function test_Metadata() public view {
        assertEq(vault.symbol(), "yUSDC");
        assertEq(vault.asset(), address(asset));
    }

    function test_DepositMintsShares() public {
        vm.prank(alice);
        uint256 shares = vault.deposit(1000e6, alice);
        assertGt(shares, 0);
        assertEq(vault.balanceOf(alice), shares);
    }

    function test_WithdrawReturnsAssets() public {
        vm.startPrank(alice);
        vault.deposit(1000e6, alice);
        uint256 before = asset.balanceOf(alice);
        vault.withdraw(500e6, alice, alice);
        vm.stopPrank();
        assertEq(asset.balanceOf(alice) - before, 500e6);
    }

    function test_MintByShares() public {
        vm.prank(alice);
        uint256 assets = vault.mint(1e12, alice);
        assertGt(assets, 0);
    }

    function test_RedeemShares() public {
        vm.startPrank(alice);
        uint256 shares = vault.deposit(1000e6, alice);
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function test_PreviewMatchesDeposit() public {
        uint256 preview = vault.previewDeposit(1000e6);
        vm.prank(alice);
        uint256 shares = vault.deposit(1000e6, alice);
        assertEq(shares, preview);
    }

    function test_AccrueYieldIncreasesAssets() public {
        vm.prank(alice);
        vault.deposit(1000e6, alice);
        vm.prank(admin);
        vault.accrueYield(100e6);
        assertEq(vault.totalAssets(), 1100e6);
    }

    function test_RevertWhen_NonYieldRoleAccrues() public {
        vm.expectRevert();
        vm.prank(alice);
        vault.accrueYield(1);
    }

    function test_TwoUserShares() public {
        vm.prank(alice);
        uint256 a = vault.deposit(1000e6, alice);
        vm.prank(bob);
        uint256 b = vault.deposit(2000e6, bob);
        assertApproxEqRel(b, a * 2, 1e15);
    }

    function test_RoundingNoFreeMoney() public {
        vm.prank(alice);
        vault.deposit(1, alice);
        vm.prank(admin);
        vault.accrueYield(1e6);
        vm.prank(bob);
        uint256 s = vault.deposit(1, bob);
        assertLe(vault.previewRedeem(s), 1);
    }

    function testFuzz_DepositWithdraw(uint128 amount) public {
        amount = uint128(bound(amount, 1, 100_000e6));
        vm.startPrank(alice);
        uint256 shares = vault.deposit(amount, alice);
        uint256 got = vault.redeem(shares, alice, alice);
        assertLe(got, amount);
        vm.stopPrank();
    }

    function testFuzz_PreviewIsConsistent(uint128 amount) public {
        amount = uint128(bound(amount, 1, 10_000e6));
        uint256 expectedShares = vault.previewDeposit(amount);
        vm.prank(alice);
        uint256 shares = vault.deposit(amount, alice);
        assertEq(shares, expectedShares);
    }
}
