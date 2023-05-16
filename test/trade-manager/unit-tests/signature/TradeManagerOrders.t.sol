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
        dealTokens(signer, INITIAL_BALANCE);
        vm.startPrank(signer);
        collateral.approve(address(tradeManagerOrders), INITIAL_BALANCE);
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
                address(signer),
                INITIAL_BALANCE,
                LEVERAGE_0,
                IS_SHORT_0,
                WHITELABEL_ADDRESS_0
            )
        );

        // ACT
        tradeManagerOrders.openPositionViaSignature(openPositionOrder, updateData, signer, signature);
    }

    function testClosePositionViaSignature() public {
        // ARRANGE
        ClosePositionOrder memory closePositionOrder =
            ClosePositionOrder(ClosePositionParams(address(mockTradePair), 1), Constraints(1000 hours, 99, 102), 0, 0);

        bytes32 orderHash = tradeManagerOrders.hash(closePositionOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair), abi.encodeWithSelector(MockTradePair.closePosition.selector, address(signer), 1)
        );

        // ACT
        tradeManagerOrders.closePositionViaSignature(closePositionOrder, updateData, signer, signature);
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
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.partiallyClosePosition.selector, address(signer), 1, 2)
        );

        // ACT
        tradeManagerOrders.partiallyClosePositionViaSignature(
            partiallyClosePositionOrder, updateData, signer, signature
        );
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
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.addMarginToPosition.selector, address(signer), 1, 2)
        );

        // ACT
        tradeManagerOrders.addMarginToPositionViaSignature(addMarginOrder, updateData, signer, signature);
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
            abi.encodeWithSelector(MockTradePair.removeMarginFromPosition.selector, address(signer), 1, 2)
        );

        // ACT
        tradeManagerOrders.removeMarginFromPositionViaSignature(removeMarginOrder, updateData, signer, signature);
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
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.extendPosition.selector, address(signer), 1, 2, 3)
        );

        // ACT
        tradeManagerOrders.extendPositionViaSignature(extendPositionOrder, updateData, signer, signature);
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
            abi.encodeWithSelector(MockTradePair.extendPositionToLeverage.selector, address(signer), 1, 2)
        );

        // ACT
        tradeManagerOrders.extendPositionToLeverageViaSignature(
            extendPositionToLeverageOrder, updateData, signer, signature
        );
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

    /* ========== HELPERS ========== */

    function _sign(uint256 signerPk_, bytes32 dataHash_) private returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk_, dataHash_);
        return abi.encodePacked(r, s, v);
    }
}
