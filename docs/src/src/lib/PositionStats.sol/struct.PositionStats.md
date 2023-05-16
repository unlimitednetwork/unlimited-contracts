# PositionStats
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/lib/PositionStats.sol)

Struct to store statistical information about all positions


```solidity
struct PositionStats {
    uint256 totalLongMargin;
    uint256 totalLongVolume;
    uint256 totalLongAssetAmount;
    uint256 totalShortMargin;
    uint256 totalShortVolume;
    uint256 totalShortAssetAmount;
}
```

