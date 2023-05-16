// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../interfaces/IPriceFeedAdapter.sol";

/**
 * @title Simple Price Feed Adapter
 * @notice Aggregates prices from a price feed and offers exchange rates from asset to collateral.
 */
contract PriceFeedAdapter is IPriceFeedAdapter {
    /* ========== STATE VARIABLES ========== */

    /// @notice Price Feed Aggregator for the asset
    IPriceFeedAggregator immutable assetPriceFeedAggregator;
    /// @notice Price Feed Aggregator for the collateral
    IPriceFeedAggregator immutable collateralPriceFeedAggregator;

    string public override name;
    uint256 private immutable ASSET_MULTIPLIER;
    uint256 private immutable COLLATERAL_MULTIPLIER;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Constructs the PriceFeedAdapter contract.
     * @param name_ The name of the price feed adapter.
     * @param assetPriceFeedAggregator_ The address of the price feed aggregator for the asset.
     * @param collateralPriceFeedAggregator_ The address of the price feed aggregator for the collateral.
     * @param assetDecimals_ The decimals of the asset.
     * @param collateralDecimals_ The decimals of the collateral.
     */
    constructor(
        string memory name_,
        IPriceFeedAggregator assetPriceFeedAggregator_,
        IPriceFeedAggregator collateralPriceFeedAggregator_,
        uint256 assetDecimals_,
        uint256 collateralDecimals_
    ) {
        name = name_;
        assetPriceFeedAggregator = assetPriceFeedAggregator_;
        collateralPriceFeedAggregator = collateralPriceFeedAggregator_;
        ASSET_MULTIPLIER = 10 ** assetDecimals_;
        COLLATERAL_MULTIPLIER = 10 ** collateralDecimals_;
    }

    /* ============ ASSET - COLLATERAL CONVERSION ============ */

    /**
     * @notice Returns max asset equivalent to the collateral amount
     * @param collateralAmount_ the amount of collateral
     */
    function collateralToAssetMax(uint256 collateralAmount_) external view returns (uint256) {
        uint256 collateralInDenominator =
            collateralAmount_ * uint256(collateralPriceFeedAggregator.maxPrice()) / COLLATERAL_MULTIPLIER;
        return collateralInDenominator * ASSET_MULTIPLIER / uint256(assetPriceFeedAggregator.minPrice());
    }

    /**
     * @notice Returns min asset equivalent to the collateral amount
     * @param collateralAmount_ the amount of collateral
     */
    function collateralToAssetMin(uint256 collateralAmount_) external view returns (uint256) {
        uint256 collateralInDenominator =
            collateralAmount_ * uint256(collateralPriceFeedAggregator.minPrice()) / COLLATERAL_MULTIPLIER;
        return collateralInDenominator * ASSET_MULTIPLIER / uint256(assetPriceFeedAggregator.maxPrice());
    }

    /**
     * @notice Returns maximumim collateral equivalent to the asset amount
     * @param assetAmount_ the amount of asset
     */
    function assetToCollateralMax(uint256 assetAmount_) external view returns (uint256) {
        uint256 assetInDenominator = assetAmount_ * uint256(assetPriceFeedAggregator.maxPrice()) / ASSET_MULTIPLIER;
        return assetInDenominator * COLLATERAL_MULTIPLIER / uint256(collateralPriceFeedAggregator.minPrice());
    }

    /**
     * @notice Returns minimum collateral equivalent to the asset amount
     * @param assetAmount_ the amount of asset
     */
    function assetToCollateralMin(uint256 assetAmount_) external view returns (uint256) {
        uint256 assetInDenominator = assetAmount_ * uint256(assetPriceFeedAggregator.minPrice()) / ASSET_MULTIPLIER;
        return assetInDenominator * COLLATERAL_MULTIPLIER / uint256(collateralPriceFeedAggregator.maxPrice());
    }

    /* ============ USD Conversion ============ */

    /**
     * @notice Returns the minimum usd equivalent to the asset amount
     * @dev The minimum collateral amount gets returned. It takes into accounts the minimum price.
     * @param assetAmount_ the amount of asset
     * @return the amount of usd
     */
    function assetToUsdMin(uint256 assetAmount_) external view returns (uint256) {
        return assetAmount_ * uint256(assetPriceFeedAggregator.minPrice()) / ASSET_MULTIPLIER;
    }

    /**
     * @notice Returns the maximum usd equivalent to the asset amount
     * @dev The maximum collateral amount gets returned. It takes into accounts the maximum price.
     * @param assetAmount_ the amount of asset
     * @return the amount of usd
     */
    function assetToUsdMax(uint256 assetAmount_) external view returns (uint256) {
        return assetAmount_ * uint256(assetPriceFeedAggregator.maxPrice()) / ASSET_MULTIPLIER;
    }

    /**
     * @notice Returns the minimum usd equivalent to the collateral amount
     * @dev The minimum collateral amount gets returned. It takes into accounts the minimum price.
     * @param collateralAmount_ the amount of collateral
     * @return the amount of usd
     */
    function collateralToUsdMin(uint256 collateralAmount_) external view returns (uint256) {
        return collateralAmount_ * uint256(collateralPriceFeedAggregator.minPrice()) / COLLATERAL_MULTIPLIER;
    }

    /**
     * @notice Returns the maximum usd equivalent to the collateral amount
     * @dev The maximum collateral amount gets returned. It takes into accounts the maximum price.
     * @param collateralAmount_ the amount of collateral
     * @return the amount of usd
     */
    function collateralToUsdMax(uint256 collateralAmount_) external view returns (uint256) {
        return collateralAmount_ * uint256(collateralPriceFeedAggregator.maxPrice()) / COLLATERAL_MULTIPLIER;
    }

    /* ============ PRICE ============ */

    /**
     * @notice Returns the max price of the asset in the collateral
     * @dev Takes into account the maximum price of the asset and the minimum price of the collateral
     */
    function markPriceMax() external view returns (int256) {
        return assetPriceFeedAggregator.maxPrice() * int256(COLLATERAL_MULTIPLIER)
            / collateralPriceFeedAggregator.minPrice();
    }

    /**
     * @notice Returns the min price of the asset in the collateral
     * @dev Takes into account the minimum price of the asset and the maximum price of the collateral
     */
    function markPriceMin() external view returns (int256) {
        return assetPriceFeedAggregator.minPrice() * int256(COLLATERAL_MULTIPLIER)
            / collateralPriceFeedAggregator.maxPrice();
    }
}
