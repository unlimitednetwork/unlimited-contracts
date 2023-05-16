# ITradePairHelper
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ITradePairHelper.sol)


## Functions
### positionIdsOf


```solidity
function positionIdsOf(address maker, ITradePair[] calldata tradePairs)
    external
    view
    returns (uint256[][] memory positionInfos);
```

### positionDetailsOf


```solidity
function positionDetailsOf(address maker, ITradePair[] calldata tradePairs)
    external
    view
    returns (PositionDetails[][] memory positionDetails);
```

### pricesOf


```solidity
function pricesOf(ITradePair[] calldata tradePairs) external view returns (PricePair[] memory prices);
```

