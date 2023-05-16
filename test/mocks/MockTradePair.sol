// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "src/interfaces/ITradePair.sol";

contract MockTradePair is ITradePair {
    /// @notice The price feed to calculate asset to collateral amounts
    IPriceFeedAdapter public priceFeedAdapter = IPriceFeedAdapter(address(0));
    /// @notice The liquidity pool adapter that the funds will get borrowed from
    ILiquidityPoolAdapter public liquidityPoolAdapter = ILiquidityPoolAdapter(address(0));
    IERC20 public collateral;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    function initialize(string memory, IERC20Metadata, uint256, IPriceFeedAdapter, ILiquidityPoolAdapter) external {}
    /* ========== MOCK FUNCTIONS ========== */

    function setCollateral(IERC20 _collateral) external {
        collateral = _collateral;
    }

    function syncPositionFees() external {}

    /* ========== VIEW FUNCTIONS ========== */

    function name() external pure returns (string memory) {
        return "MockTradePair";
    }

    function positionIdsOf(address) external pure returns (uint256[] memory) {
        uint256[] memory positionIds = new uint256[](3);
        positionIds[0] = 111;
        positionIds[1] = 200;
        positionIds[2] = 333;
        return positionIds;
    }

    function getCurrentPrices() public pure returns (int256, int256) {
        return (int256(99), int256(101));
    }

    function detailsOfPosition(uint256) external pure returns (PositionDetails memory positionDetails) {}

    function setPriceFeedAdapter(IPriceFeedAdapter _priceFeedAdapter) external {
        priceFeedAdapter = _priceFeedAdapter;
    }

    function setLiquidityPoolAdapter(ILiquidityPoolAdapter _liquidityPoolAdapter) external {
        liquidityPoolAdapter = _liquidityPoolAdapter;
    }

    function userManager() external pure returns (IUserManager) {
        return IUserManager(address(0));
    }

    function feeManager() external pure returns (IFeeManager) {
        return IFeeManager(address(0));
    }

    function tradeManager() external pure returns (ITradeManager) {
        return ITradeManager(address(0));
    }

    function positionIsLiquidatable(uint256 positionId) public pure returns (bool) {
        if (positionId % 5 == 0) {
            return true;
        }
        return false;
    }

    function getCurrentFundingFeeRates() external pure returns (int256, int256) {
        return (0, 0);
    }

    function positionStats() external pure returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (0, 0, 0, 0, 0, 0);
    }

    function feeBuffer() external pure returns (int256, int256) {
        return (0, 250_000);
    }

    function positionIsShort(uint256) external pure returns (bool) {
        return false;
    }

    /* ========== GENERATED VIEW FUNCTIONS ========== */

    function feeIntegral() external pure returns (int256, int256, int256, int256, int256, int256, uint256) {
        return (0, 0, 0, 0, 0, 0, 0);
    }

    function liquidatorReward() external pure returns (uint256) {
        return 0;
    }

    function maxLeverage() external pure returns (uint128) {
        return 0;
    }

    function minLeverage() external pure returns (uint128) {
        return 0;
    }

    function minMargin() external pure returns (uint256) {
        return 0;
    }

    function volumeLimit() external pure returns (uint256) {
        return 0;
    }

    function totalSizeLimit() external pure returns (uint256) {
        return 0;
    }

    function overcollectedFees() external pure returns (int256) {
        return 0;
    }

    function positionIdToWhiteLabel(uint256) external pure returns (address) {
        return address(0);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function openPosition(address, uint256, uint256, bool, address) external pure returns (uint256 positionId) {
        return 0;
    }

    function closePosition(address, uint256) external {}

    function addMarginToPosition(address, uint256, uint256) external {}

    function removeMarginFromPosition(address, uint256, uint256) external {}

    function partiallyClosePosition(address, uint256, uint256) external {}

    function extendPosition(address, uint256, uint256, uint256) external {}

    function extendPositionToLeverage(address, uint256, uint256) external {}

    function liquidatePosition(address, uint256 positionId) external pure {
        require(positionIsLiquidatable(positionId), "Position is not liquidatable");
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function setBorrowFeeRate(int256) external {}

    function setMaxFundingFeeRate(int256) external {}

    function setMaxExcessRatio(int256) external {}

    function setLiquidatorReward(uint256) external {}

    function setMinLeverage(uint128) external {}

    function setMaxLeverage(uint128) external {}

    function setMinMargin(uint256) external {}

    function setVolumeLimit(uint256) external {}

    function setFeeBufferFactor(int256) external {}

    function setTotalSizeLimit(uint256) external {}
}
