// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "src/price-feed/UnlimitedPriceFeed.sol";
import "test/mocks/MockV3Aggregator.sol";
import "test/setup/WithMocks.t.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract UnlimitedPriceFeedTest is Test, WithMocks {
    MockV3Aggregator mockAggregator;
    UnlimitedPriceFeed unlimitedPriceFeed;

    function setUp() public {
        mockAggregator = new MockV3Aggregator(18, 1000 ether);

        unlimitedPriceFeed = new UnlimitedPriceFeed(
            mockUnlimitedOwner,
            mockAggregator,
            mockController,
            10
        );
    }

    function testUpdatePriceData() public {
        // ARRANGE
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        PriceData memory priceData = PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 1001 ether);

        bytes32 priceDataHash = _hashPriceDataUpdate(address(unlimitedPriceFeed), priceData);
        bytes memory signature = _sign(signerPk, priceDataHash);

        bytes memory updateData = _encodeUpdateData(signature, signer, priceData);

        // ACT
        unlimitedPriceFeed.update(updateData);

        // ASSERT
        (uint32 createdOn, uint32 validTo, int192 price) = unlimitedPriceFeed.priceData();

        assertEq(priceData.createdOn, createdOn);
        assertEq(priceData.validTo, validTo);
        assertEq(priceData.price, price);
        assertEq(priceData.price, unlimitedPriceFeed.price());
    }

    function testVerifySigner() public {
        // ARRANGE
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        PriceData memory priceData = PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 1000 ether);

        bytes32 priceDataHash = _hashPriceDataUpdate(address(unlimitedPriceFeed), priceData);
        bytes memory signature = _sign(signerPk, priceDataHash);

        bytes memory updateData = _encodeUpdateData(signature, signer, priceData);

        vm.mockCall(address(mockController), abi.encodeWithSignature("isSigner(address)", signer), abi.encode(false));

        // ACT
        vm.expectRevert("UnlimitedPriceFeed::_verifySigner: Bad signer");
        unlimitedPriceFeed.update(updateData);

        // ASSERT
    }

    function testBadDataLength() public {
        // ARRANGE
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        PriceData memory priceData = PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 1000 ether);

        bytes32 priceDataHash = _hashPriceDataUpdate(address(unlimitedPriceFeed), priceData);
        bytes memory signature = _sign(signerPk, priceDataHash);
        bytes memory badData = abi.encodePacked(signature, abi.encode(signer), _encodePriceData(priceData), "bad");

        // ACT
        vm.expectRevert("UnlimitedPriceFeed::update: Bad data length");
        unlimitedPriceFeed.update(badData);
    }

    function testRecentUpdate() public {
        /// ARRANGE
        bytes memory updateData1 =
            _getUpdateData(PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 999 ether));
        bytes memory updateData2 =
            _getUpdateData(PriceData(uint32(block.timestamp + 10), uint32(block.timestamp + 70), 1001 ether));

        // ACT
        unlimitedPriceFeed.update(updateData2);
        unlimitedPriceFeed.update(updateData1);

        // ASSERT
        assertEq(1001 ether, unlimitedPriceFeed.price());
    }

    function testBadSignature() public {
        // ARRANGE
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        PriceData memory priceData1 = PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 1000 ether);
        PriceData memory priceData2 = PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 9999 ether);

        bytes32 priceDataHash = _hashPriceDataUpdate(address(unlimitedPriceFeed), priceData1);
        bytes memory signature = _sign(signerPk, priceDataHash);

        bytes memory updateData = _encodeUpdateData(signature, signer, priceData2);

        // ACT
        vm.expectRevert("UnlimitedPriceFeed::update: Bad signature");
        unlimitedPriceFeed.update(updateData);
    }

    function testDeviation() public {
        /// ARRANGE
        bytes memory updateData1 =
            _getUpdateData(PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 998 ether));
        bytes memory updateData2 =
            _getUpdateData(PriceData(uint32(block.timestamp + 10), uint32(block.timestamp + 70), 1002 ether));

        // ACT
        vm.expectRevert("UnlimitedPriceFeed::update: Price deviation too high");
        unlimitedPriceFeed.update(updateData2);
        vm.expectRevert("UnlimitedPriceFeed::update: Price deviation too high");
        unlimitedPriceFeed.update(updateData1);

        vm.prank(UNLIMITED_OWNER);
        unlimitedPriceFeed.updateMaxDeviation(20);

        // ASSERT
        unlimitedPriceFeed.update(updateData2);
        unlimitedPriceFeed.update(updateData1);
    }

    function testMaxUpdateDeviation() public {
        // ARRANGE
        vm.startPrank(UNLIMITED_OWNER);

        // ACT
        vm.expectRevert("UnlimitedPriceFeed::_updateMaxDeviation: Bad max deviation");
        unlimitedPriceFeed.updateMaxDeviation(5);
        vm.expectRevert("UnlimitedPriceFeed::_updateMaxDeviation: Bad max deviation");
        unlimitedPriceFeed.updateMaxDeviation(FULL_PERCENT + 1);
    }

    function testIsValidTo() public {
        // ARRANGE
        bytes memory updateData =
            _getUpdateData(PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 1000 ether));
        vm.warp(2 minutes);

        // ACT
        vm.expectRevert("UnlimitedPriceFeed::_verifyValidTo: Price is not valid");
        unlimitedPriceFeed.update(updateData);
    }

    function testCannotGetHacked() public {
        // ARRANGE
        bytes memory updateData =
            _getUpdateDataDifferentAddress(PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 1000 ether));

        // ACT
        vm.expectRevert("UnlimitedPriceFeed::update: Bad signature");
        unlimitedPriceFeed.update(updateData);
    }

    /* ========== HELPERS ========== */

    function _getUpdateData(PriceData memory priceData) internal view returns (bytes memory) {
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        bytes32 priceDataHash = _hashPriceDataUpdate(address(unlimitedPriceFeed), priceData);
        bytes memory signature = _sign(signerPk, priceDataHash);

        return _encodeUpdateData(signature, signer, priceData);
    }

    function _getUpdateDataDifferentAddress(PriceData memory priceData) internal pure returns (bytes memory) {
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        bytes32 priceDataHash = _hashPriceDataUpdate(address(123), priceData);
        bytes memory signature = _sign(signerPk, priceDataHash);

        return _encodeUpdateData(signature, signer, priceData);
    }

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

    function _sign(uint256 signerPk, bytes32 dataHash) private pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, dataHash);
        return abi.encodePacked(r, s, v);
    }
}
