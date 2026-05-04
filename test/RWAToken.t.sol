// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {RWATokenV1} from "../contracts/rwa/RWATokenV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract RWATokenTest is Test {
    RWATokenV1 token;
    address admin = address(0xA11CE);
    address minter = address(0x111);
    address alice = address(0xA);

    function setUp() public {
        RWATokenV1 impl = new RWATokenV1();
        bytes memory data = abi.encodeCall(
            RWATokenV1.initialize, ("Gold RWA", "gRWA", "XAU", 1_000_000 ether, admin)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), data);
        token = RWATokenV1(address(proxy));
        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), minter);
        vm.stopPrank();
    }

    function test_InitializeFields() public view {
        assertEq(token.name(), "Gold RWA");
        assertEq(token.symbol(), "gRWA");
        assertEq(token.assetSymbol(), "XAU");
        assertEq(token.cap(), 1_000_000 ether);
        assertEq(token.version(), "1.0.0");
    }

    function test_CannotInitializeTwice() public {
        vm.expectRevert();
        token.initialize("X", "X", "X", 1, admin);
    }

    function test_AdminHasRoles() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(token.hasRole(token.UPGRADER_ROLE(), admin));
    }

    function test_MinterMints() public {
        vm.prank(minter);
        token.mint(alice, 100 ether);
        assertEq(token.balanceOf(alice), 100 ether);
    }

    function test_RevertWhen_NonMinterMints() public {
        vm.expectRevert();
        vm.prank(alice);
        token.mint(alice, 100 ether);
    }

    function test_RevertWhen_MintZero() public {
        vm.expectRevert(RWATokenV1.ZeroAmount.selector);
        vm.prank(minter);
        token.mint(alice, 0);
    }

    function test_RevertWhen_MintAboveCap() public {
        vm.expectRevert(RWATokenV1.CapExceeded.selector);
        vm.prank(minter);
        token.mint(alice, 1_000_001 ether);
    }

    function test_BurnByHolder() public {
        vm.prank(minter);
        token.mint(alice, 100 ether);
        vm.prank(alice);
        token.burn(40 ether);
        assertEq(token.balanceOf(alice), 60 ether);
        assertEq(token.totalSupply(), 60 ether);
    }

    function test_RevertWhen_BurnZero() public {
        vm.expectRevert(RWATokenV1.ZeroAmount.selector);
        vm.prank(alice);
        token.burn(0);
    }

    function test_TransferAfterMint() public {
        vm.prank(minter);
        token.mint(alice, 50 ether);
        vm.prank(alice);
        token.transfer(admin, 20 ether);
        assertEq(token.balanceOf(admin), 20 ether);
        assertEq(token.balanceOf(alice), 30 ether);
    }

    function test_GrantAndRevokeMinter() public {
        vm.startPrank(admin);
        token.revokeRole(token.MINTER_ROLE(), minter);
        vm.stopPrank();
        vm.expectRevert();
        vm.prank(minter);
        token.mint(alice, 1 ether);
    }

    function test_FuzzMint(uint128 amount) public {
        vm.assume(amount > 0 && amount <= 1_000_000 ether);
        vm.prank(minter);
        token.mint(alice, amount);
        assertEq(token.balanceOf(alice), amount);
    }
}
