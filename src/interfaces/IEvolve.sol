// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {IERC20} from "./IERC20.sol";

/// @title IEvolve Interface
/// @author andreas@nascent.xyz
interface IEvolve is IERC20 {
    function mint(address to, uint256 value) external;
    function setMintable(address minter, uint256 amount) external;
    function warden() external view returns (address);
}