// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "test/setup/Constants.sol";
import "src/interfaces/ITradeManagerOrders.sol";

contract WithAlterationHelpers is Test {
    UpdateData[] emptyUpdateData;

    uint256 salt;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock2() public virtual {}

    function _openPosition(
        uint256 userPrivateKey_,
        ITradeManagerOrders tradeManager_,
        ITradePair tradePair_,
        int256 constraintPrice_,
        uint256 margin_,
        uint256 leverage_,
        bool isShort_
    ) internal returns (uint256) {
        OpenPositionOrder memory openPositionOrder = OpenPositionOrder(
            OpenPositionParams(address(tradePair_), margin_, leverage_, isShort_, address(0), address(0)),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            0
        );

        bytes memory signature = _sign(userPrivateKey_, tradeManager_.hash(openPositionOrder));

        vm.startPrank(vm.addr(userPrivateKey_));
        tradePair_.collateral().approve(address(tradeManager_), margin_ + ORDER_REWARD);
        vm.stopPrank();

        vm.prank(BACKEND);
        return ITradeManagerOrders(tradeManager_).openPositionViaSignature(
            openPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    /// @dev Copy of _openPosition with deal token and approval
    function _openPosition2(
        uint256 userPrivateKey_,
        ITradeManagerOrders tradeManager_,
        ITradePair tradePair_,
        int256 constraintPrice_,
        uint256 margin_,
        uint256 leverage_,
        bool isShort_
    ) internal increaseBlockNumber increaseSalt returns (uint256) {
        OpenPositionOrder memory openPositionOrder = OpenPositionOrder(
            OpenPositionParams(address(tradePair_), margin_, leverage_, isShort_, address(0), address(0)),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            salt
        );

        bytes memory signature = _sign(userPrivateKey_, tradeManager_.hash(openPositionOrder));

        // Deal and approve collateral
        deal(address(tradePair_.collateral()), vm.addr(userPrivateKey_), margin_);
        vm.startPrank(vm.addr(userPrivateKey_));
        tradePair_.collateral().approve(address(tradeManager_), margin_ + ORDER_REWARD);
        vm.stopPrank();

        vm.prank(BACKEND);
        return ITradeManagerOrders(tradeManager_).openPositionViaSignature(
            openPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _closePosition(
        uint256 userPrivateKey_,
        ITradeManagerOrders tradeManager_,
        ITradePair tradePair_,
        uint256 positionId_,
        int256 constraintPrice_
    ) internal {
        ClosePositionOrder memory closePositionOrder = ClosePositionOrder(
            ClosePositionParams(address(tradePair_), positionId_),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            0,
            0
        );

        bytes32 orderHash = tradeManager_.hash(closePositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.prank(BACKEND);
        ITradeManagerOrders(tradeManager_).closePositionViaSignature(
            closePositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _partiallyClosePosition(
        uint256 userPrivateKey_,
        ITradeManagerOrders tradeManager_,
        ITradePair tradePair_,
        uint256 positionId_,
        int256 constraintPrice_,
        uint256 proportion_
    ) internal {
        PartiallyClosePositionOrder memory partiallyClosePositionOrder = PartiallyClosePositionOrder(
            PartiallyClosePositionParams(address(tradePair_), positionId_, proportion_),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            0,
            0
        );

        bytes32 orderHash = tradeManager_.hashPartiallyClosePositionOrder(partiallyClosePositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.prank(BACKEND);
        ITradeManagerOrders(tradeManager_).partiallyClosePositionViaSignature(
            partiallyClosePositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _addMarginToPosition(
        uint256 userPrivateKey_,
        ITradeManagerOrders tradeManager_,
        ITradePair tradePair_,
        uint256 positionId_,
        int256 constraintPrice_,
        uint256 addedMargin_
    ) internal {
        AddMarginToPositionOrder memory addMarginToPositionOrder = AddMarginToPositionOrder(
            AddMarginToPositionParams(address(tradePair_), positionId_, addedMargin_),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            0,
            0
        );

        bytes32 orderHash = tradeManager_.hashAddMarginToPositionOrder(addMarginToPositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.startPrank(vm.addr(userPrivateKey_));
        tradePair_.collateral().approve(address(tradeManager_), addedMargin_ + ORDER_REWARD);
        vm.stopPrank();

        vm.prank(BACKEND);
        ITradeManagerOrders(tradeManager_).addMarginToPositionViaSignature(
            addMarginToPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _removeMarginFromPosition(
        uint256 userPrivateKey_,
        ITradeManagerOrders tradeManager_,
        ITradePair tradePair_,
        uint256 positionId_,
        int256 constraintPrice_,
        uint256 removedMargin_
    ) internal {
        RemoveMarginFromPositionOrder memory removeMarginFromPositionOrder = RemoveMarginFromPositionOrder(
            RemoveMarginFromPositionParams(address(tradePair_), positionId_, removedMargin_),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            0,
            0
        );

        bytes32 orderHash = tradeManager_.hashRemoveMarginFromPositionOrder(removeMarginFromPositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.prank(BACKEND);
        ITradeManagerOrders(tradeManager_).removeMarginFromPositionViaSignature(
            removeMarginFromPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _extendPosition(
        uint256 userPrivateKey_,
        ITradeManagerOrders tradeManager_,
        ITradePair tradePair_,
        uint256 positionId_,
        int256 constraintPrice_,
        uint256 addedMargin_,
        uint256 addedLeverage_
    ) internal {
        ExtendPositionOrder memory extendPositionOrder = ExtendPositionOrder(
            ExtendPositionParams(address(tradePair_), positionId_, addedMargin_, addedLeverage_),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            0,
            0
        );

        bytes32 orderHash = tradeManager_.hashExtendPositionOrder(extendPositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.startPrank(vm.addr(userPrivateKey_));
        tradePair_.collateral().approve(address(tradeManager_), addedMargin_ + ORDER_REWARD);
        vm.stopPrank();

        vm.prank(BACKEND);
        ITradeManagerOrders(tradeManager_).extendPositionViaSignature(
            extendPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _extendPosition2(
        uint256 userPrivateKey_,
        ITradeManagerOrders tradeManager_,
        ITradePair tradePair_,
        uint256 positionId_,
        int256 constraintPrice_,
        uint256 addedMargin_,
        uint256 addedLeverage_
    ) internal increaseBlockNumber {
        ExtendPositionOrder memory extendPositionOrder = ExtendPositionOrder(
            ExtendPositionParams(address(tradePair_), positionId_, addedMargin_, addedLeverage_),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            0,
            0
        );

        bytes32 orderHash = tradeManager_.hashExtendPositionOrder(extendPositionOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        // Deal and approve collateral
        deal(address(tradePair_.collateral()), vm.addr(userPrivateKey_), addedMargin_);
        vm.startPrank(vm.addr(userPrivateKey_));
        tradePair_.collateral().approve(address(tradeManager_), addedMargin_ + ORDER_REWARD);
        vm.stopPrank();

        vm.prank(BACKEND);
        ITradeManagerOrders(tradeManager_).extendPositionViaSignature(
            extendPositionOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _extendPositionToLeverage(
        uint256 userPrivateKey_,
        ITradeManagerOrders tradeManager_,
        ITradePair tradePair_,
        uint256 positionId_,
        int256 constraintPrice_,
        uint256 targetLeverage_
    ) internal {
        ExtendPositionToLeverageOrder memory extendPositionToLeverageOrder = ExtendPositionToLeverageOrder(
            ExtendPositionToLeverageParams(address(tradePair_), positionId_, targetLeverage_),
            Constraints(block.timestamp + 1 hours, constraintPrice_ * 90 / 100, constraintPrice_ * 110 / 100),
            0,
            0
        );

        bytes32 orderHash = tradeManager_.hashExtendPositionToLeverageOrder(extendPositionToLeverageOrder);
        bytes memory signature = _sign(userPrivateKey_, orderHash);

        vm.prank(BACKEND);
        ITradeManagerOrders(tradeManager_).extendPositionToLeverageViaSignature(
            extendPositionToLeverageOrder, emptyUpdateData, vm.addr(userPrivateKey_), signature
        );
    }

    function _sign(uint256 signerPk_, bytes32 dataHash_) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk_, dataHash_);
        return abi.encodePacked(r, s, v);
    }

    modifier prank(address executor_) {
        vm.startPrank(executor_);
        _;
        vm.stopPrank();
    }

    /// Increase block.number to allow edit of position
    modifier increaseBlockNumber() {
        _;
        vm.roll(block.number + 1);
    }

    modifier increaseSalt() {
        _;
        salt++;
    }
}
