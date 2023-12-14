// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {ERC20} from "../ERC20.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {LiquidityMining} from "../token/LiquidityMining.sol";

contract LiquidityMiningTest is Test {
    MockERC20 lp;
    LiquidityMining c;

    function setUp() public override {
        super.setUp();
        lp = new MockERC20(18);
        c = new LiquidityMining();
        c.file("rewardPerDay", 1000e18);
        c.file("rewardToken", address(weth));
        c.file("lpToken", address(lp));
        c.file("strategyHelper", address(this));
        c.file("lpBoostAmount", 2e18);
        c.file("lpBoostThreshold", 0.05e18);
        weth.transfer(address(c), 100e18);
        c.poolAdd(6000, address(usdcPool));
        c.poolAdd(4000, address(wethPool));
        usdc.approve(address(usdcPool), 120e6);
        usdcPool.mint(120e6, address(this));
        usdcPool.approve(address(c), 120e6);
        vm.warp(block.timestamp + 3600);
    }

    function testInfo() public {
        assertEq(c.poolLength(), 2);
        assertEq(c.totalAllocPoint(), 10000);
    }

    function testFile() public {
        c.file("boostMax", 567);
        assertEq(c.boostMax(), 567);
        c.file("boostMaxDuration", 2 days);
        assertEq(c.boostMaxDuration(), 2 days);
        c.file("rewardPerDay", 123);
        assertEq(c.rewardPerDay(), 123);
        c.file("rewardToken", vm.addr(1));
        assertEq(address(c.rewardToken()), vm.addr(1));
        c.file("exec", vm.addr(2));
        assertTrue(c.exec(vm.addr(2)));
        c.file("exec", vm.addr(2));
        assertTrue(!c.exec(vm.addr(2)));
        c.file("paused", 1);
        vm.expectRevert();
        c.deposit(0, 1e6, address(this), 0);
    }

    function testConfigure() public {
        c.poolAdd(1000, address(usdc));
        assertEq(c.poolLength(), 3);
        assertEq(c.totalAllocPoint(), 11000);
        assertEq(address(c.token(2)), address(usdc));
        (, uint128 accRewardPerShare, uint64 lastRewardTime, uint64 allocPoint) = c.poolInfo(2);
        assertEq(accRewardPerShare, 0);
        assertEq(lastRewardTime, block.timestamp);
        assertEq(allocPoint, 1000);
        c.poolSet(2, 2000);
        (,,, allocPoint) = c.poolInfo(2);
        assertEq(allocPoint, 2000);
        assertEq(c.totalAllocPoint(), 12000);
    }

    function testDeposit() public {
        c.deposit(0, 50e6, address(this), 0);
        (uint256 amount,,,, int256 rewardDebt,) = c.userInfo(0, address(this));
        assertEq(amount, 50e6);
        assertEq(rewardDebt, 0);
        vm.warp(block.timestamp + 3600);
        c.deposit(0, 10e6, address(this), 0);
        (amount,,,, rewardDebt,) = c.userInfo(0, address(this));
        assertEq(amount, 60e6);
        assertEq(rewardDebt, 50e17);

        c.withdraw(0, 60e6, address(this));

        c.deposit(0, 10e6, address(this), 3600);
        (,,,,, uint256 lock) = c.userInfo(0, address(this));
        assertEq(lock, block.timestamp + 3600);
        // errors when withdrawing before lock end
        vm.expectRevert();
        c.withdraw(0, 1e6, address(this));
        vm.warp(block.timestamp + 3600);
        c.withdraw(0, 1e6, address(this));
        c.deposit(0, 1e6, address(this), 0);
    }

    function testWithdraw() public {
        c.deposit(0, 10e6, address(this), 0);
        uint256 before = usdcPool.balanceOf(address(this));
        c.withdraw(0, 4e6, address(this));
        (uint256 amount,,,, int256 rewardDebt,) = c.userInfo(0, address(this));
        assertEq(amount, 6e6);
        assertEq(rewardDebt, 0);
        assertEq(usdcPool.balanceOf(address(this)) - before, 4e6);
        c.withdraw(0, 1e6, address(this));

        usdcPool.transfer(address(c), 10e6);
        vm.expectRevert();
        c.withdraw(0, 10e6, address(this));
    }

    function testWithdrawEarly() public {
        c.deposit(0, 10e6, address(this), 30 days);
        uint256 before = usdcPool.balanceOf(address(this));
        c.withdrawEarly(0, address(this));
        (uint256 amount,,,, int256 rewardDebt,) = c.userInfo(0, address(this));
        assertEq(amount, 0);
        assertEq(rewardDebt, 0);
        assertEq(usdcPool.balanceOf(address(this)) - before, 9383562);
        assertEq(usdcPool.balanceOf(address(0)), 616438);
    }

    function testEmergencyWithdraw() public {
        c.deposit(0, 10e6, address(this), 0);
        uint256 before = usdcPool.balanceOf(address(this));
        c.emergencyWithdraw(0, address(this));
        (uint256 amount,,,, int256 rewardDebt,) = c.userInfo(0, address(this));
        assertEq(amount, 0);
        assertEq(rewardDebt, 0);
        assertEq(usdcPool.balanceOf(address(this)) - before, 10e6);
    }

    function testWrapping() public {
        c.deposit(0, 10e6, address(this), 0);
        uint256 before = usdc.balanceOf(address(this));
        (uint256 amount,,,,,) = c.userInfo(0, address(this));
        c.withdrawWithUnwrap(0, amount, address(this));
        assertEq(usdc.balanceOf(address(this)) - before, 10000111);
    }

    function testHarvest() public {
        c.deposit(0, 50e6, address(this), 0);
        vm.warp(block.timestamp + 3600);
        uint256 before = weth.balanceOf(address(this));
        assertEq(c.pendingRewards(0, address(this)), 25e18);
        c.harvest(0, address(this), address(0));
        (uint256 amount,,,, int256 rewardDebt,) = c.userInfo(0, address(this));
        assertEq(amount, 50e6);
        assertEq(rewardDebt, 25e18);
        assertEq(weth.balanceOf(address(this)) - before, 25e18);

        before = weth.balanceOf(address(this));
        c.harvest(0, address(this), address(0));
        (amount,,,, rewardDebt,) = c.userInfo(0, address(this));
        assertEq(amount, 50e6);
        assertEq(rewardDebt, 25e18);
        assertEq(weth.balanceOf(address(this)) - before, 0);
    }

    function testHarvestBoosted() public {
        usdcPool.transfer(vm.addr(1), 50e6);
        vm.startPrank(vm.addr(1));
        usdcPool.approve(address(c), 50e6);
        c.deposit(0, 50e6, vm.addr(1), 0);
        vm.stopPrank();

        c.deposit(0, 50e6, address(this), 365 days / 2);

        vm.warp(block.timestamp + 3600);
        assertEq(c.pendingRewards(0, address(this)), 15e18);
        assertEq(c.pendingRewards(0, vm.addr(1)), 10e18);

        uint256 before = weth.balanceOf(address(this));
        c.harvest(0, address(this), address(0));
        (uint256 amount,,,, int256 rewardDebt,) = c.userInfo(0, address(this));
        assertEq(amount, 50e6);
        assertEq(rewardDebt, 15e18);
        assertEq(weth.balanceOf(address(this)) - before, 15e18);
    }

    function testDepositLp() public {
        lp.mint(address(this), 1e18);
        lp.approve(address(c), 1e18);
        c.deposit(0, 10e6, address(this), 0);
        c.depositLp(0, address(this), 1e18);
        vm.warp(block.timestamp + 3600);
        (uint256 amount, uint256 lpAmt,, uint256 boostLp,, uint256 owed, uint256 val, uint256 lpValue) =
            c.getUser(0, address(this));
        assertEq(amount, 10e6);
        assertEq(lpAmt, 1e18);
        assertEq(boostLp, 2e18);
        assertEq(owed, 24999999999999999999);
        assertEq(val, 10e18);
        assertEq(lpValue, 220e18);
    }

    function testWithdrawLp() public {
        lp.mint(address(this), 2e18);
        lp.approve(address(c), 2e18);
        c.depositLp(0, address(this), 2e18);
        uint256 before = lp.balanceOf(address(this));
        c.withdrawLp(0, 1e18, address(this));
        (, uint256 amountLp,,,,) = c.userInfo(0, address(this));
        assertEq(amountLp, 1e18);
        assertEq(lp.balanceOf(address(this)) - before, 1e18);

        vm.expectRevert();
        c.withdrawLp(0, 99e18, address(this));
    }

    function value(address asset, uint256 amount) public view returns (uint256) {
        if (asset == address(lp)) {
            return amount * 220;
        }
        return amount * 1e12;
    }
}
