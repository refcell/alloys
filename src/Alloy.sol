// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";

import {Base64} from "./lib/Base64.sol";

/// @title Alloy
/// @notice Composable ERC721 Token with Cross-Domain Fungibility
/// @dev Modularized ERC721 tokens that have fungible traits
/// @author andreas@nascent.xyz
contract Alloy is ERC721 {

  /// :::::::::::::::::::::  CONSTRUCTOR  ::::::::::::::::::::: ///

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  /// :::::::::::::::::::::::  METADATA  :::::::::::::::::::::: ///

  function tokenURI(uint256 id) public view override virtual returns (string memory) {
    // TODO: get balance of different traits

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            "<NAME>",
            ' -- NFT #: ',
            string(abi.encodePacked(id)),
            '", "description": "Alloy Example Contract", "image": "ipfs://',
            "<IMAGE_URI>",
            // TODO: define traits here
            '", "attributes": [ { "trait_type": "Health Points", "value": ',
            "<HEALTH_POINTS>",
            ', "max_value":',
            "<MAX_HEALTH_POINTS>",
            '}, { "trait_type": "Attack Damage", "value": ',
            "<ATTACK_DAMAGE>",
            '} ]}'
          )
        )
      )
    );

    string memory output = string(
        abi.encodePacked("data:application/json;base64,", json)
    );

    return output;
  }
}