// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "src/price-feed/UnlimitedPriceFeedAdapter.sol";
import "test/mocks/MockV3Aggregator.sol";
import "test/setup/WithMocks.t.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract UnlimitedPriceFeedAdapterTest is Test, WithMocks {
    MockV3Aggregator mockCollateralAggregator;
    MockV3Aggregator mockAssetAggregator;
    UnlimitedPriceFeedAdapter unlimitedPriceFeedAdapter;
    uint256 priceDecimals;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 domainSeparator;

    function setUp() public {
        mockCollateralAggregator = new MockV3Aggregator(8, 1 * 10 ** 8);
        mockAssetAggregator = new MockV3Aggregator(8, 1500 * 10 ** 8);

        address implementation = address(
            new UnlimitedPriceFeedAdapter(
            6, // 1% deviation
            mockController,
            mockUnlimitedOwner
            )
        );
        unlimitedPriceFeedAdapter = UnlimitedPriceFeedAdapter(_deployProxy(implementation, address(mockUnlimitedOwner)));

        vm.startPrank(UNLIMITED_OWNER);
        unlimitedPriceFeedAdapter.initialize(
            "TEST1/TEST2", FULL_PERCENT / 100, mockCollateralAggregator, mockAssetAggregator
        );
        vm.stopPrank();

        domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes("TEST1/TEST2")),
                keccak256(bytes("1")),
                block.chainid,
                address(unlimitedPriceFeedAdapter)
            )
        );
    }

    function testUpdatePriceData() public {
        // ARRANGE
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        PriceData memory priceData =
            PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), int192(int256(1500 * PRICE_MULTIPLIER)));

        bytes32 priceDataHash = _hashPriceDataUpdate(address(unlimitedPriceFeedAdapter), priceData);
        bytes32 typedDataHash = ECDSA.toTypedDataHash(domainSeparator, priceDataHash);
        bytes memory signature = _sign(signerPk, typedDataHash);

        bytes memory updateData = _encodeUpdateData(signature, signer, priceData);

        // ACT
        unlimitedPriceFeedAdapter.update(updateData);

        // ASSERT
        (uint32 createdOn, uint32 validTo, int192 price) = unlimitedPriceFeedAdapter.priceData();

        assertEq(priceData.createdOn, createdOn);
        assertEq(priceData.validTo, validTo);
        assertEq(priceData.price, price);
        assertEq(priceData.price, unlimitedPriceFeedAdapter.markPriceMin());
        assertEq(priceData.price, unlimitedPriceFeedAdapter.markPriceMax());
    }

    function testVerifySigner() public {
        // ARRANGE
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        PriceData memory priceData =
            PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), int192(int256(1500 * PRICE_MULTIPLIER)));

        bytes32 priceDataHash = _hashPriceDataUpdate(address(unlimitedPriceFeedAdapter), priceData);
        bytes memory signature = _sign(signerPk, priceDataHash);

        bytes memory updateData = _encodeUpdateData(signature, signer, priceData);

        vm.mockCall(address(mockController), abi.encodeWithSignature("isSigner(address)", signer), abi.encode(false));

        // ACT / ASSERT
        vm.expectRevert("UnlimitedPriceFeedUpdater::_verifySigner: Bad signer");
        unlimitedPriceFeedAdapter.update(updateData);
    }

    function testBadDataLength() public {
        // ARRANGE
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        PriceData memory priceData =
            PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), int192(int256(1500 * PRICE_MULTIPLIER)));

        bytes32 priceDataHash = _hashPriceDataUpdate(address(unlimitedPriceFeedAdapter), priceData);
        bytes memory signature = _sign(signerPk, priceDataHash);
        bytes memory badData = abi.encodePacked(signature, abi.encode(signer), _encodePriceData(priceData), "bad");

        // ACT
        vm.expectRevert("UnlimitedPriceFeedUpdater::update: Bad data length");
        unlimitedPriceFeedAdapter.update(badData);
    }

    function testRecentUpdate() public {
        // We have to increase devitation to 10% because we want to differentiate by price
        vm.prank(UNLIMITED_OWNER);
        unlimitedPriceFeedAdapter.updateMaxDeviation(FULL_PERCENT / 10);

        int192 secondPrice = int192(int192(int256(1510 * PRICE_MULTIPLIER)));

        /// ARRANGE
        bytes memory updateData1 = _getUpdateData(
            PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), int192(int256(1490 * PRICE_MULTIPLIER)))
        );
        bytes memory updateData2 =
            _getUpdateData(PriceData(uint32(block.timestamp + 10), uint32(block.timestamp + 70), secondPrice));

        // ACT
        unlimitedPriceFeedAdapter.update(updateData2);
        // This update should be ignored as it is outdated by the first one (updateData2)
        unlimitedPriceFeedAdapter.update(updateData1);

        // ASSERT
        assertEq(secondPrice, unlimitedPriceFeedAdapter.markPriceMin());
    }

    function testBadSignature() public {
        // ARRANGE
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        PriceData memory priceData1 =
            PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), int192(int256(1500 * PRICE_MULTIPLIER)));
        PriceData memory priceData2 = PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 1510 * 10 ** 8);

        bytes32 priceDataHash = _hashPriceDataUpdate(address(unlimitedPriceFeedAdapter), priceData1);
        bytes memory signature = _sign(signerPk, priceDataHash);

        bytes memory updateData = _encodeUpdateData(signature, signer, priceData2);

        // ACT
        vm.expectRevert("UnlimitedPriceFeedUpdater::update: Bad signature");
        unlimitedPriceFeedAdapter.update(updateData);
    }

    function testDeviation() public {
        /// ARRANGE
        bytes memory updateData1 = _getUpdateData(
            PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), int192(int256(1520 * PRICE_MULTIPLIER)))
        );
        bytes memory updateData2 = _getUpdateData(
            PriceData(
                uint32(block.timestamp + 10), uint32(block.timestamp + 70), int192(int256(1480 * PRICE_MULTIPLIER))
            )
        );

        // ACT
        vm.expectRevert("UnlimitedPriceFeedAdapter::_verifyNewPrice: Price deviation too high");
        unlimitedPriceFeedAdapter.update(updateData1);
        vm.expectRevert("UnlimitedPriceFeedAdapter::_verifyNewPrice: Price deviation too high");
        unlimitedPriceFeedAdapter.update(updateData2);

        vm.prank(UNLIMITED_OWNER);
        unlimitedPriceFeedAdapter.updateMaxDeviation(FULL_PERCENT / 10);

        // ASSERT
        unlimitedPriceFeedAdapter.update(updateData2);
        unlimitedPriceFeedAdapter.update(updateData1);
    }

    function testMaxUpdateDeviation() public {
        // ARRANGE
        vm.startPrank(UNLIMITED_OWNER);

        // ACT
        vm.expectRevert("UnlimitedPriceFeedAdapter::_updateMaxDeviation: Bad max deviation");
        unlimitedPriceFeedAdapter.updateMaxDeviation(4);
        vm.expectRevert("UnlimitedPriceFeedAdapter::_updateMaxDeviation: Bad max deviation");
        unlimitedPriceFeedAdapter.updateMaxDeviation(FULL_PERCENT + 1);
    }

    function testIsValidTo() public {
        // ARRANGE
        bytes memory updateData =
            _getUpdateData(PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 1000 ether));
        vm.warp(2 minutes);

        // ACT
        vm.expectRevert("UnlimitedPriceFeedUpdater::_verifyValidTo: Price is not valid");
        unlimitedPriceFeedAdapter.update(updateData);
    }

    function testCannotUpdateWrongPriceFeed() public {
        // ARRANGE
        bytes memory updateData =
            _getUpdateDataDifferentAddress(PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), 1000 ether));

        // ACT
        vm.expectRevert("UnlimitedPriceFeedUpdater::update: Bad signature");
        unlimitedPriceFeedAdapter.update(updateData);
    }

    /* ========== HELPERS ========== */

    function _getUpdateData(PriceData memory priceData) internal view returns (bytes memory) {
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        bytes32 priceDataHash = _hashPriceDataUpdate(address(unlimitedPriceFeedAdapter), priceData);
        bytes32 typedDataHash = ECDSA.toTypedDataHash(domainSeparator, priceDataHash);
        bytes memory signature = _sign(signerPk, typedDataHash);

        return _encodeUpdateData(signature, signer, priceData);
    }

    function _getUpdateDataDifferentAddress(PriceData memory priceData) internal view returns (bytes memory) {
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);

        bytes32 priceDataHash = _hashPriceDataUpdate(address(123), priceData);
        bytes32 typedDataHash = ECDSA.toTypedDataHash(domainSeparator, priceDataHash);
        bytes memory signature = _sign(signerPk, typedDataHash);

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

    function _deployProxy(address implementation, address admin) internal returns (address) {
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            admin,
            ""
        );
        return address(proxy);
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
