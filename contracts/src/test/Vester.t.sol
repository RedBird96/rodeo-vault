// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {Vester} from "../token/Vester.sol";

contract VesterTest is Test {
    Vester c;

    function setUp() public override {
        usdc = new MockERC20(6);
        c = new Vester();
        usdc.mint(address(this), 10_000e6);
        usdc.approve(address(c), 10_000e6);
    }

    function testSetExec() public {
        c.file("exec", vm.addr(1));
        assertEq(c.exec(vm.addr(1)) ? 1 : 0, 1);
        c.file("exec", vm.addr(1));
        assertEq(c.exec(vm.addr(1)) ? 1 : 0, 0);
    }

    function testSetExit() public {
        c.setExit(vm.addr(1), 0.42e18);
        assertEq(c.exitTarget(), vm.addr(1));
        assertEq(c.exitPenalty(), 0.42e18);
    }

    function testVest() public {
        address target = vm.addr(1);
        c.vest(8, target, address(usdc), 200e6, 0.2e18, 300, 1800);
        assertEq(c.schedulesCount(target), 1);
        (uint256[] memory amount, uint256[] memory claimed, uint256[] memory available) = c.getSchedules(target, 0, 1);
        assertEq(amount[0], 200e6);
        assertEq(claimed[0], 0);
        assertEq(available[0], 40e6);
        (
            uint256[] memory source,
            address[] memory token,
            uint256[] memory initial,
            uint256[] memory time,
            uint256[] memory start
        ) = c.getSchedulesInfo(target, 0, 1);
        assertEq(token[0], address(usdc));
        assertEq(initial[0], 0.2e18);
        assertEq(time[0], 1800);
        assertEq(start[0], 301);
    }

    function testClaim() public {
        c.vest(8, vm.addr(1), address(usdc), 200e6, 0.2e18, 300, 1800);
        vm.startPrank(vm.addr(1));
        c.claim(0, address(0));
        assertEq(usdc.balanceOf(vm.addr(1)), 40e6);

        // 0%
        vm.warp(block.timestamp + 300);
        assertEq(c.getAvailable(vm.addr(1), 0), 40e6);
        vm.expectRevert();
        c.claim(0, address(0));
        assertEq(usdc.balanceOf(vm.addr(1)), 40e6);

        // 50%
        vm.warp(block.timestamp + 900);
        assertEq(c.getAvailable(vm.addr(1), 0), 120e6);
        c.claim(0, address(0));
        assertEq(usdc.balanceOf(vm.addr(1)), 120e6);

        // >100%
        vm.warp(block.timestamp + 1000);
        assertEq(c.getAvailable(vm.addr(1), 0), 200e6);
        uint256 before = usdc.balanceOf(address(this));
        c.claim(0, address(this));
        assertEq(usdc.balanceOf(address(this)) - before, 80e6);
        assertEq(onClaimFrom, vm.addr(1));
        assertEq(onClaimAmount, 80e6);

        vm.stopPrank();
        c.setPaused(vm.addr(1), 0, true);
        vm.startPrank(vm.addr(1));
        vm.expectRevert();
        c.claim(0, address(0));

        vm.expectRevert();
        c.claim(1, address(0));
    }

    function testExit() public {
        c.vest(8, vm.addr(1), address(usdc), 200e6, 0.2e18, 300, 1800);
        c.vest(108, vm.addr(1), address(usdc), 200e6, 0.2e18, 300, 1800);
        vm.startPrank(vm.addr(1));

        vm.expectRevert();
        c.exit(0);

        // Vested 20% initial (40) + 25% progress (40)
        // penalty is 50% of remaining (120/2 = 60)
        vm.warp(block.timestamp + 750);
        c.exit(1);
        assertEq(usdc.balanceOf(vm.addr(1)), 140e6);
        assertEq(usdc.balanceOf(address(0)), 60e6);

        vm.expectRevert();
        c.claim(1, address(0));
    }

    address onClaimFrom;
    uint256 onClaimAmount;

    function onClaim(address from, uint256, address, uint256 amount) external {
        onClaimFrom = from;
        onClaimAmount = amount;
    }
}
