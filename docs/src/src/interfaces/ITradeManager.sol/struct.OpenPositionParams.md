# OpenPositionParams
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ITradeManager.sol)

Parameters for opening a position


```solidity
struct OpenPositionParams {
    address tradePair;
    uint256 margin;
    uint256 leverage;
    bool isShort;
    address referrer;
    address whitelabelAddress;
}
```

