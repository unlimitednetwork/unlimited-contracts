// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../interfaces/ITradePair.sol";
import "../interfaces/ITradePairHelper.sol";

contract TradePairHelper is ITradePairHelper {
    /**
     * @notice Returns all position ids of a maker
     * @param maker_ The maker to get the position ids of
     * @param tradePairs_ The TradePairs to get the position ids of
     * @return positionIds All position ids of the maker
     */
    function positionIdsOf(address maker_, ITradePair[] calldata tradePairs_)
        external
        view
        returns (uint256[][] memory positionIds)
    {
        positionIds = new uint256[][](tradePairs_.length);
        for (uint256 i = 0; i < tradePairs_.length; i++) {
            positionIds[i] = tradePairs_[i].positionIdsOf(maker_);
        }
    }

    /**
     * @notice Returns all PositionDetails of a maker
     * @param maker_ The maker to get the PositionDetails of
     * @param tradePairs_ The TradePairs to get the PositionDetails of
     * @return positionDetails All PositionDetails of the maker
     */
    function positionDetailsOf(address maker_, ITradePair[] calldata tradePairs_)
        external
        view
        returns (PositionDetails[][] memory positionDetails)
    {
        positionDetails = new PositionDetails[][](tradePairs_.length);
        for (uint256 i = 0; i < tradePairs_.length; i++) {
            uint256[] memory positionIds = tradePairs_[i].positionIdsOf(maker_);
            positionDetails[i] = new PositionDetails[](positionIds.length);
            for (uint256 j = 0; j < positionIds.length; j++) {
                positionDetails[i][j] = tradePairs_[i].detailsOfPosition(positionIds[j]);
            }
        }
    }

    /**
     * @notice Returns the current prices (min and max) of the given TradePairs
     * @param tradePairs_ The TradePairs to get the current prices of
     * @return prices PricePairy[] of min and max prices
     */
    function pricesOf(ITradePair[] calldata tradePairs_) external view override returns (PricePair[] memory prices) {
        prices = new PricePair[](tradePairs_.length);
        for (uint256 i = 0; i < tradePairs_.length; i++) {
            (int256 minPrice, int256 maxPrice) = tradePairs_[i].getCurrentPrices();

            prices[i] = PricePair(minPrice, maxPrice);
        }
    }
}
