// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {ERC20} from "../ERC20.sol";
import {LiquidityMiningSimple} from "../token/LiquidityMiningSimple.sol";

contract LiquidityMiningSimpleTest is Test {
    LiquidityMiningSimple c;

    function setUp() public override {
        super.setUp();
        c = new LiquidityMiningSimple(address(usdcPool));
        c.file("rate", 1000e18);
        c.file("tokenReward", address(weth));
        weth.transfer(address(c), 100e18);
        usdc.approve(address(usdcPool), 120e6);
        usdcPool.mint(120e6, address(this));
        usdcPool.approve(address(c), 120e6);
        vm.warp(block.timestamp + 3600);
    }

    function testFile() public {
        c.file("rate", 123);
        assertEq(c.rate(), 123);
        c.file("tokenReward", vm.addr(1));
        assertEq(address(c.tokenReward()), vm.addr(1));
        c.file("exec", vm.addr(2));
        assertTrue(c.exec(vm.addr(2)));
        c.file("exec", vm.addr(2));
        assertTrue(!c.exec(vm.addr(2)));
        c.file("paused", 1);
        vm.expectRevert();
        c.deposit(1e6, address(this));
    }

    function testDeposit() public {
        c.deposit(50e6, address(this));
        (uint256 deposit, int256 claimed) = c.users(address(this));
        assertEq(deposit, 50e6);
        assertEq(claimed, 0);
        vm.warp(block.timestamp + 3600);
        c.deposit(10e6, address(this));
        (deposit, claimed) = c.users(address(this));
        assertEq(deposit, 60e6);
        assertEq(claimed, 16666666666666666666);
    }

    function testWithdraw() public {
        c.deposit(10e6, address(this));
        uint256 before = usdcPool.balanceOf(address(this));
        c.withdraw(4e6, address(this));
        (uint256 deposit, int256 claimed) = c.users(address(this));
        assertEq(deposit, 6e6);
        assertEq(claimed, -16666666666666666666);
        assertEq(c.getPending(address(this)), 41666666666666666665);
        assertEq(usdcPool.balanceOf(address(this)) - before, 4e6);
        c.withdraw(1e6, address(this));
        vm.expectRevert();
        c.withdraw(10e6, address(this));
    }

    function testHarvest() public {
        c.deposit(50e6, address(this));
        vm.warp(block.timestamp + 3600);
        uint256 before = weth.balanceOf(address(this));
        assertEq(c.getPending(address(this)), 83333333333333333333);
        c.harvest(address(this));
        (uint256 deposit, int256 claimed) = c.users(address(this));
        assertEq(deposit, 50e6);
        assertEq(claimed, 83333333333333333333);
        assertEq(weth.balanceOf(address(this)) - before, 83333333333333333333);

        before = weth.balanceOf(address(this));
        c.harvest(address(this));
        (deposit, claimed) = c.users(address(this));
        assertEq(deposit, 50e6);
        assertEq(claimed, 83333333333333333333);
        assertEq(weth.balanceOf(address(this)) - before, 0);
    }
}
