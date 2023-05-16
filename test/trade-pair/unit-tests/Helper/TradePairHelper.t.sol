// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "src/trade-pair/TradePairHelper.sol";
import "test/mocks/MockController.sol";
import "test/mocks/MockTradePair.sol";

contract TradePairHelperTest is Test {
    MockTradePair mockTradePair;
    TradePairHelper tradePairHelper;
    MockController mockController;

    function setUp() public {
        mockController = new MockController();
        mockTradePair = new MockTradePair();
        tradePairHelper = new TradePairHelper();
    }

    function testPositionIdsOf() public {
        ITradePair[] memory tradePairs = new ITradePair[](1);
        tradePairs[0] = mockTradePair;

        uint256[][] memory positionIds = tradePairHelper.positionIdsOf(address(this), tradePairs);
        assertEq(positionIds.length, 1);
        assertEq(positionIds[0][0], 111);
        assertEq(positionIds[0][1], 200);
        assertEq(positionIds[0][2], 333);
    }

    function testPositionDetails() public {
        ITradePair[] memory tradePairs = new ITradePair[](1);
        tradePairs[0] = mockTradePair;

        PositionDetails[][] memory positionDetails = tradePairHelper.positionDetailsOf(address(this), tradePairs);
        assertEq(positionDetails.length, 1);
        assertEq(positionDetails[0][0].margin, 0);
    }

    function testWithTwoTradePairs() public {
        MockTradePair mockTradePair2 = new MockTradePair();
        ITradePair[] memory tradePairs = new ITradePair[](2);
        tradePairs[0] = mockTradePair;
        tradePairs[1] = mockTradePair2;

        PositionDetails[][] memory positionDetails = tradePairHelper.positionDetailsOf(address(this), tradePairs);
        assertEq(positionDetails.length, 2);
        assertEq(positionDetails[1][2].margin, 0);
    }

    function testPricesOfOneOfTwo() public {
        MockTradePair mockTradePair2 = new MockTradePair();
        ITradePair[] memory tradePairs = new ITradePair[](1);
        tradePairs[0] = mockTradePair2;

        PricePair[] memory prices = tradePairHelper.pricesOf(tradePairs);
        assertEq(prices.length, 1);
        assertEq(prices[0].minPrice, 99);
        assertEq(prices[0].maxPrice, 101);
    }

    function testPricesOfBoth() public {
        MockTradePair mockTradePair2 = new MockTradePair();

        ITradePair[] memory tradePairs = new ITradePair[](2);
        tradePairs[0] = mockTradePair;
        tradePairs[1] = mockTradePair2;

        PricePair[] memory prices = tradePairHelper.pricesOf(tradePairs);
        assertEq(prices.length, 2);
        assertEq(prices[0].minPrice, 99);
        assertEq(prices[0].maxPrice, 101);
        assertEq(prices[1].minPrice, 99);
        assertEq(prices[1].maxPrice, 101);
    }
}
