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
import "test/setup/WithMocks.t.sol";

contract TradeManagerAlterPositionsTest is Test, WithMocks {
    TradeManager tradeManager;
    Constraints constraints;
    UpdateData[] updateData;

    function setUp() public {
        tradeManager = new TradeManager(mockController, mockUserManager);
        constraints = Constraints(1000 hours, 98, 102);
    }

    function testPartiallyClosePosition() public {
        // ARRANGE
        PartiallyClosePositionParams memory params =
            PartiallyClosePositionParams({tradePair: address(mockTradePair), positionId: 111, proportion: 500_000});

        // EXPECT
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.partiallyClosePosition.selector, address(ALICE), 111, 500_000)
        );

        // ACT
        vm.prank(ALICE);
        tradeManager.partiallyClosePosition(params, constraints, updateData);
    }

    function testRemoveMarginFromPosition() public {
        // ARRANGE
        RemoveMarginFromPositionParams memory params = RemoveMarginFromPositionParams({
            tradePair: address(mockTradePair),
            positionId: 111,
            removedMargin: 1_000_000
        });

        // EXPECT
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.removeMarginFromPosition.selector, address(ALICE), 111, 1_000_000)
        );

        // ACT
        vm.prank(ALICE);
        tradeManager.removeMarginFromPosition(params, constraints, updateData);
    }

    function testAddMarginToPosition() public {
        // ARRANGE
        dealTokens(address(ALICE), 1_000_000);

        AddMarginToPositionParams memory params =
            AddMarginToPositionParams({tradePair: address(mockTradePair), positionId: 111, addedMargin: 1_000_000});

        // EXPECT
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.addMarginToPosition.selector, address(ALICE), 111, 1_000_000)
        );

        // ACT
        vm.startPrank(ALICE);
        collateral.increaseAllowance(address(tradeManager), 1_000_000);
        tradeManager.addMarginToPosition(params, constraints, updateData);
    }

    function testExtendPositionToLeverage() public {
        // ARRANGE
        dealTokens(address(ALICE), 1_000_000);

        ExtendPositionToLeverageParams memory params = ExtendPositionToLeverageParams({
            tradePair: address(mockTradePair),
            positionId: 111,
            targetLeverage: 1_000_000
        });

        vm.warp(1001 hours);

        // ACT
        vm.startPrank(ALICE);
        vm.expectRevert("TradeManager::_verifyConstraints: Deadline passed");
        tradeManager.extendPositionToLeverage(params, constraints, updateData);
    }

    function testDeadlinePassed() public {
        // ARRANGE
        dealTokens(address(ALICE), 1_000_000);

        ExtendPositionToLeverageParams memory params = ExtendPositionToLeverageParams({
            tradePair: address(mockTradePair),
            positionId: 111,
            targetLeverage: 1_000_000
        });

        // EXPECT
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.extendPositionToLeverage.selector, address(ALICE), 111, 1_000_000)
        );

        // ACT
        vm.startPrank(ALICE);
        collateral.increaseAllowance(address(tradeManager), 1_000_000);
        tradeManager.extendPositionToLeverage(params, constraints, updateData);
    }
}
