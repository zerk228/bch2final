// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {RWAFactory} from "../contracts/factory/RWAFactory.sol";
import {RWATokenV1} from "../contracts/rwa/RWATokenV1.sol";

contract FactoryTest is Test {
    RWAFactory factory;
    RWATokenV1 impl;
    address admin = address(0xA11CE);
    address tokenAdmin = address(0xB);

    function setUp() public {
        impl = new RWATokenV1();
        factory = new RWAFactory(address(impl), admin);
    }

    function test_DeployCreate() public {
        vm.prank(admin);
        address t = factory.deploy("Gold", "GLD", "XAU", 1 ether, tokenAdmin);
        assertEq(RWATokenV1(t).symbol(), "GLD");
        assertEq(factory.deployedCount(), 1);
    }

    function test_DeployCreate2() public {
        bytes32 salt = keccak256("v1");
        address predicted =
            factory.predictAddress(salt, "Silver", "SLV", "XAG", 1 ether, tokenAdmin);
        vm.prank(admin);
        address actual = factory.deploy2(salt, "Silver", "SLV", "XAG", 1 ether, tokenAdmin);
        assertEq(predicted, actual);
    }

    function test_RevertWhen_DuplicateSalt() public {
        bytes32 salt = keccak256("dup");
        vm.startPrank(admin);
        factory.deploy2(salt, "A", "A", "A", 1 ether, tokenAdmin);
        vm.expectRevert();
        factory.deploy2(salt, "A", "A", "A", 1 ether, tokenAdmin);
        vm.stopPrank();
    }

    function test_RevertWhen_NonDeployerDeploys() public {
        vm.expectRevert();
        factory.deploy("X", "X", "X", 1 ether, tokenAdmin);
    }

    function test_DeployedTokensTracked() public {
        vm.startPrank(admin);
        factory.deploy("A", "A", "A", 1 ether, tokenAdmin);
        factory.deploy("B", "B", "B", 1 ether, tokenAdmin);
        vm.stopPrank();
        assertEq(factory.deployedCount(), 2);
    }

    function test_PredictionMatchesCreate2() public {
        bytes32 salt = keccak256("pred");
        address predicted =
            factory.predictAddress(salt, "P", "P", "P", 1 ether, tokenAdmin);
        vm.prank(admin);
        address actual = factory.deploy2(salt, "P", "P", "P", 1 ether, tokenAdmin);
        assertEq(predicted, actual);
    }
}
