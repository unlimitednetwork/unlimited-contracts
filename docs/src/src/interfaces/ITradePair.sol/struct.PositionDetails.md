# PositionDetails
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ITradePair.sol)

Struct with details of a position, returned by the detailsOfPosition function


```solidity
struct PositionDetails {
    uint256 id;
    uint256 margin;
    uint256 volume;
    uint256 assetAmount;
    uint256 leverage;
    bool isShort;
    int256 entryPrice;
    int256 liquidationPrice;
    int256 totalFeeAmount;
}
```

