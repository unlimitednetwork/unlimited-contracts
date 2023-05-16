// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/PositionMaths.sol";
import "test/setup/Constants.sol";

contract LongPositionTest is Test {
    Position position;

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
            lastFeeCalculationAt: uint48(block.timestamp),
            openedAt: uint48(block.timestamp),
            isShort: IS_SHORT_0,
            owner: msg.sender,
            assetDecimals: ASSET_DECIMALS,
            lastAlterationBlock: uint40(block.number)
        });
    }

    function testEntryVolume() public {
        assertEq(position.volume, VOLUME_0);
    }

    function testEntryPrice() public {
        assertEq(position.entryPrice(), ASSET_PRICE_0);
    }

    function testEntryLeverage() public {
        assertEq(position.entryLeverage(), LEVERAGE_0);
    }

    function testBankruptcyPrice() public {
        assertEq(position.bankruptcyPrice(), PRICE_BANKRUPTCY_0);
    }

    function testCurrentVolume() public {
        assertEq(position.currentVolume(ASSET_PRICE_1), VOLUME_0_1);
    }

    function testCurrentValue() public {
        // Current Value should equal the current volume for LONG
        assertEq(position.currentValue(ASSET_PRICE_0), int256(VOLUME_0));
        assertEq(position.currentValue(ASSET_PRICE_1), int256(VOLUME_0_1));
        assertEq(position.currentValue(ASSET_PRICE_0_3), int256(VOLUME_0_3));
    }

    function testCurrentPnL() public {
        assertEq(position.currentPnL(ASSET_PRICE_1), PNL_0_1);
    }

    function testCurrentEquity() public {
        assertEq(position.currentEquity(ASSET_PRICE_1), EQUITY_0_1);
    }

    function testCurrentBorrowFeeAmount() public {
        assertEq(position.currentBorrowFeeAmount(BORROW_FEE_INTEGRAL_0), BORROW_FEE_AMOUNT_0);
    }

    function testCurrentFundingFeeAmount() public {
        assertEq(position.currentFundingFeeAmount(FUNDING_FEE_INTEGRAL_0), FUNDING_FEE_AMOUNT_0);
    }

    function testWithPastFeeIntegralAndAmount() public {
        // Set pastFeeIntegrals to 0.5 of the current integrals
        // Set lastFeeAmounts to 1.0 of the current amounts
        // Should give 1.5 of the current fee amounts
        position.pastBorrowFeeIntegral = BORROW_FEE_INTEGRAL_0 / 2;
        position.lastBorrowFeeAmount = BORROW_FEE_AMOUNT_0;
        position.pastFundingFeeIntegral = FUNDING_FEE_INTEGRAL_0 / 2;
        position.lastFundingFeeAmount = FUNDING_FEE_AMOUNT_0;
        assertEq(position.currentBorrowFeeAmount(BORROW_FEE_INTEGRAL_0), BORROW_FEE_AMOUNT_0 * 3 / 2);
        assertEq(position.currentFundingFeeAmount(FUNDING_FEE_INTEGRAL_0), FUNDING_FEE_AMOUNT_0 * 3 / 2);
    }

    function testNetPnl() public {
        assertEq(position.currentNetPnL(ASSET_PRICE_1, BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0), NET_PNL_0_1);
    }

    function testCurrentNetEquity() public {
        assertEq(
            position.currentNetEquity(ASSET_PRICE_1, BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0), NET_EQUITY_0_1
        );
    }

    function testNegativeFundingFee() public {
        position = Position(
            MARGIN_0,
            VOLUME_0,
            ASSET_AMOUNT_0,
            0,
            0,
            0,
            0,
            uint48(block.timestamp),
            uint48(block.timestamp),
            IS_SHORT_0,
            msg.sender,
            ASSET_DECIMALS,
            uint40(block.number)
        );

        assertEq(
            position.currentFundingFeeAmount(-1 * FUNDING_FEE_INTEGRAL_0),
            -1 * FUNDING_FEE_AMOUNT_0,
            "current funding fee amount"
        );
        assertEq(
            position.currentNetPnL(ASSET_PRICE_0, BORROW_FEE_INTEGRAL_0, -1 * FUNDING_FEE_INTEGRAL_0),
            FUNDING_FEE_AMOUNT_0 - BORROW_FEE_AMOUNT_0,
            "current net PnL"
        );
        assertEq(
            position.currentNetEquity(ASSET_PRICE_0, BORROW_FEE_INTEGRAL_0, -1 * FUNDING_FEE_INTEGRAL_0),
            int256(MARGIN_0) + FUNDING_FEE_AMOUNT_0 - BORROW_FEE_AMOUNT_0,
            "current net equity"
        );
    }

    function testExists() public {
        assertEq(position.exists(), true);
        delete position;
        assertEq(position.exists(), false);
    }

    function testCurrentNetMargin() public {
        // ACT
        uint256 currentNetMargin = position.currentNetMargin(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(currentNetMargin, NET_MARGIN_0);
    }

    function testCurrentNetLeverage() public {
        // ARRANGE
        int256 totalFeeAmount = BORROW_FEE_AMOUNT_0 + FUNDING_FEE_AMOUNT_0; // 600_000

        uint256 netMargin = MARGIN_0 - uint256(totalFeeAmount); // 400_000
        uint256 expectedNetLeverage = VOLUME_0 * LEVERAGE_MULTIPLIER / netMargin; // 5_000_000 / 400_000 = 12.5

        // ACT
        uint256 currentNetLeverage = position.currentNetLeverage(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(currentNetLeverage, expectedNetLeverage);
    }

    function testRemovesFeesFromLastNetMargin() public {
        // ARRANGE
        uint256 expectedMargin = MARGIN_0 - uint256(BORROW_FEE_AMOUNT_0) - uint256(FUNDING_FEE_AMOUNT_0);

        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(position.margin, MARGIN_0);
        assertEq(position.lastNetMargin(), expectedMargin);
    }

    function testRemovesFeesFromMarginDoesNotChangeEntryLeverage() public {
        // ARRANGE
        uint256 expectedMargin = MARGIN_0 - uint256(BORROW_FEE_AMOUNT_0) - uint256(FUNDING_FEE_AMOUNT_0);
        uint256 expectedNetLeverage = VOLUME_0 * LEVERAGE_MULTIPLIER / expectedMargin; // 5_000_000 / 400_000 = 12.5

        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(position.entryLeverage(), LEVERAGE_0, "entry leverage");
        assertEq(
            position.currentNetLeverage(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0),
            expectedNetLeverage,
            "net leverage"
        );
    }

    function testUpdateFeesStoresFeeAmount() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(position.lastBorrowFeeAmount, BORROW_FEE_AMOUNT_0);
        assertEq(position.lastFundingFeeAmount, FUNDING_FEE_AMOUNT_0);
    }

    function testUpdateFeesDoesNotChangeVolume() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        assertEq(position.volume, VOLUME_0);
    }

    function testCurrentNetMarginAfterFeeUpdate() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        uint256 currentNetMargin = position.currentNetMargin(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        assertEq(currentNetMargin, NET_MARGIN_0);
    }

    function testCurrentNetLeverageAfterFeeUpdate() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);

        // ASSERT
        uint256 currentNetLeverage = position.currentNetLeverage(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        assertEq(currentNetLeverage, NET_LEVERAGE_0);
    }

    function testCurrentNetMarginAfterHalfFeeUpdate() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0 / 2, FUNDING_FEE_INTEGRAL_0 / 2);

        // ASSERT
        uint256 currentNetMargin = position.currentNetMargin(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        assertEq(currentNetMargin, NET_MARGIN_0);
    }

    function testCurrentNetLeverageAfterHalfFeeUpdate() public {
        // ACT
        position.updateFees(BORROW_FEE_INTEGRAL_0 / 2, FUNDING_FEE_INTEGRAL_0 / 2);

        // ASSERT
        uint256 currentNetLeverage = position.currentNetLeverage(BORROW_FEE_INTEGRAL_0, FUNDING_FEE_INTEGRAL_0);
        assertEq(currentNetLeverage, NET_LEVERAGE_0);
    }
}
