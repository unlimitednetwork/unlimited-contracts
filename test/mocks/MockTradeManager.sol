// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "src/interfaces/ITradeManager.sol";

contract MockTradeManager is ITradeManager {
    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}
    function openPosition(OpenPositionParams calldata, Constraints calldata, UpdateData[] calldata)
        external
        returns (uint256)
    {}

    function closePosition(ClosePositionParams calldata, Constraints calldata, UpdateData[] calldata) external {}

    function partiallyClosePosition(
        PartiallyClosePositionParams calldata params,
        Constraints calldata constraints,
        UpdateData[] calldata updateData
    ) public {}

    function removeMarginFromPosition(
        RemoveMarginFromPositionParams calldata params,
        Constraints calldata constraints,
        UpdateData[] calldata updateData
    ) public {}

    function addMarginToPosition(
        AddMarginToPositionParams calldata params,
        Constraints calldata constraints,
        UpdateData[] calldata updateData
    ) public {}

    function extendPosition(
        ExtendPositionParams calldata params,
        Constraints calldata constraints,
        UpdateData[] calldata updateData
    ) public {}

    function extendPositionToLeverage(
        ExtendPositionToLeverageParams calldata params,
        Constraints calldata constraints,
        UpdateData[] calldata updateData
    ) public {}

    function liquidatePosition(address _tradePair, uint256 _positionId, UpdateData[] calldata) public {}

    function batchLiquidatePositions(
        address[] calldata _tradePairs,
        uint256[][] calldata _positionIds,
        bool allowRevert,
        UpdateData[] calldata
    ) external returns (bool[][] memory didLiquidate) {}

    function detailsOfPosition(address _tradePair, uint256 _positionId)
        external
        view
        returns (PositionDetails memory positionDetails)
    {}

    function positionIsLiquidatable(address _tradePair, uint256 _positionId) public view returns (bool) {}

    function canLiquidatePositions(address[] calldata _tradePairs, uint256[][] calldata _positionIds)
        external
        view
        returns (bool[][] memory canLiquidate)
    {}

    function getCurrentFundingFeeRates(address _tradePair)
        public
        view
        returns (int256 longFundingFeeRate, int256 shortFundingFeeRate)
    {}

    function totalSizeLimitOfTradePair(address tradePair_) public view returns (uint256) {}
}
