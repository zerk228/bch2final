// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract YieldVault is ERC4626, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant YIELD_ROLE = keccak256("YIELD_ROLE");

    event YieldAccrued(uint256 amount);

    constructor(IERC20 asset_, address admin)
        ERC4626(asset_)
        ERC20(
            string.concat("yield-", IERC20Metadata(address(asset_)).symbol()),
            string.concat("y", IERC20Metadata(address(asset_)).symbol())
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(YIELD_ROLE, admin);
    }

    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner)
        public
        override
        nonReentrant
        returns (uint256)
    {
        return super.withdraw(assets, receiver, owner);
    }

    function mint(uint256 shares, address receiver) public override nonReentrant returns (uint256) {
        return super.mint(shares, receiver);
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        nonReentrant
        returns (uint256)
    {
        return super.redeem(shares, receiver, owner);
    }

    function accrueYield(uint256 amount) external onlyRole(YIELD_ROLE) {
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);
        emit YieldAccrued(amount);
    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return 6;
    }
}
