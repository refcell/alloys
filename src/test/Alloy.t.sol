// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Alloy} from "../Alloy.sol";
import {Clerk} from "../Clerk.sol";
import {Kink} from "../Kink.sol";
import {Ownable} from "../kinks/Ownable.sol";
import {Staked} from "../kinks/Staked.sol";
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
        uint256 evolveMintables = alloy.KEEP_REWARD() * alloy.MAXIMUM_TOKENS();
        evolve.setMintable(EVOLVE_WARDEN, evolveMintables);
        evolve.mint(address(alloy), evolveMintables);
        vm.stopPrank();
    }

    function testMetadata() public {
        assertEq(alloy.name(), "Alloy");
        assertEq(alloy.symbol(), "ALOY");
        assertEq(alloy.MAXIMUM_TOKENS(), 1_000);
        assertEq(alloy.KEEP_REWARD(), 10_000);
    }

    function testCast() public {
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.cast(address(1337));
        vm.stopPrank();
        assertEq(alloy.balanceOf(address(1337)), 1);
        assertEq(evolve.balanceOf(address(1337)), 10_000);
        assertEq(alloy.nextId(), 1);

        // The same address can't mint twice
        startHoax(address(1337), address(1337), type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("DuplicateCast()"));
        alloy.cast(address(1337));
        vm.stopPrank();
        assertEq(alloy.balanceOf(address(1337)), 1);
        assertEq(evolve.balanceOf(address(1337)), 10_000);
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
        assertEq(evolve.balanceOf(address(1337)), 10_000);
        assertEq(alloy.nextId(), 1);

        // The kink shouldn't be melded
        assertTrue(!alloy.melded(address(ownable)));

        // The user can now meld the kink
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.meld(address(ownable));
        vm.stopPrank();
        assertTrue(alloy.melded(address(ownable)));

        // Cast works!
        console.log(unicode"✅ meld tests passed!");
    }

    function testSuit(address rando) public {
        // First, deploy a new Ownable kink
        Ownable ownable = new Ownable();

        // User can't suit without being a keep
        if (rando == address(alloy) || rando == address(0)) {
            rando = address(1337);
        }
        startHoax(rando, rando, type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("NotKeep()"));
        alloy.suit(address(ownable), 1, true);
        vm.stopPrank();

        // Let's mint the user an alloy
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.cast(address(1337));
        vm.stopPrank();
        assertEq(alloy.balanceOf(address(1337)), 1);
        assertEq(evolve.balanceOf(address(1337)), 10_000);
        assertEq(alloy.nextId(), 1);

        // User can't suit a different token id than they own
        startHoax(rando, rando, type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("NotKeep()"));
        alloy.suit(address(ownable), 2, true);
        vm.stopPrank();

        // The user can now suit
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.meld(address(ownable));
        alloy.suit(address(ownable), 1, true);
        vm.stopPrank();
        assertTrue(alloy.suited(address(ownable), 1));

        // Cast works!
        console.log(unicode"✅ suit tests passed!");
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

        // If the user reaps again, the kink shouldn't give them any more
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.reap();
        vm.stopPrank();
        assertEq(ownable.balanceOf(address(1337)), 400 * 10 ** ownable.decimals());

        // Cast works!
        console.log(unicode"✅ reap tests passed!");
    }

    function testBrenOwnable() public {
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

        // Then, let's bren our alloy token
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.bren(1, address(ownable));
        vm.stopPrank();

        // Jump to middle of the reaping period
        vm.warp(5 days);

        // Reap the kink
        assertEq(ownable.balanceOf(address(1337)), 0);
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.reap();
        vm.stopPrank();

        // The keep should now have 100 kink units distributed them for 4 days
        assertEq(ownable.balanceOf(address(1337)), 400 * 10 ** ownable.decimals());

        // If the user reaps again, the kink shouldn't give them any more
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.reap();
        vm.stopPrank();
        assertEq(ownable.balanceOf(address(1337)), 400 * 10 ** ownable.decimals());

        // Cast works!
        console.log(unicode"✅ reap tests passed!");
    }

    function testBrenStaked() public {
        // Meld a staked kink
        Staked staked = new Staked();
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.cast(address(1337));
        alloy.meld(address(staked));
        vm.stopPrank();

        // Jump to non-zero block timestamp to avoid triggering UnKicked Revert
        vm.warp(1 days);

        // First we have to kick the kink
        staked.kick(block.timestamp + 10 days);

        // Then, let's bren our alloy token
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.bren(1, address(staked));
        vm.stopPrank();

        // Jump to middle of the reaping period
        vm.warp(5 days);

        // Reap the kink
        assertEq(staked.balanceOf(address(1337)), 0);
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.reap();
        vm.stopPrank();

        // The keep should now have 100 kink units distributed them for 4 days
        uint256 collected = (5 days - 1 days) * staked.EMISSION_RATE();
        assertEq(staked.balanceOf(address(1337)), collected);

        // If the user reaps again, the kink shouldn't give them any more
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.reap();
        vm.stopPrank();
        assertEq(staked.balanceOf(address(1337)), collected);

        // Cast works!
        console.log(unicode"✅ reap tests passed!");
    }
}
