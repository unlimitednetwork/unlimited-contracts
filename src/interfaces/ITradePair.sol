// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IFeeManager.sol";
import "./ILiquidityPoolAdapter.sol";
import "./IPriceFeedAdapter.sol";
import "./ITradeManager.sol";
import "./IUserManager.sol";

// =============================================================
//                           STRUCTS
// =============================================================

/**
 * @notice Struct with details of a position, returned by the detailsOfPosition function
 * @custom:member id the position id
 * @custom:member margin the margin of the position
 * @custom:member volume the entry volume of the position
 * @custom:member size the size of the position
 * @custom:member leverage the size of the position
 * @custom:member isShort bool if the position is short
 * @custom:member entryPrice The entry price of the position
 * @custom:member markPrice The (current) mark price of the position
 * @custom:member bankruptcyPrice the bankruptcy price of the position
 * @custom:member equity the current net equity of the position
 * @custom:member PnL the current net PnL of the position
 * @custom:member totalFeeAmount the totalFeeAmount of the position
 * @custom:member currentVolume the current volume of the position
 */
struct PositionDetails {
    uint256 id;
    uint256 margin;
    uint256 volume;
    uint256 assetAmount;
    uint256 leverage;
    bool isShort;
    int256 entryPrice;
    int256 markPrice;
    int256 bankruptcyPrice;
    int256 equity;
    int256 PnL;
    int256 totalFeeAmount;
    uint256 currentVolume;
}

/**
 * @notice Struct with a minimum and maximum price
 * @custom:member minPrice the minimum price
 * @custom:member maxPrice the maximum price
 */
struct PricePair {
    int256 minPrice;
    int256 maxPrice;
}

interface ITradePair {
    /* ========== ENUMS ========== */

    enum PositionAlterationType {
        partiallyClose,
        extend,
        extendToLeverage,
        removeMargin,
        addMargin
    }

    /* ========== EVENTS ========== */

    event OpenedPosition(address maker, uint256 id, uint256 margin, uint256 volume, uint256 size, bool isShort);

    event ClosedPosition(uint256 id, int256 closePrice);

    event LiquidatedPosition(uint256 indexed id, address indexed liquidator);

    event AlteredPosition(
        PositionAlterationType alterationType, uint256 id, uint256 netMargin, uint256 volume, uint256 size
    );

    event FeeOvercollected(int256 amount);

    event PayedOutCollateral(address maker, uint256 amount, uint256 positionId);

    event LiquidityGapWarning(uint256 amount);

    event RealizedPnL(address indexed maker, uint256 indexed positionId, int256 realizedPnL);

    /* ========== VIEW FUNCTIONS ========== */

    function name() external view returns (string memory);

    function collateral() external view returns (IERC20);

    function positionIdsOf(address maker) external view returns (uint256[] memory);

    function detailsOfPosition(uint256 positionId) external view returns (PositionDetails memory);

    function priceFeedAdapter() external view returns (IPriceFeedAdapter);

    function liquidityPoolAdapter() external view returns (ILiquidityPoolAdapter);

    function userManager() external view returns (IUserManager);

    function feeManager() external view returns (IFeeManager);

    function tradeManager() external view returns (ITradeManager);

    function positionIsLiquidatable(uint256 positionId) external view returns (bool);

    function getCurrentFundingFeeRates() external view returns (int256, int256);

    function getCurrentPrices() external view returns (int256, int256);

    function positionIsShort(uint256) external view returns (bool);

    /* ========== GENERATED VIEW FUNCTIONS ========== */

    function feeIntegral() external view returns (int256, int256, int256, int256, int256, int256, uint256);

    function liquidatorReward() external view returns (uint256);

    function maxLeverage() external view returns (uint128);

    function minLeverage() external view returns (uint128);

    function minMargin() external view returns (uint256);

    function volumeLimit() external view returns (uint256);

    function totalSizeLimit() external view returns (uint256);

    function positionStats() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    function overcollectedFees() external view returns (int256);

    function feeBuffer() external view returns (int256, int256);

    function positionIdToWhiteLabel(uint256) external view returns (address);

    /* ========== CORE FUNCTIONS - POSITIONS ========== */

    function openPosition(address maker, uint256 margin, uint256 leverage, bool isShort, address whitelabelAddress)
        external
        returns (uint256 positionId);

    function closePosition(address maker, uint256 positionId) external;

    function addMarginToPosition(address maker, uint256 positionId, uint256 margin) external;

    function removeMarginFromPosition(address maker, uint256 positionId, uint256 removedMargin) external;

    function partiallyClosePosition(address maker, uint256 positionId, uint256 proportion) external;

    function extendPosition(address maker, uint256 positionId, uint256 addedMargin, uint256 addedLeverage) external;

    function extendPositionToLeverage(address maker, uint256 positionId, uint256 targetLeverage) external;

    function liquidatePosition(address liquidator, uint256 positionId) external;

    /* ========== CORE FUNCTIONS - FEES ========== */

    function syncPositionFees() external;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function initialize(
        string memory name,
        IERC20Metadata collateral,
        uint256 assetDecimals,
        IPriceFeedAdapter priceFeedAdapter,
        ILiquidityPoolAdapter liquidityPoolAdapter
    ) external;

    function setBorrowFeeRate(int256 borrowFeeRate) external;

    function setMaxFundingFeeRate(int256 fee) external;

    function setMaxExcessRatio(int256 maxExcessRatio) external;

    function setLiquidatorReward(uint256 liquidatorReward) external;

    function setMinLeverage(uint128 minLeverage) external;

    function setMaxLeverage(uint128 maxLeverage) external;

    function setMinMargin(uint256 minMargin) external;

    function setVolumeLimit(uint256 volumeLimit) external;

    function setFeeBufferFactor(int256 feeBufferAmount) external;

    function setTotalSizeLimit(uint256 totalSizeLimit) external;
}
