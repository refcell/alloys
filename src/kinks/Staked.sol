// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Kink} from "../Kink.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

/// @title Staked Kink
/// @notice Vests tokens using a staking mechanism.
/// @author andreas@nascent.xyz
contract Staked is Kink {

  /// :::::::::::::::::::::::  STOR  ::::::::::::::::::::::: ///

  /// @notice Reward per token staked
  uint256 public emissionBasis;

  /// @notice Number of alloys staked
  uint256 public brenc;

  /// @notice The last update time
  uint256 public stash;

  /// @notice Last reaping for a given address.
  mapping(address => uint256) public base;

  /// @notice Accrued Rewards
  mapping(address => uint256) public accrued;

  /// @notice Collected Rewards
  mapping(address => uint256) public collected;

  /// @notice Mapping of brens to if they're staked
  mapping(address => bool) public brens;

  /// :::::::::::::::::::::::  IMUT  ::::::::::::::::::::::: ///

  /// @notice The emission rate per unit time quantum in BASE_UNITS.
  uint256 immutable public EMISSION_RATE;

  /// @notice The base unit for ff precision.
  uint256 constant public BASE_UNIT = 1e18;

  /// :::::::::::::::::::::::  SEND  ::::::::::::::::::::::: ///

  constructor() ERC20("Kink", "KINK", 18) {
    prex = msg.sender;
    EMISSION_RATE = 100 * BASE_UNIT;
  }

  /// :::::::::::::::::::::::::  REAP  :::::::::::::::::::::::: ///

  /// @notice Distributes tokens to the given Alloy keep.
  function reap(address who) external override kicked notFelled update(who) returns (uint256) {
    // Calculate amount of emissions to reap.
    uint256 acc = accrued[who];
    accrued[who] = 0;
    _mint(who, acc);
    return acc;
  }

  /// :::::::::::::::::::::::::  BREN  :::::::::::::::::::::::: ///

  /// @notice Stakes an alloy token
  function bren(address who) external override kicked notFelled onlyClerk update(who) {
    if (brens[who]) {
      brenc--;
      brens[who] = false;
    } else {
      brenc++;
      brens[who] = true;
    }
  }

  /// :::::::::::::::::::::::::  REND  :::::::::::::::::::::::: ///

  /// @notice Renders a Kink's styles and html on an alloy.
  function rend() external override pure returns (string memory style, string memory html) {
    style = ".text--line{font-size:400px;font-weight:bold;font-family:'Arial';}"
      ".top-text{fill:#50A682;font-weight: bold;font-color:#50A682;font-size:40px;font-family:'Arial';}"
      ".text-copy{fill:none;stroke:white;stroke-dasharray:25% 40%;stroke-width:4px;animation:stroke-offset 9s infinite linear;}"
      ".text-copy:nth-child(1){stroke:#FFFFFF;stroke-dashoffset:6% * 1;}.text-copy:nth-child(2){stroke:#FFFFFF;stroke-dashoffset:6% * 2;}"
      ".text-copy:nth-child(3){stroke:#FFFFFF;stroke-dashoffset:6% * 3;}.text-copy:nth-child(4){stroke:#FFFFFF;stroke-dashoffset:6% * 4;}"
      ".text-copy:nth-child(5){stroke:#FFFFFF;stroke-dashoffset:6% * 5;}.text-copy:nth-child(6){stroke:#FFFFFF;stroke-dashoffset:6% * 6;}"
      ".text-copy:nth-child(7){stroke:#FFFFFF;stroke-dashoffset:6% * 7;}.text-copy:nth-child(8){stroke:#FFFFFF;stroke-dashoffset:6% * 8;}"
      ".text-copy:nth-child(9){stroke:#FFFFFF;stroke-dashoffset:6% * 9;}.text-copy:nth-child(10){stroke:#FFFFFF;stroke-dashoffset:6% * 10;}"
      "@keyframes stroke-offset{45%{stroke-dashoffset:40%;stroke-dasharray:25% 0%;}60%{stroke-dashoffset:40%;stroke-dasharray:25% 0%;}}";

    html = "<rect width='100%' height='100%' fill='black' />"
      "<symbol id='s-text'>"
      "<text text-anchor='middle' x='50%' y='70%' class='text--line'>_</text>"
      "</symbol><g class='g-ants'>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use>"
      "<use href='#s-text' class='text-copy'></use></g>";
  }

  /// :::::::::::::::::::::::::  COIN  :::::::::::::::::::::::: ///

  /// @notice Returns the amount of reward per alloy staked
  function coin() public view returns (uint256) {
    if (brenc == 0) {
        return emissionBasis;
    }
    return emissionBasis + (((block.timestamp - stash) * EMISSION_RATE) / brenc);
  }

  function earned(address account) public view returns (uint256) {
    return (coin() - collected[account]) + accrued[account];
  }

  /// :::::::::::::::::::::::::  MODS  :::::::::::::::::::::::: ///

  modifier update(address account) {
    // Get the reward per alloy staked
    emissionBasis = coin();
    stash = block.timestamp;

    accrued[account] = earned(account);
    collected[account] = emissionBasis;
    _;
  }
}