// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {Vester} from "../token/Vester.sol";
import {TokenStaking} from "../token/TokenStaking.sol";

contract TokenStakingTest is Test {
    Vester vester;
    TokenStaking c;
    bool allocateCalled;
    bool deallocateCalled;

    function setUp() public override {
        usdc = new MockERC20(6);
        vester = new Vester();
        c = new TokenStaking(address(usdc), address(vester));
        usdc.mint(address(this), 10_000e6);
        usdc.approve(address(c), 10_000e6);
        c.setPlugin(0, address(this), 0.01e18, address(1));
    }

    function testFile() public {
        c.file("exec", vm.addr(1));
        assert(c.exec(vm.addr(1)));
        c.file("token", vm.addr(1));
        assertEq(address(c.token()), vm.addr(1));
        c.file("vester", vm.addr(1));
        assertEq(address(c.vester()), vm.addr(1));
        c.file("whitelist", vm.addr(1));
        assert(c.whitelist(vm.addr(1)));
        c.file("vestingFeeTarget", vm.addr(1));
        assertEq(c.vestingFeeTarget(), vm.addr(1));
        c.file("paused", 1);
        assert(c.paused());
        c.file("vestingTimeMin", 42);
        assertEq(c.vestingTimeMin(), 42);
        c.file("vestingTimeMax", 42);
        assertEq(c.vestingTimeMax(), 42);
        c.file("vestingFee", 42);
        assertEq(c.vestingFee(), 42);
    }

    function testSetPlugin() public {
        c.setPlugin(1, vm.addr(1), 42, vm.addr(2));
        (, address target, uint256 fee, address feeTarget) = c.plugins(1);
        assertEq(target, vm.addr(1));
        assertEq(fee, 42);
        assertEq(feeTarget, vm.addr(2));
    }

    function testMint() public {
        c.mint(20e6, address(this));
        uint256 t = block.timestamp;
        vm.warp(t + 1);

        assertEq(c.totalSupply(), 20e6);
        assertEq(c.balanceOf(address(this)), 20e6);
        assertEq(c.delegates(address(this)), address(this));
        vm.expectRevert();
        c.transfer(address(0), 1e6);
        c.file("whitelist", address(this));
        c.transfer(address(0), 1e6);

        uint256 t2 = block.timestamp;
        vm.warp(t2 + 1);
        assertEq(c.getPriorVotes(address(this), t), 20e6);
        assertEq(c.getPriorVotes(address(this), t2), 19e6);

        c.delegate(vm.addr(1));
        uint256 t3 = block.timestamp;
        vm.warp(t3 + 1);
        assertEq(c.getCurrentVotes(vm.addr(1)), 19e6);
        assertEq(c.getCurrentVotes(address(this)), 0);
        assertEq(c.getPriorVotes(vm.addr(1), t3), 19e6);
        assertEq(c.getPriorVotes(address(this), t3), 0);

        c.mint(20e6, address(this));
        assertEq(c.balanceOf(address(this)), 39e6);
    }

    function testBurn() public {
        c.mint(10e6, address(this));
        vm.expectRevert();
        c.burn(1e6, 14 days);
        c.burn(1e6, 31.5 days);
        assertEq(c.balanceOf(address(this)), 9e6);
        assertEq(usdc.balanceOf(address(0)), 0.45e6);
        assertEq(usdc.balanceOf(address(vester)), 0.55e6);
        c.burn(1e6, 181 days);
        assertEq(usdc.balanceOf(address(vester)), 1.55e6);
        vm.expectRevert();
        c.burn(100e6, 15 days);
        c.allocate(1, 1e6);
        vm.expectRevert();
        c.burn(7.5e6, 15 days);

        assertEq(c.totalSupply(), 8e6);
    }

    function testAllocate() public {
        c.mint(10e6, address(this));
        vm.expectRevert();
        c.deallocate(0, 1);
        c.allocate(0, 5e6);
        (uint256 amount,,,) = c.plugins(0);
        assertEq(amount, 5e6);
        assertEq(c.allocated(address(this)), 5e6);
        assertEq(c.allocations(address(this), 0), 5e6);
        assert(allocateCalled);
        vm.expectRevert();
        c.allocate(0, 6e6);
    }

    function testDeallocate() public {
        vm.expectRevert();
        c.allocate(0, 1);
        c.mint(10e6, address(this));
        c.allocate(0, 5e6);
        c.deallocate(0, 2e6);
        (uint256 amount,,,) = c.plugins(0);
        assertEq(amount, 3e6);
        assertEq(c.allocated(address(this)), 3e6);
        assertEq(c.allocations(address(this), 0), 3e6);
        assertEq(c.balanceOf(address(this)), 9.98e6);
        assertEq(usdc.balanceOf(address(1)), 0.02e6);
        assert(deallocateCalled);
    }

    function testGetUser() public {
        c.mint(10e6, address(this));
        c.allocate(0, 5e6);
        c.allocate(1, 1e6);
        (uint256 balance, uint256 allocated, uint256[] memory allocations) = c.getUser(address(this), 2);
        assertEq(balance, 10e6);
        assertEq(allocated, 6e6);
        assertEq(allocations.length, 2);
        assertEq(allocations[0], 5e6);
        assertEq(allocations[1], 1e6);
    }

    function onAllocate(address, uint256) public {
        allocateCalled = true;
    }

    function onDeallocate(address, uint256) public {
        deallocateCalled = true;
    }
}
