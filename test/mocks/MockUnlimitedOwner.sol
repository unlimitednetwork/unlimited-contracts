// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "src/interfaces/IUnlimitedOwner.sol";

contract MockUnlimitedOwner is IUnlimitedOwner {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    function isUnlimitedOwner(address user) external view returns (bool) {
        return owner == user;
    }

    function setOwner(address _owner) external {
        owner = _owner;
    }
}
