// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IFeeManager.sol";
import "../interfaces/ILiquidityPoolAdapter.sol";
import "../interfaces/IPriceFeedAdapter.sol";
import "../interfaces/ITradeManager.sol";
import "../interfaces/ITradePair.sol";
import "../interfaces/IUserManager.sol";
import "../shared/Constants.sol";
import "../shared/UnlimitedOwnable.sol";
import "../lib/FeeBuffer.sol";
import "../lib/FeeIntegral.sol";
import "../lib/PositionMaths.sol";
import "../lib/PositionStats.sol";

contract TradePair is ITradePair, UnlimitedOwnable, Initializable {
    using SafeERC20 for IERC20;
    using FeeIntegralLib for FeeIntegral;
    using FeeBufferLib for FeeBuffer;
    using PositionMaths for Position;
    using PositionStatsLib for PositionStats;

    /* ========== CONSTANTS ========== */

    uint256 private constant SURPLUS_MULTIPLIER = 1_000_000; // 1e6
    uint256 private constant BPS_MULTIPLIER = 100_00; // 1e4

    uint256 private constant MIN_LEVERAGE = 11 * LEVERAGE_MULTIPLIER / 10;
    uint256 private constant MAX_LEVERAGE = 100 * LEVERAGE_MULTIPLIER;

    uint256 private constant USD_TRIM = 10 ** 8;

    enum PositionAlteration {
        partialClose,
        partiallyCloseToLeverage,
        extend,
        extendToLeverage,
        removeMargin,
        addMargin
    }

    /* ========== SYSTEM SMART CONTRACTS ========== */

    /// @notice Trade manager that manages trades.
    ITradeManager public immutable tradeManager;

    /// @notice manages fees per user
    IUserManager public immutable userManager;

    /// @notice Fee Manager that collects and distributes fees
    IFeeManager public immutable feeManager;

    // =============================================================
    //                            STORAGE
    // =============================================================

    /// @notice The price feed to calculate asset to collateral amounts
    IPriceFeedAdapter public priceFeedAdapter;

    /// @notice The liquidity pool adapter that the funds will get borrowed from
    ILiquidityPoolAdapter public liquidityPoolAdapter;

    /// @notice The token that is used as a collateral
    IERC20 public collateral;

    /* ========== PARAMETERS ========== */

    /// @notice The name of this trade pair
    string public name;

    /// @notice Decimals of the asset
    uint256 public assetDecimals;

    /* ============ INTERNAL SETTINGS ========== */

    /// @notice Minimum Leverage
    uint128 public minLeverage;

    /// @notice Maximum Leverage
    uint128 public maxLeverage;

    /// @notice Minimum margin
    uint256 public minMargin;

    /// @notice Maximum Volume a position can have
    uint256 public volumeLimit;

    /// @notice Limit for the total size of all positions
    uint256 public totalSizeLimit;

    /// @notice Fee to hold a loan for one hour in relative terms
    uint256 public baseFundingFee = 100_000_000_000; // 0.1% (/FEE_MULTIPLIER)

    /// @notice Maximum value of the surplus / balance fee
    uint256 public maxSurplusFee = 100_000_000_000; // 0.1% (/FEE_MULTIPLIER)

    /// @notice The Threshold of the long/short surplus at which the max surplus fee kicks in
    uint256 public maxSurplus = 2_000_000; // (/SURPLUS_MULTIPLIER)

    /// @notice reward for liquidator
    uint256 public liquidatorReward;

    /* ========== STATE VARIABLES ========== */

    /// @notice The positions of this tradepair
    mapping(uint256 => Position) positions;

    /// @notice Maps position id to the white label address that opened a position
    /// @dev White label recieves part of the open and close position fees collected
    mapping(uint256 => address) public positionIdToWhiteLabel;

    /// @notice position ids of each user
    mapping(address => uint256[]) public userToPositionIds;

    /// @notice increasing counter for the next position id
    uint256 public nextId = 0;

    /// @notice Keeps track of total amounts of positions
    PositionStats public positionStats;

    /// @notice Calculates the fee integrals
    FeeIntegral public feeIntegral;

    /// @notice Keeps track of the fee buffer
    FeeBuffer public feeBuffer;

    /// @notice Amount of overcollected fees
    int256 public overcollectedFees;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Constructs the TradePair contract
     * @param unlimitedOwner_ The Unlimited Owner constract
     * @param tradeManager_ The TradeManager contract
     * @param userManager_ The UserManager contract
     * @param feeManager_ The FeeManager contract
     */
    constructor(
        IUnlimitedOwner unlimitedOwner_,
        ITradeManager tradeManager_,
        IUserManager userManager_,
        IFeeManager feeManager_
    ) UnlimitedOwnable(unlimitedOwner_) {
        tradeManager = tradeManager_;
        userManager = userManager_;
        feeManager = feeManager_;
    }

    /**
     * @notice Initializes state variables
     * @param name_ The name of this trade pair
     * @param collateral_ the collateral ERC20 contract
     * @param assetDecimals_ the decimals of the asset
     * @param priceFeedAdapter_ The price feed adapter
     * @param liquidityPoolAdapter_ The liquidity pool adapter
     */
    function initialize(
        string calldata name_,
        IERC20Metadata collateral_,
        uint256 assetDecimals_,
        IPriceFeedAdapter priceFeedAdapter_,
        ILiquidityPoolAdapter liquidityPoolAdapter_
    ) external onlyOwner initializer {
        name = name_;
        collateral = collateral_;
        assetDecimals = assetDecimals_;
        priceFeedAdapter = priceFeedAdapter_;
        liquidityPoolAdapter = liquidityPoolAdapter_;
    }

    /* ========== CORE FUNCTIONS - POSITIONS ========== */

    /**
     * @notice opens a position
     * @param maker_ owner of the position
     * @param margin_ the amount of collateral used as a margin
     * @param leverage_ the target leverage, should respect LEVERAGE_MULTIPLIER
     * @param isShort_ bool if the position is a short position
     */
    function openPosition(address maker_, uint256 margin_, uint256 leverage_, bool isShort_, address whitelabelAddress)
        external
        verifyLeverage(leverage_)
        onlyTradeManager
        syncFeesBefore
        checkSizeLimitAfter
        returns (uint256)
    {
        if (whitelabelAddress != address(0)) {
            positionIdToWhiteLabel[nextId] = whitelabelAddress;
        }

        return _openPosition(maker_, margin_, leverage_, isShort_);
    }

    /**
     * @dev Should have received margin from TradeManager
     */
    function _openPosition(address maker_, uint256 margin_, uint256 leverage_, bool isShort_)
        private
        returns (uint256)
    {
        require(margin_ >= minMargin, "TradePair::_openPosition: margin must be above or equal min margin");

        uint256 id = nextId;
        nextId++;

        margin_ = _deductAndTransferOpenFee(maker_, margin_, leverage_, id);

        uint256 volume = (margin_ * leverage_) / LEVERAGE_MULTIPLIER;
        require(volume <= volumeLimit, "TradePair::_openPosition: borrow limit reached");
        _registerUserVolume(maker_, volume);

        uint256 assetAmount;
        if (isShort_) {
            assetAmount = priceFeedAdapter.collateralToAssetMax(volume);
        } else {
            assetAmount = priceFeedAdapter.collateralToAssetMin(volume);
        }

        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(isShort_);

        positions[id] = Position({
            margin: margin_,
            volume: volume,
            assetAmount: assetAmount,
            pastBorrowFeeIntegral: currentBorrowFeeIntegral,
            lastBorrowFeeAmount: 0,
            pastFundingFeeIntegral: currentFundingFeeIntegral,
            lastFundingFeeAmount: 0,
            lastFeeCalculationAt: uint48(block.timestamp),
            openedAt: uint48(block.timestamp),
            isShort: isShort_,
            owner: maker_,
            assetDecimals: uint16(assetDecimals),
            lastAlterationBlock: uint40(block.number)
        });

        userToPositionIds[maker_].push(id);

        positionStats.addTotalCount(margin_, volume, assetAmount, isShort_);

        emit OpenedPosition(maker_, id, margin_, volume, assetAmount, isShort_);

        return id;
    }

    /**
     * @notice Closes A position
     * @param maker_ address of the maker of this position.
     * @param positionId_ the position id.
     */
    function closePosition(address maker_, uint256 positionId_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        syncFeesBefore
    {
        _verifyAndUpdateLastAlterationBlock(positionId_);
        _closePosition(positionId_);
    }

    function _closePosition(uint256 positionId_) private {
        Position storage position = positions[positionId_];

        // Clear Buffer
        (uint256 remainingMargin, uint256 remainingBufferFee, uint256 requestLoss) = _clearBuffer(position, false);

        // Get the payout to the maker
        uint256 payoutToMaker = _getPayoutToMaker(position);

        // update aggregated values
        positionStats.removeTotalCount(position.margin, position.volume, position.assetAmount, position.isShort);

        int256 protocolPnL = int256(remainingMargin) - int256(payoutToMaker) - int256(requestLoss);

        // fee manager receives the remaining fees
        _depositBorrowFees(remainingBufferFee);

        uint256 payout = _registerProtocolPnL(protocolPnL);

        if (payoutToMaker > payout + remainingMargin) {
            payoutToMaker = payout + remainingMargin;
        }

        if (payoutToMaker > 0) {
            _payoutToMaker(position.owner, int256(payoutToMaker), positionId_);
        }

        emit ClosedPosition(positionId_);

        // Finally delete position
        _deletePosition(positionId_);
    }

    /**
     * @notice Partially closes a position on a trade pair.
     * @param maker_ owner of the position
     * @param positionId_ id of the position
     * @param proportion_ the proportion of the position that should be closed, should respect PERCENTAGE_MULTIPLIER
     */
    function partiallyClosePosition(address maker_, uint256 positionId_, uint256 proportion_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        syncFeesBefore
        updatePositionFees(positionId_)
        onlyValidAlteration(positionId_)
    {
        _partiallyClosePosition(maker_, positionId_, proportion_);
    }

    function _partiallyClosePosition(address maker_, uint256 positionId_, uint256 proportion_) private {
        Position storage position = positions[positionId_];

        int256 payoutToMaker;

        // positionDelta saves the changes in position margin, volume and size.
        // First it gets assigned the old values, than the new values are subtracted.
        PositionDetails memory positionDelta;

        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position.isShort);

        // Assign old values to positionDelta
        positionDelta.margin = position.margin;
        positionDelta.volume = position.volume;
        positionDelta.assetAmount = position.assetAmount;
        positionDelta.PnL = position.currentNetPnL(
            _getCurrentPrice(position.isShort, true), currentBorrowFeeIntegral, currentFundingFeeIntegral
        );

        // partially close in storage
        payoutToMaker = position.partiallyClose(_getCurrentPrice(position.isShort, true), proportion_);

        // Subtract new values from positionDelta. This way positionDelta contains the changes in position margin, volume and size.
        positionDelta.margin -= position.margin;
        positionDelta.volume -= position.volume;
        positionDelta.assetAmount -= position.assetAmount;
        positionDelta.PnL -= position.currentNetPnL(
            _getCurrentPrice(position.isShort, true), currentBorrowFeeIntegral, currentFundingFeeIntegral
        );

        uint256 payout = _registerProtocolPnL(-positionDelta.PnL);

        if (payoutToMaker > int256(payout + positionDelta.margin)) {
            payoutToMaker = int256(payout + positionDelta.margin);
        }

        if (payoutToMaker > 0) {
            _payoutToMaker(maker_, int256(payoutToMaker), positionId_);
        }

        // Use positionDelta to update positionStats
        positionStats.removeTotalCount(
            positionDelta.margin, positionDelta.volume, positionDelta.assetAmount, position.isShort
        );

        emit AlteredPosition(
            PositionAlterationType.partiallyClose,
            positionId_,
            position.lastNetMargin(),
            position.volume,
            position.assetAmount
            );
    }

    /**
     * @notice Extends position with margin and leverage. Leverage determins added loan. New margin and loan get added
     * to the existing position.
     * @param maker_ Address of the position maker.
     * @param positionId_ ID of the position.
     * @param addedMargin_ Margin added to the position.
     * @param addedLeverage_ Denoted in LEVERAGE_MULTIPLIER.
     */
    function extendPosition(address maker_, uint256 positionId_, uint256 addedMargin_, uint256 addedLeverage_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        verifyLeverage(addedLeverage_)
        syncFeesBefore
        updatePositionFees(positionId_)
        onlyValidAlteration(positionId_)
        checkSizeLimitAfter
    {
        _extendPosition(maker_, positionId_, addedMargin_, addedLeverage_);
    }

    /**
     * @notice Should have received margin from TradeManager
     * @dev extendPosition simply "adds" a "new" position on top of the existing position. The two positions get merged.
     */
    function _extendPosition(address maker_, uint256 positionId_, uint256 addedMargin_, uint256 addedLeverage_)
        private
        verifyLeverage(addedLeverage_)
    {
        Position storage position = positions[positionId_];

        addedMargin_ = _deductAndTransferOpenFee(maker_, addedMargin_, addedLeverage_, positionId_);

        uint256 addedVolume = addedMargin_ * addedLeverage_ / LEVERAGE_MULTIPLIER;
        _registerUserVolume(maker_, addedVolume);

        uint256 addedSize;
        if (position.isShort) {
            addedSize = priceFeedAdapter.collateralToAssetMax(addedVolume);
        } else {
            addedSize = priceFeedAdapter.collateralToAssetMin(addedVolume);
        }

        // Update tally.
        positionStats.addTotalCount(addedMargin_, addedVolume, addedSize, position.isShort);

        // Update position.
        position.extend(addedMargin_, addedSize, addedVolume);

        emit AlteredPosition(
            PositionAlterationType.extend, positionId_, position.lastNetMargin(), position.volume, position.assetAmount
            );
    }

    /**
     * @notice Extends position with loan to target leverage.
     * @param maker_ Address of the position maker.
     * @param positionId_ ID of the position.
     * @param targetLeverage_ Target leverage in respect to LEVERAGE_MULTIPLIER.
     */
    function extendPositionToLeverage(address maker_, uint256 positionId_, uint256 targetLeverage_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        syncFeesBefore
        updatePositionFees(positionId_)
        onlyValidAlteration(positionId_)
        checkSizeLimitAfter
    {
        _extendPositionToLeverage(positionId_, targetLeverage_);
    }

    function _extendPositionToLeverage(uint256 positionId_, uint256 targetLeverage_) private {
        Position storage position = positions[positionId_];

        int256 currentPrice = _getCurrentPrice(position.isShort, false);

        // Old values are needed to calculate the differences of aggregated values
        uint256 old_margin = position.margin;
        uint256 old_volume = position.volume;
        uint256 old_size = position.assetAmount;

        // The user does not deposit fee with this transaction, so the fee is taken from the margin of the position
        position.margin = _deductAndTransferExtendToLeverageFee(
            position.owner, position.margin, position.currentVolume(currentPrice), targetLeverage_, positionId_
        );

        // update position in storage
        position.extendToLeverage(currentPrice, targetLeverage_);

        // update aggregated values
        _registerUserVolume(position.owner, position.volume - old_volume);
        positionStats.addTotalCount(0, position.volume - old_volume, position.assetAmount - old_size, position.isShort);

        positionStats.removeTotalCount(old_margin - position.margin, 0, 0, position.isShort);

        emit AlteredPosition(
            PositionAlterationType.extendToLeverage,
            positionId_,
            position.lastNetMargin(),
            position.volume,
            position.assetAmount
            );
    }

    /**
     * @notice Removes margin from a position
     * @param maker_ owner of the position
     * @param positionId_ id of the position
     * @param removedMargin_ the margin to be removed
     */
    function removeMarginFromPosition(address maker_, uint256 positionId_, uint256 removedMargin_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        syncFeesBefore
        updatePositionFees(positionId_)
        onlyValidAlteration(positionId_)
    {
        _removeMarginFromPosition(maker_, positionId_, removedMargin_);
    }

    function _removeMarginFromPosition(address maker_, uint256 positionId_, uint256 removedMargin_) private {
        Position storage position = positions[positionId_];

        // update position in storage
        position.removeMargin(removedMargin_);

        // update aggregated values
        positionStats.removeTotalCount(removedMargin_, 0, 0, position.isShort);

        _payoutToMaker(maker_, int256(removedMargin_), positionId_);

        emit AlteredPosition(
            PositionAlterationType.removeMargin,
            positionId_,
            position.lastNetMargin(),
            position.volume,
            position.assetAmount
            );
    }

    /**
     * @notice Adds margin to a position
     * @param maker_ owner of the position
     * @param positionId_ id of the position
     * @param addedMargin_ the margin to be added
     */
    function addMarginToPosition(address maker_, uint256 positionId_, uint256 addedMargin_)
        external
        onlyTradeManager
        verifyOwner(maker_, positionId_)
        syncFeesBefore
        updatePositionFees(positionId_)
        onlyValidAlteration(positionId_)
    {
        _addMarginToPosition(maker_, positionId_, addedMargin_);
    }

    /**
     * @dev Should have received margin from TradeManager
     */
    function _addMarginToPosition(address maker_, uint256 positionId_, uint256 addedMargin_) private {
        Position storage position = positions[positionId_];

        addedMargin_ = _deductAndTransferOpenFee(maker_, addedMargin_, LEVERAGE_MULTIPLIER, positionId_);

        // change position in storage
        position.addMargin(addedMargin_);
        // update aggregated values
        positionStats.addTotalCount(addedMargin_, 0, 0, position.isShort);

        emit AlteredPosition(
            PositionAlterationType.addMargin,
            positionId_,
            position.lastNetMargin(),
            position.volume,
            position.assetAmount
            );
    }

    /**
     * @notice Liquidates position and sends liquidation reward to msg.sender
     * @param liquidator_ Address of the liquidator.
     * @param positionId_ position id
     */
    function liquidatePosition(address liquidator_, uint256 positionId_)
        external
        onlyTradeManager
        onlyLiquidatable(positionId_)
        syncFeesBefore
    {
        _verifyAndUpdateLastAlterationBlock(positionId_);
        _liquidatePosition(liquidator_, positionId_);
    }

    /**
     * @notice liquidates a position
     */
    function _liquidatePosition(address liquidator_, uint256 positionId_) private {
        Position storage position = positions[positionId_];

        // Clear Buffer
        (uint256 remainingMargin, uint256 remainingBufferFee, uint256 requestLoss) = _clearBuffer(position, true);

        // Get the payout to the maker
        uint256 payoutToMaker = _getPayoutToMaker(position);

        // Calculate the protocol PnL
        int256 protocolPnL = int256(remainingMargin) - int256(payoutToMaker) - int256(requestLoss);

        // Register the protocol PnL and receive a possible payout
        uint256 payout = _registerProtocolPnL(protocolPnL);

        // Calculate the available liquidity for this position's liquidation
        uint256 availableLiquidity = remainingBufferFee + payout + uint256(liquidatorReward);

        // Prio 1: Keep the request loss at TradePair, as this makes up the funding fee that pays the other positions
        if (availableLiquidity > requestLoss) {
            availableLiquidity -= requestLoss;
        } else {
            // If available liquidity is not enough to cover the requested loss,
            // emit a warning, because the liquidity pools are drained.
            requestLoss = availableLiquidity;
            emit LiquidityGapWarning(requestLoss);
            availableLiquidity = 0;
        }

        // Prio 2: Pay out the liquidator reward
        if (availableLiquidity > liquidatorReward) {
            _payOut(liquidator_, liquidatorReward);
            availableLiquidity -= liquidatorReward;
        } else {
            _payOut(liquidator_, availableLiquidity);
            availableLiquidity = 0;
        }

        // Prio 3: Pay out to the maker
        if (availableLiquidity > payoutToMaker) {
            _payoutToMaker(position.owner, int256(payoutToMaker), positionId_);
            availableLiquidity -= payoutToMaker;
        } else {
            _payoutToMaker(position.owner, int256(availableLiquidity), positionId_);
            availableLiquidity = 0;
        }

        // Prio 4: Pay out the buffered fee
        if (availableLiquidity > remainingBufferFee) {
            _depositBorrowFees(remainingBufferFee);
            availableLiquidity -= remainingBufferFee;
        } else {
            _depositBorrowFees(availableLiquidity);
            availableLiquidity = 0;
        }
        // Now, available liquity is zero

        // Remove position from total counts
        positionStats.removeTotalCount(position.margin, position.volume, position.assetAmount, position.isShort);

        // Delete Position
        _deletePosition(positionId_);
    }

    /* ========== HELPER FUNCTIONS ========= */

    /**
     * @notice Calculates outstanding borrow fees, transfers it to FeeManager and updates the fee integrals.
     * Funding fee stays at this TradePair as it is transfered virtually to the opposite positions ("long pays short").
     *
     * All positions' margins make up the trade pair's balance of which the fee is transfered from.
     * @dev This function is public to allow possible fee syncing in periods without trades.
     */
    function syncPositionFees() public {
        // The total amount of borrow fee is based on the entry volume of all positions
        // This is done to batch collect borrow fees for all open positions

        int256 elapsedBorrowFeeIntegral = feeIntegral.getElapsedBorrowFeeIntegral();

        if (elapsedBorrowFeeIntegral > 0) {
            uint256 totalVolume = positionStats.totalShortVolume + positionStats.totalLongVolume;

            int256 newBorrowFeeAmount = elapsedBorrowFeeIntegral * int256(totalVolume) / FEE_MULTIPLIER;
            // Fee Integrals get updated for funding fee.
            feeIntegral.update(positionStats.totalLongAssetAmount, positionStats.totalShortAssetAmount);

            // Reduce by the fee buffer
            // Buffer is used to prevent overrtaking the fees from the position
            uint256 reducedFeeAmount = feeBuffer.takeBufferFrom(uint256(newBorrowFeeAmount));

            // Transfer borrow fee to FeeManager
            _depositBorrowFees(reducedFeeAmount);
        }
    }

    /**
     * @dev Returns borrow and funding fee intagral for long or short position
     */
    function _getCurrentFeeIntegrals(bool isShort_) internal view returns (int256, int256) {
        // Funding fee integrals differ for short and long positions
        (int256 longFeeIntegral, int256 shortFeeIntegral) = feeIntegral.getCurrentFundingFeeIntegrals(
            positionStats.totalLongAssetAmount, positionStats.totalShortAssetAmount
        );
        int256 currentFundingFeeIntegral = isShort_ ? shortFeeIntegral : longFeeIntegral;

        // Borrow fee integrals are the same for short and long positions
        int256 currentBorrowFeeIntegral = feeIntegral.getCurrentBorrowFeeIntegral();

        // Return the current fee integrals
        return (currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    /**
     * @dev Deletes position entries from storage.
     */
    function _deletePosition(uint256 positionId_) internal {
        address maker = positions[positionId_].owner;
        uint256[] storage makerPositions = userToPositionIds[maker];
        for (uint256 i = 0; i < makerPositions.length; i++) {
            if (makerPositions[i] == positionId_) {
                makerPositions[i] = makerPositions[makerPositions.length - 1];
                makerPositions.pop();
                break;
            }
        }
        delete positions[positionId_];
    }

    /**
     * @notice Clears the fee buffer and returns the remaining margin, remaining buffer fee and request loss.
     * @param position_ The position to clear the buffer for.
     * @param isLiquidation_ Whether the buffer is cleared due to a liquidation. In this case, liquidatorReward is added to funding fee.
     * @return remainingMargin the _margin of the position after clearing the buffer and paying fees
     * @return remainingBuffer remaining amount that needs to be transferred to the fee manager
     * @return requestLoss the amount of loss that needs to be requested from the liquidity pool
     */
    function _clearBuffer(Position storage position_, bool isLiquidation_)
        private
        returns (uint256, uint256, uint256)
    {
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position_.isShort);

        uint256 additionalFee = isLiquidation_ ? liquidatorReward : 0;

        // Clear Buffer
        return feeBuffer.clearBuffer(
            position_.margin,
            position_.currentBorrowFeeAmount(currentBorrowFeeIntegral),
            position_.currentFundingFeeAmount(currentFundingFeeIntegral) + int256(additionalFee)
        );
    }

    /**
     * @notice Returns the payout to the maker of this position
     * @param position_ the position to calculate the payout for
     * @return the payout to the maker of this position
     */
    function _getPayoutToMaker(Position storage position_) private view returns (uint256) {
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position_.isShort);

        int256 netEquity = position_.currentNetEquity(
            _getCurrentPrice(position_.isShort, true), currentBorrowFeeIntegral, currentFundingFeeIntegral
        );
        return netEquity > 0 ? uint256(netEquity) : 0;
    }

    /**
     * @notice updates the fee of this position. Necessary before changing its volume.
     * @param positionId_ the id of the position
     */
    function _updatePositionFees(uint256 positionId_) internal {
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) =
            _getCurrentFeeIntegrals(positions[positionId_].isShort);

        positions[positionId_].updateFees(currentBorrowFeeIntegral, currentFundingFeeIntegral);
    }

    /**
     * @notice Registers profit or loss at liquidity pool adapter
     * @param protocolPnL_ Profit or loss of protocol
     * @return payout Payout received from the liquidity pool adapter
     */
    function _registerProtocolPnL(int256 protocolPnL_) internal returns (uint256 payout) {
        if (protocolPnL_ > 0) {
            // Profit
            collateral.safeTransfer(address(liquidityPoolAdapter), uint256(protocolPnL_));
            liquidityPoolAdapter.depositProfit(uint256(protocolPnL_));
        } else if (protocolPnL_ < 0) {
            // Loss
            payout = liquidityPoolAdapter.requestLossPayout(uint256(-protocolPnL_));
        }
        // if PnL == 0, nothing happens
    }

    /**
     * @notice Pays out amount to receiver. If balance does not suffice, registers loss.
     * @param receiver_ Address of receiver.
     * @param amount_ Amount to pay out.
     */
    function _payOut(address receiver_, uint256 amount_) internal {
        if (amount_ > collateral.balanceOf(address(this))) {
            liquidityPoolAdapter.requestLossPayout(amount_ - collateral.balanceOf(address(this)));
        }
        collateral.safeTransfer(receiver_, amount_);
    }

    /**
     * @dev Deducts fees from the given amount and pays the rest to maker
     */
    function _payoutToMaker(address maker_, int256 amount_, uint256 positionId_) private {
        if (amount_ > 0) {
            uint256 closePositionFee = feeManager.calculateUserCloseFeeAmount(maker_, uint256(amount_));
            _depositClosePositionFees(maker_, closePositionFee, positionId_);

            uint256 reducedAmount = uint256(amount_) - closePositionFee;

            collateral.safeTransfer(maker_, reducedAmount);

            emit PayedOutCollateral(maker_, reducedAmount, positionId_);
        }
    }

    /**
     * @notice Deducts open position fee for a given margin and leverage. Returns the margin after fee deduction.
     * @dev The fee is exactly [userFee] of the resulting volume.
     * @param margin_ The margin of the position.
     * @param leverage_ The leverage of the position.
     * @return marginAfterFee_ The margin after fee deduction.
     */
    function _deductAndTransferOpenFee(address maker_, uint256 margin_, uint256 leverage_, uint256 positionId_)
        internal
        returns (uint256 marginAfterFee_)
    {
        uint256 openPositionFee = feeManager.calculateUserOpenFeeAmount(maker_, margin_, leverage_);
        _depositOpenPositionFees(maker_, openPositionFee, positionId_);

        marginAfterFee_ = margin_ - openPositionFee;
    }

    /**
     * @notice Deducts open position fee for a given margin and leverage. Returns the margin after fee deduction.
     * @dev The fee is exactly [userFee] of the resulting volume.
     * @param maker_ The maker of the position.
     * @param margin_ The margin of the position.
     * @param volume_ The volume of the position.
     * @param targetLeverage_ The target leverage of the position.
     * @param positionId_ The id of the position.
     * @return marginAfterFee_ The margin after fee deduction.
     */
    function _deductAndTransferExtendToLeverageFee(
        address maker_,
        uint256 margin_,
        uint256 volume_,
        uint256 targetLeverage_,
        uint256 positionId_
    ) internal returns (uint256 marginAfterFee_) {
        uint256 openPositionFee =
            feeManager.calculateUserExtendToLeverageFeeAmount(maker_, margin_, volume_, targetLeverage_);
        _depositOpenPositionFees(maker_, openPositionFee, positionId_);

        marginAfterFee_ = margin_ - openPositionFee;
    }

    /**
     * @notice Registers user volume in USD.
     * @dev Trimms decimals from USD value.
     *
     * @param user_ User address.
     * @param volume_ Volume in collateral.
     */
    function _registerUserVolume(address user_, uint256 volume_) private {
        uint256 volumeUsd = priceFeedAdapter.collateralToUsdMin(volume_);

        uint40 volumeUsdTrimmed = uint40(volumeUsd / USD_TRIM);

        userManager.addUserVolume(user_, volumeUsdTrimmed);
    }

    /**
     * @dev Deposits the open position fees to the FeeManager.
     */
    function _depositOpenPositionFees(address user_, uint256 amount_, uint256 positionId_) private {
        _resetApprove(address(feeManager), amount_);
        feeManager.depositOpenFees(user_, address(collateral), amount_, positionIdToWhiteLabel[positionId_]);
    }

    /**
     * @dev Deposits the close position fees to the FeeManager.
     */
    function _depositClosePositionFees(address user_, uint256 amount_, uint256 positionId_) private {
        _resetApprove(address(feeManager), amount_);
        feeManager.depositCloseFees(user_, address(collateral), amount_, positionIdToWhiteLabel[positionId_]);
    }

    /**
     * @dev Deposits the borrow fees to the FeeManager
     */
    function _depositBorrowFees(uint256 amount_) private {
        if (amount_ > 0) {
            _resetApprove(address(feeManager), amount_);
            feeManager.depositBorrowFees(address(collateral), amount_);
        }
    }

    /**
     * @dev Sets the allowance on the collateral to 0.
     */
    function _resetApprove(address user_, uint256 amount_) private {
        if (collateral.allowance(address(this), user_) > 0) {
            collateral.safeApprove(user_, 0);
        }

        collateral.safeApprove(user_, amount_);
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */
    /**
     * @notice Calculates the current funding fee rates
     * @return longFundingFeeRate long funding fee rate
     * @return shortFundingFeeRate short funding fee rate
     */
    function getCurrentFundingFeeRates()
        external
        view
        returns (int256 longFundingFeeRate, int256 shortFundingFeeRate)
    {
        return feeIntegral.getCurrentFundingFeeRates(
            positionStats.totalLongAssetAmount, positionStats.totalShortAssetAmount
        );
    }

    /**
     * @notice Returns positionIds of a user/maker
     * @param maker_ Address of maker
     * @return positionIds of maker
     */
    function positionIdsOf(address maker_) external view returns (uint256[] memory) {
        return userToPositionIds[maker_];
    }

    /**
     * @notice returns the details of a position
     * @dev returns PositionDetails
     */
    function detailsOfPosition(uint256 positionId_) external view returns (PositionDetails memory) {
        Position storage position = positions[positionId_];
        require(position.exists(), "TradePair::detailsOfPosition: Position does not exist");

        // Fee integrals
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position.isShort);

        // Construnct position info
        PositionDetails memory positionDetails;
        positionDetails.id = positionId_;
        positionDetails.margin = position.currentNetMargin(currentBorrowFeeIntegral, currentFundingFeeIntegral);
        positionDetails.volume = position.volume;
        positionDetails.assetAmount = position.assetAmount;
        positionDetails.isShort = position.isShort;
        int256 currentPrice = _getCurrentPrice(position.isShort, true);
        positionDetails.leverage = position.currentNetLeverage(currentBorrowFeeIntegral, currentFundingFeeIntegral);
        positionDetails.volume = position.volume;
        positionDetails.currentVolume =
            position.currentValue(currentPrice) > 0 ? uint256(position.currentValue(currentPrice)) : 0;
        positionDetails.entryPrice = position.entryPrice();
        positionDetails.markPrice = currentPrice;
        positionDetails.bankruptcyPrice = position.bankruptcyPrice();
        positionDetails.totalFeeAmount =
            position.currentTotalFeeAmount(currentBorrowFeeIntegral, currentFundingFeeIntegral);
        positionDetails.PnL = position.currentNetPnL(currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral);
        positionDetails.equity =
            position.currentNetEquity(currentPrice, currentBorrowFeeIntegral, currentFundingFeeIntegral);
        return positionDetails;
    }

    /**
     * @notice Returns if a position is liquidatable
     * @param positionId_ the position id
     */
    function positionIsLiquidatable(uint256 positionId_) external view returns (bool) {
        return _positionIsLiquidatable(positionId_);
    }

    /**
     * @notice Returns if the position is short
     * @param positionId_ the position id
     * @return isShort_ true if the position is short
     */
    function positionIsShort(uint256 positionId_) external view returns (bool) {
        return positions[positionId_].isShort;
    }

    /**
     * @notice Returns the current min and max price
     */
    function getCurrentPrices() external view returns (int256, int256) {
        return (priceFeedAdapter.markPriceMin(), priceFeedAdapter.markPriceMax());
    }

    /**
     * @notice returns absolute maintenance margin
     * @dev Currently only the liquidator reward is the absolute maintenance margin, but this could change in the future
     * @return absoluteMaintenanceMargin
     */
    function absoluteMaintenanceMargin() public view returns (uint256) {
        return liquidatorReward;
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /**
     * @notice Sets the basis hourly borrow fee
     * @param borrowFeeRate_ should be in FEE_DECIMALS and per hour
     */
    function setBorrowFeeRate(int256 borrowFeeRate_) public onlyOwner syncFeesBefore {
        feeIntegral.borrowFeeRate = int256(borrowFeeRate_);
    }

    /**
     * @notice Sets the surplus fee
     * @param maxFundingFeeRate_ should be in FEE_DECIMALS and per hour
     */
    function setMaxFundingFeeRate(int256 maxFundingFeeRate_) public onlyOwner syncFeesBefore {
        feeIntegral.fundingFeeRate = maxFundingFeeRate_;
    }

    /**
     * @notice Sets the max excess ratio at which the full funding fee is charged
     * @param maxExcessRatio_ should be denominated by FEE_MULTIPLER
     */
    function setMaxExcessRatio(int256 maxExcessRatio_) public onlyOwner syncFeesBefore {
        feeIntegral.maxExcessRatio = maxExcessRatio_;
    }

    /**
     * @notice Sets the liquidator reward
     * @param liquidatorReward_ in collateral decimals
     */
    function setLiquidatorReward(uint256 liquidatorReward_) public onlyOwner {
        liquidatorReward = liquidatorReward_;
    }

    /**
     * @notice Sets the minimum leverage
     * @param minLeverage_ in respect to LEVERAGE_MULTIPLIER
     */
    function setMinLeverage(uint128 minLeverage_) public onlyOwner {
        require(minLeverage_ >= MIN_LEVERAGE, "TradePair::setMinLeverage: Leverage too small");
        minLeverage = minLeverage_;
    }

    /**
     * @notice Sets the maximum leverage
     * @param maxLeverage_ in respect to LEVERAGE_MULTIPLIER
     */
    function setMaxLeverage(uint128 maxLeverage_) public onlyOwner {
        require(maxLeverage_ <= MAX_LEVERAGE, "TradePair::setMaxLeverage: Leverage to high");
        maxLeverage = maxLeverage_;
    }

    /**
     * @notice Sets the minimum margin
     * @param minMargin_ in collateral decimals
     */
    function setMinMargin(uint256 minMargin_) public onlyOwner {
        minMargin = minMargin_;
    }

    /**
     * @notice Sets the borrow limit
     * @param volumeLimit_ in collateral decimals
     */
    function setVolumeLimit(uint256 volumeLimit_) public onlyOwner {
        volumeLimit = volumeLimit_;
    }

    /**
     * @notice Sets the factor for the fee buffer. Denominated by BUFFER_MULTIPLIER
     * @param feeBufferFactor_ the factor for the fee buffer
     */
    function setFeeBufferFactor(int256 feeBufferFactor_) public onlyOwner syncFeesBefore {
        feeBuffer.bufferFactor = feeBufferFactor_;
    }

    /**
     * @notice Sets the limit for the total size of all positions
     * @param totalSizeLimit_ limit for the total size of all positions
     */
    function setTotalSizeLimit(uint256 totalSizeLimit_) public onlyOwner {
        totalSizeLimit = totalSizeLimit_;
    }

    /* ========== INTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Returns if a position is liquidatable
     * @param positionId_ the position id
     */
    function _positionIsLiquidatable(uint256 positionId_) internal view returns (bool) {
        Position storage position = positions[positionId_];
        require(position.exists(), "TradePair::_positionIsLiquidatable: position does not exist");
        (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) = _getCurrentFeeIntegrals(position.isShort);

        return position.isLiquidatable(
            _getCurrentPrice(position.isShort, true),
            currentBorrowFeeIntegral,
            currentFundingFeeIntegral,
            absoluteMaintenanceMargin()
        );
    }

    /**
     * @notice Returns current price depending on the direction of the trade and if is buying or selling
     * @param isShort_ bool if the position is short
     * @param isDecreasingPosition_ true on closing and decreasing the position. False on open and extending.
     */
    function _getCurrentPrice(bool isShort_, bool isDecreasingPosition_) internal view returns (int256) {
        if (isShort_ == isDecreasingPosition_) {
            // buy long, sell short
            // get maxprice
            return priceFeedAdapter.markPriceMax();
        } else {
            // buy short, sell long
            // get minprice
            return priceFeedAdapter.markPriceMin();
        }
    }

    /* ========== RESTRICTION FUNCTIONS ========== */

    /**
     * @dev Reverts when sender is not the TradeManager
     */
    function _onlyTradeManager() private view {
        require(msg.sender == address(tradeManager), "TradePair::_onlyTradeManager: only TradeManager");
    }

    /**
     * @dev Reverts when the total size limit is reached by the sum of either all long or all short position
     */
    function _checkSizeLimit() private view {
        require(
            positionStats.totalLongAssetAmount + positionStats.totalShortAssetAmount <= totalSizeLimit,
            "TradePair::_checkSizeLimit: size limit reached"
        );
    }

    /**
     * @notice Verifies that the position did not get altered this block and updates lastAlterationBlock of this position.
     * @dev Positions must not be altered at the same block. This reduces that risk of sandwich attacks.
     */
    function _verifyAndUpdateLastAlterationBlock(uint256 positionId_) private {
        require(
            positions[positionId_].lastAlterationBlock < block.number,
            "TradePair::_verifyAndUpdateLastAlterationBlock: position already altered this block"
        );
        positions[positionId_].lastAlterationBlock = uint40(block.number);
    }

    /**
     * @notice Checks if the position is valid:
     *
     * - The position must exists
     * - The position must not be liquidatable
     * - The position must not reach the volume limit
     */
    function _verifyPositionsValidity(uint256 positionId_) private view {
        // Position must exist
        require(positions[positionId_].exists(), "TradePair::_verifyPositionsValidity: position does not exist");

        // Position must not be liquidatable
        {
            (int256 currentBorrowFeeIntegral, int256 currentFundingFeeIntegral) =
                _getCurrentFeeIntegrals(positions[positionId_].isShort);
            require(
                !positions[positionId_].isLiquidatable(
                    _getCurrentPrice(positions[positionId_].isShort, true),
                    currentBorrowFeeIntegral,
                    currentFundingFeeIntegral,
                    absoluteMaintenanceMargin()
                ),
                "TradePair::_verifyPositionsValidity: position would be liquidatable"
            );
        }

        // Position must not reach the volume limit
        {
            require(
                positions[positionId_].currentVolume(_getCurrentPrice(positions[positionId_].isShort, false))
                    <= volumeLimit,
                "TradePair_verifyPositionsValidity: Borrow limit reached"
            );
        }
    }

    /**
     * @dev Reverts when leverage is out of bounds
     */
    function _verifyLeverage(uint256 leverage_) private view {
        require(leverage_ >= minLeverage, "TradePair::_verifyLeverage: leverage must be above or equal min leverage");
        require(leverage_ <= maxLeverage, "TradePair::_verifyLeverage: leverage must be under or equal max leverage");
    }

    function _verifyOwner(address maker_, uint256 positionId_) private view {
        require(positions[positionId_].owner == maker_, "TradePair::_verifyOwner: not the owner");
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev updates the fee collected fees of this position. Necessary before changing its volume.
     * @param positionId_ the id of the position
     */
    modifier updatePositionFees(uint256 positionId_) {
        _updatePositionFees(positionId_);
        _;
    }

    /**
     * @dev collects fees by transferring them to the FeeManager
     */
    modifier syncFeesBefore() {
        syncPositionFees();
        _;
    }

    /**
     * @dev reverts when position is not liquidatable
     */
    modifier onlyLiquidatable(uint256 positionId_) {
        require(_positionIsLiquidatable(positionId_), "TradePair::onlyLiquidatable: position is not liquidatable");
        _;
    }

    /**
     * @dev Reverts when aggregated size reaches size limit after transaction
     */
    modifier checkSizeLimitAfter() {
        _;
        _checkSizeLimit();
    }

    /**
     * @notice Checks if the alteration is valid. Alteration is valid, when:
     *
     * - The position did not get altered at this block
     * - The position is not liquidatable after the alteration
     */
    modifier onlyValidAlteration(uint256 positionId_) {
        _verifyAndUpdateLastAlterationBlock(positionId_);
        _;
        _verifyPositionsValidity(positionId_);
    }

    /**
     * @dev verifies that leverage is in bounds
     */
    modifier verifyLeverage(uint256 leverage_) {
        _verifyLeverage(leverage_);
        _;
    }

    /**
     * @dev Verfies that sender is the owner of the position
     */
    modifier verifyOwner(address maker_, uint256 positionId_) {
        _verifyOwner(maker_, positionId_);
        _;
    }

    /**
     * @dev Verfies that TradeManager sent the transactions
     */
    modifier onlyTradeManager() {
        _onlyTradeManager();
        _;
    }
}
