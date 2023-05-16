// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/FundingFee.sol";
import "test/setup/Constants.sol";

contract FundingFeeLib_Fee_Test is Test {
    int256 public constant ONE = FEE_MULTIPLIER;
    int256 constant PERCENT = ONE / 100;

    function testCalculatesFee() public {
        int256 maxFee = PERCENT * 1 / 10; // 0.1%
        assertEq(FundingFee.calculateFundingFee(0, maxFee), 0, "0");
        assertEq(FundingFee.calculateFundingFee(10 * PERCENT, maxFee), maxFee * 1 / 10, "1");
        assertEq(FundingFee.calculateFundingFee(20 * PERCENT, maxFee), maxFee * 2 / 10, "2");
        assertEq(FundingFee.calculateFundingFee(30 * PERCENT, maxFee), maxFee * 3 / 10, "3");
        assertEq(FundingFee.calculateFundingFee(40 * PERCENT, maxFee), maxFee * 4 / 10, "4");
        assertEq(FundingFee.calculateFundingFee(50 * PERCENT, maxFee), maxFee * 5 / 10, "5");
        assertEq(FundingFee.calculateFundingFee(60 * PERCENT, maxFee), maxFee * 6 / 10, "6");
        assertEq(FundingFee.calculateFundingFee(70 * PERCENT, maxFee), maxFee * 7 / 10, "7");
        assertEq(FundingFee.calculateFundingFee(80 * PERCENT, maxFee), maxFee * 8 / 10, "8");
        assertEq(FundingFee.calculateFundingFee(90 * PERCENT, maxFee), maxFee * 9 / 10, "9");
        assertEq(FundingFee.calculateFundingFee(100 * PERCENT, maxFee), maxFee, "10");
        assertEq(FundingFee.calculateFundingFee(110 * PERCENT, maxFee), maxFee, "11");
    }
}
