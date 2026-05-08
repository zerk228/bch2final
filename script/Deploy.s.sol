// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {GovToken} from "../contracts/governance/GovToken.sol";
import {MyTimelock} from "../contracts/governance/MyTimelock.sol";
import {MyGovernor} from "../contracts/governance/MyGovernor.sol";
import {RWATokenV1} from "../contracts/rwa/RWATokenV1.sol";
import {RWAFactory} from "../contracts/factory/RWAFactory.sol";
import {IssuerNFT} from "../contracts/rwa/IssuerNFT.sol";
import {YieldVault} from "../contracts/rwa/YieldVault.sol";
import {SimpleAMM} from "../contracts/amm/SimpleAMM.sol";
import {PriceOracle, IAggregatorV3} from "../contracts/oracle/PriceOracle.sol";
import {MockAggregator} from "../contracts/oracle/MockAggregator.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Deploy is Script {
    struct Deployed {
        address gov;
        address timelock;
        address governor;
        address rwaImpl;
        address rwaProxy;
        address nft;
        address factory;
        address vault;
        address oracle;
        address amm;
    }

    function _deployGovernance(address deployer) internal returns (address gov, address timelock, address governor) {
        gov = address(new GovToken(deployer, 1_000_000 ether));
        address[] memory empty = new address[](0);
        MyTimelock tl = new MyTimelock(2 days, empty, empty, deployer);
        timelock = address(tl);
        governor = address(new MyGovernor(IVotes(gov), tl));
        tl.grantRole(tl.PROPOSER_ROLE(), governor);
        tl.grantRole(tl.EXECUTOR_ROLE(), address(0));
        tl.grantRole(tl.CANCELLER_ROLE(), governor);
    }

    function _deployRWA(address admin) internal returns (address impl, address proxy) {
        impl = address(new RWATokenV1());
        bytes memory data = abi.encodeCall(
            RWATokenV1.initialize, ("Gold RWA", "gRWA", "XAU", 10_000_000 ether, admin)
        );
        proxy = address(new ERC1967Proxy(impl, data));
    }

    function _deployPeripherals(address rwa, address gov, address admin)
        internal
        returns (address nft, address factory, address vault, address oracle, address amm, address rwaImpl)
    {
        rwaImpl = address(new RWATokenV1());
        nft = address(new IssuerNFT(admin));
        factory = address(new RWAFactory(rwaImpl, admin));
        vault = address(new YieldVault(IERC20(rwa), admin));
        MockAggregator agg = new MockAggregator(8, 2000e8);
        oracle = address(new PriceOracle(IAggregatorV3(address(agg)), 3600, admin));
        amm = address(new SimpleAMM(IERC20(rwa), IERC20(gov)));
    }

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        vm.startBroadcast(pk);

        Deployed memory d;
        (d.gov, d.timelock, d.governor) = _deployGovernance(deployer);
        (d.rwaImpl, d.rwaProxy) = _deployRWA(d.timelock);
        (d.nft, d.factory, d.vault, d.oracle, d.amm,) =
            _deployPeripherals(d.rwaProxy, d.gov, d.timelock);

        MyTimelock(payable(d.timelock)).revokeRole(
            MyTimelock(payable(d.timelock)).DEFAULT_ADMIN_ROLE(), deployer
        );

        vm.stopBroadcast();

        console2.log("GovToken:", d.gov);
        console2.log("Timelock:", d.timelock);
        console2.log("Governor:", d.governor);
        console2.log("RWA impl:", d.rwaImpl);
        console2.log("RWA proxy:", d.rwaProxy);
        console2.log("IssuerNFT:", d.nft);
        console2.log("Factory:", d.factory);
        console2.log("Vault:", d.vault);
        console2.log("Oracle:", d.oracle);
        console2.log("AMM:", d.amm);
    }
}
