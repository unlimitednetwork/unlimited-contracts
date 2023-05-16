// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/interfaces/ITradePair.sol";
import "src/lib/PositionMaths.sol";
import "src/trade-manager/TradeManager.sol";
import "test/mocks/MockTradePair.sol";
import "test/mocks/MockUserManager.sol";
import "test/mocks/MockController.sol";
import "test/setup/Constants.sol";

contract TradeManagerLiquidatePositionsTest is Test {
    // MockTradePair can liquidate positions with positionId % 5 == 0

    TradeManager tradeManager;
    MockTradePair mockTradePair;
    MockController mockController;
    MockUserManager mockUserManager;
    UpdateData[] updateData;

    function setUp() public {
        mockController = new MockController();
        mockUserManager = new MockUserManager();
        tradeManager = new TradeManager(mockController, mockUserManager);
        mockTradePair = new MockTradePair();
    }

    function testLiquidatesPosition() public {
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.liquidatePosition.selector, address(ALICE), 100)
        );

        vm.prank(ALICE);
        tradeManager.liquidatePosition(address(mockTradePair), 100, updateData);
    }

    function testIsLiquidatable() public {
        vm.expectCall(
            address(mockTradePair), abi.encodeWithSelector(MockTradePair.positionIsLiquidatable.selector, 100)
        );
        vm.prank(ALICE);
        tradeManager.positionIsLiquidatable(address(mockTradePair), 100);
        assertEq(tradeManager.positionIsLiquidatable(address(mockTradePair), 100), true);
    }

    function testCanLiquidatePositions() public {
        address[] memory tradePairs = new address[](1);
        tradePairs[0] = address(mockTradePair);
        uint256[][] memory positions = new uint256[][](1);
        positions[0] = new uint256[](2);
        positions[0][0] = 100;
        positions[0][1] = 222;
        bool[][] memory expected = new bool[][](1);
        expected[0] = new bool[](2);
        expected[0][0] = true;
        expected[0][1] = false;
        bool[][] memory result = tradeManager.canLiquidatePositions(tradePairs, positions);
        assertEq(result[0][0], expected[0][0], "Position 100 should be liquidatable");
        assertEq(result[0][1], expected[0][1], "Position 222 should not be liquidatable");
    }

    function testSameArrayLenth() public {
        address[] memory tradePairs = new address[](1);
        uint256[][] memory positions = new uint256[][](2);
        vm.expectRevert("TradeManager::canLiquidatePositions: TradePair and PositionId arrays must be of same length");
        tradeManager.canLiquidatePositions(tradePairs, positions);
    }

    function testSameArrayLenthBatchLiquidate() public {
        address[] memory tradePairs = new address[](1);
        uint256[][] memory positions = new uint256[][](2);
        vm.expectRevert("TradeManager::batchLiquidatePositions: invalid input");
        tradeManager.batchLiquidatePositions(tradePairs, positions, true, updateData);
    }

    function testBatchLiquidatePositions() public {
        address[] memory tradePairs = new address[](1);
        tradePairs[0] = address(mockTradePair);
        uint256[][] memory positions = new uint256[][](1);
        positions[0] = new uint256[](2);
        positions[0][0] = 100;
        positions[0][1] = 222;
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.liquidatePosition.selector, address(ALICE), 100)
        );
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.liquidatePosition.selector, address(ALICE), 222)
        );

        vm.prank(ALICE);
        bool[][] memory result = tradeManager.batchLiquidatePositions(tradePairs, positions, true, updateData);
        assertEq(result[0][0], true, "Position 100 should be liquidated");
        assertEq(result[0][1], false, "Position 222 should not be liquidated");
    }

    function testAllowRevert() public {
        address[] memory tradePairs = new address[](1);
        tradePairs[0] = address(mockTradePair);
        uint256[][] memory positions = new uint256[][](1);
        positions[0] = new uint256[](2);
        positions[0][0] = 100;
        positions[0][1] = 222;
        vm.expectRevert("TradeManager::_batchLiquidatePositionsOfTradePair: liquidation failed");

        vm.prank(ALICE);
        tradeManager.batchLiquidatePositions(tradePairs, positions, false, updateData);
    }
}
