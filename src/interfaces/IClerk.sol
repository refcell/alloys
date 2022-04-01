// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {IERC20} from "./IERC20.sol";

/// @title Clerk Interface
/// @author andreas@nascent.xyz
interface IClerk is IERC20 {
  function meld(address kink) external;
  function melded(address kink) external view returns (bool);
  function reap(address who) external;
  
}