# DFP

- [Smart-contract](#smart-contract)
  - [State Variables](#state-variables)
  - [Functions](#functions)
  - [Errors](#errors)
  - [Events](#events)
  - [Extensions](#extensions)
    - [Ownable](#ownable)
    - [ERC-165](#erc-165)
    - [ERC-2612 Permit](#erc-2612-permit)
- [Getting started for foundry](#getting-started-for-foundry)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
  - [Testing](#testing)
- [Deploying to a network](#deploying-to-a-network)
  - [Deploying to testnet](#deploying-to-testnet)
  - [Deploying to mainnet](#deploying-to-mainnet)
- [Security](#security)
- [Resources](#resources)

## Smart contract

The DFP token is an [ERC20](https://eips.ethereum.org/EIPS/eip-20) compliant token with integrated [ERC-2612](https://eips.ethereum.org/EIPS/eip-2612) (Permit) functionality. It is capped at a maximum supply of 100,000,000 DFP tokens. The contract uses the Ownable module to control access based on the owner address.
The token contract contains a selling functionality. The price of 0.1 USDT per 1 DFP is set.

## State Variables

### MIN_PURCHASE_AMOUNT

```solidity
uint256 public constant MIN_PURCHASE_AMOUNT = 1e18;
```

The `MIN_PURCHASE_AMOUNT` is a public constant state variable that specifies the minimum amount of tokens a buyer must purchase in a single transaction. Its value is set at 1 DFP.

| Name                  | Type      | Description                                                                |
| --------------------- | --------- | -------------------------------------------------------------------------- |
| `MIN_PURCHASE_AMOUNT` | `uint256` | The minimum amount of tokens a buyer can purchase in a single transaction. |

### SALE_RATE

```solidity
uint256 public constant SALE_RATE = 0.1e6;
```

The `SALE_RATE` is a public constant state variable that specifies the rate at which tokens are sold, set to 0.1 USDT per token.

| Name        | Type      | Description                                             |
| ----------- | --------- | ------------------------------------------------------- |
| `SALE_RATE` | `uint256` | The rate at which tokens are sold (0.1 USDT per token). |

### \_TOTAL_SUPPLY

```solidity
uint256 private constant _TOTAL_SUPPLY = 100_000_000e18;
```

`_TOTAL_SUPPLY` is a private constant state variable that specifies the total supply of DFP tokens. Its value is set at 100 million DFP tokens.

| Name            | Type      | Description                     |
| --------------- | --------- | ------------------------------- |
| `_TOTAL_SUPPLY` | `uint256` | The total supply of DFP tokens. |

### \_MULTIPLIER

```solidity
uint256 private constant _MULTIPLIER = 1e18;
```

`_MULTIPLIER` is a private constant state variable that is used to calculate the price of tokens in smaller units. Its value is set at 1e18.

| Name          | Type      | Description                                                            |
| ------------- | --------- | ---------------------------------------------------------------------- |
| `_MULTIPLIER` | `uint256` | The multiplier used to calculate the price of tokens in smaller units. |

### \_paymentToken

```solidity
IERC20 private immutable _paymentToken;
```

`_paymentToken` is an immutable state variable of type IERC20 that holds the reference to the ERC20 token contract that will be used for payments.

| Name            | Type     | Description                                     |
| --------------- | -------- | ----------------------------------------------- |
| `_paymentToken` | `IERC20` | The ERC20 token that will be used for payments. |

### \_sellerWallet

```solidity
address private immutable _sellerWallet;
```

`_sellerWallet` is a private immutable state variable of type address that holds the wallet address of the seller.

| Name            | Type      | Description                       |
| --------------- | --------- | --------------------------------- |
| `_sellerWallet` | `address` | The wallet address of the seller. |

## Functions

**Inherits:**
ERC20, ERC165, ERC20Permit, Ownable

### constructor

```solidity
constructor(IERC20 paymentToken, address sellerWallet) ERC20("DFP", "DFP") ERC20Permit("DFP");
```

The constructor function is called once when the contract is first deployed. It takes as parameters an ERC20 token to be used as the payment token and a seller's wallet address. It also inherits the `ERC20` and `ERC20Permit` constructors, setting the token's name and symbol to "DFP". The constructor mints the 100_000_000e18 of DFP tokens to the contract's address.

**Parameters**
| Name | Type | Description |
| --------- | ---- | ----------- |
| `paymentToken` | `IERC20` | The address of the ERC20 token that will be used for payments. |
| `sellerWallet` | `address` | The wallet address to which payments are accepted. |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view override returns (bool);
```

The `supportsInterface` function is an overriding function that checks if the contract implements an interface identified by the `interfaceId`. This method is used to support Interface Identification as per the EIP-165 standard.

**Parameters**
| Name | Type | Description |
| --------- | ---- | ----------- |
| `interfaceId` | `bytes4` | The identifier of the interface to query for. |

### getPaymentToken

```solidity
function getPaymentToken() external view returns (address);
```

The `getPaymentToken` function is a public view function that returns the address of the ERC20 token used for payments in the sale.

### withdraw

```solidity
function withdraw(IERC20 token, address to, uint256 amount) external onlyOwner;
```

The `withdraw` function allows the contract owner to withdraw a specified amount of tokens from the contract. The tokens are transferred to the specified address. This function can only be called by the owner of the contract.

**Parameters**
| Name | Type | Description |
| --------- | ---- | ----------- |
| `token` | `IERC20` | The address of the ERC20 token contract to withdraw from. |
| `to` | `address` | The address where the tokens will be transferred to. |
| `amount` | `uint256` | The amount of tokens to be withdrawn. |

### buy

```solidity
function buy(uint256 amount) external;
```

The `buy` function allows a user to purchase a specified amount of tokens. The function internally calls the `_buy` function to handle the token purchase.

**Parameters**
| Name | Type | Description |
| --------- | ---- | ----------- |
| `amount` | `uint256` | The amount of tokens to be purchased. |

### buy

```solidity
function buy(uint256 amount, address recipient) external;
```

The `buy` function allows a user to purchase a specified amount of tokens and send them to a specified recipient address. The function internally calls the `_buy` function to handle the token purchase.

**Parameters**
| Name | Type | Description |
| --------- | ---- | ----------- |
| `amount` | `uint256` | The amount of tokens to be purchased. |
| `recipient` | `address` | The address where the purchased tokens will be transferred. |

### \_buy

```solidity
function _buy(uint256 amount, address recipient) private;
```

The `_buy` function is a private function that is called by the `buy` functions to handle the token purchase. It checks the purchase amount against the minimum purchase amount, checks the contract's token balance, calculates the purchase price, transfers the payment from the buyer to the seller's wallet, and transfers the purchased tokens from the contract to the recipient address. It then emits a `Sold` event.

**Parameters**
| Name | Type | Description |
| --------- | ---- | ----------- |
| `amount` | `uint256` | The amount of tokens to be purchased. |
| `recipient` | `address` | The address where the purchased tokens will be transferred. |

## Errors

### ZeroAddress

```solidity
error ZeroAddress();
```

The `ZeroAddress` error is thrown when an operation is attempted involving an Ethereum address that is set to zero.

### LessThanMinPurchase

```solidity
error LessThanMinPurchase();
```

The `LessThanMinPurchase` error is triggered when the amount of tokens a user is trying to purchase is less than the minimum allowed purchase amount.

### InsufficientTokenToSell

```solidity
error InsufficientTokenToSell();
```

The `InsufficientTokenToSell` error is thrown when a token purchase transaction cannot be completed because there are not enough tokens available in the contract to fulfill the purchase. This could occur when the contract's supply of tokens has been exhausted, or when the amount requested in a purchase exceeds the current balance of tokens in the contract.

## Events

### Sold

```solidity
event Sold(address indexed buyer, address indexed recipient, uint256 amount);
```

The `Sold` event is emitted whenever a successful token purchase transaction occurs. It includes information about the buyer, the recipient of the tokens, and the amount of tokens purchased.

| Name        | Type      | Indexed | Description                                                                                           |
| ----------- | --------- | ------- | ----------------------------------------------------------------------------------------------------- |
| `buyer`     | `address` | Yes     | The Ethereum address of the buyer. This is the address that initiated the token purchase transaction. |
| `recipient` | `address` | Yes     | The Ethereum address to which the purchased tokens were transferred.                                  |
| `amount`    | `uint256` | No      | The amount of tokens that were purchased in the transaction.                                          |

The `indexed` keyword in an event indicates that the value can be used to filter events when listening to them. It's possible to filter `Sold` events for specific buyers or recipients, or even both, due to the `indexed` keyword.

---

## Extensions

### Ownable

The Ownable contract is a contract module which provides a basic access control mechanism. It designates an account (an owner) that can be granted exclusive access to specific functions. By default, the owner account will be the one that deploys the contract, but this can be changed later using the `transferOwnership` function. The Ownable contract uses the `onlyOwner` modifier to restrict the use of certain functions to the owner.

## State Variables

### \_owner

```solidity
address private _owner;
```

The `_owner` private state variable stores the Ethereum address of the current owner of the contract.

**Parameters**

| Name     | Type      | Description                                |
| -------- | --------- | ------------------------------------------ |
| `_owner` | `address` | The Ethereum address of the current owner. |

## Functions

### constructor

```solidity
constructor();
```

The `constructor` function initializes the contract by setting the deployer as the initial owner.

### onlyOwner

```solidity
modifier onlyOwner();
```

The `onlyOwner` function is a modifier that throws an error if the function it is attached to is called by any account other than the owner.

### owner

```solidity
function owner() public view virtual returns (address);
```

The `owner` function returns the address of the current owner of the contract.

### \_checkOwner

```solidity
function _checkOwner() internal view virtual;
```

The `_checkOwner` function throws an error if the caller of the function is not the owner.

### renounceOwnership

```solidity
function renounceOwnership() public virtual onlyOwner;
```

The `renounceOwnership` function allows the current owner to renounce ownership of the contract. This leaves the contract without an owner and disables any functionality that is only available to the owner.

### transferOwnership

```solidity
function transferOwnership(address newOwner) public virtual onlyOwner;
```

The `transferOwnership` function allows the current owner to transfer ownership of the contract to a new account. This function can only be called by the current owner.

**Parameters**

| Name       | Type      | Description                            |
| ---------- | --------- | -------------------------------------- |
| `newOwner` | `address` | The Ethereum address of the new owner. |

## Events

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
```

The `OwnershipTransferred` event is emitted when ownership of the contract has been transferred from one account to another. It includes information about the previous owner and the new owner.

| Parameter       | Type      | Indexed | Description                                 |
| --------------- | --------- | ------- | ------------------------------------------- |
| `previousOwner` | `address` | Yes     | The Ethereum address of the previous owner. |
| `newOwner`      | `address` | Yes     | The Ethereum address of the new owner.      |

---

### ERC-165

ERC165 is an Ethereum standard used for discovering and identifying interfaces that a smart contract complies with. The ERC165 contract is an implementation of the {IERC165} interface.

## Functions

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool);
```

The `supportsInterface` function takes an interface ID as input and returns a boolean indicating whether the contract implements that interface. This function is a requirement for any contract that implements ERC165.

The function is designed to be overridden by the contract that inherits from it, allowing the contract to specify which interfaces it supports.

**Parameters**

| Name          | Type     | Description                                                       |
| ------------- | -------- | ----------------------------------------------------------------- |
| `interfaceId` | `bytes4` | The 4-byte ID of the interface that is being checked for support. |

**Returns**

`bool`: Returns `true` if the contract implements `interfaceId` and `false` otherwise.

---

### ERC-2612 Permit

The DFP token contract integrates the ERC-2612 Permit standard, which allows token holders to provide approvals for token transfers using off-chain signed messages. This feature simplifies the process of granting permissions for token transfers, reduces gas costs, and enhances user experience by eliminating the need for on-chain transactions.

**Inherits:**

- ERC20
- IERC20Permit
- EIP712

## Functions

### constructor

```solidity
constructor(string memory name) EIP712(name, "1");
```

The constructor initializes the {EIP712} domain separator using the `name` parameter and sets `version` to `"1"`.

**Parameters**

| Name   | Type            | Description                                       |
| ------ | --------------- | ------------------------------------------------- |
| `name` | `string memory` | The name that is defined as the ERC20 token name. |

### permit

```js
function permit(
  address owner,
  address spender,
  uint256 value,
  uint256 deadline,
  uint8 v,
  bytes32 r,
  bytes32 s
) external;
```

The `permit` function allows token holders to generate permit messages, sign them with their private keys, and share the permit signatures with recipients to authorize token transfers. This function enhances efficiency, reduces gas costs, and provides flexibility for seamless token transfer approvals in various decentralized applications and platforms.

**Parameters**

| Name       | Type      | Description                               |
| ---------- | --------- | ----------------------------------------- |
| `owner`    | `address` | The account that owns the tokens.         |
| `spender`  | `address` | The account that will spend the tokens.   |
| `value`    | `uint256` | The number of tokens to be spent.         |
| `deadline` | `uint256` | The time until which the permit is valid. |
| `v`        | `uint8`   | The recovery byte of the signature.       |
| `r`        | `bytes32` | The first 32 bytes of the signature.      |
| `s`        | `bytes32` | The second 32 bytes of the signature.     |

### nonces

```solidity
function nonces(address owner) public view virtual override returns (uint256);
```

Returns the current nonce for a given owner address. This nonce is used to prevent replay attacks.

**Parameters**

| Name    | Type      | Description                             |
| ------- | --------- | --------------------------------------- |
| `owner` | `address` | The address for which to get the nonce. |

**Returns**

`uint256`: The current nonce for the given owner address.

### DOMAIN_SEPARATOR

```solidity
function DOMAIN_SEPARATOR() external view override returns (bytes32);
```

Returns the EIP712 domain separator of the contract.

**Returns**

`bytes32`: The EIP712 domain separator of the contract.

---

## Getting Started for foundry

### Requirements

Please install the following:

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you've done it right if you can run `git --version`
- [Foundry / Foundryup](https://github.com/gakonst/foundry)
  - This will install `forge`, `cast`, and `anvil`. [Installation Instructions](https://book.getfoundry.sh/getting-started/installation)
  - You can test you've installed them right by running `forge --version` and get an output like: `forge 0.2.0 (f016135 2022-07-04T00:15:02.930499Z)`

### Quickstart

```sh
git clone https://github.com/Dashkokiss/DFP-Token.git
cd DFP-Token
forge build
```

### Testing

```
forge test
```

---

## Deploying to a network

Deploying to a network uses the [foundry scripting system](https://book.getfoundry.sh/tutorials/solidity-scripting.html).

### Setup

You need to create a file `.env` in the project and add the following variables to it:

- `SEPOLIA_RPC_URL`: A URL to connect to the Ethereum testnet. You can get one for free from [Alchemy](https://www.alchemy.com/).
- `MAINNET_RPC_URL`: A URL to connect to the Ethereum mainnet.
- `PRIVATE_KEY`: A private key from your wallet. You can get a private key from a new [Metamask](https://metamask.io/) account
- `ETHERSCAN_API_KEY`: To verify a contract on etherscan.

In the file `HelperConfig.s.sol`, which is located in the folder `script/` you must change the wallet address for the test network sepolia and for the ethereum mainnet.

```js
sepoliaNetworkConfig = NetworkConfig({
  usdt: 0x7169d38820dfd117c3fa1f22a697dba58d90ba06,
  wallet: 0x32bb35fc246cb3979c4df996f18366c6c753c29c,
});

mainnetNetworkConfig = NetworkConfig({
  usdt: 0xdac17f958d2ee523a2206206994597c13d831ec7,
  wallet: 0x32bb35fc246cb3979c4df996f18366c6c753c29c,
});
```

This is the address to which payments in USDT token will be received.

**IMPORTANT**: before deploating to the mainnet, perform all actions in the testnet and make sure everything works as expected.

### Deploying to testnet

This will run the forge script, the script it's running is:

```bash
forge script script/Dfp.s.sol:DeployDfp --rpc-url sepolia --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
```

### Deploying to mainnet

```bash
forge script script/Dfp.s.sol:DeployDfp --rpc-url mainnet --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
```

---

## Security

To use slither, you'll first need to [install python](https://www.python.org/downloads/) and [install slither](https://github.com/crytic/slither#how-to-install).

Then, you can run:

```bash
slither ./src/Dfp.sol
```

And get your slither output.

---

## Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
