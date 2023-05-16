# Position
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/lib/PositionMaths.sol)

Struct to store details of a position


```solidity
struct Position {
    uint256 margin;
    uint256 volume;
    uint256 assetAmount;
    int256 pastBorrowFeeIntegral;
    int256 lastBorrowFeeAmount;
    int256 pastFundingFeeIntegral;
    int256 lastFundingFeeAmount;
    uint48 lastFeeCalculationAt;
    uint48 openedAt;
    bool isShort;
    address owner;
    uint16 assetDecimals;
    uint40 lastAlterationBlock;
}
```

