// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Alloy} from "./Alloy.sol";
import {Kink} from "./Kink.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

/// @title Registry
/// @notice The kink(trait) orchestrator for Alloy.
/// @notice Kinks cannot be unmelded.
/// @author andreas@nascent.xyz
contract Registry {

  /// :::::::::::::::::::::::  STORAGE  ::::::::::::::::::::::: ///

  /// @notice The Alloy that deployed the Registry
  Alloy immutable public alloy;

  /// @dev Kink Count
  uint256 public kinkc;

  /// @notice Tracks Alloy Kinks
  mapping(uint256 => address) kinks;

  /// :::::::::::::::::::::  CONSTRUCTOR  ::::::::::::::::::::: ///

  constructor() {
    alloy = Alloy(msg.sender);
  }

  /// :::::::::::::::::::::::::  MELD  :::::::::::::::::::::::: ///

  /// @notice Melds a Kink to the Registry.
  /// @notice Only the Alloy can meld a Kink.
  /// @dev Alloy Keepers must meld through the Alloy contract.
  /// @param kink The kink to meld.
  function meld(Kink kink) external onlyAlloy {
    uint256 kinkCount = kinkc;
    kinkc++;
    kinks[kinkCount] = kink;

    // ?? get the kink distribution method
  }

  /// ::::::::::::::::::::::::::  REAP  ::::::::::::::::::::::: ///

  /// @notice Allows the kinks to be harvested.
  /// @notice Only the Alloy can reap.
  function reap(address who) external onlyAlloy {

  }

  /// :::::::::::::::::::::::  VIEWABLES  ::::::::::::::::::::: ///

  /// @notice Returns all melded kinks.
  function mass() external view returns (address[]) {
    uint256 kinkCount = kinkc;
    address[] tkinks = new address[](tkinkCount);
    for (uint256 i = 0; i < kinkCount;) {
      tkinks[i] = kinks[i];
      unchecked { ++i; }
    }
    return tkinks;
  }

  /// :::::::::::::::::::::::  MODIFIERS  ::::::::::::::::::::: ///

  modifier onlyAlloy() {
    if (msg.sender != address(alloy)) revert Unauthorized();
    _;
  }
}