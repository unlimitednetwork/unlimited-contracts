// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract MockArbSys {
    /// @notice Returns block.number to make vm.roll() work
    function arbBlockNumber() external view returns (uint256) {
        return block.number;
    }
}
