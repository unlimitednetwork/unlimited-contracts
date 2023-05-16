// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "test/setup/WithMocks.t.sol";
import "src/interfaces/ITradePair.sol";
import "src/lib/PositionMaths.sol";
import "./../TradeManagerHarness.t.sol";
import "test/mocks/MockTradePair.sol";
import "test/mocks/MockUserManager.sol";
import "test/mocks/MockController.sol";
import "test/mocks/MockToken.sol";
import "test/setup/Constants.sol";

contract TradeManagerCollateralTest is Test, WithMocks {
    TradeManagerHarness tradeManager;
    Constraints constraints = Constraints(1000 hours, 98, 100);
    UpdateData[] updateData;

    function setUp() public {
        tradeManager = new TradeManagerHarness(mockController, mockUserManager);
        mockTradePair.setCollateral(collateral);
    }

    function testOpenPosition() public {
        dealTokens(address(ALICE), 1_000);
        vm.startPrank(ALICE);
        collateral.increaseAllowance(address(tradeManager), 1_000);
        tradeManager.exposed_openPosition(
            OpenPositionParams(address(mockTradePair), 1_000, LEVERAGE_0, IS_SHORT_0, REFERRER_0, WHITELABEL_ADDRESS_0),
            ALICE
        );
        assertEq(collateral.balanceOf(address(tradeManager)), 0, "TradeManager should have nothing");
        assertEq(collateral.balanceOf(address(mockTradePair)), 1_000, "Trade pair should have margin");
    }

    function testAddMargin() public {
        // ARRANGE
        AddMarginToPositionParams memory params =
            AddMarginToPositionParams({tradePair: address(mockTradePair), positionId: 111, addedMargin: 1_000});

        dealTokens(address(ALICE), 1_000);
        vm.startPrank(ALICE);
        collateral.increaseAllowance(address(tradeManager), 1_000);

        // ACT
        tradeManager.exposed_addMarginToPosition(params, ALICE);

        // ASSERT
        assertEq(collateral.balanceOf(address(tradeManager)), 0, "TradeManager should have nothing");
        assertEq(collateral.balanceOf(address(mockTradePair)), 1_000, "Trade pair should have margin");
    }

    function testExtendPosition() public {
        // ARRANGE
        dealTokens(address(ALICE), 1_000);
        ExtendPositionParams memory params = ExtendPositionParams({
            tradePair: address(mockTradePair),
            positionId: 111,
            addedMargin: 1_000,
            addedLeverage: 5_000_000
        });

        // ACT
        vm.prank(ALICE);
        collateral.increaseAllowance(address(tradeManager), 1_000);
        tradeManager.exposed_extendPosition(params, ALICE);

        // ASSERT
        assertEq(collateral.balanceOf(address(tradeManager)), 0, "TradeManager should have nothing");
        assertEq(collateral.balanceOf(address(mockTradePair)), 1_000, "Trade pair should have margin");
    }
}
