// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/FundingFee.sol";
import "test/setup/Constants.sol";

contract FundingFeeLib_FundingFee_Test is Test {
    int256 public constant ONE = 1e14;
    int256 constant PERCENT = ONE / 100; // 1e4
    int256 constant BPS = PERCENT / 100; // 1e2
    // 50_000_000_000 5 BPS

    function testAtMaxRatio() public {
        (int256 longFee, int256 shortFee) = FundingFee.getFundingFeeRates({
            longVolume: 2_000,
            shortVolume: 1_000,
            maxRatio: 2 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee, 10 * int256(BPS), "long fee");
        assertEq(shortFee, -10 * 2 * int256(BPS), "short fee");
    }

    function testMaxRatioFour() public {
        // normalized ratio: 0.333
        // normalized fee: 0.222
        (int256 longFee, int256 shortFee) = FundingFee.getFundingFeeRates({
            longVolume: 2_000,
            shortVolume: 1_000,
            maxRatio: 4 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee, 22222222222, "long fee");
        assertEq(shortFee, -44444444444, "short fee");

        // normalized ratio: 0.666
        // normalized fee: 0.777
        (int256 longFee2, int256 shortFee2) = FundingFee.getFundingFeeRates({
            longVolume: 3_000,
            shortVolume: 1_000,
            maxRatio: 4 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee2, 77777777777, "long fee 2");
        assertEq(shortFee2, -233333333331, "short fee 2");
    }

    function testMaxRatioSeven() public {
        // normalized ratio: 1/6 = 0.166
        // normalized fee: 0.0556
        (int256 longFee, int256 shortFee) = FundingFee.getFundingFeeRates({
            longVolume: 2_000,
            shortVolume: 1_000,
            maxRatio: 7 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee, 5555555555, "long fee");
        assertEq(shortFee, -11111111110, "short fee");

        // normalized ratio: 2/6 = 0.333
        // normalized fee: 0.222
        (int256 longFee2, int256 shortFee2) = FundingFee.getFundingFeeRates({
            longVolume: 3_000,
            shortVolume: 1_000,
            maxRatio: 7 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee2, 22222222222, "long fee 2");
        assertEq(shortFee2, -66666666666, "short fee 2");

        // normalized ratio: 3/6 = 0.5
        // normalized fee: 0.5
        (int256 longFee3, int256 shortFee3) = FundingFee.getFundingFeeRates({
            longVolume: 4_000,
            shortVolume: 1_000,
            maxRatio: 7 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee3, 50000000000, "long fee 3");
        assertEq(shortFee3, -200000000000, "short fee 3");

        // normalized ratio: 4/6 = 0.666
        // normalized fee: 0.777
        (int256 longFee4, int256 shortFee4) = FundingFee.getFundingFeeRates({
            longVolume: 5_000,
            shortVolume: 1_000,
            maxRatio: 7 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee4, 77777777777, "long fee 4");
        assertEq(shortFee4, -388888888885, "short fee 4");

        // normalized ratio: 5/6 = 0.833
        // normalized fee: 0.944
        (int256 longFee5, int256 shortFee5) = FundingFee.getFundingFeeRates({
            longVolume: 6_000,
            shortVolume: 1_000,
            maxRatio: 7 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee5, 94444444444, "long fee 5");
        assertEq(shortFee5, -566666666664, "short fee 5");

        // normalized ratio: 6/6 = 1
        // normalized fee: 1
        (int256 longFee6, int256 shortFee6) = FundingFee.getFundingFeeRates({
            longVolume: 7_000,
            shortVolume: 1_000,
            maxRatio: 7 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee6, 100000000000, "long fee 6");
        assertEq(shortFee6, -700000000000, "short fee 6");
    }

    function testShortInExcess() public {
        // normalized ratio: 0.5
        // normalized fee: 0.5
        (int256 longFee, int256 shortFee) = FundingFee.getFundingFeeRates({
            longVolume: 1_000,
            shortVolume: 2_000,
            maxRatio: 3 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee, -100000000000, "long fee");
        assertEq(shortFee, 50000000000, "short fee");
    }

    function testDifferentRatios() public {
        // normalized ratio: 0.5
        // normalized fee: 0.5
        (int256 longFee, int256 shortFee) = FundingFee.getFundingFeeRates({
            longVolume: 3_000,
            shortVolume: 6_000,
            maxRatio: 3 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee, -10 * FEE_BPS_MULTIPLIER, "long fee");
        assertEq(shortFee, 5 * FEE_BPS_MULTIPLIER, "short fee");

        // normalized ratio: 0.666
        // normalized fee: 0.777
        (int256 longFee2, int256 shortFee2) = FundingFee.getFundingFeeRates({
            longVolume: 2_000,
            shortVolume: 6_000,
            maxRatio: 4 * ONE,
            maxFeeRate: 10 * BPS
        });
        assertEq(longFee2, -233333333331, "long fee 2");
        assertEq(shortFee2, 77777777777, "short fee 2");
    }
}
