// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract SimpleAMM is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public constant FEE_NUM = 997;
    uint256 public constant FEE_DEN = 1000;
    uint256 public constant MIN_LIQUIDITY = 1000;

    uint256 private reserve0;
    uint256 private reserve1;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1, uint256 lp);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, uint256 lp, address to);
    event Swap(address indexed sender, address tokenIn, uint256 amountIn, uint256 amountOut, address to);
    event Sync(uint256 reserve0, uint256 reserve1);

    error InvalidToken();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientInputAmount();
    error InvariantBroken();
    error SlippageExceeded();
    error IdenticalTokens();
    error ZeroAddress();

    constructor(IERC20 _t0, IERC20 _t1) ERC20("RWA-LP", "rwaLP") {
        if (address(_t0) == address(0) || address(_t1) == address(0)) revert ZeroAddress();
        if (address(_t0) == address(_t1)) revert IdenticalTokens();
        token0 = _t0;
        token1 = _t1;
    }

    function getReserves() public view returns (uint256, uint256) {
        return (reserve0, reserve1);
    }

    function _update(uint256 bal0, uint256 bal1) private {
        reserve0 = bal0;
        reserve1 = bal1;
        emit Sync(bal0, bal1);
    }

    function addLiquidity(uint256 a0Desired, uint256 a1Desired, uint256 minLP)
        external
        nonReentrant
        returns (uint256 a0, uint256 a1, uint256 lp)
    {
        (uint256 r0, uint256 r1) = (reserve0, reserve1);
        if (r0 == 0 && r1 == 0) {
            (a0, a1) = (a0Desired, a1Desired);
        } else {
            uint256 a1Optimal = (a0Desired * r1) / r0;
            if (a1Optimal <= a1Desired) {
                (a0, a1) = (a0Desired, a1Optimal);
            } else {
                uint256 a0Optimal = (a1Desired * r0) / r1;
                (a0, a1) = (a0Optimal, a1Desired);
            }
        }
        token0.safeTransferFrom(msg.sender, address(this), a0);
        token1.safeTransferFrom(msg.sender, address(this), a1);

        uint256 _ts = totalSupply();
        if (_ts == 0) {
            lp = Math.sqrt(a0 * a1) - MIN_LIQUIDITY;
            _mint(address(0xdead), MIN_LIQUIDITY);
        } else {
            lp = Math.min((a0 * _ts) / r0, (a1 * _ts) / r1);
        }
        if (lp == 0) revert InsufficientLiquidityMinted();
        if (lp < minLP) revert SlippageExceeded();
        _mint(msg.sender, lp);
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
        emit Mint(msg.sender, a0, a1, lp);
    }

    function removeLiquidity(uint256 lp, uint256 min0, uint256 min1, address to)
        external
        nonReentrant
        returns (uint256 a0, uint256 a1)
    {
        if (lp == 0) revert InsufficientLiquidityBurned();
        uint256 _ts = totalSupply();
        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));
        a0 = (lp * bal0) / _ts;
        a1 = (lp * bal1) / _ts;
        if (a0 == 0 || a1 == 0) revert InsufficientLiquidityBurned();
        if (a0 < min0 || a1 < min1) revert SlippageExceeded();
        _burn(msg.sender, lp);
        token0.safeTransfer(to, a0);
        token1.safeTransfer(to, a1);
        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
        emit Burn(msg.sender, a0, a1, lp, to);
    }

    function getAmountOut(uint256 amountIn, uint256 rIn, uint256 rOut) public pure returns (uint256) {
        if (amountIn == 0) revert InsufficientInputAmount();
        if (rIn == 0 || rOut == 0) revert InsufficientLiquidityMinted();
        uint256 amountInWithFee = amountIn * FEE_NUM;
        uint256 numerator = amountInWithFee * rOut;
        uint256 denominator = rIn * FEE_DEN + amountInWithFee;
        return numerator / denominator;
    }

    function swap(address tokenIn, uint256 amountIn, uint256 minOut, address to)
        external
        nonReentrant
        returns (uint256 amountOut)
    {
        if (tokenIn != address(token0) && tokenIn != address(token1)) revert InvalidToken();
        if (amountIn == 0) revert InsufficientInputAmount();
        (uint256 r0, uint256 r1) = (reserve0, reserve1);
        (uint256 rIn, uint256 rOut) = tokenIn == address(token0) ? (r0, r1) : (r1, r0);
        amountOut = getAmountOut(amountIn, rIn, rOut);
        if (amountOut < minOut) revert SlippageExceeded();
        if (amountOut == 0) revert InsufficientOutputAmount();

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20 tokenOut = tokenIn == address(token0) ? token1 : token0;
        tokenOut.safeTransfer(to, amountOut);

        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));
        if (bal0 * bal1 < r0 * r1) revert InvariantBroken();
        _update(bal0, bal1);
        emit Swap(msg.sender, tokenIn, amountIn, amountOut, to);
    }
}
