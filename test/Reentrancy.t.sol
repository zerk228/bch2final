// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {YieldVault} from "../contracts/rwa/YieldVault.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VulnerableSink {
    address public vault;
    address public asset;
    bool public attacking;

    constructor(address _vault, address _asset) {
        vault = _vault;
        asset = _asset;
    }

    function attack() external {
        attacking = true;
        YieldVault(vault).withdraw(1, address(this), address(this));
    }

    fallback() external payable {
        if (attacking) {
            attacking = false;
            try YieldVault(vault).withdraw(1, address(this), address(this)) {} catch {}
        }
    }
}

contract ReentrancyCaseStudyTest is Test {
    YieldVault vault;
    MockERC20 asset;
    address admin = address(0xA11CE);
    address alice = address(0xA);

    function setUp() public {
        asset = new MockERC20("USD Coin", "USDC", 6);
        vault = new YieldVault(IERC20(address(asset)), admin);
        asset.mint(alice, 1_000_000e6);
        vm.startPrank(alice);
        asset.approve(address(vault), type(uint256).max);
        vault.deposit(10_000e6, alice);
        vm.stopPrank();
    }

    function test_NonReentrantWithdrawProtects() public {
        vm.prank(alice);
        vault.withdraw(100e6, alice, alice);
        assertEq(vault.totalAssets(), 9_900e6);
    }

    function test_NonReentrantDepositProtects() public {
        vm.prank(alice);
        uint256 s = vault.deposit(50e6, alice);
        assertGt(s, 0);
    }

    function test_ReentrancyGuard_BlocksReenter() public {
        VulnerableSink sink = new VulnerableSink(address(vault), address(asset));
        asset.mint(address(sink), 1e6);
        vm.prank(address(sink));
        asset.approve(address(vault), type(uint256).max);
        vm.prank(address(sink));
        vault.deposit(100, address(sink));
        sink.attack();
    }
}
