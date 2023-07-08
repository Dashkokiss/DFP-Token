# DFP

## Summary

- [Smart-contract](#smart-contract)
  - [State Variables](#state-variables)
  - [Functions](#functions)
  - [Errors](#errors)
  - [Events](#events)
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

The DFP token is an [ERC20](https://eips.ethereum.org/EIPS/eip-20) compliant token with integrated [ERC-2612](https://eips.ethereum.org/EIPS/eip-2612) (Permit) functionality. It is capped at a maximum supply of 100,000,000 DFP tokens. The contract uses the Ownable module to control access based on the owner address.
The token contract contains a selling functionality. The price of 0.1 USDT per 1 DFP is set.

## State Variables

### MIN_PURCHASE_AMOUNT

```solidity
uint256 public constant MIN_PURCHASE_AMOUNT = 1e18;
```

The `MIN_PURCHASE_AMOUNT` is a public constant state variable that specifies the minimum amount of tokens a buyer must purchase in a single transaction. Its value is set at 1 DFP.

| Name                 | Type     | Description                                      |
| -------------------- | -------- | ------------------------------------------------ |
| `MIN_PURCHASE_AMOUNT`| `uint256`| The minimum amount of tokens a buyer can purchase in a single transaction.|


### SALE_RATE

```solidity
uint256 public constant SALE_RATE = 0.1e6;
```

The `SALE_RATE` is a public constant state variable that specifies the rate at which tokens are sold, set to 0.1 USDT per token.

| Name         | Type     | Description                                      |
| ------------ | -------- | ------------------------------------------------ |
| `SALE_RATE`  | `uint256`| The rate at which tokens are sold (0.1 USDT per token).|


### _TOTAL_SUPPLY

```solidity
uint256 private constant _TOTAL_SUPPLY = 100_000_000e18;
```

`_TOTAL_SUPPLY` is a private constant state variable that specifies the total supply of DFP tokens. Its value is set at 100 million DFP tokens.

| Name           | Type     | Description                                      |
| -------------- | -------- | ------------------------------------------------ |
| `_TOTAL_SUPPLY`| `uint256`| The total supply of DFP tokens.|


### _MULTIPLIER

```solidity
uint256 private constant _MULTIPLIER = 1e18;
```

`_MULTIPLIER` is a private constant state variable that is used to calculate the price of tokens in smaller units. Its value is set at 1e18.

| Name          | Type     | Description                                      |
| ------------- | -------- | ------------------------------------------------ |
| `_MULTIPLIER` | `uint256`| The multiplier used to calculate the price of tokens in smaller units.|


### _paymentToken

```solidity
IERC20 private immutable _paymentToken;
```

`_paymentToken` is an immutable state variable of type IERC20 that holds the reference to the ERC20 token contract that will be used for payments.

| Name           | Type    | Description                                      |
| -------------- | ------- | ------------------------------------------------ |
| `_paymentToken`| `IERC20`| The ERC20 token that will be used for payments.|


### _sellerWallet

```solidity
address private immutable _sellerWallet;
```

`_sellerWallet` is a private immutable state variable of type address that holds the wallet address of the seller.

| Name           | Type     | Description                                      |
| -------------- | -------- | ------------------------------------------------ |
| `_sellerWallet`| `address`| The wallet address of the seller.|


## Functions

**Inherits:**
ERC20, ERC165, ERC20Permit, Ownable

## Errors

## Events

### ERC-2612 Permit

The DFP token contract integrates the ERC-2612 Permit standard, which allows token holders to provide approvals for token transfers using off-chain signed messages. This feature simplifies the process of granting permissions for token transfers, reduces gas costs, and enhances user experience by eliminating the need for on-chain transactions.

### `permit`

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
