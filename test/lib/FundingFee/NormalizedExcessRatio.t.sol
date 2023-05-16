// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/FundingFee.sol";
import "test/setup/Constants.sol";

contract FundingFeeLib_NormalizedExcessRatio_Test is Test {
    int256 public constant ONE = FEE_MULTIPLIER;
    int256 constant PERCENT = ONE / 100;

    function testThrowsWhenExcessVolumeSmallerThanDeficientVolume() public {
        vm.expectRevert("FundingFee::onlyPositiveVolumeExcess: Excess volume must be higher than deficient volume");
        FundingFee.normalizedExcessRatio(0, 1, ONE);
    }

    function testReturnsOneWhenMaxRatioIsSmallerThanOne() public {
        assertEq(FundingFee.normalizedExcessRatio(1_000, 1_000, 0), ONE, "0");
        assertEq(FundingFee.normalizedExcessRatio(2_000, 1_000, PERCENT), ONE, "1");
        assertEq(FundingFee.normalizedExcessRatio(3_000, 2_000, PERCENT / 2), ONE, "2");
    }

    function testNormalizedExcessRatioInBalance() public {
        assertEq(FundingFee.normalizedExcessRatio(1_000, 1_000, ONE * 2), 0, "1");
        assertEq(FundingFee.normalizedExcessRatio(1_000, 1_000, ONE * 20), 0, "1");
    }

    function testRatioExceedsMaxRatio() public {
        assertEq(FundingFee.normalizedExcessRatio(2_000, 1_000, ONE), ONE, "1");
        assertEq(FundingFee.normalizedExcessRatio(3_000, 1_000, ONE), ONE, "2");
        assertEq(FundingFee.normalizedExcessRatio(20_000, 1_000, ONE * 20), ONE, "3");
        assertEq(FundingFee.normalizedExcessRatio(21_000, 1_000, ONE * 20), ONE, "4");
        assertEq(FundingFee.normalizedExcessRatio(20_000, 10_000, ONE), ONE, "5");
        assertEq(FundingFee.normalizedExcessRatio(21_000, 10_000, ONE), ONE, "6");
    }

    function testValuesForMaxRatioFour() public {
        assertEq(
            FundingFee.normalizedExcessRatio({excessVolume: 2_000, deficientVolume: 1_000, maxRatio: 4 * ONE}),
            ONE / 3,
            "0"
        );
        assertEq(
            FundingFee.normalizedExcessRatio({excessVolume: 3_000, deficientVolume: 1_000, maxRatio: 4 * ONE}),
            2 * ONE / 3,
            "1"
        );
    }

    function testValuesForMaxRatioSeven() public {
        assertEq(
            FundingFee.normalizedExcessRatio({excessVolume: 2_000, deficientVolume: 1_000, maxRatio: 7 * ONE}),
            ONE / 6,
            "0"
        );
        assertEq(
            FundingFee.normalizedExcessRatio({excessVolume: 3_000, deficientVolume: 1_000, maxRatio: 7 * ONE}),
            ONE * 2 / 6,
            "1"
        );
        assertEq(
            FundingFee.normalizedExcessRatio({excessVolume: 4_000, deficientVolume: 1_000, maxRatio: 7 * ONE}),
            ONE * 3 / 6,
            "2"
        );
        assertEq(
            FundingFee.normalizedExcessRatio({excessVolume: 5_000, deficientVolume: 1_000, maxRatio: 7 * ONE}),
            ONE * 4 / 6,
            "3"
        );
        assertEq(
            FundingFee.normalizedExcessRatio({excessVolume: 6_000, deficientVolume: 1_000, maxRatio: 7 * ONE}),
            ONE * 5 / 6,
            "4"
        );
        assertEq(
            FundingFee.normalizedExcessRatio({excessVolume: 7_000, deficientVolume: 1_000, maxRatio: 7 * ONE}),
            ONE * 6 / 6,
            "5"
        );
    }

    function testDifferentDecimalsForVolumes() public {
        assertEq(FundingFee.normalizedExcessRatio(3 * 1e18, 1e18, 50 * PERCENT), ONE, "3");
        assertEq(FundingFee.normalizedExcessRatio(9 * 1e12, 1e12, ONE * 8 / 9), ONE, "9 maxRatio=10");
    }
}
