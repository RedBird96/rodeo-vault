// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {TokenStakingDividends} from "../token/TokenStakingDividends.sol";

contract TokenStakingDividendsTest is Test {
    MockERC20 rdo;
    TokenStakingDividends c;

    function setUp() public override {
        rdo = new MockERC20(18);
        c = new TokenStakingDividends();
        c.setReward(0, address(rdo));
        rdo.mint(address(this), 1000e18);
        rdo.approve(address(c), 1000e18);
    }

    function testSetReward() public {
        vm.startPrank(vm.addr(1));
        vm.expectRevert();
        c.setReward(1, address(1));
        vm.stopPrank();

        c.setReward(1, address(1));
        (IERC20 token,) = c.rewards(1);
        assertEq(address(token), address(1));
    }

    function testDonate() public {
        vm.startPrank(vm.addr(1));
        vm.expectRevert();
        c.donate(0, 1);
        vm.stopPrank();

        c.onAllocate(vm.addr(1), 10e18);
        c.onAllocate(vm.addr(2), 30e18);

        c.donate(0, 80e18);

        (, uint256 perShare) = c.rewards(0);
        assertEq(perShare, 2e12);
        (uint256 owed,) = c.claimable(vm.addr(1), 0);
        assertEq(owed, 20e18);
    }

    function testClaim() public {
        c.onAllocate(address(this), 10e18);
        c.onAllocate(vm.addr(2), 30e18);

        c.donate(0, 100e18);
        uint256 before = rdo.balanceOf(address(this));
        c.claim();
        assertEq(rdo.balanceOf(address(this)) - before, 25e18);

        (uint256 owed, int256 claimed) = c.claimable(address(this), 0);
        assertEq(owed, 0);
        assertEq(claimed, 25e18);
    }

    function testAllocations() public {
        c.onAllocate(vm.addr(1), 10e18);
        c.onAllocate(vm.addr(2), 30e18);
        c.donate(0, 60e18);
        assertEq(getClaimable(vm.addr(1)), 15e18);
        assertEq(getClaimable(vm.addr(2)), 45e18);
        c.onDeallocate(vm.addr(2), 20e18);
        c.donate(0, 40e18);
        assertEq(getClaimable(vm.addr(1)), 35e18);
        assertEq(getClaimable(vm.addr(2)), 65e18);
        c.onDeallocate(vm.addr(2), 99e18);
        c.donate(0, 1e18);
        assertEq(getClaimable(vm.addr(1)), 36e18);
        assertEq(getClaimable(vm.addr(2)), 65e18);
    }

    function getClaimable(address user) public view returns (uint256) {
        (uint256 owed,) = c.claimable(user, 0);
        return owed;
    }
}
