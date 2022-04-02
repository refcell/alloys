// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import {Alloy} from "../Alloy.sol";
import {Clerk} from "../Clerk.sol";
import {Kink} from "../Kink.sol";
import {Ownable} from "../kinks/Ownable.sol";
import {IEvolve} from "../interfaces/IEvolve.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {Evolve} from "@evolve/Evolve.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";

contract KinkTest is DSTestPlus {
    Alloy alloy;
    Clerk clerk;
    Ownable kink;
    IEvolve evolve;

    address constant public EVOLVE_WARDEN = 0xc9AB63915c6738c8Ce5ca245979203Bfa3F2499F;

    function setUp() public {
        console.log(unicode"🧪 Testing Kink...");
        alloy = new Alloy();
        clerk = alloy.CLERK();
        evolve = alloy.EVOLVE();

        // Deploy a new Ownable Kink
        kink = new Ownable();

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
        assertEq(kink.name(), "Kink");
        assertEq(kink.symbol(), "KINK");
        assertEq(kink.prex(), address(this));
        assertEq(kink.BASE_UNIT(), 1e18);
        assertEq(kink.EMISSION_RATE(), 100 * kink.BASE_UNIT());
        assertEq(kink.EMISSION_QUANTUM(), 1 days);
    }

    function testReap(address rando) public {
        if (rando == address(this) || rando == address(0) || rando == address(alloy) || rando == address(clerk) || rando == address(kink)) {
            rando = address(1337);
        }

        // Meld an ownable kink
        startHoax(rando, rando, type(uint256).max);
        alloy.cast(rando);
        alloy.meld(address(kink));
        vm.stopPrank();

        // Once the kink is melded, it should be rolled
        assertEq(address(kink.alloy()), address(alloy));

        // Once the kink is melded, it should be linked
        assertEq(address(kink.clerk()), address(clerk));

        // The clerk can only link once
        startHoax(address(clerk), address(clerk), type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("ClerkSet()"));
        kink.link();
        vm.stopPrank();

        // Only the clerk can roll
        startHoax(rando, rando, type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("NotClerk()"));
        kink.roll(ERC721(address(alloy)));
        vm.stopPrank();

        // Only an address conforming to the IClerk Interface can roll
        startHoax(rando, rando, type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("NotClerk()"));
        kink.roll(ERC721(address(alloy)));
        vm.stopPrank();

        // Jump to non-zero block timestamp to avoid triggering UnKicked Revert
        vm.warp(1 days);

        // Reaping fails if kink isn't kicked
        assertEq(kink.seed(), 0);
        assertEq(kink.fell(), 0);
        startHoax(rando, rando, type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("UnKicked()"));
        kink.reap(rando);
        vm.stopPrank();

        // Only the prex can kick
        startHoax(rando, rando, type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("ExecutiveOrder66()"));
        kink.kick(block.timestamp + 10 days);
        vm.stopPrank();

        // First we have to kick the kink
        kink.kick(block.timestamp + 10 days);
        assertEq(kink.seed(), block.timestamp);
        assertEq(kink.fell(), block.timestamp + 10 days);

        // Reaping fails if kink is felled
        vm.warp(12 days);
        startHoax(rando, rando, type(uint256).max);
        vm.expectRevert(abi.encodeWithSignature("Felled()"));
        kink.reap(rando);
        vm.stopPrank();

        // Jump to middle of the reaping period
        vm.warp(5 days);

        // We can reap directly on the kink
        assertEq(kink.balanceOf(rando), 0);
        startHoax(rando, rando, type(uint256).max);
        kink.reap(rando);
        vm.stopPrank();

        // The keep should now have 100 kink units distributed them for 4 days
        assertEq(kink.balanceOf(rando), 400 * 10 ** kink.decimals());
        assertEq(kink.base(rando), block.timestamp);

        // If the user reaps again, the kink shouldn't give them any more
        startHoax(rando, rando, type(uint256).max);
        kink.reap(rando);
        vm.stopPrank();
        assertEq(kink.balanceOf(rando), 400 * 10 ** kink.decimals());

        // Cast works!
        console.log(unicode"✅ reap tests passed!");
    }
}
