// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {Util} from "../Util.sol";
import {Pool} from "../Pool.sol";
import {PoolRateModel} from "../PoolRateModel.sol";
import {InvestorActor} from "../InvestorActor.sol";
import {ERC20} from "../ERC20.sol";

contract PoolTest is Test {
    function setUp() public override {
        super.setUp();
        investorActor.file("poolMaxUtilization", 0.99e18);
    }

    function testFile() public {
        vm.startPrank(vm.addr(1));
        vm.expectRevert(Util.Unauthorized.selector);
        usdcPool.file("test", 1);
        vm.stopPrank();

        usdcPool.file("paused", 1);
        assertEq(usdcPool.paused() ? 1 : 0, 1);
        usdcPool.file("borrowMin", 2);
        assertEq(usdcPool.borrowMin(), 2);
        usdcPool.file("liquidationFactor", 4);
        assertEq(usdcPool.liquidationFactor(), 4);
        usdcPool.file("amountCap", 5);
        assertEq(usdcPool.amountCap(), 5);
        usdcPool.file("exec", vm.addr(1));
        assertTrue(usdcPool.exec(vm.addr(1)));
        usdcPool.file("exec", vm.addr(1));
        assertTrue(!usdcPool.exec(vm.addr(1)));
        usdcPool.file("rateModel", vm.addr(2));
        assertEq(address(usdcPool.rateModel()), vm.addr(2));
        usdcPool.file("oracle", vm.addr(3));
        assertEq(address(usdcPool.oracle()), vm.addr(3));
    }

    function testInitialMint() public {
        Pool p = new Pool(address(usdc), address(poolRateModel), address(usdcOracle), 100e6, 95e16, 1000000e6);
        usdc.approve(address(p), 10e6);
        p.mint(10e6, address(this));
        assertEq(p.balanceOf(address(this)), 9e6);
        assertEq(p.balanceOf(0x000000000000000000000000000000000000dEaD), 1e6);
    }

    function testTransfer() public {
        usdc.approve(address(usdcPool), 1e6);
        usdcPool.mint(1e6, address(this));
        usdcPool.transfer(vm.addr(2), 6e5);
        assertEq(usdcPool.balanceOf(address(this)), 399989);
        assertEq(usdcPool.balanceOf(vm.addr(2)), 6e5);
    }

    function testTransferFrom() public {
        usdc.approve(address(usdcPool), 2e6);
        usdcPool.mint(2e6, address(this));
        usdcPool.approve(address(vm.addr(1)), 1e6);

        vm.startPrank(vm.addr(1));

        vm.expectRevert(ERC20.InsufficientBalance.selector);
        usdcPool.transferFrom(t, vm.addr(2), 10000e6);
        vm.expectRevert(ERC20.InsufficientAllowance.selector);
        usdcPool.transferFrom(t, vm.addr(2), 11e5);

        assertEq(usdcPool.allowance(t, vm.addr(1)), 1e6);
        usdcPool.transferFrom(t, vm.addr(2), 1e6);
        assertEq(usdcPool.balanceOf(vm.addr(2)), 1e6);
        assertEq(usdcPool.allowance(t, vm.addr(1)), 0);
    }

    function testMint() public {
        usdcPool.file("borrowMin", 1e5);
        // Revert on missing approval
        vm.expectRevert(bytes("insufficient allowance"));
        usdcPool.mint(1e6, address(this));
        // First mint
        usdc.approve(address(usdcPool), 13e6);
        usdcPool.mint(10e6, address(this));
        assertEq(usdc.balanceOf(address(this)), 940e6);
        assertEq(usdcPool.balanceOf(address(this)), 9999890);
        assertEq(usdcPool.totalSupply(), 1009999890);
        // Mint more
        usdcPool.mint(1e6, address(this));
        assertEq(usdc.balanceOf(address(this)), 939e6);
        assertEq(usdcPool.balanceOf(address(this)), 10999879);
        assertEq(usdcPool.totalSupply(), 1010999879);
        // Same index at 0% utilization
        vm.warp(block.timestamp + 86400);
        usdcPool.mint(1e6, address(this));
        assertEq(usdcPool.balanceOf(address(this)), 11999862);
        // Less shares once index accrues interest
        usdc.approve(address(investor), 1e6);
        investor.earn(address(this), address(usdcPool), 0, 1e6, 1e6, "");
        vm.warp(block.timestamp + (2 * 86400));
        usdcPool.mint(1e6, address(this));
        assertEq(usdcPool.balanceOf(address(this)), 12999834);

        investorActor.file("poolMaxUtilization", 0.5e18);
        usdc.approve(address(investor), 300e6);
        vm.expectRevert(InvestorActor.PoolOverMaxUtilization.selector);
        investor.earn(address(this), address(usdcPool), 0, 300e6, 850e6, "");
    }

    function testBurn() public {
        usdcPool.file("borrowMin", 1e5);

        vm.startPrank(vm.addr(1));
        vm.expectRevert(Pool.UtilizationTooHigh.selector);
        usdcPool.burn(950e6, address(this));
        vm.stopPrank();

        usdc.approve(address(usdcPool), 10e6);
        usdcPool.mint(10e6, address(this));
        uint256 before = usdc.balanceOf(address(this));
        usdcPool.burn(9e6, address(this));
        assertEq(usdc.balanceOf(address(this)) - before, 9000098);
        assertEq(usdcPool.balanceOf(address(this)), 999890);
        assertEq(usdcPool.totalSupply(), 1000999890);

        // Withdraw more USDC when index increased
        usdc.approve(address(investor), 1e6);
        investor.earn(address(this), address(usdcPool), 0, 1e6, 5e6, "");
        vm.warp(block.timestamp + 86400);
        before = usdc.balanceOf(address(this));
        usdcPool.burn(4e5, address(this));
        assertEq(usdc.balanceOf(address(this)) - before, 400006);
    }

    function testUpdate() public {
        uint256 year = 365 * 24 * 60 * 60;
        PoolRateModel rm = new PoolRateModel(85e16, 2e16/year, 4e16/year, 150e16/year);
        usdcPool.file("rateModel", address(rm));

        vm.warp(block.timestamp + year);
        usdcPool.update();
        // Utilization is ~10%, borrow should pay 2% + 0.4%
        assertEq(usdcPool.index() / 1e14, 10241);

        strategy1.file("rate", 1500e18);
        usdc.approve(address(investor), 300e6);
        investor.earn(address(this), address(usdcPool), 0, 300e6, 850e6, "");
        vm.warp(block.timestamp + year);
        usdcPool.update();
        // Utilization is ~95%, borrow should pay 2% + 3.4% + 15% (+ previous 2.4 compounded)
        assertEq(usdcPool.index() / 1e14, 12332);
    }

    function testRepay() public {
        uint256 bor = usdcPool.borrow(10e6);
        uint256 balanceUsdc = usdc.balanceOf(address(this));
        uint256 borrowBefore = usdcPool.totalBorrow();
        usdc.approve(address(usdcPool), 10e6);
        usdcPool.repay(bor);
        assertEq(balanceUsdc - usdc.balanceOf(address(this)), 9999999);
        assertEq(borrowBefore - usdcPool.totalBorrow(), bor);

        usdc.approve(address(usdcPool), 0);
        vm.expectRevert();
        usdcPool.repay(1000);
    }

    function testEmergency() public {
        vm.expectRevert(Pool.NotInEmergency.selector);
        usdcPool.emergency();

        usdcPool.file("emergency", 1);
        usdc.approve(address(usdcPool), 1e6);
        usdcPool.mint(1e6, address(this));
        uint256 before = usdc.balanceOf(address(this));
        usdcPool.emergency();
        assertEq(usdc.balanceOf(address(this)) - before, 999999);
    }

    function testGetters() public {
        assertEq(usdcPool.getUtilization(), 1e17);
        assertEq(usdcPool.getTotalLiquidity(), 1000e6);
        assertEq(usdcPool.getTotalBorrow(), 100e6);
        assertEq(usdcPool.getUpdatedIndex(), 1000109588406783361);
    }
}
