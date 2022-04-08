#!/usr/bin/env bash

# Read Your RPC URL
echo Enter an RPC URL:
echo Example: "https://eth-mainnet.alchemyapi.io/v2/XXXXXXXXXX"
read -s rpc

echo Enter the address to receive the first alloy:
read -s addr

echo Enter your etherscan api key:
read -s etherscan

# Deploys Alloy.sol and Clerk.sol
forge create ./src/Alloy.sol:Alloy -i --rpc-url $rpc

echo Enter the deploy alloy address:
read -s alloy

# Allow the alloy to mint Evolve Tokens
cast send --etherscan-api-key $etherscan 0x14813e8905a0f782f796a5273d2efbe6551100d6 "setMintable(address,uint256)" $addr 1000000 --rpc-url $rpc --from $addr -i

# Mints the user an alloy
cast send --etherscan-api-key $etherscan $alloy "cast(address)" $addr --rpc-url $rpc --from $addr -i

# Deploy an Ownable Kink
forge create ./src/kinks/Ownable.sol:Ownable -i --rpc-url $rpc

echo Enter the deployed kink address:
read -s ownable

# Meld the Kink to Alloy
cast send --etherscan-api-key $etherscan $alloy "meld(address)" $ownable --rpc-url $rpc --from $addr -i
