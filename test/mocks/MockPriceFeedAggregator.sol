// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/interfaces/IPriceFeedAggregator.sol";

/**
 * Used for tests.
 */
contract MockPriceFeedAggregator is IPriceFeedAggregator {
    string public name;
    int256 public minPrice;
    int256 public maxPrice;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    constructor(string memory _name, int256 _minPrice, int256 _maxPrice) {
        name = _name;
        minPrice = _minPrice;
        maxPrice = _maxPrice;
    }

    function update(int256 _minPrice, int256 _maxPrice) public {
        minPrice = _minPrice;
        maxPrice = _maxPrice;
    }

    function initialize(IPriceFeed[] calldata) external {}

    function addPriceFeed(IPriceFeed) external {}

    function removePriceFeed(uint256) external {}
}
