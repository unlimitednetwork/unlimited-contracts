// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {Solarray} from "test/setup/Solarray.sol";

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

    function testBatchDetailsOfPositions() public {
        MockTradePair mockTradePair2 = new MockTradePair();
        PositionDetails memory differentDetails;

        uint256 differentPositionId = 17;
        uint256 differentMargin = 123;
        differentDetails.margin = 123;

        vm.mockCall(
            address(mockTradePair2),
            abi.encodeWithSelector(mockTradePair2.detailsOfPosition.selector, differentPositionId),
            abi.encode(differentDetails)
        );

        address[] memory tradePairs = Solarray.addresses(address(mockTradePair), address(mockTradePair2));

        uint256[][] memory ids = new uint256[][](2);
        ids[0] = Solarray.uint256s(1, 2);
        ids[1] = Solarray.uint256s(3, 4, differentPositionId);

        PositionDetails[][] memory positionDetails = tradePairHelper.detailsOfPositions(tradePairs, ids);
        assertEq(positionDetails.length, 2);
        assertEq(positionDetails[0].length, 2);
        assertEq(positionDetails[1].length, 3);
        assertEq(positionDetails[0][0].margin, 0);
        assertEq(positionDetails[1][2].margin, differentMargin);
    }
}
