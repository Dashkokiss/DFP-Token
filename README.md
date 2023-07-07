# DFP

## Summary

- [Smart-contract](#smart-contract)
  - [Functions](#functions)
  - [Errors](#errors)
  - [Events](#events)
  - [ERC-2612 Permit](#erc-2612-permit)
- [Getting started for foundry](#getting-started-for-foundry)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
  - [Testing](#testing)
- [Security](#security)
- [Resources](#resources)

The DFP token is an [ERC20](https://eips.ethereum.org/EIPS/eip-20) compliant token with integrated [ERC-2612](https://eips.ethereum.org/EIPS/eip-2612) (Permit) functionality. It is capped at a maximum supply of 100,000,000 DFP tokens. The contract uses the Ownable module to control access based on the owner address.
The token contract contains a selling functionality. The price of 0.1 USDT per 1 DFP is set.

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
  - This will install `forge`, `cast`, and `anvil`
  - You can test you've installed them right by running `forge --version` and get an output like: `forge 0.2.0 (f016135 2022-07-04T00:15:02.930499Z)`
  - To get the latest of each, just run `foundryup`

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
