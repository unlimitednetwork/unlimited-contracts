# AddMarginToPositionOrder
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ITradeManager.sol)

Parameters foradding margin to a position


```solidity
struct AddMarginToPositionOrder {
    AddMarginToPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}
```

