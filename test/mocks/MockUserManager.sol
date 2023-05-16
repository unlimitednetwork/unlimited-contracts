// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "src/interfaces/IController.sol";
import "src/interfaces/IUserManager.sol";

contract MockUserManager is IUserManager {
    uint256 userFee = 10;
    Tier userManualTier = Tier.ZERO;
    uint256 volume;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    /// @notice User referrer.
    mapping(address => address) private _userReferrer;

    /* =========== MOCK FUNCTIONS ========== */
    function setUserFee(uint256 _userFee) public {
        userFee = _userFee;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Gets users open and close position fee.
     * @dev The fee is based on users last 30 day volume.
     *
     * @param user user address
     * @return fee size in BPS
     */
    function getUserFee(address user) external view override returns (uint256) {
        user;
        return userFee;
    }

    function getUserReferrer(address user) external view returns (address referrer) {
        return _userReferrer[user];
    }

    function setUserReferrer(address user, address referrer) external {
        _userReferrer[user] = referrer;
    }

    /**
     * @notice Gets users fee manual tier.
     *
     * @param user user address
     * @return Tier fee tier of the user
     */
    function getUserManualTier(address user) public view returns (Tier) {
        user;
        return userManualTier;
    }

    /**
     * @notice Gets users last 30 days traded volume.
     *
     * @param user user address
     * @return user30dayVolume users last 30 days volume
     */
    function getUser30DaysVolume(address user) public view returns (uint256 user30dayVolume) {
        user;
        return volume;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Adds user volume to total daily traded when new position is open.
     * @param user user address
     * @param _volume volume to add
     */
    function addUserVolume(address user, uint40 _volume) external pure override {
        user;
        _volume;
    }

    /**
     * @notice Sets users manual tier including valid time.
     * @dev
     *
     * Requirements:
     * - The caller must be a controller
     *
     * @param user user address
     * @param tier tier to set
     * @param validUntil unix time when the manual tier expires
     */
    function setUserManualTier(address user, Tier tier, uint32 validUntil) external {}

    /**
     * @notice Sets fee sizes for a tier.
     * @dev
     * `feeIndexes` start with 0 as the base fee and increase by 1 for each tier.
     *
     * Requirements:
     * - The caller must be a controller
     * - `feeIndexes` and `feeSizes` must be of same length
     *
     * @param feeIndexes Index of fees to update
     * @param feeSizes Fee sizes in BPS
     */
    function setFeeSizes(uint256[] calldata feeIndexes, uint8[] calldata feeSizes) external override {}

    /**
     * @notice Sets minimum volume for a fee tier.
     * @dev
     * `feeIndexes` start with 1 as the tier one and increment by one.
     *
     * Requirements:
     * - The caller must be a controller
     * - `feeIndexes` and `feeSizes` must be of same length
     *
     * @param feeIndexes Index of fees to update
     * @param feeVolumes Fee volume for an index
     */
    function setFeeVolumes(uint256[] calldata feeIndexes, uint32[] calldata feeVolumes) external {}
}
