// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract IssuerNFT is ERC721, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public nextId;
    mapping(uint256 => string) public license;

    event LicenseIssued(address indexed issuer, uint256 indexed tokenId, string license);
    event LicenseRevoked(uint256 indexed tokenId);

    constructor(address admin) ERC721("RWA Issuer License", "rwaLIC") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }

    function issue(address to, string calldata licenseURI) external onlyRole(MINTER_ROLE) returns (uint256 id) {
        id = ++nextId;
        _safeMint(to, id);
        license[id] = licenseURI;
        emit LicenseIssued(to, id, licenseURI);
    }

    function revoke(uint256 id) external onlyRole(MINTER_ROLE) {
        _burn(id);
        delete license[id];
        emit LicenseRevoked(id);
    }

    function supportsInterface(bytes4 iid) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(iid);
    }
}
