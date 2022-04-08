// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Alloy} from "../Alloy.sol";
import {Clerk} from "../Clerk.sol";
import {Kink} from "../Kink.sol";
import {Ownable} from "../kinks/Ownable.sol";
import {Staked} from "../kinks/Staked.sol";
import {IEvolve} from "../interfaces/IEvolve.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {Deployer} from "../deploy/Deployer.sol";

import {Evolve} from "@evolve/Evolve.sol";

contract DeployerTest is DSTestPlus {
  Deployer deployer;

  /// @notice The Evolve Reward Token
  IEvolve constant public EVOLVE = IEvolve(0x14813e8905a0f782F796A5273d2EFbe6551100D6);
  address constant public EVOLVE_WARDEN = 0xc9AB63915c6738c8Ce5ca245979203Bfa3F2499F;

  function setUp() public {
    console.log(unicode"🧪 Testing Deployer...");

    // Deploy a new Evolve and etch into the EVOLVE address
    startHoax(EVOLVE_WARDEN, EVOLVE_WARDEN, type(uint256).max);
    Evolve ev = new Evolve();
    vm.etch(address(EVOLVE), address(ev).code);
    vm.stopPrank();

    // Mint evolve tokens
    startHoax(EVOLVE_WARDEN, EVOLVE_WARDEN, type(uint256).max / 2);
    EVOLVE.setMintable(EVOLVE_WARDEN, 10_000_000);
    EVOLVE.mint(address(this), 10_000_000);
    vm.stopPrank();
  }

  function testDeployer() public {
    deployer = new Deployer();
  }
}