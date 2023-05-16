// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * Used for tests.
 */
contract MockToken is ERC20 {
    uint8 _decimals = 6;

    /// @notice this function is necessary to exclude this contract from test coverage
    function testMock() public {}

    constructor() ERC20("Unlimited USDC", "UL_USDC") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function setDecimals(uint8 decimals_) external {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
