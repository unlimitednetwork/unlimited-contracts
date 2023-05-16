// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/PositionMaths.sol";
import "test/setup/Constants.sol";

contract ExtendPositionTest is Test {
    using PositionMaths for Position;

    Position position;

    function setUp() public {
        vm.warp(0);
        position = Position({
            margin: MARGIN_0,
            volume: VOLUME_0,
            assetAmount: ASSET_AMOUNT_0,
            pastBorrowFeeIntegral: 0,
            lastBorrowFeeAmount: 0,
            pastFundingFeeIntegral: 0,
            lastFundingFeeAmount: 0,
            lastFeeCalculationAt: uint48(block.timestamp),
            openedAt: uint48(block.timestamp),
            isShort: IS_SHORT_0,
            owner: msg.sender,
            assetDecimals: ASSET_DECIMALS,
            lastAlterationBlock: uint40(block.number)
        });
    }

    function testExtendPosition() public {
        position.extend(MARGIN_0, ASSET_AMOUNT_0, VOLUME_0);
        assertEq(position.margin, MARGIN_0 * 2);
        assertEq(position.volume, VOLUME_0 * 2);
        assertEq(position.entryPrice(), ASSET_PRICE_0);
    }

    function testExtendAfterPriceChange() public {
        // ACT
        // Imagine that the price has doubled since the position was opened
        // This would mean that the new size is only 50% of the original size
        position.extend(MARGIN_0, ASSET_AMOUNT_0 / 2, VOLUME_0);

        // ASSERT
        assertEq(position.margin, MARGIN_0 * 2, "margin");
        assertEq(position.volume, VOLUME_0 * 2, "volume");
        assertEq(position.assetAmount, ASSET_AMOUNT_0 * 3 / 2, "size");

        // entryPrice should be 50% of full price + 50% of half price, so 75% of full price
        assertEq(position.entryPrice(), ASSET_PRICE_0 * 4 / 3, "entryPrice");
    }

    function testExtendPositionToLeverage() public {
        position.extendToLeverage(ASSET_PRICE_0, LEVERAGE_0 * 2);
        assertEq(position.margin, MARGIN_0);
        assertEq(position.volume, VOLUME_0 * 2);
        assertEq(position.entryPrice(), ASSET_PRICE_0);
    }

    function testExtendToLeverageRevertsWhenLeverageTooLow() public {
        vm.expectRevert("PositionMaths::_extendToLeverage: target leverage must be larger than current leverage");
        position.extendToLeverage(ASSET_PRICE_0, LEVERAGE_0);
        position.extendToLeverage(ASSET_PRICE_0, LEVERAGE_0 + 1);
    }

    function testExtendToLeverageAfterFeeUpdate() public {
        // ARRANGE
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ACT
        position.extendToLeverage(ASSET_PRICE_0, NET_LEVERAGE_0 * 2);

        // ASSERT
        assertEq(position.lastNetMargin(), NET_MARGIN_0, "margin");
        assertEq(position.volume, VOLUME_0 * 2, "volume");
        assertEq(position.assetAmount, ASSET_AMOUNT_0 * 2, "size");
        assertEq(position.entryPrice(), ASSET_PRICE_0, "entryPrice");
        assertEq(position.lastNetLeverage(), NET_LEVERAGE_0 * 2, "net leverage");
    }

    function testExtendToLeverageWithFeeAndProfit() public {
        // ARRANGE
        uint256 addedSize = VOLUME_0 * ASSET_MULTIPLIER / uint256(ASSET_PRICE_1);
        int256 expectedEntryPrice = int256(VOLUME_0 * 2 * ASSET_MULTIPLIER / (ASSET_AMOUNT_0 + addedSize));

        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        position.extendToLeverage(ASSET_PRICE_1, NET_LEVERAGE_0 * 2);

        // ASSERT
        assertEq(position.lastNetMargin(), NET_MARGIN_0, "net margin");
        assertEq(position.margin, MARGIN_0, "margin");
        assertEq(position.volume, VOLUME_0 * 2, "volume");
        assertEq(position.assetAmount, ASSET_AMOUNT_0 + addedSize, "size");
        assertEq(position.entryPrice(), expectedEntryPrice, "entryPrice");
        assertEq(position.lastNetLeverage(), NET_LEVERAGE_0 * 2, "net leverage");
    }

    function testExtendWithFeeAndProfit() public {
        // ARRANGE
        uint256 addedSize = VOLUME_0 * ASSET_MULTIPLIER / uint256(ASSET_PRICE_1);
        int256 expectedEntryPrice = int256(VOLUME_0 * 2 * ASSET_MULTIPLIER / (ASSET_AMOUNT_0 + addedSize));
        uint256 expectedLeverage = VOLUME_0 * 2 * LEVERAGE_MULTIPLIER / (NET_MARGIN_0 + MARGIN_0);

        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        position.extend(MARGIN_0, addedSize, VOLUME_0);

        // ASSERT
        assertEq(position.lastNetMargin(), NET_MARGIN_0 + MARGIN_0, "net margin");
        assertEq(position.margin, MARGIN_0 * 2, "margin");
        assertEq(position.volume, VOLUME_0 * 2, "volume");
        assertEq(position.assetAmount, ASSET_AMOUNT_0 + addedSize, "size");
        assertEq(position.entryPrice(), expectedEntryPrice, "entryPrice");
        assertEq(position.lastNetLeverage(), expectedLeverage, "net Leverage");
    }
}
