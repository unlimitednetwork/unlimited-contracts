// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./../../src/interfaces/IPriceFeedAdapter.sol";

/**
 * @title Simple Price Feed Adapter
 * @notice Aggregates prices from a price feed and offers exchange rates from asset to collateral.
 */
contract MockPriceFeedAdapter is IPriceFeedAdapter {
    /* ========== STATE VARIABLES ========== */

    string public name;

    // Price of asset in collateral
    int256 public markPriceMin = 2_000 * 1e6;
    int256 public markPriceMax = 2_000 * 1e6;

    uint256 public immutable ASSET_PRECISION;
    uint256 public assetDecimals = 18;
    uint256 public collateralDecimals = 6;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    /* ========== CONSTRUCTOR ========== */

    constructor(string memory _name, uint256 _assetDecimals, uint256 _collateralDecimals) {
        name = _name;
        assetDecimals = _assetDecimals;
        collateralDecimals = _collateralDecimals;
        ASSET_PRECISION = 10 ** _assetDecimals;
    }

    function initialize(IPriceFeedAggregator, IPriceFeedAggregator) external {}

    /* ========== ADMIN FUNCTIONS ========== */
    function addPriceFeed(IPriceFeed) external {}
    function removePriceFeed(uint256) external {}

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Returns asset equivalent to the collateral amount
     * @param collateralAmount the amount of collateral
     */
    function collateralToAsset(uint256 collateralAmount) external view returns (uint256) {
        return collateralAmount * ASSET_PRECISION / uint256(markPriceMin);
    }

    /**
     * @notice Returns collateral equivalent to the asset amount
     * @param assetAmount the amount of asset
     */
    function assetToCollateral(uint256 assetAmount) external view returns (uint256) {
        return assetAmount * uint256(markPriceMin) / ASSET_PRECISION;
    }

    function collateralToAssetMin(uint256 collateralAmount) external view returns (uint256) {
        return collateralAmount * ASSET_PRECISION / uint256(markPriceMax);
    }

    function collateralToAssetMax(uint256 collateralAmount) external view returns (uint256) {
        return collateralAmount * ASSET_PRECISION / uint256(markPriceMin);
    }

    function assetToCollateralMin(uint256 assetAmount) external view returns (uint256) {
        return assetAmount * uint256(markPriceMin) / ASSET_PRECISION;
    }

    function assetToCollateralMax(uint256 assetAmount) external view returns (uint256) {
        return assetAmount * uint256(markPriceMax) / ASSET_PRECISION;
    }

    function assetToUsdMin(uint256) external pure returns (uint256) {
        return 0;
    }

    function assetToUsdMax(uint256) external pure returns (uint256) {
        return 0;
    }

    function usdToAssetMin(uint256) external pure returns (uint256) {
        return 0;
    }

    function usdToAssetMax(uint256) external pure returns (uint256) {
        return 0;
    }

    function collateralToUsdMin(uint256 amount_) external pure returns (uint256) {
        return amount_ * 1e2;
    }

    function collateralToUsdMax(uint256 amount_) external pure returns (uint256) {
        return amount_ * 1e2;
    }

    // NOTE: be vary of low value coins e.g. SHIB
    function setMarkPrices(int256 _markPriceMin, int256 _markPriceMax) external {
        markPriceMin = _markPriceMin;
        markPriceMax = _markPriceMax;
    }
}
