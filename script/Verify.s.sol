// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {MyTimelock} from "../contracts/governance/MyTimelock.sol";
import {MyGovernor} from "../contracts/governance/MyGovernor.sol";
import {RWATokenV1} from "../contracts/rwa/RWATokenV1.sol";

contract Verify is Script {
    function run() external view {
        address timelockAddr = vm.envAddress("TIMELOCK");
        address governorAddr = vm.envAddress("GOVERNOR");
        address rwaAddr = vm.envAddress("RWA");
        address deployer = vm.envAddress("DEPLOYER");

        MyTimelock timelock = MyTimelock(payable(timelockAddr));
        MyGovernor governor = MyGovernor(payable(governorAddr));
        RWATokenV1 rwa = RWATokenV1(rwaAddr);

        require(timelock.getMinDelay() == 2 days, "delay");
        require(governor.votingDelay() == 7200, "voting delay");
        require(governor.votingPeriod() == 50400, "voting period");
        require(governor.quorumNumerator() == 4, "quorum");
        require(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)), "proposer");
        require(!timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), deployer), "backdoor");
        require(rwa.hasRole(rwa.DEFAULT_ADMIN_ROLE(), address(timelock)), "rwa admin");

        console2.log("verification: OK");
    }
}
