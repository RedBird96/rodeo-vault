// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {Util} from "../Util.sol";
import {Investor} from "../Investor.sol";
import {InvestorActor} from "../InvestorActor.sol";
import {MockStrategy} from "./mocks/MockStrategy.sol";
import {ERC721TokenReceiver} from "../PositionManager.sol";

contract InvestorTest is Test, ERC721TokenReceiver {
    function setUp() public override {
        super.setUp();
        usdcPool.file("borrowMin", 1e5);
    }

    function testFile() public {
        vm.startPrank(vm.addr(1));
        vm.expectRevert(Util.Unauthorized.selector);
        investor.file("test", 1);
        vm.stopPrank();

        investor.file("status", 3);
        assertEq(investor.status(), 3);
        investor.file("exec", vm.addr(1));
        assertTrue(investor.exec(vm.addr(1)));
        investor.file("exec", vm.addr(1));
        assertTrue(!investor.exec(vm.addr(1)));
        investor.setStrategy(1, vm.addr(1));
        assertEq(investor.strategies(1), vm.addr(1));
        vm.expectRevert(Investor.StrategyIndexToHigh.selector);
        investor.setStrategy(9, vm.addr(1));
    }

    function testEarn() public {
        vm.expectRevert(Investor.InvalidPool.selector);
        investor.earn(address(this), vm.addr(1), 0, 1e6, 1e6, "");
        vm.expectRevert(Investor.InvalidStrategy.selector);
        investor.earn(address(this), address(usdcPool), 9, 1e6, 1e6, "");

        usdc.approve(address(investor), 100e6);
        uint256 id = investor.earn(address(this), address(usdcPool), 0, 1e6, 0, "");
        (address ow, address po, uint256 st,, uint256 a, uint256 s, uint256 b) = investor.positions(id);
        assertEq(ow, address(this));
        assertEq(po, address(usdcPool));
        assertEq(st, 0);
        assertEq(a, 123e6);
        assertEq(s, 123e18);
        assertEq(b, 0);

        strategy1.file("rate", 20e18);
        vm.expectRevert();
        investor.earn(address(this), address(usdcPool), 0, 0, 20e6, "");
        strategy1.file("rate", 123e18);

        strategy1.file("mint", 222e18);
        uint256 before = usdc.balanceOf(address(this));
        id = investor.earn(address(this), address(usdcPool), 0, 2e6, 3e6, "");
        assertEq(before - usdc.balanceOf(address(this)), 2e6);
        (ow, po, st,, a, s, b) = investor.positions(id);
        assertEq(ow, address(this));
        assertEq(po, address(usdcPool));
        assertEq(st, 0);
        assertEq(a, 120e6);
        assertEq(s, 222e18);
        assertEq(b, 2999671);

        investorActor.file("originationFee", 20);
        before = usdcPool.balanceOf(address(0));
        id = investor.earn(address(this), address(usdcPool), 0, 1e6, 1e6, "");
        assertEq(usdc.balanceOf(address(investorActor)) - before, 2000);
    }

    function testSell() public {
        uint256 borrow;
        usdc.approve(address(investor), 3e6);
        usdc.transfer(address(strategy1), 3e6);
        strategy1.file("rate", 3e18);
        strategy1.file("mint", 100e18);
        strategy1.file("burn", 6e6);
        uint256 id = investor.earn(address(this), address(usdcPool), 0, 1e6, 2e6, "");
        (,,,,,, borrow) = investor.positions(id);

        strategy1.file("burn", 1e6);
        vm.roll(block.number + 1);
        vm.expectRevert(InvestorActor.InsufficientAmountForRepay.selector);
        investor.edit(id, -100e18, 0 - int256(borrow), "");

        strategy1.file("rate", 0e18);
        strategy1.file("burn", 6e6);
        vm.roll(block.number + 1);
        vm.expectRevert(Investor.Undercollateralized.selector);
        investor.edit(id, -100e18, 0, "");

        vm.warp(block.timestamp + 2592000);
        uint256 before = usdc.balanceOf(address(this));
        vm.expectCall(address(strategy1), abi.encodeCall(MockStrategy.burn, (address(usdc), 100e18, "")));
        investor.edit(id, -100e18, 0 - int256(borrow), "");
        assertEq(usdc.balanceOf(address(this)) - before, 3697043);
        assertEq(usdc.balanceOf(address(usdcPool)), 900003286);
        assertEq(usdc.balanceOf(address(strategy1)), 150000000);
        assertEq(usdc.balanceOf(address(investorActor)), 299671);

        strategy1.file("rate", 5e18);
        investorActor.file("guard", address(guard));
        id = investor.earn(address(this), address(usdcPool), 0, 1e6, 0, "");
        vm.roll(block.number + 1);
        investor.edit(id, -100e18, 0, "");
        assertEq(usdc.balanceOf(address(investorActor)), 399671);
    }

    function testSave() public {
        usdc.approve(address(investor), 6e6);
        usdc.transfer(address(strategy1), 3e6);
        strategy1.file("rate", 6e18);
        strategy1.file("mint", 100e18);
        strategy1.file("burn", 6e6);
        uint256 id = investor.earn(address(this), address(usdcPool), 0, 1e6, 2e6, "");
        vm.roll(block.number + 1);

        investor.edit(id, 2e6, 0, "");
        vm.roll(block.number + 1);
        assertEq(usdc.balanceOf(address(strategy1)), 158000000);
        (,,,, uint256 a, uint256 s, uint256 b) = investor.positions(id);
        assertEq(a, 6e6);
        assertEq(s, 200e18);
        assertEq(b, 1999780);
        assertEq(investor.life(id), 2850001207397144459);

        // Should allow borrowing more without depositing more
        investor.edit(id, 0, 0.5e6, "");

        // Should disallow borrowing more and divesting shares
        vm.roll(block.number + 1);
        vm.expectRevert();
        investor.edit(id, -1e18, 0.5e6, "");
    }

    function testKill() public {
        usdc.approve(address(investor), 4e6);
        usdc.transfer(address(strategy1), 3e6);
        strategy1.file("rate", 6e18);
        strategy1.file("burn", 6e6);
        uint256 id = investor.earn(address(this), address(usdcPool), 0, 1e6, 2e6, "");

        vm.roll(block.number + 1);
        vm.expectRevert(InvestorActor.PositionNotLiquidatable.selector);
        investor.kill(id, "");

        vm.startPrank(vm.addr(1));
        strategy1.file("rate", 21e17);
        strategy1.file("burn", 21e5);
        investor.kill(id, "");
        assertEq(usdc.balanceOf(vm.addr(1)), 52500);
        assertEq(usdc.balanceOf(address(usdcPool)), 899995000);

        vm.stopPrank();
        investorActor.file("liquidationFee", 250);
        strategy1.file("rate", 6e18);
        id = investor.earn(address(this), address(usdcPool), 0, 1e6, 2e6, "");
        vm.roll(block.number + 1);
        vm.startPrank(vm.addr(2));
        strategy1.file("rate", 21e17);
        uint256 before = usdc.balanceOf(address(investorActor));
        investor.kill(id, "");
        assertEq(usdc.balanceOf(vm.addr(2)), 26250);
        assertEq(usdc.balanceOf(address(usdcPool)), 899994999);
        assertEq(usdc.balanceOf(address(investorActor)) - before, 26250);
        assertEq(usdc.balanceOf(address(investorActor)), 78750);
    }

    function testKillWhenOwnerIsPM() public {
        usdc.approve(address(pm), 4e6);
        usdc.transfer(address(strategy1), 3e6);
        strategy1.file("rate", 6e18);
        strategy1.file("burn", 6e6);
        uint256 id = investor.nextPosition();
        pm.mint(address(this), address(usdcPool), 0, 1e6, 2e6, "");
        vm.roll(block.number + 1);
        vm.startPrank(vm.addr(1));
        strategy1.file("rate", 21e17);
        strategy1.file("burn", 3e6);
        uint256 beforeU = usdc.balanceOf(address(this));
        uint256 beforePM = usdc.balanceOf(address(pm));
        investor.kill(id, "");
        assertEq(usdc.balanceOf(address(this)) - beforeU, 850001);
        assertEq(usdc.balanceOf(address(pm)) - beforePM, 0);
    }

    function testLife() public {
        usdc.approve(address(investor), 4e6);
        strategy1.file("rate", 6e18);
        strategy1.file("burn", 6e6);
        uint256 id = investor.earn(address(this), address(usdcPool), 0, 1e6, 0e6, "");
        assertEq(investor.life(id), 1e18);
        id = investor.earn(address(this), address(usdcPool), 0, 1e6, 2e6, "");
        assertEq(investor.life(id), 2850001207397144459);
        strategy1.file("rate", 2e18);
        assertEq(investor.life(id), 950000402465714819);
        strategy1.file("rate", 10e18);
        assertEq(investor.life(id), 4750002012328574099);
    }
}
