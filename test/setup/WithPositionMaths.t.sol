// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "src/lib/PositionMaths.sol";
import "test/setup/Constants.sol";

contract WithPositionMaths is Test {
    using PositionMaths for Position;

    Position position;

    uint256 public collateralToPriceMultiplier = 10 ** (PRICE_DECIMALS - COLLATERAL_DECIMALS);

    function testForPositionMaths() public {}
}
