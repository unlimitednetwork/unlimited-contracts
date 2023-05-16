// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ITradePair.sol";

interface ITradePairHelper {
    /* ========== VIEW FUNCTIONS ========== */

    function positionIdsOf(address maker, ITradePair[] calldata tradePairs)
        external
        view
        returns (uint256[][] memory positionInfos);

    function positionDetailsOf(address maker, ITradePair[] calldata tradePairs)
        external
        view
        returns (PositionDetails[][] memory positionDetails);

    function pricesOf(ITradePair[] calldata tradePairs) external view returns (PricePair[] memory prices);
}
