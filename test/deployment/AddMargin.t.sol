// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "test/setup/WithDeployment.t.sol";

contract AddMarginE2ETest is WithDeployment {
    function setUp() public {
        _network = "AddMarginE2ETest";

        _deploy();

        // OPEN POSITION
        deal(address(collateral), BOB, INITIAL_BALANCE);
        positionId = _openPosition(BOB_PK, "BTC", INITIAL_BALANCE, LEVERAGE_0, false);
        vm.roll(2);
    }

    function test_addMarginSimple() public {
        // This amount is needed because the open fee gets deducted from the added margin
        deal(address(collateral), BOB, MARGIN_0 * 10009 / 10000);

        // Add Margin
        _addMarginToPosition(BOB_PK, "BTC", positionId, MARGIN_0 * 10009 / 10000);

        assertEq(collateral.balanceOf(address(tradePairBtc)), MARGIN_0 * 2, "tradePairBtc");
        assertEq(collateral.balanceOf(BOB), 0, "bob");

        // ASSERT POSITION DETAILS
        assertEq(tradePairBtc.detailsOfPosition(positionId).margin, MARGIN_0 * 2, "margin");
        assertEq(tradePairBtc.detailsOfPosition(positionId).leverage, LEVERAGE_0 / 2, "leverage");
        assertEq(tradePairBtc.detailsOfPosition(positionId).assetAmount, ASSET_AMOUNT_0, "assetAmount");
        assertEq(tradePairBtc.detailsOfPosition(positionId).entryPrice, BTC_PRICE, "entryPrice");
    }

    function testFail_cannotAddMarginUnderMinLeverage() public {
        deal(address(collateral), BOB, MARGIN_0 * 4 * 1001 / 1000);

        _addMarginToPosition(BOB_PK, "BTC", positionId, MARGIN_0 * 4 * 10009 / 10000);
    }

    function test_canAddMarginUnderMinLeverage_AfterFee() public {
        deal(address(collateral), BOB, MARGIN_0 * 4 * 10009 / 10000);

        vm.warp(1000 hours);
        _updatePrice("BTC", BTC_PRICE);

        _addMarginToPosition(BOB_PK, "BTC", positionId, MARGIN_0 * 4 * 10009 / 10000);
    }
}
