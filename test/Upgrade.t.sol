// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {RWATokenV1} from "../contracts/rwa/RWATokenV1.sol";
import {RWATokenV2} from "../contracts/rwa/RWATokenV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract UpgradeTest is Test {
    RWATokenV1 token;
    RWATokenV2 v2impl;
    address admin = address(0xA11CE);
    address minter = address(0x111);
    address alice = address(0xA);
    address attacker = address(0xBAD);

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
        v2impl = new RWATokenV2();
    }

    function test_VersionV1() public view {
        assertEq(token.version(), "1.0.0");
    }

    function test_UpgradeToV2_PreservesState() public {
        vm.prank(minter);
        token.mint(alice, 100 ether);
        vm.prank(admin);
        UUPSUpgradeable(address(token)).upgradeToAndCall(address(v2impl), "");
        RWATokenV2 v2 = RWATokenV2(address(token));
        assertEq(v2.version(), "2.0.0");
        assertEq(v2.balanceOf(alice), 100 ether);
        assertEq(v2.cap(), 1_000_000 ether);
    }

    function test_RevertWhen_NonUpgraderUpgrades() public {
        vm.expectRevert();
        vm.prank(attacker);
        UUPSUpgradeable(address(token)).upgradeToAndCall(address(v2impl), "");
    }

    function test_V2_PauseFunctional() public {
        vm.prank(minter);
        token.mint(alice, 100 ether);
        vm.prank(admin);
        UUPSUpgradeable(address(token)).upgradeToAndCall(address(v2impl), "");
        RWATokenV2 v2 = RWATokenV2(address(token));
        vm.startPrank(admin);
        v2.grantRole(v2.PAUSER_ROLE(), admin);
        vm.stopPrank();
        vm.prank(admin);
        v2.pause();
        vm.expectRevert(RWATokenV2.EnforcedPause.selector);
        vm.prank(alice);
        v2.transfer(admin, 1 ether);
    }

    function test_V2_UnpauseRestoresTransfers() public {
        vm.prank(minter);
        token.mint(alice, 100 ether);
        vm.prank(admin);
        UUPSUpgradeable(address(token)).upgradeToAndCall(address(v2impl), "");
        RWATokenV2 v2 = RWATokenV2(address(token));
        vm.startPrank(admin);
        v2.grantRole(v2.PAUSER_ROLE(), admin);
        vm.stopPrank();
        vm.startPrank(admin);
        v2.pause();
        v2.unpause();
        vm.stopPrank();
        vm.prank(alice);
        v2.transfer(admin, 10 ether);
        assertEq(v2.balanceOf(admin), 10 ether);
    }

    function test_V2_MintingStillWorks() public {
        vm.prank(admin);
        UUPSUpgradeable(address(token)).upgradeToAndCall(address(v2impl), "");
        RWATokenV2 v2 = RWATokenV2(address(token));
        vm.prank(minter);
        v2.mint(alice, 5 ether);
        assertEq(v2.balanceOf(alice), 5 ether);
    }
}
