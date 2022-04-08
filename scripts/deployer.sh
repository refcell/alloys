#!/usr/bin/env bash

# Read Your RPC URL
echo Enter an RPC URL:
echo Example: "https://eth-mainnet.alchemyapi.io/v2/XXXXXXXXXX"
read -s rpc

# Deploys Alloy.sol and Clerk.sol
forge create ./src/deploy/Deployer.sol:Deployer -i --rpc-url $rpc
