// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {Investor} from "../Investor.sol";
import {PositionManager, ERC721TokenReceiver} from "../PositionManager.sol";

contract PositionManagerTest is Test, ERC721TokenReceiver {
    function setUp() public override {
        super.setUp();
        usdcPool.file("borrowMin", 0);
        usdc.mint(address(strategy1), 100e6);
    }

    function testAll() public {
        usdc.approve(address(pm), 2e6);
        pm.mint(address(this), address(usdcPool), 0, 1e6, 2e6, "");
        uint256 id = investor.nextPosition() - 1;
        assertEq(pm.balanceOf(address(this)), 1);
        assertEq(pm.ownerOf(id), address(this));
        vm.roll(block.number + 1);
        pm.edit(id, 1e6, 0, "");
        uint256 before = usdc.balanceOf(address(this));
        vm.roll(block.number + 1);
        pm.edit(id, -123e18, -1e6, "");
        assertEq(usdc.balanceOf(address(this)) - before, 121999891);
        vm.roll(block.number + 1);
        vm.expectRevert("NOT_CLOSED");
        pm.burn(id);
        (,,,,,, uint256 borrow) = investor.positions(id);
        pm.edit(id, -123e18, 0 - int256(borrow), "");
        vm.roll(block.number + 1);
        pm.burn(id);
        assertEq(pm.balanceOf(address(this)), 0);
    }
}
