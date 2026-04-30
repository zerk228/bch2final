// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {GovToken} from "../contracts/governance/GovToken.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract GovTokenTest is Test {
    GovToken token;
    address admin = address(0xA11CE);
    address alice = address(0xA);
    address bob = address(0xB);

    function setUp() public {
        token = new GovToken(admin, 1_000_000 ether);
    }

    function test_NameSymbol() public view {
        assertEq(token.name(), "RWA Governance");
        assertEq(token.symbol(), "gRWA");
    }

    function test_InitialSupplyToAdmin() public view {
        assertEq(token.balanceOf(admin), 1_000_000 ether);
        assertEq(token.totalSupply(), 1_000_000 ether);
    }

    function test_AdminCanMint() public {
        vm.prank(admin);
        token.mint(alice, 100 ether);
        assertEq(token.balanceOf(alice), 100 ether);
    }

    function test_RevertWhen_NonMinterMints() public {
        vm.expectRevert();
        vm.prank(alice);
        token.mint(alice, 1 ether);
    }

    function test_TransferWorks() public {
        vm.prank(admin);
        token.transfer(alice, 50 ether);
        assertEq(token.balanceOf(alice), 50 ether);
    }

    function test_DelegateSelf() public {
        vm.prank(admin);
        token.transfer(alice, 100 ether);
        vm.prank(alice);
        token.delegate(alice);
        vm.roll(block.number + 1);
        assertEq(token.getVotes(alice), 100 ether);
    }

    function test_DelegateToOther() public {
        vm.prank(admin);
        token.transfer(alice, 100 ether);
        vm.prank(alice);
        token.delegate(bob);
        vm.roll(block.number + 1);
        assertEq(token.getVotes(bob), 100 ether);
        assertEq(token.getVotes(alice), 0);
    }

    function test_PastVotesSnapshot() public {
        vm.prank(admin);
        token.transfer(alice, 100 ether);
        vm.prank(alice);
        token.delegate(alice);
        vm.roll(block.number + 1);
        uint256 snap = block.number;
        vm.roll(block.number + 5);
        assertEq(token.getPastVotes(alice, snap), 100 ether);
    }

    function test_DomainSeparatorNonZero() public view {
        assertTrue(token.DOMAIN_SEPARATOR() != bytes32(0));
    }

    function test_NoncesStartAtZero() public view {
        assertEq(token.nonces(alice), 0);
    }

    function test_AdminGrantsMinter() public {
        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), alice);
        vm.stopPrank();
        vm.prank(alice);
        token.mint(bob, 1 ether);
        assertEq(token.balanceOf(bob), 1 ether);
    }

    function test_RevokeMinterRole() public {
        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), alice);
        token.revokeRole(token.MINTER_ROLE(), alice);
        vm.stopPrank();
        vm.expectRevert();
        vm.prank(alice);
        token.mint(bob, 1 ether);
    }
}
