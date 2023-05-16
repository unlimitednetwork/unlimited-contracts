// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/interfaces/ITradePair.sol";
import "src/lib/PositionMaths.sol";
import "src/trade-manager/TradeManager.sol";
import "src/trade-pair/TradePair.sol";
import "test/setup/Constants.sol";
import "test/setup/WithFixtures.t.sol";

contract TradeManagerTest is Test, WithFixtures {
    OpenPositionParams openPositionParams;
    ClosePositionParams closePositionParams;
    Constraints constraints;

    function setUp() public {
        deployContracts();
        openPositionParams = OpenPositionParams(
            address(tradePair), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, REFERRER_0, WHITELABEL_ADDRESS_0
        );
        constraints = Constraints(1000 hours, ASSET_PRICE_0 / 2, ASSET_PRICE_0 * 2);
    }

    function test_shouldOpenPositionOnTradePair() public {
        vm.startPrank(ALICE);
        UpdateData[] memory updateData;

        tradeManager.openPosition(openPositionParams, constraints, updateData);
        PositionDetails memory positionDetails = tradePair.detailsOfPosition(0);

        assertEq(positionDetails.margin, MARGIN_0, "Position margin.");
    }

    function test_shouldRevertWhenOpeningPositionOnInactiveTradePair() public {
        vm.prank(UNLIMITED_OWNER);
        controller.removeTradePair(address(tradePair));

        vm.startPrank(ALICE);
        vm.expectRevert("Controller::_onlyActiveTradePair: invalid trade pair.");
        UpdateData[] memory updateData;
        tradeManager.openPosition(openPositionParams, constraints, updateData);
    }

    function test_shouldClosePositionOnTradePair() public {
        // ARRANGE
        UpdateData[] memory updateData;

        vm.startPrank(ALICE);
        uint256 positionId = tradeManager.openPosition(openPositionParams, constraints, updateData);
        vm.roll(2);

        closePositionParams = ClosePositionParams(address(tradePair), positionId);
        constraints = Constraints(1000 hours, ASSET_PRICE_0 / 2, ASSET_PRICE_0 * 2);

        // ACT
        tradeManager.closePosition(closePositionParams, constraints, updateData);

        // ARRANGE
        vm.expectRevert("TradePair::_positionIsLiquidatable: position does not exist");
        tradeManager.positionIsLiquidatable(address(tradePair), positionId);
    }

    function test_shouldRevertWhenClosingPositionOnInactiveTradePair() public {
        vm.prank(UNLIMITED_OWNER);
        controller.removeTradePair(address(tradePair));

        vm.startPrank(ALICE);
        vm.expectRevert("Controller::_onlyActiveTradePair: invalid trade pair.");
        UpdateData[] memory updateData;
        tradeManager.closePosition(closePositionParams, constraints, updateData);
    }

    function testGetCurrentFundingFeeRates() public {
        (int256 longFundingFeeRate, int256 shortFundingFeeRate) =
            tradeManager.getCurrentFundingFeeRates(address(tradePair));
        assertEq(longFundingFeeRate, 0, "longFundingFeeRate");
        assertEq(shortFundingFeeRate, 0, "shortFundingFeeRate");
    }
}
