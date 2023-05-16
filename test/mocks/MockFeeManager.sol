// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "src/interfaces/IFeeManager.sol";
import "src/interfaces/ITradePair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../src/shared/Constants.sol";

/**
 * @notice Used for tests.
 */
contract MockFeeManager is IFeeManager {
    using SafeERC20 for IERC20;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    function calculateUserOpenFeeAmount(address, uint256 amount) external pure returns (uint256) {
        return amount * 10 / 100_00;
    }

    function calculateUserOpenFeeAmount(address, uint256 amount_, uint256 leverage_)
        external
        pure
        returns (uint256 feeAmount_)
    {
        uint256 userFee = 10;
        uint256 margin =
            amount_ * LEVERAGE_MULTIPLIER * FULL_PERCENT / (LEVERAGE_MULTIPLIER * FULL_PERCENT + leverage_ * userFee);
        uint256 volume = margin * leverage_ / LEVERAGE_MULTIPLIER;
        feeAmount_ = volume * userFee / FULL_PERCENT;
    }

    function calculateUserExtendToLeverageFeeAmount(address, uint256 margin_, uint256 volume_, uint256 targetLeverage_)
        external
        pure
        returns (uint256 feeAmount_)
    {
        uint256 userFee = 10;
        uint256 addedVolume = (margin_ * targetLeverage_ / LEVERAGE_MULTIPLIER - volume_) * FULL_PERCENT
            * LEVERAGE_MULTIPLIER / (userFee * targetLeverage_ + FULL_PERCENT * LEVERAGE_MULTIPLIER);
        feeAmount_ = addedVolume * userFee / FULL_PERCENT;
    }

    function calculateUserCloseFeeAmount(address, uint256 amount) external pure returns (uint256) {
        return amount * 10 / 100_00;
    }

    function depositOpenFees(address, address asset, uint256 amount, address) external {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
    }

    function depositCloseFees(address, address asset, uint256 amount, address) external {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
    }

    function depositBorrowFees(address asset, uint256 amount) external {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
    }
}
