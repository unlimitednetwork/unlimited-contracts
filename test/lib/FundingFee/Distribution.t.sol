// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/FundingFee.sol";

contract FundingFeeLib_Distribution_Test is Test {
    int256 public constant ONE = 1e6;
    int256 constant PERCENT = ONE / 100;

    function testDistribution() public {
        assertEq(
            FundingFee.calculateFundingFeeReward(2_000, 1_000, PERCENT * 1 / 10), int256(PERCENT) * -1 * 2 / 10, "1"
        );
        assertEq(
            FundingFee.calculateFundingFeeReward(5 * 1e18, 4 * 1e18, PERCENT * 2 / 10),
            int256(PERCENT) * -1 * 2 * 5 / 4 / 10,
            "2"
        );
        assertEq(
            FundingFee.calculateFundingFeeReward(5_000 * 1e18, 4 * 1e18, PERCENT * 2 / 10),
            int256(PERCENT) * -1 * 2 * 5_000 / 4 / 10,
            "2"
        );
    }

    function testThrowsWhenExcessVolumeIsHigherThanDeficientVolume() public {
        vm.expectRevert("FundingFee::onlyPositiveVolumeExcess: Excess volume must be higher than deficient volume");
        FundingFee.calculateFundingFeeReward(2_000, 3_000, PERCENT * 1 / 10);
    }

    function testDeficientVolumeIsZero() public {
        assertEq(FundingFee.calculateFundingFeeReward(1, 0, PERCENT * 1 / 10), 0, "0");
        assertEq(FundingFee.calculateFundingFeeReward(1_000_000, 0, PERCENT * 1 / 10), 0, "0");
    }
}
