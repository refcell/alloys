// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Alloy} from "../Alloy.sol";
import {Clerk} from "../Clerk.sol";
import {Kink} from "../Kink.sol";
import {Ownable} from "../kinks/Ownable.sol";
import {Staked} from "../kinks/Staked.sol";
import {IEvolve} from "../interfaces/IEvolve.sol";

/// @title Deployer
/// @notice Deploys Alloys and configures all accompanying contracts.
/// @author andreas@nascent.xyz
contract Deployer {

  // Alloy Contracts
  Alloy public alloy;
  Clerk public clerk;
  Ownable public ownable;
  Staked public staked;

  /// @notice The Evolve Reward Token
  IEvolve constant public EVOLVE = IEvolve(0x14813e8905a0f782F796A5273d2EFbe6551100D6);

  address[] private whitelist = [
    0xc9AB63915c6738c8Ce5ca245979203Bfa3F2499F, // deployer
    0x4B72aa21820C76e1E19193D90bdB9b5f25F8Aa19, // nati
    0x3FB7501f5e451509Da23aD25c331A0737ef514A2, // velleity
    0x29298f2C2c7448b550eC5794C58F75f8B38bEc62, // jamaal
    0x359ff1EDa7a4faC61CB3333650daFE9b7f60364a, // krisite
    0x9C0790Eb0F96B16Ea1806e20B0D0E21A31DC93BC, // a1
    0x70FD938dE9199F4650c7a97B2Ebb1AF98B4733C9, // a2
    0xcE6bd1280c9D647453A9326fAa75DF90A3AeCa86, // a3
    0xbF9f9820d7636Ced480f47d4328806CB10a49a8c  // a4
  ];

  constructor() {
    deploy();
  }

  function deploy() public payable {
    // Deploy the Alloy and get the Clerk
    alloy = new Alloy();
    clerk = alloy.CLERK();

    // Transfer evolve from the sender to the deployer
    EVOLVE.transferFrom(msg.sender, address(this), alloy.MAXIMUM_TOKENS() * alloy.KEEP_REWARD());

    // Allow the alloy to mint evolve tokens as a reward during casts
    // EVOLVE.setMintable(address(alloy), alloy.KEEP_REWARD() * alloy.MAXIMUM_TOKENS());

    // Mint alloys to whitelist
    for (uint256 i = 0; i < whitelist.length;) {
      alloy.cast(whitelist[i]);
      unchecked { ++i; }
    }
    alloy.cast(address(this));

    // Deploy and configure ownable
    ownable = new Ownable();
    ownable.kick(block.timestamp + 30 days);

    // Deploy an ownable and staked kink
    staked = new Staked();

    // Meld the kinks onto alloy
    alloy.meld(address(ownable));
    alloy.meld(address(staked));
  }
}