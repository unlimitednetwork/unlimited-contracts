// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "./../WithTradePair.sol";

contract AlterationAtSameBlockTest is Test, WithTradePair {
    uint256 positionId;

    function setUp() public {
        deployTradePair();
        vm.startPrank(address(mockTradeManager));
        vm.roll(1);
        positionId =
            tradePair.openPosition(address(ALICE), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, WHITELABEL_ADDRESS_0);
    }

    function testCannotAlterPositionAtSameBlock() public {
        vm.expectRevert("TradePair::_verifyAndUpdateLastAlterationBlock: position already altered this block");
        tradePair.partiallyClosePosition(address(ALICE), positionId, CLOSE_PROPORTION_1);
    }

    function testCannotClosePositionAtSameBlock() public {
        vm.expectRevert("TradePair::_verifyAndUpdateLastAlterationBlock: position already altered this block");
        tradePair.closePosition(address(ALICE), positionId);
    }

    function testCannotAlterTwiceInSameBlock() public {
        // ARRANGE
        vm.roll(2);
        tradePair.partiallyClosePosition(address(ALICE), positionId, CLOSE_PROPORTION_1);

        // ACT & ASSERT
        vm.expectRevert("TradePair::_verifyAndUpdateLastAlterationBlock: position already altered this block");
        tradePair.partiallyClosePosition(address(ALICE), positionId, CLOSE_PROPORTION_1);
    }

    function testCannotLiquidateAtSameBlock() public {
        // ARRANGE
        mockPriceFeedAdapter.setMarkPrices(ASSET_PRICE_0_3, ASSET_PRICE_0_3);

        // ACT & ASSERT
        vm.expectRevert("TradePair::_verifyAndUpdateLastAlterationBlock: position already altered this block");
        tradePair.liquidatePosition(address(ALICE), positionId);
    }
}
