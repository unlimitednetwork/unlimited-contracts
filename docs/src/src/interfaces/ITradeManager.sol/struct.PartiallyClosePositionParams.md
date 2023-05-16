# PartiallyClosePositionParams
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ITradeManager.sol)

Parameters for partially closing a position


```solidity
struct PartiallyClosePositionParams {
    address tradePair;
    uint256 positionId;
    uint256 proportion;
}
```

