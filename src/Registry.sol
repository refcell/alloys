// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

import {Auth} from "@solmate/auth/Auth.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

import {Kink} from "./Kink.sol";

/// @title Registry
/// @notice The kink(trait) orchestrator for Alloy
/// @author andreas@nascent.xyz
contract Registry is Auth {

  /// @dev Kink Count
  uint256 public kinkc;

  /// @notice Tracks Alloy Kinks
  mapping(uint256 => address) kinks;

  /// :::::::::::::::::::::  CONSTRUCTOR  ::::::::::::::::::::: ///

  constructor() {}

  /// :::::::::::::::::::::::  METADATA  :::::::::::::::::::::: ///

}