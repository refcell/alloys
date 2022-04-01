// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Alloy} from "../Alloy.sol";
import {Clerk} from "../Clerk.sol";
import {Kink} from "../Kink.sol";
import {Ownable} from "../kinks/Ownable.sol";
import {IEvolve} from "../interfaces/IEvolve.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {Evolve} from "@evolve/Evolve.sol";

contract AlloyTest is DSTestPlus {
    Alloy alloy;
    Clerk clerk;
    IEvolve evolve;

    address constant public EVOLVE_WARDEN = 0xc9AB63915c6738c8Ce5ca245979203Bfa3F2499F;

    function setUp() public {
        console.log(unicode"🧪 Testing Alloy...");
        alloy = new Alloy();
        clerk = alloy.CLERK();
        evolve = alloy.EVOLVE();

        // Deploy a new Evolve and etch into the EVOLVE address
        startHoax(EVOLVE_WARDEN, EVOLVE_WARDEN, type(uint256).max);
        Evolve ev = new Evolve();
        vm.etch(address(evolve), address(ev).code);
        vm.stopPrank();

        // Sanity check etch
        assertEq(evolve.warden(), EVOLVE_WARDEN);

        // Hoax evolve to allow user to mint
        startHoax(EVOLVE_WARDEN, EVOLVE_WARDEN, type(uint256).max);
        evolve.setMintable(address(alloy), 1000);
        vm.stopPrank();
    }

    function testMetadata() public {
        assertEq(alloy.name(), "Alloy");
        assertEq(alloy.symbol(), "ALOY");
        assertEq(alloy.MAXIMUM_TOKENS(), 100);
        assertEq(alloy.KEEP_REWARD(), 100);
    }

    function testCast() public {
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.cast(address(1337));
        vm.stopPrank();
        assertEq(alloy.balanceOf(address(1337)), 1);
        assertEq(evolve.balanceOf(address(1337)), 100);
        assertEq(alloy.nextId(), 1);

        // The same address can't mint twice
        startHoax(address(1337), address(1337), type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("DuplicateCast()"));
        alloy.cast(address(1337));
        vm.stopPrank();
        assertEq(alloy.balanceOf(address(1337)), 1);
        assertEq(evolve.balanceOf(address(1337)), 100);
        assertEq(alloy.nextId(), 1);

        // Cast works!
        console.log(unicode"✅ cast tests passed!");
    }

    function testMeld() public {
        // First, deploy a new Ownable kink
        Ownable ownable = new Ownable();

        // User can't meld without being a keep
        startHoax(address(1337), address(1337), type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("NotKeep()"));
        alloy.meld(address(ownable));
        vm.stopPrank();

        // Let's mint the user an alloy
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.cast(address(1337));
        vm.stopPrank();
        assertEq(alloy.balanceOf(address(1337)), 1);
        assertEq(evolve.balanceOf(address(1337)), 100);
        assertEq(alloy.nextId(), 1);

        // The kink shouldn't be melded
        assertTrue(!alloy.melded(address(ownable)));

        // The user can now meld the kind
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.meld(address(ownable));
        vm.stopPrank();
        assertTrue(alloy.melded(address(ownable)));

        // Cast works!
        console.log(unicode"✅ meld tests passed!");
    }

    function testReap() public {
        // Meld an ownable kink
        Ownable ownable = new Ownable();
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.cast(address(1337));
        alloy.meld(address(ownable));
        vm.stopPrank();

        // Jump to non-zero block timestamp to avoid triggering UnKicked Revert
        vm.warp(1 days);

        // First we have to kick the kink
        ownable.kick(block.timestamp + 10 days);

        // Jump to middle of the reaping period
        vm.warp(5 days);

        // Reap the kink
        assertEq(ownable.balanceOf(address(1337)), 0);
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.reap();
        vm.stopPrank();

        // The keep should now have 100 kink units distributed them for 4 days
        assertEq(ownable.balanceOf(address(1337)), 400 * 10 ** ownable.decimals());

        // Cast works!
        console.log(unicode"✅ meld tests passed!");
    }
}
