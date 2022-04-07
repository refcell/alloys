// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {IClerk} from "./interfaces/IClerk.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";

/// @title Kink
/// @notice An Alloy ERC721 Trait
/// @author andreas@nascent.xyz
abstract contract Kink is ERC20 {

  /// :::::::::::::::::::::::  ERRS  ::::::::::::::::::::::: ///

  /// @notice Reverts if the kink has already been kicked.
  error Kicked();

  /// @notice Reverts if caller is not Prex.
  error ExecutiveOrder66();

  /// @notice Thrown if the kink has not been kicked.
  error UnKicked();

  /// @notice Thrown if the fell time is invalid.
  error InvalidFell();

  /// @notice Thrown if the reaping period is over (current time > fell).
  error Felled();

  /// @notice Thrown if the caller isn't the clerk.
  error NotClerk();

  /// @notice Thrown if the clerk is already set
  error ClerkSet();

  /// :::::::::::::::::::::::  STOR  ::::::::::::::::::::::: ///

  /// @notice The reaping start time.
  uint256 public seed;

  /// @notice The reaping end time.
  uint256 public fell;

  /// @notice The Alloy Contract.
  ERC721 public alloy;

  /// @notice The Clerk Contract.
  address public clerk;

  /// @notice The Contract Deployer.
  address public prex;

  /// :::::::::::::::::::::::::  REAP  :::::::::::::::::::::::: ///

  /// @notice Distributes tokens to the given Alloy keep.
  function reap(address who) external virtual returns (uint256);

  /// :::::::::::::::::::::::::  REND  :::::::::::::::::::::::: ///

  /// @notice Renders a Kink's styles and html on an alloy.
  function rend() external virtual view returns (string memory style, string memory html);

  /// :::::::::::::::::::::::::  KICK  :::::::::::::::::::::::: ///

  /// @notice Initiates the kink distributions.
  /// @notice A Kink can only be kicked once.
  /// @param _fell The reaping finish time.
  function kick(uint256 _fell) external onlyPrex {
    if (seed != 0) revert Kicked();
    seed = block.timestamp;
    if (_fell < seed) revert InvalidFell();
    fell = _fell;
  }

  /// :::::::::::::::::::::::::  ROLL  :::::::::::::::::::::::: ///

  /// @notice Allows the Clerk to set the alloy address.
  function roll(ERC721 _alloy) external onlyClerk {
    alloy = _alloy;
  }

  /// :::::::::::::::::::::::::  LINK  :::::::::::::::::::::::: ///

  /// @notice Links the Kink to the Clerk.
  function link() external unsetClerk {
    if (IClerk(msg.sender).melded(address(this))) {
      clerk = msg.sender;
    }
  }

  /// :::::::::::::::::::::::::  MODS  :::::::::::::::::::::::: ///

  modifier onlyPrex() {
    if (msg.sender != prex) revert ExecutiveOrder66();
    _;
  }

  modifier notFelled() {
    if (block.timestamp > fell) {
      revert Felled();
    }
    _;
  }

  modifier kicked() {
    if (seed == 0 || block.timestamp < seed) {
      revert UnKicked();
    }
    _;
  }

  modifier onlyClerk() {
    if (msg.sender != clerk) revert NotClerk();
    _;
  }

  modifier unsetClerk() {
    if (clerk != address(0)) revert ClerkSet();
    _;
  }
}