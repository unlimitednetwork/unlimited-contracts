# FeeBuffer
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/lib/FeeBuffer.sol)

Struct to store the fee buffer for a given trade pair


```solidity
struct FeeBuffer {
    int256 currentBufferAmount;
    int256 bufferFactor;
}
```

