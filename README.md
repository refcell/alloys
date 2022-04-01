<img align="right" width="150" height="150" top="100" src="./assets/readme.jpg">

# alloys  • [![tests](https://github.com/abigger87/alloys/actions/workflows/tests.yml/badge.svg)](https://github.com/abigger87/alloys/actions/workflows/tests.yml) [![lints](https://github.com/abigger87/alloys/actions/workflows/lints.yml/badge.svg)](https://github.com/abigger87/alloys/actions/workflows/lints.yml) ![GitHub](https://img.shields.io/github/license/abigger87/alloys) ![GitHub package.json version](https://img.shields.io/github/package-json/v/abigger87/alloys)


Modularized, Cross-Domain Fungible ERC721 Kinks.

## Overview

Alloys at its core is an ERC721 where traits ("kinks") are fungible. The core [Alloy](./src/Alloy.sol) contract is an ERC721 that renders metadata with kinks tracked by the Registry. The [Registry](./src/Registry.sol) orchestrates [Kink](./src/Kink.sol) contracts (implementations in [src/kinks](./src/kinks/)), which are themselves ERC20 tokens.

Kinks are distributed to Alloy holders through a distribution mechanism.

## Glossary

`Alloys` uses Primitive and Maker's approach of Unconvential Naming inspired by [The Dangers of Surprising Code](https://samczsun.com/the-dangers-of-surprising-code/) h/t [Alex](https://twitter.com/alexangelj) [Mistrusting Variable Names](https://twitter.com/alexangelj/status/1491280313162813441?s=20&t=NoFpNkO9orH8OZ34-DIfMQ).

#### Alloy

[`src/Alloy.sol`](./src/Alloy.sol): Alloy is an ERC721 Token that has one `Clerk` and many `Kinks`.

`cast`: _Mints_ ERC721 tokens.

`keep`: An Alloy _Holder_.

`reap`: _Distributes_ kink tokens to a `keep`.

`meld`: _Registers_ a new Kink for the Alloy.


#### Clerk

[`src/Clerk.sol`](./src/Clerk.sol): Clerk is a registry deployed by the Alloy that manages the Kinks.

`meld`: _Registers_ a new Kink for the Alloy, recording it in the Clerk.

`reap`: _Distributes_ all kink tokens to a `keep`.

`mass`: Returns all melded kinks.


#### Kink

[`src/Kink.sol`](./src/Kink.sol): Kink is an ERC20 that represents a trait of an Alloy.

`seed`: The reaping start time.

`fell`: The reaping end time.

`prex`: The contract deployer.

`kick`: _Initiates_ a kink's token distribution (sets `seed` equal to the current block timestamp).

`roll`: Sets the Alloy address.

`link`: Sets the Clerk address.


## Blueprint

```ml
lib
├─ ds-test — https://github.com/dapphub/ds-test
├─ forge-std — https://github.com/brockelmore/forge-std
├─ solmate — https://github.com/Rari-Capital/solmate
├─ clones-with-immutable-args — https://github.com/wighawag/clones-with-immutable-args
src
├─ kinks — Kink Modules
│  ├─ Ownable — A Kink that is streamed to Alloy Owners
│  └─ Staked — A Kink that is distributed to Alloy Stakers
├─ tests — Contract Tests
│  └─ ...
├─ Alloy — The ERC721 Alloy Contract
├─ Kink — The ERC20 Trait for the ERC721 Alloy
└─ Registry — Orchestrates Kink Modules
```

## Development

**Setup**
```bash
make
# OR #
make setup
```

**Building**
```bash
make build
```

**Testing**
```bash
make test
```

**Deployment & Verification**

Inside the [`scripts/`](./scripts/) directory are a few preconfigured scripts that can be used to deploy and verify contracts.

Scripts take inputs from the cli, using silent mode to hide any sensitive information.

NOTE: These scripts are required to be _executable_ meaning they must be made executable by running `chmod +x ./scripts/*`.

NOTE: For local deployment, make sure to run `yarn` or `npm install` before running the `deploy_local.sh` script. Otherwise, hardhat will error due to missing dependencies.

NOTE: these scripts will prompt you for the contract name and deployed addresses (when verifying). Also, they use the `-i` flag on `forge` to ask for your private key for deployment. This uses silent mode which keeps your private key from being printed to the console (and visible in logs).

### First time with Forge/Foundry?

See the official Foundry installation [instructions](https://github.com/gakonst/foundry/blob/master/README.md#installation).

Then, install the [foundry](https://github.com/gakonst/foundry) toolchain installer (`foundryup`) with:
```bash
curl -L https://foundry.paradigm.xyz | bash
```

Now that you've installed the `foundryup` binary,
anytime you need to get the latest `forge` or `cast` binaries,
you can run `foundryup`.

So, simply execute:
```bash
foundryup
```

🎉 Foundry is installed! 🎉

### Writing Tests with Foundry

With [Foundry](https://gakonst.xyz), tests are written in Solidity! 🥳

Create a test file for your contract in the `src/tests/` directory.

For example, [`src/Greeter.sol`](./src/Greeter.sol) has its test file defined in [`./src/tests/Greeter.t.sol`](./src/tests/Greeter.t.sol).

To learn more about writing tests in Solidity for Foundry and Dapptools, reference Rari Capital's [solmate](https://github.com/Rari-Capital/solmate/tree/main/src/test) repository largely created by [@transmissions11](https://twitter.com/transmissions11).

### Configure Foundry

Using [foundry.toml](./foundry.toml), Foundry is easily configurable.

For a full list of configuration options, see the Foundry [configuration documentation](https://github.com/gakonst/foundry/blob/master/config/README.md#all-options).

### Install DappTools

Install DappTools using their [installation guide](https://github.com/dapphub/dapptools#installation).


## License

[AGPL-3.0-only](https://github.com/abigger87/alloys/blob/master/LICENSE)

## Acknowledgements

- [femplate](https://github.com/abigger87/femplate)
- [foundry](https://github.com/gakonst/foundry)
- [solmate](https://github.com/Rari-Capital/solmate)
- [forge-std](https://github.com/brockelmore/forge-std)
- [clones-with-immutable-args](https://github.com/wighawag/clones-with-immutable-args).
- [foundry-toolchain](https://github.com/onbjerg/foundry-toolchain) by [onbjerg](https://github.com/onbjerg).
- [forge-template](https://github.com/FrankieIsLost/forge-template) by [FrankieIsLost](https://github.com/FrankieIsLost).
- [Georgios Konstantopoulos](https://github.com/gakonst) for [forge-template](https://github.com/gakonst/forge-template) resource.

## Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._
