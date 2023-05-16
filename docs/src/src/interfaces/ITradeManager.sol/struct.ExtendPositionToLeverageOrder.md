# ExtendPositionToLeverageOrder
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ITradeManager.sol)

Parameters for extending a position to leverage


```solidity
struct ExtendPositionToLeverageOrder {
    ExtendPositionToLeverageParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}
```

