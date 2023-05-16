# LiquidityPoolVault
[Git Source](https://github.com/solidant/unlimited-contracts/blob/06933827b140eb30ab8723aa85a9cdce2333525a/src/liquidity-pools/LiquidityPoolVault.sol)

**Inherits:**
ERC20Upgradeable, [ILiquidityPoolVault](/src/interfaces/ILiquidityPoolVault.sol/contract.ILiquidityPoolVault.md)

ADAPTATION OF THE OPENZEPPELIN ERC4626 CONTRACT

*
All function implementations are left as in the original implementation.
Some functions are removed.
Some function scopes are changed from private to internal.*


## State Variables
### _asset

```solidity
IERC20Metadata internal immutable _asset;
```


### _decimals

```solidity
uint8 internal constant _decimals = 24;
```


## Functions
### constructor

*Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).*


```solidity
constructor(IERC20Metadata asset_);
```

### asset

*See {IERC4262-asset}*


```solidity
function asset() public view virtual override returns (address);
```

### decimals

*See {IERC4262-decimals}*


```solidity
function decimals() public view virtual override returns (uint8);
```

### totalAssets

*See {IERC4262-totalAssets}*


```solidity
function totalAssets() public view virtual override returns (uint256);
```

### convertToShares

*See {IERC4262-convertToShares}*


```solidity
function convertToShares(uint256 assets) public view virtual override returns (uint256 shares);
```

### convertToAssets

*See {IERC4262-convertToAssets}*


```solidity
function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets);
```

### previewDeposit

*See {IERC4262-previewDeposit}*


```solidity
function previewDeposit(uint256 assets) public view virtual override returns (uint256);
```

### previewMint

*See {IERC4262-previewMint}*


```solidity
function previewMint(uint256 shares) public view virtual override returns (uint256);
```

### previewWithdraw

*See {IERC4262-previewWithdraw}*


```solidity
function previewWithdraw(uint256 assets) public view virtual override returns (uint256);
```

### previewRedeem

*See {IERC4262-previewRedeem}*


```solidity
function previewRedeem(uint256 shares) public view virtual override returns (uint256);
```

### _convertToShares

*Internal convertion function (from assets to shares) with support for rounding direction
Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
would represent an infinite amout of shares.*


```solidity
function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256 shares);
```

### _convertToAssets

*Internal convertion function (from shares to assets) with support for rounding direction*


```solidity
function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256 assets);
```

### _deposit

*Deposit/mint common workflow*


```solidity
function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal;
```

### _withdraw

*Withdraw/redeem common workflow*


```solidity
function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal;
```

