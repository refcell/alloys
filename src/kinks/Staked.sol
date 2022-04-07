// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Kink} from "../Kink.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

/// @title Staked Kink
/// @notice Vests tokens using a staking mechanism.
/// @author andreas@nascent.xyz
contract Staked is Kink {

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

  /// :::::::::::::::::::::::::  REND  :::::::::::::::::::::::: ///

  /// @notice Renders a Kink's styles and html on an alloy.
  function rend() external override view returns (string memory style, string memory html) {
    style = ".text--line{font-size:400px;font-weight:bold;font-family:'Arial';}"
      ".top-text{fill:#50A682;font-weight: bold;font-color:#50A682;font-size:40px;font-family:'Arial';}"
      ".text-copy{fill:none;stroke:white;stroke-dasharray:25% 40%;stroke-width:4px;animation:stroke-offset 9s infinite linear;}"
      ".text-copy:nth-child(1){stroke:#50A682;stroke-dashoffset:6% * 1;}.text-copy:nth-child(2){stroke:#50A682;stroke-dashoffset:6% * 2;}"
      ".text-copy:nth-child(3){stroke:#50A682;stroke-dashoffset:6% * 3;}.text-copy:nth-child(4){stroke:#50A682;stroke-dashoffset:6% * 4;}"
      ".text-copy:nth-child(5){stroke:#50A682;stroke-dashoffset:6% * 5;}.text-copy:nth-child(6){stroke:#50A682;stroke-dashoffset:6% * 6;}"
      ".text-copy:nth-child(7){stroke:#50A682;stroke-dashoffset:6% * 7;}.text-copy:nth-child(8){stroke:#50A682;stroke-dashoffset:6% * 8;}"
      ".text-copy:nth-child(9){stroke:#50A682;stroke-dashoffset:6% * 9;}.text-copy:nth-child(10){stroke:#50A682;stroke-dashoffset:6% * 10;}"
      "@keyframes stroke-offset{45%{stroke-dashoffset:40%;stroke-dasharray:25% 0%;}60%{stroke-dashoffset:40%;stroke-dasharray:25% 0%;}}";

    html = "<rect width='100%' height='100%' fill='black' />"
      "<symbol id='s-text'>"
      "<text text-anchor='middle' x='50%' y='70%' class='text--line'>A</text>"
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
}