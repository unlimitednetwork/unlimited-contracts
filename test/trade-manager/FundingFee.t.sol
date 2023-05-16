// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/interfaces/ITradePair.sol";
import "src/lib/PositionMaths.sol";
import "src/trade-manager/TradeManager.sol";
import "src/trade-pair/TradePair.sol";
import "test/setup/Constants.sol";
import "test/setup/WithFixtures.t.sol";

contract TradeManagerFundingFeeTest is Test, WithFixtures {
    OpenPositionOrder openPositionOrder = OpenPositionOrder(
        OpenPositionParams(
            address(tradePair), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, REFERRER_0, WHITELABEL_ADDRESS_0
        ),
        Constraints(1000 hours, ASSET_PRICE_0 / 2, ASSET_PRICE_0 * 2),
        0
    );

    function setUp() public {
        deployContracts();
    }

    function testFundingFee() public {
        // Long: 100, Short: 10
        UpdateData[] memory updateData;

        vm.startPrank(ALICE);
        uint256 positionId1 = tradeManager.openPosition(
            OpenPositionParams(
                address(tradePair), INITIAL_BALANCE / 10, LEVERAGE_0, IS_SHORT_0, REFERRER_0, WHITELABEL_ADDRESS_0
            ),
            Constraints(1000 hours, ASSET_PRICE_0 / 2, ASSET_PRICE_0 * 2),
            updateData
        );
        uint256 positionId2 = tradeManager.openPosition(
            OpenPositionParams(
                address(tradePair), INITIAL_BALANCE / 100, LEVERAGE_0, IS_SHORT_1, REFERRER_0, WHITELABEL_ADDRESS_0
            ),
            Constraints(1000 hours, ASSET_PRICE_0 / 2, ASSET_PRICE_0 * 2),
            updateData
        );

        // move by 30 hours
        vm.warp(30 hours);
        PositionDetails memory positionDetails1 = tradeManager.detailsOfPosition(address(tradePair), positionId1);
        PositionDetails memory positionDetails2 = tradeManager.detailsOfPosition(address(tradePair), positionId2);

        // surplus position pays full borrow fee and full funding fee
        assertEq(
            positionDetails1.equity, (int256(MARGIN_0) - BORROW_FEE_AMOUNT_0 - FUNDING_FEE_AMOUNT_0) / 10, "equity 1"
        );
        // deficient position pays full borrow fee and receives 10x funding fee
        assertEq(
            positionDetails2.equity,
            (int256(MARGIN_0) - BORROW_FEE_AMOUNT_0 + 10 * FUNDING_FEE_AMOUNT_0) / 100,
            "equity 2"
        );
    }
}
