# UnlimitedOwner
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/sys-controller/UnlimitedOwner.sol)

**Inherits:**
[IUnlimitedOwner](/src/interfaces/IUnlimitedOwner.sol/contract.IUnlimitedOwner.md), OwnableUpgradeable

Implementation of the {IUnlimitedOwner} interface.

*
This implementation acts as a simple central Unlimited owner oracle.
All Unlimited contracts should refer to this contract to check the owner of the Unlimited.*


## Functions
### initialize


```solidity
function initialize() external initializer;
```

### isUnlimitedOwner

checks if input is the Unlimited owner contract.


```solidity
function isUnlimitedOwner(address user) external view returns (bool isOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|the address to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isOwner`|`bool`|returns true if user is the Unlimited owner, else returns false.|


### owner

*Returns the address of the current owner.*


```solidity
function owner() public view override(IUnlimitedOwner, OwnableUpgradeable) returns (address);
```

### renounceOwnership

removed renounceOwnership function

*
overrides OpenZeppelin renounceOwnership() function and reverts in all cases,
as Unlimited ownership should never be renounced.*


```solidity
function renounceOwnership() public view override onlyOwner;
```

