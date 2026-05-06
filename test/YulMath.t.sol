// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {YulMath} from "../contracts/libraries/YulMath.sol";

contract YulMathWrapper {
    function mulDivAsm(uint256 x, uint256 y, uint256 d) external pure returns (uint256) {
        return YulMath.mulDivAsm(x, y, d);
    }

    function mulDivSol(uint256 x, uint256 y, uint256 d) external pure returns (uint256) {
        return YulMath.mulDivSol(x, y, d);
    }

    function sqrtAsm(uint256 x) external pure returns (uint256) {
        return YulMath.sqrtAsm(x);
    }

    function sqrtSol(uint256 x) external pure returns (uint256) {
        return YulMath.sqrtSol(x);
    }
}

contract YulMathTest is Test {
    YulMathWrapper w;

    function setUp() public {
        w = new YulMathWrapper();
    }

    function test_MulDivBasic() public view {
        assertEq(w.mulDivAsm(6, 7, 2), 21);
        assertEq(w.mulDivSol(6, 7, 2), 21);
    }

    function test_SqrtBasic() public view {
        assertEq(w.sqrtAsm(0), 0);
        assertEq(w.sqrtAsm(4), 2);
        assertEq(w.sqrtAsm(16), 4);
        assertEq(w.sqrtAsm(100), 10);
    }

    function test_GasComparison_MulDiv() public {
        uint256 g1 = gasleft();
        w.mulDivAsm(1e18, 1e18, 1e9);
        uint256 asmGas = g1 - gasleft();
        uint256 g2 = gasleft();
        w.mulDivSol(1e18, 1e18, 1e9);
        uint256 solGas = g2 - gasleft();
        emit log_named_uint("mulDivAsm gas", asmGas);
        emit log_named_uint("mulDivSol gas", solGas);
        assertGt(asmGas, 0);
        assertGt(solGas, 0);
    }

    function test_RevertWhen_MulDivByZero() public {
        vm.expectRevert();
        w.mulDivAsm(1, 1, 0);
    }

    function testFuzz_MulDivConsistent(uint128 x, uint128 y, uint64 d) public view {
        vm.assume(d > 0);
        assertEq(w.mulDivAsm(x, y, d), w.mulDivSol(x, y, d));
    }

    function testFuzz_SqrtConsistent(uint128 x) public view {
        assertEq(w.sqrtAsm(x), w.sqrtSol(x));
    }
}
