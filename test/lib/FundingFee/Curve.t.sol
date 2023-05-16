// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/FundingFee.sol";
import "test/setup/Constants.sol";

contract FundingFeeLib_Curve_Test is Test {
    int256 public constant ONE = FEE_MULTIPLIER;
    int256 constant PERCENT = ONE / 100;

    function testValues() public {
        assertEq(FundingFee.curve(0), 0, "0");
        assertEq(FundingFee.curve(ONE * 1 / 10), 2 * PERCENT, "0.1");
        assertEq(FundingFee.curve(ONE * 2 / 10), 8 * PERCENT, "0.2");
        assertEq(FundingFee.curve(ONE * 3 / 10), 18 * PERCENT, "0.3");
        assertEq(FundingFee.curve(ONE * 4 / 10), 32 * PERCENT, "0.4");
        assertEq(FundingFee.curve(ONE * 5 / 10), 50 * PERCENT, "0.5");
        assertEq(FundingFee.curve(ONE * 6 / 10), 68 * PERCENT, "0.6");
        assertEq(FundingFee.curve(ONE * 7 / 10), 82 * PERCENT, "0.7");
        assertEq(FundingFee.curve(ONE * 8 / 10), 92 * PERCENT, "0.8");
        assertEq(FundingFee.curve(ONE * 9 / 10), 98 * PERCENT, "0.9");
        assertEq(FundingFee.curve(ONE), ONE, "1");
        assertEq(FundingFee.curve(ONE + 1), ONE, "~1.00001");
        assertEq(FundingFee.curve(ONE * 11 / 10), ONE, "1.1");
    }
}
