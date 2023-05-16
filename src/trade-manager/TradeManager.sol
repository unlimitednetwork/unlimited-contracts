// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IController.sol";
import "../interfaces/ITradeManager.sol";
import "../interfaces/ITradePair.sol";
import "../interfaces/IUpdatable.sol";
import "../interfaces/IUserManager.sol";

/**
 * @notice Indicates if the min or max price should be used. Depends on LONG or SHORT and buy or sell.
 * @custom:value MIN (0) indicates that the min price should be used
 * @custom:value MAX (1) indicates that the max price should be used
 */
enum UsePrice {
    MIN,
    MAX
}

/**
 * @title TradeManager
 * @notice Facilitates trading on trading pairs.
 */
contract TradeManager is ITradeManager {
    using SafeERC20 for IERC20;
    /* ========== STATE VARIABLES ========== */

    IController public immutable controller;
    IUserManager public immutable userManager;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Constructs the TradeManager contract.
     * @param controller_ The address of the controller.
     * @param userManager_ The address of the user manager.
     */
    constructor(IController controller_, IUserManager userManager_) {
        require(address(controller_) != address(0), "TradeManager::constructor: controller is 0 address");

        controller = controller_;
        userManager = userManager_;
    }

    /* ========== TRADING FUNCTIONS ========== */

    /**
     * @notice Opens a position for a trading pair.
     * @param params_ The parameters for opening a position.
     * @param constraints_ Deadline and price constraints for the transaction.
     * @param updateData_ Possible update data for updatable contracts.
     */
    function openPosition(
        OpenPositionParams calldata params_,
        Constraints calldata constraints_,
        UpdateData[] calldata updateData_
    ) external onlyActiveTradePair(params_.tradePair) returns (uint256) {
        _updateContracts(updateData_);
        _verifyConstraints(params_.tradePair, constraints_, params_.isShort ? UsePrice.MAX : UsePrice.MIN);
        return _openPosition(params_);
    }

    function _openPosition(OpenPositionParams memory params_) internal returns (uint256) {
        ITradePair(params_.tradePair).collateral().safeTransferFrom(
            msg.sender, address(params_.tradePair), params_.margin
        );

        userManager.setUserReferrer(msg.sender, params_.referrer);

        uint256 id = ITradePair(params_.tradePair).openPosition(
            msg.sender, params_.margin, params_.leverage, params_.isShort, params_.whitelabelAddress
        );

        emit PositionOpened(params_.tradePair, id);

        return id;
    }

    /**
     * @notice Closes a position for a trading pair.
     *
     * @param params_ The parameters for closing the position.
     * @param constraints_ Deadline and price constraints for the transaction.
     * @param updateData_ Possible update data for updatable contracts.
     */
    function closePosition(
        ClosePositionParams calldata params_,
        Constraints calldata constraints_,
        UpdateData[] calldata updateData_
    ) external onlyActiveTradePair(params_.tradePair) {
        _updateContracts(updateData_);
        // Verify Constraints
        PositionDetails memory positionDetails = ITradePair(params_.tradePair).detailsOfPosition(params_.positionId);
        _verifyConstraints(params_.tradePair, constraints_, positionDetails.isShort ? UsePrice.MAX : UsePrice.MIN);

        _closePosition(params_);
    }

    function _closePosition(ClosePositionParams memory params_) internal {
        ITradePair(params_.tradePair).closePosition(msg.sender, params_.positionId);
        emit PositionClosed(params_.tradePair, params_.positionId);
    }

    /**
     * @notice Partially closes a position on a trade pair.
     * @param params_ The parameters for partially closing the position.
     * @param constraints_ Deadline and price constraints for the transaction.
     * @param updateData_ Possible update data for updatable contracts.
     */
    function partiallyClosePosition(
        PartiallyClosePositionParams calldata params_,
        Constraints calldata constraints_,
        UpdateData[] calldata updateData_
    ) public onlyActiveTradePair(params_.tradePair) {
        _updateContracts(updateData_);
        // Verify Constraints
        PositionDetails memory positionDetails = ITradePair(params_.tradePair).detailsOfPosition(params_.positionId);
        _verifyConstraints(params_.tradePair, constraints_, positionDetails.isShort ? UsePrice.MAX : UsePrice.MIN);

        _partiallyClosePosition(params_);
    }

    function _partiallyClosePosition(PartiallyClosePositionParams memory params_) internal {
        ITradePair(params_.tradePair).partiallyClosePosition(msg.sender, params_.positionId, params_.proportion);
        emit PositionPartiallyClosed(params_.tradePair, params_.positionId, params_.proportion);
    }

    /**
     * @notice Removes margin from a position
     * @param params_ The parameters for removing margin from the position.
     * @param constraints_ Deadline and price constraints for the transaction.
     * @param updateData_ Possible update data for updatable contracts.
     */
    function removeMarginFromPosition(
        RemoveMarginFromPositionParams calldata params_,
        Constraints calldata constraints_,
        UpdateData[] calldata updateData_
    ) public onlyActiveTradePair(params_.tradePair) {
        _updateContracts(updateData_);

        // Verify Constraints
        PositionDetails memory positionDetails = ITradePair(params_.tradePair).detailsOfPosition(params_.positionId);
        _verifyConstraints(params_.tradePair, constraints_, positionDetails.isShort ? UsePrice.MAX : UsePrice.MIN);

        _removeMarginFromPosition(params_);
    }

    function _removeMarginFromPosition(RemoveMarginFromPositionParams memory params_) internal {
        ITradePair(params_.tradePair).removeMarginFromPosition(msg.sender, params_.positionId, params_.removedMargin);

        emit MarginRemovedFromPosition(params_.tradePair, params_.positionId, params_.removedMargin);
    }

    /**
     * @notice Adds margin to a position
     * @param params_ The parameters for adding margin to the position.
     * @param constraints_ Deadline and price constraints for the transaction.
     * @param updateData_ Possible update data for updatable contracts.
     */
    function addMarginToPosition(
        AddMarginToPositionParams calldata params_,
        Constraints calldata constraints_,
        UpdateData[] calldata updateData_
    ) public onlyActiveTradePair(params_.tradePair) {
        _updateContracts(updateData_);

        // Verify Constraints
        PositionDetails memory positionDetails = ITradePair(params_.tradePair).detailsOfPosition(params_.positionId);
        _verifyConstraints(params_.tradePair, constraints_, positionDetails.isShort ? UsePrice.MAX : UsePrice.MIN);

        // Transfer Collateral to TradePair
        ITradePair(params_.tradePair).collateral().safeTransferFrom(
            msg.sender, address(params_.tradePair), params_.addedMargin
        );

        // Call Add Margin
        _addMarginToPosition(params_);
    }

    function _addMarginToPosition(AddMarginToPositionParams memory params_) internal {
        ITradePair(params_.tradePair).addMarginToPosition(msg.sender, params_.positionId, params_.addedMargin);

        emit MarginAddedToPosition(params_.tradePair, params_.positionId, params_.addedMargin);
    }

    /**
     * @notice Extends position with margin and loan.
     * @param params_ The parameters for extending the position.
     * @param constraints_ Deadline and price constraints for the transaction.
     * @param updateData_ Possible update data for updatable contracts.
     */
    function extendPosition(
        ExtendPositionParams calldata params_,
        Constraints calldata constraints_,
        UpdateData[] calldata updateData_
    ) public onlyActiveTradePair(params_.tradePair) {
        _updateContracts(updateData_);

        // Verify Constraints
        PositionDetails memory positionDetails = ITradePair(params_.tradePair).detailsOfPosition(params_.positionId);
        _verifyConstraints(params_.tradePair, constraints_, positionDetails.isShort ? UsePrice.MAX : UsePrice.MIN);

        // Transfer Collateral to TradePair
        ITradePair(params_.tradePair).collateral().safeTransferFrom(
            msg.sender, address(params_.tradePair), params_.addedMargin
        );

        _extendPosition(params_);
    }

    function _extendPosition(ExtendPositionParams memory params_) internal {
        ITradePair(params_.tradePair).extendPosition(
            msg.sender, params_.positionId, params_.addedMargin, params_.addedLeverage
        );

        emit PositionExtended(params_.tradePair, params_.positionId, params_.addedMargin, params_.addedLeverage);
    }

    /**
     * @notice Extends position with loan to target leverage.
     * @param params_ The parameters for extending the position to target leverage.
     * @param constraints_ Deadline and price constraints for the transaction.
     * @param updateData_ Possible update data for updatable contracts.
     */
    function extendPositionToLeverage(
        ExtendPositionToLeverageParams calldata params_,
        Constraints calldata constraints_,
        UpdateData[] calldata updateData_
    ) public onlyActiveTradePair(params_.tradePair) {
        _updateContracts(updateData_);

        // Verify Constraints
        PositionDetails memory positionDetails = ITradePair(params_.tradePair).detailsOfPosition(params_.positionId);
        _verifyConstraints(params_.tradePair, constraints_, positionDetails.isShort ? UsePrice.MAX : UsePrice.MIN);

        _extendPositionToLeverage(params_);
    }

    function _extendPositionToLeverage(ExtendPositionToLeverageParams memory params_) internal {
        ITradePair(params_.tradePair).extendPositionToLeverage(msg.sender, params_.positionId, params_.targetLeverage);

        emit PositionExtendedToLeverage(params_.tradePair, params_.positionId, params_.targetLeverage);
    }

    /* ========== LIQUIDATIONS ========== */

    /**
     * @notice Liquidates position
     * @param tradePair_ address of the trade pair
     * @param positionId_ position id
     * @param updateData_ Data to update state before the execution of the function
     */
    function liquidatePosition(address tradePair_, uint256 positionId_, UpdateData[] calldata updateData_)
        public
        onlyActiveTradePair(tradePair_)
    {
        _updateContracts(updateData_);
        ITradePair(tradePair_).liquidatePosition(msg.sender, positionId_);
        emit PositionLiquidated(tradePair_, positionId_);
    }

    /**
     * @notice Try to liquidate a position, return false if call reverts
     * @param tradePair_ address of the trade pair
     * @param positionId_ position id
     */
    function _tryLiquidatePosition(address tradePair_, uint256 positionId_)
        internal
        onlyActiveTradePair(tradePair_)
        returns (bool)
    {
        try ITradePair(tradePair_).liquidatePosition(msg.sender, positionId_) {
            emit PositionLiquidated(tradePair_, positionId_);
            return true;
        } catch {
            return false;
        }
    }

    /**
     * @notice Trys to liquidates all given positions
     * @param tradePairs addresses of the trade pairs
     * @param positionIds position ids
     * @param allowRevert if true, reverts if any call reverts
     * @return didLiquidate bool[][] results of the individual liquidation calls
     * @dev Requirements
     *
     * - `tradePairs` and `positionIds` must have the same length
     */
    function batchLiquidatePositions(
        address[] calldata tradePairs,
        uint256[][] calldata positionIds,
        bool allowRevert,
        UpdateData[] calldata updateData_
    ) external returns (bool[][] memory didLiquidate) {
        require(tradePairs.length == positionIds.length, "TradeManager::batchLiquidatePositions: invalid input");
        _updateContracts(updateData_);

        didLiquidate = new bool[][](tradePairs.length);

        for (uint256 i = 0; i < tradePairs.length; i++) {
            didLiquidate[i] = _batchLiquidatePositionsOfTradePair(tradePairs[i], positionIds[i], allowRevert);
        }
    }

    /**
     * @notice Trys to liquidates given positions of a trade pair
     * @param tradePair address of the trade pair
     * @param positionIds position ids
     * @param allowRevert if true, reverts if any call reverts
     * @return didLiquidate bool[] results of the individual liquidation calls
     */
    function _batchLiquidatePositionsOfTradePair(address tradePair, uint256[] calldata positionIds, bool allowRevert)
        internal
        returns (bool[] memory didLiquidate)
    {
        didLiquidate = new bool[](positionIds.length);

        for (uint256 i = 0; i < positionIds.length; i++) {
            if (_tryLiquidatePosition(tradePair, positionIds[i])) {
                didLiquidate[i] = true;
            } else {
                if (allowRevert) {
                    didLiquidate[i] = false;
                } else {
                    revert("TradeManager::_batchLiquidatePositionsOfTradePair: liquidation failed");
                }
            }
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns the details of a position
     * @dev returns PositionDetails struct
     * @param tradePair_ address of the trade pair
     * @param positionId_ id of the position
     */
    function detailsOfPosition(address tradePair_, uint256 positionId_)
        external
        view
        returns (PositionDetails memory)
    {
        return ITradePair(tradePair_).detailsOfPosition(positionId_);
    }

    /**
     * @notice Indicates if a position is liquidatable
     * @param tradePair_ address of the trade pair
     * @param positionId_ id of the position
     */
    function positionIsLiquidatable(address tradePair_, uint256 positionId_) public view returns (bool) {
        return ITradePair(tradePair_).positionIsLiquidatable(positionId_);
    }

    /**
     * @notice Indicates if the positions are liquidatable
     * @param tradePairs_ addresses of the trade pairs
     * @param positionIds_ ids of the positions
     * @return canLiquidate array of bools indicating if the positions are liquidatable
     * @dev Requirements:
     *
     * - tradePairs_ and positionIds_ must have the same length
     */
    function canLiquidatePositions(address[] calldata tradePairs_, uint256[][] calldata positionIds_)
        external
        view
        returns (bool[][] memory canLiquidate)
    {
        require(
            tradePairs_.length == positionIds_.length,
            "TradeManager::canLiquidatePositions: TradePair and PositionId arrays must be of same length"
        );
        canLiquidate = new bool[][](tradePairs_.length);
        for (uint256 i = 0; i < tradePairs_.length; i++) {
            // for positionId in positionIds_
            canLiquidate[i] = _canLiquidatePositionsAtTradePair(tradePairs_[i], positionIds_[i]);
        }
    }

    /**
     * @notice Indicates if the positions are liquidatable
     * @param tradePair_ address of the trade pair
     * @param positionIds_ ids of the positions
     * @return canLiquidate array of bools indicating if the positions are liquidatable
     */
    function _canLiquidatePositionsAtTradePair(address tradePair_, uint256[] calldata positionIds_)
        internal
        view
        returns (bool[] memory)
    {
        bool[] memory canLiquidate = new bool[](positionIds_.length);
        for (uint256 i = 0; i < positionIds_.length; i++) {
            canLiquidate[i] = positionIsLiquidatable(tradePair_, positionIds_[i]);
        }
        return canLiquidate;
    }

    /**
     * @notice Returns the current funding fee rates of a trade pair
     * @param tradePair_ address of the trade pair
     * @return longFundingFeeRate long funding fee rate
     * @return shortFundingFeeRate short funding fee rate
     */
    function getCurrentFundingFeeRates(address tradePair_)
        external
        view
        returns (int256 longFundingFeeRate, int256 shortFundingFeeRate)
    {
        return ITradePair(tradePair_).getCurrentFundingFeeRates();
    }

    /**
     * @notice Returns the maximum size in assets of a tradePair
     * @param tradePair_ address of the trade pair
     * @return maxSize maximum size
     */
    function totalSizeLimitOfTradePair(address tradePair_) external view returns (uint256) {
        return ITradePair(tradePair_).totalSizeLimit();
    }

    /**
     * @dev Checks if constraints_ are satisfied. If not, reverts.
     * When the transaction staid in the mempool for a long time, the price may change.
     *
     * - Price is in price range
     * - Deadline is not exceeded
     */
    function _verifyConstraints(address tradePair_, Constraints calldata constraints_, UsePrice usePrice_)
        internal
        view
    {
        // Verify Deadline
        require(constraints_.deadline > block.timestamp, "TradeManager::_verifyConstraints: Deadline passed");

        // Verify Price
        {
            int256 markPrice;

            if (usePrice_ == UsePrice.MIN) {
                (markPrice,) = ITradePair(tradePair_).getCurrentPrices();
            } else {
                (, markPrice) = ITradePair(tradePair_).getCurrentPrices();
            }

            require(
                constraints_.minPrice <= markPrice && markPrice <= constraints_.maxPrice,
                "TradeManager::_verifyConstraints: Price out of bounds"
            );
        }
    }

    /**
     * @dev Updates all updatdable contracts. Reverts if one update operation is invalid or not successfull.
     */
    function _updateContracts(UpdateData[] calldata updateData_) internal {
        for (uint256 i; i < updateData_.length; i++) {
            require(
                controller.isUpdatable(updateData_[i].updatableContract),
                "TradeManager::_updateContracts: Contract not updatable"
            );

            IUpdatable(updateData_[i].updatableContract).update(updateData_[i].data);
        }
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Checks if trading pair is active.
     * @param tradePair_ address of the trade pair
     */
    modifier onlyActiveTradePair(address tradePair_) {
        controller.checkTradePairActive(tradePair_);
        _;
    }
}
