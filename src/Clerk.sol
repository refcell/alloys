// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Alloy} from "./Alloy.sol";
import {Kink} from "./Kink.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";

/// @title Clerk
/// @notice The kink(trait) orchestrator for Alloy.
/// @notice Kinks cannot be unmelded.
/// @author andreas@nascent.xyz
contract Clerk {

  /// :::::::::::::::::::::::  ERRORS  :::::::::::::::::::::::: ///

  /// @notice Thrown if the caller isn't the alloy.
  error NonAlloy();

  /// :::::::::::::::::::::::  STORAGE  ::::::::::::::::::::::: ///

  /// @notice The Alloy that deployed the Clerk
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

  /// @notice Melds a Kink to the Clerk.
  /// @notice Only the Alloy can meld a Kink.
  /// @dev Alloy keeps must meld through the Alloy contract.
  /// @param kink The kink to meld.
  function meld(address kink) external onlyAlloy {
    uint256 kinkCount = kinkc;
    kinkc++;
    kinks[kinkCount] = kink;
    // Sets the Clerk on the Kink
    Kink(kink).link();
    // Sets the Alloy on the Kink
    Kink(kink).roll(ERC721(address(alloy)));
  }

  /// @notice Checks if a kink has been melded.
  function melded(address kink) external view returns (bool) {
    uint256 kinkCount = kinkc;
    for (uint256 i = 0; i < kinkCount;) {
      if (kinks[i] == kink) {
        return true;
      }
      unchecked { ++i; }
    }
    return false;
  }

  /// ::::::::::::::::::::::::::  REAP  ::::::::::::::::::::::: ///

  /// @notice Allows the kinks to be harvested.
  /// @notice Only the Alloy can reap.
  function reap(address who) external onlyAlloy {
    uint256 kinkCount = kinkc;
    for (uint256 i = 0; i < kinkCount;) {
      Kink(kinks[i]).reap(who);
      unchecked { ++i; }
    }
  }

  /// :::::::::::::::::::::::  VIEWABLES  ::::::::::::::::::::: ///

  /// @notice Returns all melded kinks.
  function mass() external view returns (address[] memory) {
    uint256 kinkCount = kinkc;
    address[] memory tkinks = new address[](kinkCount);
    for (uint256 i = 0; i < kinkCount;) {
      tkinks[i] = kinks[i];
      unchecked { ++i; }
    }
    return tkinks;
  }

  /// :::::::::::::::::::::::  MODIFIERS  ::::::::::::::::::::: ///

  modifier onlyAlloy() {
    if (msg.sender != address(alloy)) revert NonAlloy();
    _;
  }
}