// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/PositionMaths.sol";
import "test/setup/Constants.sol";
import "test/setup/WithPositionMaths.t.sol";

contract LiquidationPrice is Test, WithPositionMaths {
    using PositionMaths for Position;

    function setUp() public {
        position = Position({
            margin: MARGIN_0,
            volume: VOLUME_0,
            assetAmount: ASSET_AMOUNT_0,
            pastBorrowFeeIntegral: 0,
            lastBorrowFeeAmount: 0,
            pastFundingFeeIntegral: 0,
            lastFundingFeeAmount: 0,
            collectedFundingFeeAmount: 0,
            collectedBorrowFeeAmount: 0,
            lastFeeCalculationAt: uint48(block.timestamp),
            openedAt: uint48(block.timestamp),
            isShort: IS_SHORT_0,
            owner: msg.sender,
            lastAlterationBlock: uint40(block.number)
        });
    }

    function testSimple() public {
        assertEq(position.liquidationPrice(0, 0, 0), ASSET_PRICE_0 * 4 / 5);
    }

    function testSimpleShort() public {
        position.isShort = true;
        assertEq(position.liquidationPrice(0, 0, 0), ASSET_PRICE_0 * 6 / 5);
    }

    function testLiquidatorRewardLong() public {
        assertEq(position.liquidationPrice(0, 0, MARGIN_0 / 2), ASSET_PRICE_0 * 9 / 10);
    }

    function testLiquidatorRewardShort() public {
        position.isShort = true;
        assertEq(position.liquidationPrice(0, 0, MARGIN_0 / 2), ASSET_PRICE_0 * 11 / 10);
    }

    function testFeeIntegralsLong() public {
        // 50% fee integral (10% * 5x leverage = 50% of margin)
        int256 feeIntegral = FEE_MULTIPLIER * 10 / 100;
        assertEq(position.liquidationPrice(0, feeIntegral, 0), ASSET_PRICE_0 * 9 / 10);
        assertEq(position.liquidationPrice(feeIntegral, 0, 0), ASSET_PRICE_0 * 9 / 10);
        assertEq(position.liquidationPrice(feeIntegral / 4, feeIntegral * 3 / 4, 0), ASSET_PRICE_0 * 9 / 10);
    }

    function testFeeIntegralsShort() public {
        position.isShort = true;

        // 50% fee integral (10% * 5x leverage = 50% of margin)
        int256 feeIntegral = FEE_MULTIPLIER * 10 / 100;
        assertEq(position.liquidationPrice(0, feeIntegral, 0), ASSET_PRICE_0 * 11 / 10);
        assertEq(position.liquidationPrice(feeIntegral, 0, 0), ASSET_PRICE_0 * 11 / 10);
        assertEq(position.liquidationPrice(feeIntegral / 4, feeIntegral * 3 / 4, 0), ASSET_PRICE_0 * 11 / 10);
    }

    function testFeeIntegralsAndLiquidatorRewardLong() public {
        // ARRANGE

        // 25% fee integral (5% * 5x leverage = 25% of margin)
        int256 feeIntegral = FEE_MULTIPLIER * 5 / 100;

        // 25% of margin removed by liquidator reward
        uint256 liquidatorReward = MARGIN_0 / 4;

        // ASSERT

        assertEq(position.liquidationPrice(0, feeIntegral, liquidatorReward), ASSET_PRICE_0 * 9 / 10);
        assertEq(position.liquidationPrice(feeIntegral, 0, liquidatorReward), ASSET_PRICE_0 * 9 / 10);
        assertEq(
            position.liquidationPrice(feeIntegral / 4, feeIntegral * 3 / 4, liquidatorReward), ASSET_PRICE_0 * 9 / 10
        );
    }

    function testFeeIntegralsAndLiquidatorRewardShort() public {
        // ARRANGE

        position.isShort = true;

        // 25% fee integral (5% * 5x leverage = 25% of margin)
        int256 feeIntegral = FEE_MULTIPLIER * 5 / 100;

        // 25% of margin removed by liquidator reward
        uint256 liquidatorReward = MARGIN_0 / 4;

        // ASSERT

        assertEq(position.liquidationPrice(0, feeIntegral, liquidatorReward), ASSET_PRICE_0 * 11 / 10);
        assertEq(position.liquidationPrice(feeIntegral, 0, liquidatorReward), ASSET_PRICE_0 * 11 / 10);
        assertEq(
            position.liquidationPrice(feeIntegral / 4, feeIntegral * 3 / 4, liquidatorReward), ASSET_PRICE_0 * 11 / 10
        );
    }

    function testNegativeFundingFee1() public {
        // -100% fee integral (20% * 5x leverage = 100% of margin)
        int256 feeIntegral = FEE_MULTIPLIER * -20 / 100;

        assertEq(position.liquidationPrice(0, feeIntegral, 0), ASSET_PRICE_0 * 3 / 5);
    }

    function testNegativeFundingFee2() public {
        // 50% fee integral (10% * 5x leverage = 50% of margin)
        int256 feeIntegral = FEE_MULTIPLIER * -10 / 100;

        // leverage is volume to margin: before 5x
        // after 5 / 1.5 = 10 / 3 = 3.333x
        // liquidation price should thus be entryPrice * 1 - 1 / 3.333 = 0.7 entryPrice

        assertEq(position.liquidationPrice(0, feeIntegral, 0), ASSET_PRICE_0 * 7 / 10);
    }

    function testNegativeFundingFee2Short() public {
        // ARRANGE

        position.isShort = true;

        // 50% fee integral (10% * 5x leverage = 50% of margin)
        int256 feeIntegral = FEE_MULTIPLIER * -10 / 100;

        // leverage is volume to margin: before 5x
        // after 5 / 1.5 = 10 / 3 = 3.333x
        // liquidation price should thus be entryPrice * 1 + 1 / 3.333 = 1.3 entryPrice

        assertEq(position.liquidationPrice(0, feeIntegral, 0), ASSET_PRICE_0 * 13 / 10);
    }

    function testNegativeFundingFeeBorrowFeeAndLiquidatorReward2() public {
        // 50% fee integral (10% * 5x leverage = 50% of margin)
        int256 feeIntegral = FEE_MULTIPLIER * -10 / 100;

        // should be leveled out by liquidator reward and borrow fee integral

        assertEq(position.liquidationPrice(-feeIntegral / 2, feeIntegral, MARGIN_0 / 4), ASSET_PRICE_0 * 4 / 5);
    }

    function testNegativeFundingFeeBorrowFeeAndLiquidatorReward2Short() public {
        // ARRANGE

        position.isShort = true;

        // 50% fee integral (10% * 5x leverage = 50% of margin)
        int256 feeIntegral = FEE_MULTIPLIER * -10 / 100;

        // should be leveled out by liquidator reward and borrow fee integral

        assertEq(position.liquidationPrice(-feeIntegral / 2, feeIntegral, MARGIN_0 / 4), ASSET_PRICE_0 * 6 / 5);
    }
}
