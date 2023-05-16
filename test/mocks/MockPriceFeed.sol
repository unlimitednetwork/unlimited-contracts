// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "src/interfaces/IPriceFeed.sol";

/**
 * Used for tests.
 */
contract MockPriceFeed is IPriceFeed {
    int256 public price;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    constructor(int256 _price) {
        price = _price;
    }

    function update(int256 _newPrice) public {
        price = _newPrice;
    }

    function update(bytes calldata updateData_) external {}
}
