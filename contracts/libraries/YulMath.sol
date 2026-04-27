// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

library YulMath {
    function mulDivAsm(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        assembly {
            if iszero(d) { revert(0, 0) }
            let p := mul(x, y)
            if iszero(eq(div(p, y), x)) {
                if iszero(iszero(y)) { revert(0, 0) }
            }
            z := div(p, d)
        }
    }

    function mulDivSol(uint256 x, uint256 y, uint256 d) internal pure returns (uint256) {
        require(d != 0, "ZERO_DIV");
        return (x * y) / d;
    }

    function sqrtAsm(uint256 x) internal pure returns (uint256 z) {
        assembly {
            if iszero(iszero(x)) {
                z := x
                let r := add(div(x, 2), 1)
                for {} lt(r, z) {} {
                    z := r
                    r := div(add(div(x, r), r), 2)
                }
            }
        }
    }

    function sqrtSol(uint256 x) internal pure returns (uint256 z) {
        if (x == 0) return 0;
        z = x;
        uint256 r = x / 2 + 1;
        while (r < z) {
            z = r;
            r = (x / r + r) / 2;
        }
    }
}
