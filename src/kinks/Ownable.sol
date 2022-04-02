// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Kink} from "../Kink.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

/// @title Ownable Kink
/// @notice Vests tokens equally across all Alloy keeps.
/// @author andreas@nascent.xyz
contract Ownable is Kink {

  /// :::::::::::::::::::::::  STOR  ::::::::::::::::::::::: ///

  /// @notice Last reaping for a given address.
  mapping(address => uint256) public base;

  /// :::::::::::::::::::::::  IMUT  ::::::::::::::::::::::: ///

  /// @notice The emission rate per unit time quantum in BASE_UNITS.
  uint256 immutable public EMISSION_RATE;

  /// @notice Emission time quantum.
  uint256 immutable public EMISSION_QUANTUM;

  /// @notice The base unit for ff precision.
  uint256 constant public BASE_UNIT = 1e18;

  /// :::::::::::::::::::::::  SEND  ::::::::::::::::::::::: ///

  constructor() ERC20("Kink", "KINK", 18) {
    prex = msg.sender;
    EMISSION_RATE = 100 * BASE_UNIT;
    EMISSION_QUANTUM = 1 days;
  }

  /// :::::::::::::::::::::::::  REAP  :::::::::::::::::::::::: ///

  /// @notice Distributes tokens to the given Alloy keep.
  function reap(address who) external override kicked notFelled returns (uint256) {
    // Grab the previous base timestamp, or seed (reap start time) if none.
    uint256 prev_base = base[who];
    if (prev_base == 0) {
      prev_base = seed;
    }
    base[who] = block.timestamp;

    // Calculate the number of emission periods since base.
    uint256 lots = ((block.timestamp - prev_base) / EMISSION_QUANTUM);

    // Calculate amount of emissions to reap.
    uint256 acc = lots * EMISSION_RATE;
    _mint(who, acc);

    return acc;
  }
}