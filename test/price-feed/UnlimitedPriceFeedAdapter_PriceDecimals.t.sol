// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "src/price-feed/ChainlinkUsdPriceFeed.sol";
import "src/price-feed/UnlimitedPriceFeedAdapter.sol";
import "test/mocks/MockV3Aggregator.sol";
import "test/setup/WithMocks.t.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract UnlimitedPriceFeedAdapter_PriceDecimals_Test is Test, WithMocks {
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
            6,
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

        unlimitedPriceFeedAdapter.update(_getUpdateDataForPrice(1500 * int256(PRICE_MULTIPLIER)));
        vm.roll(2);
        vm.warp(2);
    }

    function test_ShouldUpdateWithCorrectPriceDecimals() public {
        int256 newPrice = 1500 * int256(10 ** PRICE_DECIMALS);

        unlimitedPriceFeedAdapter.update(_getUpdateDataForPrice(newPrice));

        assertEq(unlimitedPriceFeedAdapter.markPriceMin(), newPrice);
    }

    function test_ShouldFailOnUpdateWithWrongPriceDecimals() public {
        int256 wrongPrice = 1500 * int256(10 ** 8);

        vm.expectRevert("UnlimitedPriceFeedAdapter::_verifyNewPrice: Price deviation too high");
        unlimitedPriceFeedAdapter.update(_getUpdateDataForPrice(wrongPrice));
    }

    function test_CollateralToAsset() public {
        assertEq(unlimitedPriceFeedAdapter.collateralToAssetMax(1500 * 1e6), 1 * 1e18, "max");
        assertEq(unlimitedPriceFeedAdapter.collateralToAssetMin(1500 * 1e6), 1 * 1e18, "min");
    }

    function test_AssetToCollateral() public {
        assertEq(unlimitedPriceFeedAdapter.assetToCollateralMax(1 * 1e18), 1500 * 1e6, "max");
        assertEq(unlimitedPriceFeedAdapter.assetToCollateralMin(1 * 1e18), 1500 * 1e6, "min");
    }

    function test_FailsOnCollateralPriceDeviation() public {
        mockCollateralAggregator.updateAnswer(98 * 1e6);

        vm.expectRevert("UnlimitedPriceFeedAdapter::_verifyNewPrice: Price deviation too high");
        unlimitedPriceFeedAdapter.update(_getUpdateDataForPrice(1500 * int256(PRICE_MULTIPLIER)));
    }

    function test_UpdatesOnSmallCollateralPriceDeviation() public {
        mockCollateralAggregator.updateAnswer(9999 * 1e4);

        unlimitedPriceFeedAdapter.update(_getUpdateDataForPrice(1500 * int256(PRICE_MULTIPLIER)));
    }

    function testCollateralToUsd() public {
        mockCollateralAggregator.updateAnswer(99 * 1e6);
        assertEq(unlimitedPriceFeedAdapter.collateralToUsdMax(100 * 1e6), 99 * 1e8, "max");
        assertEq(unlimitedPriceFeedAdapter.collateralToUsdMin(100 * 1e6), 99 * 1e8, "min");
    }

    function testAssetToUsd() public {
        assertEq(unlimitedPriceFeedAdapter.assetToUsdMax(1 * 1e18), 1500 * 1e8, "max");
        assertEq(unlimitedPriceFeedAdapter.assetToUsdMin(1 * 1e18), 1500 * 1e8, "min");
    }

    /* ========== HELPERS ========== */

    function _getUpdateDataForPrice(int256 price_) internal view returns (bytes memory updateData) {
        uint256 signerPk = 999;
        address signer = vm.addr(signerPk);
        PriceData memory priceData = PriceData(uint32(block.timestamp), uint32(block.timestamp + 60), int192(price_));

        bytes32 priceDataHash = _hashPriceDataUpdate(address(unlimitedPriceFeedAdapter), priceData);
        bytes32 typedDataHash = ECDSA.toTypedDataHash(domainSeparator, priceDataHash);
        bytes memory signature = _sign(signerPk, typedDataHash);

        updateData = _encodeUpdateData(signature, signer, priceData);
    }

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
