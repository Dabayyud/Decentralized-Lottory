This repository implements a decentralized lottery system using Solidity and the Foundry framework. The core Lotto contract enables users to participate in a transparent lottery by sending ETH, with winners selected through Chainlink VRF to ensure provable randomness. The project is designed with modularity in mind, featuring separate funding and price conversion contracts that integrate seamlessly with Chainlink price feeds for accurate ETH/USD conversions.

Deployment scripts are provided to automate the setup and configuration of the contracts across different environments. The codebase includes a comprehensive suite of unit and integration tests, leveraging Foundry’s testing tools and mock contracts to ensure reliability and security. The architecture is extensible, allowing for easy integration of additional libraries and contracts such as solmate, foundry-devops, and forge-std.

Continuous integration is supported via GitHub Actions workflows, enabling automated testing and streamlined development. This project serves as a robust foundation for building, learning, or experimenting with decentralized lottery applications on Ethereum and compatible blockchains.





## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
