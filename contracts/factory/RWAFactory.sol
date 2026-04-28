// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {RWATokenV1} from "../rwa/RWATokenV1.sol";

contract RWAFactory is AccessControl {
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    address public immutable implementation;
    address[] public deployedTokens;

    event TokenDeployed(address indexed token, bytes32 salt, bool create2);

    error DeploymentFailed();

    constructor(address impl, address admin) {
        implementation = impl;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEPLOYER_ROLE, admin);
    }

    function deploy(
        string calldata name_,
        string calldata symbol_,
        string calldata assetSymbol_,
        uint256 cap_,
        address tokenAdmin
    ) external onlyRole(DEPLOYER_ROLE) returns (address proxy) {
        bytes memory data = abi.encodeCall(
            RWATokenV1.initialize, (name_, symbol_, assetSymbol_, cap_, tokenAdmin)
        );
        proxy = address(new ERC1967Proxy(implementation, data));
        deployedTokens.push(proxy);
        emit TokenDeployed(proxy, bytes32(0), false);
    }

    function deploy2(
        bytes32 salt,
        string calldata name_,
        string calldata symbol_,
        string calldata assetSymbol_,
        uint256 cap_,
        address tokenAdmin
    ) external onlyRole(DEPLOYER_ROLE) returns (address proxy) {
        bytes memory data = abi.encodeCall(
            RWATokenV1.initialize, (name_, symbol_, assetSymbol_, cap_, tokenAdmin)
        );
        bytes memory bytecode = abi.encodePacked(
            type(ERC1967Proxy).creationCode, abi.encode(implementation, data)
        );
        assembly {
            proxy := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        if (proxy == address(0)) revert DeploymentFailed();
        deployedTokens.push(proxy);
        emit TokenDeployed(proxy, salt, true);
    }

    function predictAddress(
        bytes32 salt,
        string calldata name_,
        string calldata symbol_,
        string calldata assetSymbol_,
        uint256 cap_,
        address tokenAdmin
    ) external view returns (address) {
        bytes memory data = abi.encodeCall(
            RWATokenV1.initialize, (name_, symbol_, assetSymbol_, cap_, tokenAdmin)
        );
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(
                    abi.encodePacked(
                        type(ERC1967Proxy).creationCode, abi.encode(implementation, data)
                    )
                )
            )
        );
        return address(uint160(uint256(hash)));
    }

    function deployedCount() external view returns (uint256) {
        return deployedTokens.length;
    }
}
