// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "src/trade-manager/TradeManager.sol";

contract TradeManagerHarness is TradeManager {
    constructor(IController controller_, IUserManager userManager_) TradeManager(controller_, userManager_) {}

    function testMock() public {}

    /**
     * @notice Opens a position on a trade pair.
     * @param params_ The parameters to opening the position.
     * @param maker_ Maker of the position
     */
    function exposed_openPosition(OpenPositionParams calldata params_, address maker_) public returns (uint256) {
        return _openPosition(params_, maker_);
    }

    /**
     * @notice Closes a position on a trade pair.
     * @param params_ The parameters to close the position.
     * @param maker_ Maker of the position
     */
    function exposed_closePosition(ClosePositionParams calldata params_, address maker_) public {
        _closePosition(params_, maker_);
    }
    /**
     * @notice Partially closes a position on a trade pair.
     * @param params_ The parameters for partially closing the position.
     * @param maker_ Maker of the position
     */

    function exposed_partiallyClosePosition(PartiallyClosePositionParams calldata params_, address maker_) public {
        _partiallyClosePosition(params_, maker_);
    }

    /**
     * @notice Adds margin to a position on a trade pair.
     * @param params_ The parameters for adding margin to the position.
     * @param maker_ Maker of the position
     */
    function exposed_addMarginToPosition(AddMarginToPositionParams calldata params_, address maker_) public {
        _addMarginToPosition(params_, maker_);
    }

    /**
     * @notice Removes margin from a position on a trade pair.
     * @param params_ The parameters for removing margin from the position.
     * @param maker_ Maker of the position
     */
    function exposed_removeMarginFromPosition(RemoveMarginFromPositionParams calldata params_, address maker_) public {
        _removeMarginFromPosition(params_, maker_);
    }

    /**
     * @notice Extends Position
     * @param params_ The parameters for extending the position.
     * @param maker_ Maker of the position
     */
    function exposed_extendPosition(ExtendPositionParams calldata params_, address maker_) public {
        _extendPosition(params_, maker_);
    }

    /**
     * @notice Extends Position to leverage
     * @param params_ The parameters for extending the position to leverage.
     * @param maker_ Maker of the position
     */
    function exposed_extendPositionToLeverage(ExtendPositionToLeverageParams calldata params_, address maker_) public {
        _extendPositionToLeverage(params_, maker_);
    }
}
