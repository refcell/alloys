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
  mapping(uint256 => address) public kinks;

  /// @notice Maps a kink to its id.
  mapping(address => uint256) public kinkcs;

  /// @notice Tracks the equipped Kinks for a given alloy token id
  /// @dev token_id => kink_number => is_equipped
  mapping(uint256 => mapping(uint256 => bool)) public suited;

  /// @notice Maps alloy tokens to if they're brens (staked) or not
  mapping(uint256 => bool) public brens;

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
    uint256 kinkCount = kinkc + 1; // sload
    kinks[kinkCount] = kink;
    kinkcs[kink] = kinkCount;
    kinkc = kinkCount; // sstore
    // Sets the Clerk on the Kink
    Kink(kink).link();
    // Sets the Alloy on the Kink
    Kink(kink).roll(ERC721(address(alloy)));
  }

  /// @notice Checks if a kink has been melded.
  function melded(address kink) external view returns (bool) {
    return kinkcs[kink] > 0;
  }

  /// ::::::::::::::::::::::::::  REAP  ::::::::::::::::::::::: ///

  /// @notice Allows the kinks to be harvested.
  /// @notice Only the Alloy can reap.
  function reap(address who) external onlyAlloy {
    uint256 kinkCount = kinkc;
    for (uint256 i = 1; i <= kinkCount;) {
      Kink(kinks[i]).reap(who);
      unchecked { ++i; }
    }
  }

  /// ::::::::::::::::::::::::::  MASS  ::::::::::::::::::::::: ///

  /// @notice Returns all melded kinks.
  function mass() external view returns (address[] memory) {
    uint256 kinkCount = kinkc;
    address[] memory tkinks = new address[](kinkCount);
    for (uint256 i = 1; i <= kinkCount;) {
      tkinks[i - 1] = kinks[i];
      unchecked { ++i; }
    }
    return tkinks;
  }

  /// :::::::::::::::::::::::::  BREN  ::::::::::::::::::::::::: ///

  /// @notice Stakes the token in a given kink
  function bren(uint256 id, address kink) public onlyAlloy {
    // Validate that kink is stakeable
    if (!Kink(kink).isBren()) revert NonBren();
    // If the alloy is staked, we cannot bren
    if (brens[id]) revert AlreadyBren();
    brens[id] = true;
    Kink(kink).bren(id);
  }

  /// ::::::::::::::::::::::::::  SUIT  ::::::::::::::::::::::: ///

  /// @notice Equips a kink onto a keep's alloy.
  function suit(address kink, uint256 tokenid, bool suit) external onlyAlloy {
    suited[tokenid][kinkcs[kink]] = suit;
  }

  /// ::::::::::::::::::::::::::  PILE  ::::::::::::::::::::::: ///

  /// @notice Grabs all the equiped kinks' uris.
  function pile(uint256 tokenid) external view returns (string memory styles, string memory html) {
    uint256 kinkCount = kinkc;
    for (uint256 i = 1; i <= kinkCount;) {
      // If the kink is suited, we want to pile the styles and html
      if(suited[tokenid][i]) {
        Kink kink = Kink(kinks[i]);
        (string memory s, string memory h) = kink.rend();
        styles = string(
        abi.encodePacked(
          s,
          styles
        ));
        html = string(
        abi.encodePacked(
          h,
          html
        ));
      }
      unchecked { ++i; }
    }
  }

  /// :::::::::::::::::::::::  MODIFIERS  ::::::::::::::::::::: ///

  modifier onlyAlloy() {
    if (msg.sender != address(alloy)) revert NonAlloy();
    _;
  }
}