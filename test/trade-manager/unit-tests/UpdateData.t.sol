// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "test/setup/WithMocks.t.sol";
import "test/setup/WithAlterationHelpers.t.sol";
import "src/interfaces/ITradePair.sol";
import "src/lib/PositionMaths.sol";
import "src/trade-manager/TradeManagerOrders.sol";
import "test/mocks/MockTradePair.sol";
import "test/mocks/MockUserManager.sol";
import "test/mocks/MockController.sol";
import "test/mocks/MockToken.sol";
import "test/setup/Constants.sol";
import "src/price-feed/UnlimitedPriceFeed.sol";

contract TradeManagerUpdateDataTest is Test, WithMocks, WithAlterationHelpers {
    TradeManagerOrders tradeManager;
    Constraints constraints = Constraints(1000 hours, 98, 100);
    UpdateData[] updateData;

    function setUp() public {
        tradeManager = new TradeManagerOrders(mockController, mockUserManager);
        mockTradePair.setCollateral(collateral);
    }

    function testUpdateData() public {
        // ARRANGE
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        PriceData memory priceData = PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 101);

        bytes32 priceDataHash = _hashPriceDataUpdate(address(mockPriceFeed), priceData);
        bytes memory signature = _sign(signerPk, priceDataHash);

        bytes memory data = _encodeUpdateData(signature, signer, priceData);
        updateData.push(UpdateData(address(mockPriceFeed), data));

        PartiallyClosePositionParams memory params =
            PartiallyClosePositionParams({tradePair: address(mockTradePair), positionId: 111, proportion: 500_000});

        PartiallyClosePositionOrder memory partiallyClosePositionOrder =
            PartiallyClosePositionOrder(params, constraints, 0, 0);

        bytes32 orderHash = tradeManager.hashPartiallyClosePositionOrder(partiallyClosePositionOrder);
        bytes memory orderSignature = _sign(ALICE_PK, orderHash);

        // EXPECT
        vm.expectCall(address(mockPriceFeed), abi.encodeWithSelector(IUpdatable.update.selector, data));

        // ACT
        tradeManager.partiallyClosePositionViaSignature(partiallyClosePositionOrder, updateData, ALICE, orderSignature);
    }

    function testUpdateDataOnlyOnUpdatable() public {
        // ARRANGE
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        PriceData memory priceData = PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 101);

        bytes32 priceDataHash = _hashPriceDataUpdate(address(mockPriceFeed), priceData);
        bytes memory signature = _sign(signerPk, priceDataHash);

        bytes memory data = _encodeUpdateData(signature, signer, priceData);
        updateData.push(UpdateData(address(mockPriceFeed), data));

        PartiallyClosePositionParams memory params =
            PartiallyClosePositionParams({tradePair: address(mockTradePair), positionId: 111, proportion: 500_000});

        PartiallyClosePositionOrder memory partiallyClosePositionOrder =
            PartiallyClosePositionOrder(params, constraints, 0, 0);

        bytes32 orderHash = tradeManager.hashPartiallyClosePositionOrder(partiallyClosePositionOrder);
        bytes memory orderSignature = _sign(signerPk, orderHash);

        vm.mockCall(
            address(mockController),
            abi.encodeWithSelector(IController.isUpdatable.selector, address(mockPriceFeed)),
            abi.encode(false)
        );

        // ACT
        vm.expectRevert("TradeManager::_updateContracts: Contract not updatable");
        tradeManager.partiallyClosePositionViaSignature(partiallyClosePositionOrder, updateData, signer, orderSignature);
    }

    function testTotalVolumeLimitOfTradePair() public {
        // ARRANGE
        vm.mockCall(
            address(mockTradePair), abi.encodeWithSelector(ITradePair.totalVolumeLimit.selector), abi.encode(123)
        );

        // ASSERT
        assertEq(tradeManager.totalVolumeLimitOfTradePair(address(mockTradePair)), 123);
    }

    function testDeadlinePassed() public {
        // ARRANGE

        ExtendPositionToLeverageParams memory params = ExtendPositionToLeverageParams({
            tradePair: address(mockTradePair),
            positionId: 111,
            targetLeverage: 500_000
        });

        ExtendPositionToLeverageOrder memory extendPositionToLeverageOrder =
            ExtendPositionToLeverageOrder(params, constraints, 0, 0);

        bytes32 orderHash = tradeManager.hashExtendPositionToLeverageOrder(extendPositionToLeverageOrder);
        bytes memory orderSignature = _sign(ALICE_PK, orderHash);

        vm.warp(1001 hours);

        // ACT
        vm.expectRevert("TradeManager::_verifyConstraints: Deadline passed");
        tradeManager.extendPositionToLeverageViaSignature(
            extendPositionToLeverageOrder, updateData, ALICE, orderSignature
        );
    }

    /* ========== HELPER FUNCTIONS ========== */

    function _hashPriceDataUpdate(address priceFeedAddress, PriceData memory _priceData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(_encodePriceDataWithAddress(priceFeedAddress, _priceData));
    }

    function _encodePriceDataWithAddress(address priceFeedAddress, PriceData memory _priceData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(priceFeedAddress, _priceData);
    }

    function _encodePriceData(PriceData memory _priceData) internal pure returns (bytes memory) {
        return abi.encode(_priceData);
    }

    function _encodeUpdateData(bytes memory signature, address signer, PriceData memory _priceData)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(signature, abi.encode(signer), _encodePriceData(_priceData));
    }
}
