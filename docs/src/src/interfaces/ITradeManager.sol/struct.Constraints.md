# Constraints
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/interfaces/ITradeManager.sol)

Constraints to constraint the opening, alteration or closing of a position


```solidity
struct Constraints {
    uint256 deadline;
    int256 minPrice;
    int256 maxPrice;
}
```

