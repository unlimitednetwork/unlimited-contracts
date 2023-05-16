// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "../external/interfaces/chainlink/AggregatorV2V3Interface.sol";
import "../interfaces/IController.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IUpdatable.sol";
import "../shared/Constants.sol";
import "../shared/UnlimitedOwnable.sol";

/**
 * @notice Struct to store the price feed data.
 * @custom:member createdOn The timestamp when the price data was stored.
 * @custom:member validTo The timestamp until which the price data is valid.
 * @custom:member price The price.
 */
struct PriceData {
    uint32 createdOn;
    uint32 validTo;
    int192 price;
}

/**
 * @title Unlimited Price Feed
 * @notice Unlimited Price Feed is a price feed that can be updated by anyone.
 * To update the price feed, the caller must provide a UpdateData struct that contains
 * a valid signature from the registered signer. Price Updates contained must by valid and more recent than
 * the last update. The price feed will only accept updates that are within the validTo period.
 * The price may only deviate at a set percentage from the chainlink price feed.
 */
contract UnlimitedPriceFeed is IPriceFeed, IUpdatable, UnlimitedOwnable {
    /* ========== CONSTANTS ========== */

    // EVM operates on 32 bytes / 256 bites words, so a word length is 32 bytes.
    uint256 private constant WORD_LENGTH = 32;
    // The signature is 65 bytes long
    uint256 private constant SIGNATURE_END = 65;
    // The signer address is 20 bytes long, but padded to 32 bytes, so it ends at this position:
    uint256 private constant SIGNER_END = SIGNATURE_END + WORD_LENGTH;
    // The price data consists of three uints, that all get padded to 32 bytes.
    // It is thus three words long, so it ends at this position:
    uint256 private constant DATA_LENGTH = SIGNER_END + WORD_LENGTH * 3;

    /// @notice Minimum value that can be set for max deviation.
    uint256 constant MINIMUM_MAX_DEVIATION = 5;

    /* ========== STATE VARIABLES ========== */

    /// @notice Controller contract.
    IController public immutable controller;
    /// @notice PriceFeed against which the price is compared. Only a maximum deviation is allowed.
    AggregatorV2V3Interface public immutable chainlinkPriceFeed;
    /// @notice Maximum deviation from the chainlink price feed
    uint256 public maxDeviation;
    /// @notice Recent price data. It gets updated with each valid update request.
    PriceData public priceData;

    /**
     * @notice Constructs the UnlimitedPriceFeed contract.
     * @param unlimitedOwner_ The address of the unlimited owner.
     * @param chainlinkPriceFeed_ The address of the Chainlink price feed.
     * @param controller_ The address of the controller contract.
     * @param maxDeviation_ The maximum deviation from the chainlink price feed.
     */
    constructor(
        IUnlimitedOwner unlimitedOwner_,
        AggregatorV2V3Interface chainlinkPriceFeed_,
        IController controller_,
        uint256 maxDeviation_
    ) UnlimitedOwnable(unlimitedOwner_) {
        chainlinkPriceFeed = chainlinkPriceFeed_;
        controller = controller_;
        _updateMaxDeviation(maxDeviation_);
    }

    /**
     * @notice Returns last price
     * @return the price from the last round
     */
    function price() public view verifyPriceValidity returns (int256) {
        return priceData.price;
    }

    /**
     * @notice Update price with signed data.
     * @param updateData_ Data bytes consisting of signature, signer and price data in respected order.
     */
    function update(bytes calldata updateData_) external {
        require(updateData_.length == DATA_LENGTH, "UnlimitedPriceFeed::update: Bad data length");

        PriceData memory newPriceData = abi.decode(updateData_[SIGNER_END:], (PriceData));

        // Verify new price data is more recent than the current price data
        if (newPriceData.createdOn <= priceData.createdOn) {
            return;
        }

        // verify signer access controlls
        address signer = abi.decode(updateData_[SIGNATURE_END:SIGNER_END], (address));

        // throw if the signer is not allowed to update the price
        _verifySigner(signer);

        // verify signature
        bytes calldata signature = updateData_[:SIGNATURE_END];
        require(
            SignatureChecker.isValidSignatureNow(signer, _hashPriceDataUpdate(newPriceData), signature),
            "UnlimitedPriceFeed::update: Bad signature"
        );

        // verify validity of data
        _verifyValidTo(newPriceData.validTo);

        // verify price deviation is not too high
        int256 chainlinkPrice = chainlinkPriceFeed.latestAnswer();

        unchecked {
            int256 maxAbsoluteDeviation = int256(uint256(chainlinkPrice) * maxDeviation / FULL_PERCENT);

            require(
                newPriceData.price >= chainlinkPrice - maxAbsoluteDeviation
                    && newPriceData.price <= chainlinkPrice + maxAbsoluteDeviation,
                "UnlimitedPriceFeed::update: Price deviation too high"
            );
        }

        priceData = newPriceData;
    }

    /**
     * @notice Updates the maximum deviation from the chainlink price feed.
     * @param maxDeviation_ The new maximum deviation.
     */
    function updateMaxDeviation(uint256 maxDeviation_) external onlyOwner {
        _updateMaxDeviation(maxDeviation_);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _hashPriceDataUpdate(PriceData memory priceData_) internal view returns (bytes32) {
        return keccak256(abi.encode(address(this), priceData_));
    }

    function _updateMaxDeviation(uint256 maxDeviation_) private {
        require(
            maxDeviation_ > MINIMUM_MAX_DEVIATION && maxDeviation_ <= FULL_PERCENT,
            "UnlimitedPriceFeed::_updateMaxDeviation: Bad max deviation"
        );

        maxDeviation = maxDeviation_;
    }

    /* ========== RESTRICTION FUNCTIONS ========== */

    function _verifyValidTo(uint256 validTo_) private view {
        require(validTo_ >= block.timestamp, "UnlimitedPriceFeed::_verifyValidTo: Price is not valid");
    }

    function _verifySigner(address signer_) private view {
        require(controller.isSigner(signer_), "UnlimitedPriceFeed::_verifySigner: Bad signer");
    }

    /* ========== MODIFIERS ========== */

    modifier verifyPriceValidity() {
        _verifyValidTo(priceData.validTo);
        _;
    }
}
