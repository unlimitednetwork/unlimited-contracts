# UnlimitedOwnable
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/shared/UnlimitedOwnable.sol)


## State Variables
### unlimitedOwner
Contract that holds the address of Unlimited owner


```solidity
IUnlimitedOwner public immutable unlimitedOwner;
```


## Functions
### constructor

Sets correct initial values


```solidity
constructor(IUnlimitedOwner _unlimitedOwner);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_unlimitedOwner`|`IUnlimitedOwner`|Unlimited owner contract address|


### isUnlimitedOwner

Checks if caller is Unlimited owner


```solidity
function isUnlimitedOwner() internal view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if caller is Unlimited owner, false otherwise|


### _onlyOwner

Checks and throws if caller is not Unlimited owner


```solidity
function _onlyOwner() private view;
```

### onlyOwner

Checks and throws if caller is not Unlimited owner


```solidity
modifier onlyOwner();
```

