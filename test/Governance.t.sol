// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {GovToken} from "../contracts/governance/GovToken.sol";
import {MyGovernor} from "../contracts/governance/MyGovernor.sol";
import {MyTimelock} from "../contracts/governance/MyTimelock.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract Treasury {
    uint256 public x;

    function setX(uint256 _x) external {
        x = _x;
    }
}

contract GovernanceTest is Test {
    GovToken token;
    MyTimelock timelock;
    MyGovernor governor;
    Treasury treasury;

    address voter = address(0xA);
    uint256 constant DELAY = 2 days;

    function setUp() public {
        token = new GovToken(address(this), 1_000_000 ether);
        address[] memory empty = new address[](0);
        timelock = new MyTimelock(DELAY, empty, empty, address(this));
        governor = new MyGovernor(IVotes(address(token)), timelock);

        bytes32 PROPOSER = timelock.PROPOSER_ROLE();
        bytes32 EXECUTOR = timelock.EXECUTOR_ROLE();
        bytes32 ADMIN = timelock.DEFAULT_ADMIN_ROLE();
        timelock.grantRole(PROPOSER, address(governor));
        timelock.grantRole(EXECUTOR, address(0));
        timelock.revokeRole(ADMIN, address(this));

        treasury = new Treasury();
        treasury.setX(0);

        token.transfer(voter, 100_000 ether);
        vm.prank(voter);
        token.delegate(voter);
        vm.roll(block.number + 1);
    }

    function _proposeSetX(uint256 newX) internal returns (uint256, address[] memory, uint256[] memory, bytes[] memory, bytes32) {
        address[] memory targets = new address[](1);
        targets[0] = address(treasury);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(Treasury.setX.selector, newX);
        string memory desc = "set x";
        vm.prank(voter);
        uint256 id = governor.propose(targets, values, calldatas, desc);
        return (id, targets, values, calldatas, keccak256(bytes(desc)));
    }

    function test_GovernorParams() public view {
        assertEq(governor.votingDelay(), 7200);
        assertEq(governor.votingPeriod(), 50400);
        assertEq(governor.quorumNumerator(), 4);
    }

    function test_TimelockDelay() public view {
        assertEq(timelock.getMinDelay(), DELAY);
    }

    function test_ProposeCreatesProposal() public {
        (uint256 id,,,,) = _proposeSetX(42);
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Pending));
    }

    function test_VoteFlow_Succeeds() public {
        (uint256 id,,,,) = _proposeSetX(42);
        vm.roll(block.number + 7201);
        vm.prank(voter);
        governor.castVote(id, 1);
        vm.roll(block.number + 50401);
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Succeeded));
    }

    function test_QueueAndExecute() public {
        (
            uint256 id,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 hash
        ) = _proposeSetX(42);
        vm.roll(block.number + 7201);
        vm.prank(voter);
        governor.castVote(id, 1);
        vm.roll(block.number + 50401);

        governor.queue(targets, values, calldatas, hash);
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Queued));

        vm.warp(block.timestamp + DELAY + 1);
        governor.execute(targets, values, calldatas, hash);
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Executed));
        assertEq(treasury.x(), 42);
    }

    function test_DefeatedWithoutQuorum() public {
        token.transfer(address(0xC0FFEE), 1 ether);
        vm.prank(address(0xC0FFEE));
        token.delegate(address(0xC0FFEE));
        vm.roll(block.number + 1);

        address[] memory targets = new address[](1);
        targets[0] = address(treasury);
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(Treasury.setX.selector, 1);
        string memory desc = "small";
        vm.prank(voter);
        uint256 id = governor.propose(targets, values, calldatas, desc);
        vm.roll(block.number + 7201);
        vm.prank(address(0xC0FFEE));
        governor.castVote(id, 1);
        vm.roll(block.number + 50401);
        assertEq(uint8(governor.state(id)), uint8(IGovernor.ProposalState.Defeated));
    }

    function test_RevertWhen_ExecuteBeforeDelay() public {
        (
            uint256 id,
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas,
            bytes32 hash
        ) = _proposeSetX(7);
        vm.roll(block.number + 7201);
        vm.prank(voter);
        governor.castVote(id, 1);
        vm.roll(block.number + 50401);
        governor.queue(targets, values, calldatas, hash);
        vm.expectRevert();
        governor.execute(targets, values, calldatas, hash);
    }

    function testFuzz_VotingPower(uint96 amount) public {
        amount = uint96(bound(amount, 1, 100_000 ether));
        address u = address(0xD00D);
        token.transfer(u, amount);
        vm.prank(u);
        token.delegate(u);
        vm.roll(block.number + 1);
        assertEq(token.getVotes(u), amount);
    }
}
