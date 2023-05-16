// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/trade-manager/TradeManagerOrders.sol";
import "test/setup/WithMocks.t.sol";

contract TradeManagerOrdersTest is Test, WithMocks {
    TradeSignature tradeSignature;

    TradeManagerOrders tradeManagerOrders;
    UpdateData[] updateData;

    uint256 signerPk;
    address signer;

    function setUp() public {
        tradeSignature = new TradeSignature();
        tradeManagerOrders = new TradeManagerOrders(mockController, mockUserManager);
        signerPk = 999;
        signer = vm.addr(signerPk);
        dealTokens(signer, INITIAL_BALANCE + ORDER_REWARD);
        vm.prank(signer);
        collateral.approve(address(tradeManagerOrders), INITIAL_BALANCE + ORDER_REWARD);

        vm.mockCall(
            address(mockController),
            abi.encodeWithSelector(MockController.orderRewardOfCollateral.selector, address(collateral)),
            abi.encode(ORDER_REWARD)
        );
    }

    function testOpenPositionViaSignature() public {
        // ARRANGE
        OpenPositionOrder memory openPositionOrder = OpenPositionOrder(
            OpenPositionParams(
                address(mockTradePair), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, REFERRER_0, WHITELABEL_ADDRESS_0
            ),
            Constraints(1000 hours, 99, 102),
            0
        );

        bytes32 orderHash = tradeManagerOrders.hash(openPositionOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(
                MockTradePair.openPosition.selector,
                signer,
                INITIAL_BALANCE,
                LEVERAGE_0,
                IS_SHORT_0,
                WHITELABEL_ADDRESS_0
            )
        );

        // ACT
        vm.prank(BACKEND);
        tradeManagerOrders.openPositionViaSignature(openPositionOrder, updateData, signer, signature);

        // ASSERT
        assertEq(collateral.balanceOf(address(mockTradePair)), INITIAL_BALANCE);
        assertEq(collateral.balanceOf(BACKEND), ORDER_REWARD);
    }

    function testClosePositionViaSignature() public {
        // ARRANGE
        ClosePositionOrder memory closePositionOrder =
            ClosePositionOrder(ClosePositionParams(address(mockTradePair), 1), Constraints(1000 hours, 99, 102), 0, 0);

        bytes32 orderHash = tradeManagerOrders.hash(closePositionOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(address(mockTradePair), abi.encodeWithSelector(MockTradePair.closePosition.selector, signer, 1));

        // ACT
        vm.prank(BACKEND);
        tradeManagerOrders.closePositionViaSignature(closePositionOrder, updateData, signer, signature);

        // ASSERT
        assertEq(collateral.balanceOf(BACKEND), ORDER_REWARD);
    }

    function testPartiallyClosePositionViaSignature() public {
        // ARRANGE
        PartiallyClosePositionOrder memory partiallyClosePositionOrder = PartiallyClosePositionOrder(
            PartiallyClosePositionParams(address(mockTradePair), 1, 2), Constraints(1000 hours, 99, 102), 0, 0
        );

        bytes32 orderHash = tradeManagerOrders.hashPartiallyClosePositionOrder(partiallyClosePositionOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair), abi.encodeWithSelector(MockTradePair.partiallyClosePosition.selector, signer, 1, 2)
        );

        // ACT
        vm.prank(BACKEND);
        tradeManagerOrders.partiallyClosePositionViaSignature(
            partiallyClosePositionOrder, updateData, signer, signature
        );

        // ASSERT
        assertEq(collateral.balanceOf(BACKEND), ORDER_REWARD);
    }

    function testAddMarginToPositionViaSignature() public {
        // ARRANGE
        AddMarginToPositionOrder memory addMarginOrder = AddMarginToPositionOrder(
            AddMarginToPositionParams(address(mockTradePair), 1, 2), Constraints(1000 hours, 99, 102), 0, 0
        );

        bytes32 orderHash = tradeManagerOrders.hashAddMarginToPositionOrder(addMarginOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair), abi.encodeWithSelector(MockTradePair.addMarginToPosition.selector, signer, 1, 2)
        );

        // ACT
        vm.prank(BACKEND);
        tradeManagerOrders.addMarginToPositionViaSignature(addMarginOrder, updateData, signer, signature);

        // ASSERT
        assertEq(collateral.balanceOf(BACKEND), ORDER_REWARD);
    }

    function testRemoveMarginFromPositionViaSignature() public {
        // ARRANGE
        RemoveMarginFromPositionOrder memory removeMarginOrder = RemoveMarginFromPositionOrder(
            RemoveMarginFromPositionParams(address(mockTradePair), 1, 2), Constraints(1000 hours, 99, 102), 0, 0
        );

        bytes32 orderHash = tradeManagerOrders.hashRemoveMarginFromPositionOrder(removeMarginOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.removeMarginFromPosition.selector, signer, 1, 2)
        );

        // ACT
        vm.prank(BACKEND);
        tradeManagerOrders.removeMarginFromPositionViaSignature(removeMarginOrder, updateData, signer, signature);

        // ASSERT
        assertEq(collateral.balanceOf(BACKEND), ORDER_REWARD);
    }

    function testExtendPositionViaSignature() public {
        // ARRANGE
        ExtendPositionOrder memory extendPositionOrder = ExtendPositionOrder(
            ExtendPositionParams(address(mockTradePair), 1, 2, 3), Constraints(1000 hours, 99, 102), 0, 0
        );

        bytes32 orderHash = tradeManagerOrders.hashExtendPositionOrder(extendPositionOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair), abi.encodeWithSelector(MockTradePair.extendPosition.selector, signer, 1, 2, 3)
        );

        // ACT
        vm.prank(BACKEND);
        tradeManagerOrders.extendPositionViaSignature(extendPositionOrder, updateData, signer, signature);

        // ASSERT
        assertEq(collateral.balanceOf(BACKEND), ORDER_REWARD);
    }

    function testExtendPositionToLeverageViaSignature() public {
        // ARRANGE
        ExtendPositionToLeverageOrder memory extendPositionToLeverageOrder = ExtendPositionToLeverageOrder(
            ExtendPositionToLeverageParams(address(mockTradePair), 1, 2), Constraints(1000 hours, 99, 102), 0, 0
        );

        bytes32 orderHash = tradeManagerOrders.hashExtendPositionToLeverageOrder(extendPositionToLeverageOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.extendPositionToLeverage.selector, signer, 1, 2)
        );

        // ACT
        vm.prank(BACKEND);
        tradeManagerOrders.extendPositionToLeverageViaSignature(
            extendPositionToLeverageOrder, updateData, signer, signature
        );

        // ASSERT
        assertEq(collateral.balanceOf(BACKEND), ORDER_REWARD);
    }

    function testVerifyConstraints() public {
        // ARRANGE
        ClosePositionOrder memory closePositionOrder =
            ClosePositionOrder(ClosePositionParams(address(mockTradePair), 1), Constraints(1000 hours, 101, 102), 0, 0);

        bytes32 orderHash = tradeManagerOrders.hash(closePositionOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // ACT
        vm.expectRevert("TradeManager::_verifyConstraints: Price out of bounds");
        tradeManagerOrders.closePositionViaSignature(closePositionOrder, updateData, signer, signature);
    }

    function testCannotUseSameSignatureTwice() public {
        // ARRANGE
        OpenPositionOrder memory openPositionOrder = OpenPositionOrder(
            OpenPositionParams(
                address(mockTradePair), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, REFERRER_0, WHITELABEL_ADDRESS_0
            ),
            Constraints(1000 hours, 99, 102),
            0
        );

        bytes32 orderHash = tradeManagerOrders.hash(openPositionOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // ACT
        tradeManagerOrders.openPositionViaSignature(openPositionOrder, updateData, signer, signature);

        // ACT
        vm.expectRevert("TradeSignature::_onlyNonProcessedSignature: Signature already processed");
        tradeManagerOrders.openPositionViaSignature(openPositionOrder, updateData, signer, signature);
    }

    function testCannotExecuteWhenNotOrderExecutor() public {
        // ARRANGE
        vm.mockCall(
            address(mockController),
            abi.encodeWithSelector(MockController.isOrderExecutor.selector, address(this)),
            abi.encode(false)
        );

        OpenPositionOrder memory openPositionOrder = OpenPositionOrder(
            OpenPositionParams(
                address(mockTradePair), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, REFERRER_0, WHITELABEL_ADDRESS_0
            ),
            Constraints(1000 hours, 99, 102),
            0
        );

        bytes32 orderHash = tradeManagerOrders.hash(openPositionOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // ACT
        vm.expectRevert("TradeManagerOrders::_verifyOrderExecutor: Sender is not order executor");
        tradeManagerOrders.openPositionViaSignature(openPositionOrder, updateData, signer, signature);
    }

    /* ========== HELPERS ========== */

    function _sign(uint256 signerPk_, bytes32 dataHash_) private pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk_, dataHash_);
        return abi.encodePacked(r, s, v);
    }
}
