// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Alloy} from "../Alloy.sol";
import {Clerk} from "../Clerk.sol";
import {Kink} from "../Kink.sol";
import {Ownable} from "../kinks/Ownable.sol";
import {IEvolve} from "../interfaces/IEvolve.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {Evolve} from "@evolve/Evolve.sol";

contract ClerkTest is DSTestPlus {
    Alloy alloy;
    Clerk clerk;
    IEvolve evolve;

    address constant public EVOLVE_WARDEN = 0xc9AB63915c6738c8Ce5ca245979203Bfa3F2499F;

    function setUp() public {
        console.log(unicode"🧪 Testing Clerk...");
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
        assertEq(address(clerk.alloy()), address(alloy));
        assertEq(clerk.kinkc(), 0);
    }

    function testMeld(address rando) public {
        // First, deploy a new Ownable kink
        Ownable ownable = new Ownable();

        // Melding directly on the clerk should fail - it has to be alloy
        if (rando == address(alloy)) {
            rando = address(1337);
        }
        startHoax(rando, rando, type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("NonAlloy()"));
        clerk.meld(address(ownable));
        vm.stopPrank();

        // The user can now meld
        assertEq(clerk.mass().length, 0);
        assertTrue(!clerk.melded(address(ownable)));
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.cast(address(1337));
        alloy.meld(address(ownable));
        vm.stopPrank();
        assertTrue(clerk.melded(address(ownable)));
        assertEq(clerk.kinkc(), 1);
        assertEq(clerk.kinks(1), address(ownable));
        assertEq(clerk.mass()[0], address(ownable));

        // Cast works!
        console.log(unicode"✅ meld tests passed!");
    }

    function testSuit(address rando) public {
        // First, deploy a new Ownable kink
        Ownable ownable = new Ownable();

        // Suiting directly on the clerk should fail - it has to be alloy
        if (rando == address(alloy)) {
            rando = address(1337);
        }
        startHoax(rando, rando, type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("NonAlloy()"));
        clerk.suit(address(ownable), 1, true);
        vm.stopPrank();

        // The user can now suit
        assertEq(clerk.mass().length, 0);
        assertTrue(!clerk.melded(address(ownable)));
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.cast(address(1337));
        alloy.meld(address(ownable));
        alloy.suit(address(ownable), 1, true);
        vm.stopPrank();
        assertTrue(clerk.suited(1, 1));

        // Cast works!
        console.log(unicode"✅ suit tests passed!");
    }

    function testPile(address rando) public {
        // First, deploy a new Ownable kink
        Ownable ownable = new Ownable();

        // Initial piling should return empty renderings
        (string memory styles, string memory html) = clerk.pile(1);
        assertEq(bytes(styles).length, 0);
        assertEq(bytes(html).length, 0);

        // After suiting, pile should return that kinks uri
        startHoax(address(1337), address(1337), type(uint256).max);
        alloy.cast(address(1337));
        alloy.meld(address(ownable));
        alloy.suit(address(ownable), 1, true);
        vm.stopPrank();
        (string memory styles2, string memory html2) = clerk.pile(1);
        assertTrue(bytes(styles2).length > 0);
        assertTrue(bytes(html2).length > 0);

        // Cast works!
        console.log(unicode"✅ pile tests passed!");
    }

    function testReap(address rando) public {
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

        // Only Alloy can directly reap the clerk
        if (rando == address(alloy)) {
            rando = address(1337);
        }
        startHoax(rando, rando, type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("NonAlloy()"));
        clerk.reap(address(ownable));
        vm.stopPrank();

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
}
