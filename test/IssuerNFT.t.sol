// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {IssuerNFT} from "../contracts/rwa/IssuerNFT.sol";

contract IssuerNFTTest is Test {
    IssuerNFT nft;
    address admin = address(0xA11CE);
    address alice = address(0xA);
    address bob = address(0xB);

    function setUp() public {
        nft = new IssuerNFT(admin);
    }

    function test_NameSymbol() public view {
        assertEq(nft.name(), "RWA Issuer License");
        assertEq(nft.symbol(), "rwaLIC");
    }

    function test_IssueIncrementsId() public {
        vm.prank(admin);
        uint256 id = nft.issue(alice, "ipfs://lic1");
        assertEq(id, 1);
        assertEq(nft.ownerOf(1), alice);
        assertEq(nft.license(1), "ipfs://lic1");
    }

    function test_RevertWhen_NonMinterIssues() public {
        vm.expectRevert();
        vm.prank(alice);
        nft.issue(alice, "ipfs://x");
    }

    function test_RevokeBurnsToken() public {
        vm.startPrank(admin);
        uint256 id = nft.issue(alice, "ipfs://lic1");
        nft.revoke(id);
        vm.stopPrank();
        vm.expectRevert();
        nft.ownerOf(id);
        assertEq(nft.license(id), "");
    }

    function test_SupportsInterface() public view {
        assertTrue(nft.supportsInterface(0x80ac58cd));
        assertTrue(nft.supportsInterface(0x01ffc9a7));
        assertTrue(nft.supportsInterface(0x7965db0b));
    }

    function test_MultipleIssues() public {
        vm.startPrank(admin);
        nft.issue(alice, "a");
        nft.issue(bob, "b");
        vm.stopPrank();
        assertEq(nft.nextId(), 2);
    }
}
