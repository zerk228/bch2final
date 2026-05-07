// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {RWATokenV1} from "../contracts/rwa/RWATokenV1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract AccessControlCaseTest is Test {
    RWATokenV1 token;
    address admin = address(0xA11CE);
    address attacker = address(0xBAD);
    address alice = address(0xA);

    function setUp() public {
        RWATokenV1 impl = new RWATokenV1();
        bytes memory data = abi.encodeCall(
            RWATokenV1.initialize, ("G", "G", "XAU", 1_000_000 ether, admin)
        );
        ERC1967Proxy p = new ERC1967Proxy(address(impl), data);
        token = RWATokenV1(address(p));
    }

    function test_AttackerCannotMint() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                attacker,
                token.MINTER_ROLE()
            )
        );
        vm.prank(attacker);
        token.mint(attacker, 1 ether);
    }

    function test_AttackerCannotUpgrade() public {
        RWATokenV1 newImpl = new RWATokenV1();
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                attacker,
                token.UPGRADER_ROLE()
            )
        );
        vm.prank(attacker);
        (bool ok,) = address(token).call(
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(newImpl), "")
        );
        ok;
    }

    function test_AdminCanRevokeRoleFromAttacker() public {
        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), attacker);
        vm.stopPrank();
        vm.prank(attacker);
        token.mint(alice, 1 ether);
        vm.startPrank(admin);
        token.revokeRole(token.MINTER_ROLE(), attacker);
        vm.stopPrank();
        vm.expectRevert();
        vm.prank(attacker);
        token.mint(alice, 1 ether);
    }
}
