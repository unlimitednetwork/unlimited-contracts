// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/trade-manager/TradeManagerOrders.sol";
import "test/setup/WithMocks.t.sol";

contract PositionIdInjectionTests is Test, WithMocks {
    TradeSignature tradeSignature;

    TradeManagerOrders tradeManagerOrders;
    UpdateData[] updateData;

    uint256 signerPk;
    address signer;
    bytes32 positionSignatureHash;

    function setUp() public {
        tradeSignature = new TradeSignature();
        tradeManagerOrders = new TradeManagerOrders(mockController, mockUserManager);
        signerPk = 999;
        signer = vm.addr(signerPk);
        dealTokens(signer, INITIAL_BALANCE * 2);
        vm.prank(signer);
        collateral.approve(address(tradeManagerOrders), INITIAL_BALANCE * 2);

        OpenPositionOrder memory openPositionOrder = OpenPositionOrder(
            OpenPositionParams(
                address(mockTradePair), INITIAL_BALANCE, LEVERAGE_0, IS_SHORT_0, REFERRER_0, WHITELABEL_ADDRESS_0
            ),
            Constraints(1000 hours, 99, 102),
            0
        );

        bytes32 orderHash = tradeManagerOrders.hash(openPositionOrder);
        bytes memory positionSignature = _sign(signerPk, orderHash);
        positionSignatureHash = keccak256(positionSignature);

        tradeManagerOrders.openPositionViaSignature(openPositionOrder, updateData, signer, positionSignature);
    }

    function testInjectPositionIdToClosePosition() public {
        // ARRANGE
        ClosePositionOrder memory closePositionOrder = ClosePositionOrder(
            ClosePositionParams(address(mockTradePair), type(uint256).max),
            Constraints(1000 hours, 99, 102),
            positionSignatureHash,
            0
        );

        bytes32 orderHash = tradeManagerOrders.hash(closePositionOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(address(mockTradePair), abi.encodeWithSelector(MockTradePair.closePosition.selector, signer, 0));

        // ACT
        tradeManagerOrders.closePositionViaSignature(closePositionOrder, updateData, signer, signature);

        // ASSERT
        assertEq(collateral.balanceOf(address(mockTradePair)), INITIAL_BALANCE);
    }

    function testInjectPositionIdToPartiallyClosePosition() public {
        // ARRANGE
        PartiallyClosePositionOrder memory partiallyClosePositionOrder = PartiallyClosePositionOrder(
            PartiallyClosePositionParams(address(mockTradePair), type(uint256).max, 2),
            Constraints(1000 hours, 99, 102),
            positionSignatureHash,
            0
        );

        bytes32 orderHash = tradeManagerOrders.hashPartiallyClosePositionOrder(partiallyClosePositionOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair), abi.encodeWithSelector(MockTradePair.partiallyClosePosition.selector, signer, 0, 2)
        );

        // ACT
        tradeManagerOrders.partiallyClosePositionViaSignature(
            partiallyClosePositionOrder, updateData, signer, signature
        );

        // ASSERT
        assertEq(collateral.balanceOf(address(mockTradePair)), INITIAL_BALANCE);
    }

    function testInjectPositionIdToAddMarginToPosition() public {
        // ARRANGE
        AddMarginToPositionOrder memory addMarginOrder = AddMarginToPositionOrder(
            AddMarginToPositionParams(address(mockTradePair), type(uint256).max, INITIAL_BALANCE),
            Constraints(1000 hours, 99, 102),
            positionSignatureHash,
            0
        );

        bytes32 orderHash = tradeManagerOrders.hashAddMarginToPositionOrder(addMarginOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.addMarginToPosition.selector, signer, 0, INITIAL_BALANCE)
        );

        // ACT
        tradeManagerOrders.addMarginToPositionViaSignature(addMarginOrder, updateData, signer, signature);

        // ASSERT
        assertEq(collateral.balanceOf(address(mockTradePair)), INITIAL_BALANCE * 2);
    }

    function testInjectPositionIdToRemoveMarginFromPosition() public {
        // ARRANGE
        RemoveMarginFromPositionOrder memory removeMarginOrder = RemoveMarginFromPositionOrder(
            RemoveMarginFromPositionParams(address(mockTradePair), type(uint256).max, 2),
            Constraints(1000 hours, 99, 102),
            positionSignatureHash,
            0
        );

        bytes32 orderHash = tradeManagerOrders.hashRemoveMarginFromPositionOrder(removeMarginOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.removeMarginFromPosition.selector, signer, 0, 2)
        );

        // ACT
        tradeManagerOrders.removeMarginFromPositionViaSignature(removeMarginOrder, updateData, signer, signature);

        // ASSERT
        assertEq(collateral.balanceOf(address(mockTradePair)), INITIAL_BALANCE);
    }

    function testInjectPositionIdToExtendPosition() public {
        // ARRANGE
        ExtendPositionOrder memory extendPositionOrder = ExtendPositionOrder(
            ExtendPositionParams(address(mockTradePair), type(uint256).max, INITIAL_BALANCE, LEVERAGE_MULTIPLIER),
            Constraints(1000 hours, 99, 102),
            positionSignatureHash,
            0
        );

        bytes32 orderHash = tradeManagerOrders.hashExtendPositionOrder(extendPositionOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(
                MockTradePair.extendPosition.selector, signer, 0, INITIAL_BALANCE, LEVERAGE_MULTIPLIER
            )
        );

        // ACT
        tradeManagerOrders.extendPositionViaSignature(extendPositionOrder, updateData, signer, signature);

        // ASSERT
        assertEq(collateral.balanceOf(address(mockTradePair)), INITIAL_BALANCE * 2);
    }

    function testInjectPositionIdToExtendPositionToLeverage() public {
        // ARRANGE
        ExtendPositionToLeverageOrder memory extendPositionToLeverageOrder = ExtendPositionToLeverageOrder(
            ExtendPositionToLeverageParams(address(mockTradePair), type(uint256).max, 2),
            Constraints(1000 hours, 99, 102),
            positionSignatureHash,
            0
        );

        bytes32 orderHash = tradeManagerOrders.hashExtendPositionToLeverageOrder(extendPositionToLeverageOrder);
        bytes memory signature = _sign(signerPk, orderHash);

        // EXPECT
        vm.expectCall(
            address(mockTradePair),
            abi.encodeWithSelector(MockTradePair.extendPositionToLeverage.selector, signer, 0, 2)
        );

        // ACT
        tradeManagerOrders.extendPositionToLeverageViaSignature(
            extendPositionToLeverageOrder, updateData, signer, signature
        );

        // ASSERT
        assertEq(collateral.balanceOf(address(mockTradePair)), INITIAL_BALANCE);
    }

    /* ========== HELPERS ========== */

    function _sign(uint256 signerPk_, bytes32 dataHash_) private pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk_, dataHash_);
        return abi.encodePacked(r, s, v);
    }
}
