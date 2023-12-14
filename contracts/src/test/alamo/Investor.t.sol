// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "../utils/Test.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockOracle} from "../mocks/MockOracle.sol";
import {MockStrategy} from "../mocks/MockStrategy.sol";

import {Pool} from "../../Pool.sol";
import {PoolRateModel} from "../../PoolRateModel.sol";
import {InvestorActorStrategyProxy} from "../../InvestorActorStrategyProxy.sol";
import {Bank} from "../../alamo/Bank.sol";
import {Store} from "../../alamo/Store.sol";
import {Investor} from "../../alamo/Investor.sol";

contract AInvestorTest is Test {
    MockERC20 public reth;
    MockOracle public oUsdc;
    MockOracle public oReth;
    Pool public p;
    Bank public b;
    Store public s;
    Investor public i;
    MockStrategy public st;

    function setUp() public override {
        usdc = new MockERC20(6);
        reth = new MockERC20(18);
        oUsdc = new MockOracle(1e8);
        oReth = new MockOracle(1600e8);
        p = new Pool(address(usdc), address(new PoolRateModel(0.5e18, 10000, 0, 0)),
              address(oUsdc), 0, 0.95e18, 10000e6);
        b = new Bank();
        s = new Store();
        i = new Investor(address(s), address(this));
        InvestorActorStrategyProxy iasp = new InvestorActorStrategyProxy();
        iasp.file("exec", address(i));
        i.file("strategyProxy", address(iasp));
        b.file("exec", address(i));
        p.file("exec", address(i));
        s.setUint(i.STATUS(), i.STATUS_LIVE());
        s.setUint(keccak256(abi.encode(address(reth), i.COLLATERAL_FACTOR())), 0.9e18);
        s.file("exec", address(i));
        i.file("bank", address(b));
        i.file("pool", address(p));

        st = new MockStrategy();
        s.setAddress(keccak256(abi.encode(1, i.STRATEGIES())), address(st));

        usdc.mint(address(this), 11000e6);
        reth.mint(address(this), 100e18);

        usdc.approve(address(p), 10000e6);
        p.mint(10000e6, address(this));
    }

    function testFile() public {
        i.file("exec", vm.addr(1));
        assertTrue(i.exec(vm.addr(1)));

        Store ns = new Store();
        ns.file("exec", address(i));

        vm.expectRevert();
        i.file("helper", vm.addr(1));
        i.file("helper", address(this));
        assertEq(address(i.helper()), address(this));

        vm.expectRevert();
        i.file("strategyProxy", vm.addr(1));
        i.file("strategyProxy", address(ns));
        assertEq(address(i.strategyProxy()), address(ns));

        vm.expectRevert();
        i.file("bank", vm.addr(1));
        i.file("bank", address(ns));
        assertEq(s.getAddress(i.BANK()), address(ns));

        Pool np = new Pool(address(usdc), address(new PoolRateModel(0.5e18, 10000, 0, 0)), address(oUsdc), 0, 0.95e18, 10000e6);
        vm.expectRevert();
        i.file("pool", address(np));
        np.file("exec", address(i));
        i.file("pool", address(np));
        assertEq(s.getAddress(i.POOL()), address(np));

        vm.expectRevert(Investor.InvalidFile.selector);
        i.file("slippage", 1.1e18);
        i.file("slippage", 123);
        assertEq(i.slippage(), 123);
        vm.expectRevert(Investor.InvalidFile.selector);
        i.file("performanceFee", 0.6e18);
        i.file("performanceFee", 123);
        assertEq(i.performanceFee(), 123);
        vm.expectRevert(Investor.InvalidFile.selector);
        i.file("killCollateralPadding", 2e18);
        i.file("killCollateralPadding", 123);
        assertEq(i.killCollateralPadding(), 123);
        vm.expectRevert(Investor.InvalidFile.selector);
        i.file("closeCollateralPadding", 2e18);
        i.file("closeCollateralPadding", 123);
        assertEq(i.closeCollateralPadding(), 123);

        vm.expectRevert(Investor.InvalidFile.selector);
        i.file("status", 0);
        vm.expectRevert(Investor.InvalidFile.selector);
        i.file("status", 5);
        i.file("status", 3);
        assertEq(s.getUint(i.STATUS()), 3);

        vm.expectRevert(Investor.InvalidFile.selector);
        i.file("random", vm.addr(1));
        vm.expectRevert(Investor.InvalidFile.selector);
        i.file("random", 1);


        vm.startPrank(vm.addr(2));
        vm.expectRevert(Investor.Unauthorized.selector);
        i.file("test", address(0));
        vm.expectRevert(Investor.Unauthorized.selector);
        i.file("test", 1);
    }

    function testCollect() public {
        usdc.transfer(address(i), 1.5e6);
        uint256 before = usdc.balanceOf(address(this));
        i.collect(address(usdc));
        assertEq(usdc.balanceOf(address(this))-before, 1.5e6);
        vm.startPrank(vm.addr(1));
        vm.expectRevert(Investor.Unauthorized.selector);
        i.collect(address(usdc));
    }

    function testOpen() public {
        st.file("rate", 810e18);
        st.file("mint", 800e18);
        st.file("burn", 810e6);
        reth.approve(address(i), 0.1e18);
        i.open(1, address(reth), 0.1e18, 800e6, "");
        uint256 id = 1;
        Investor.Position memory p = i.getPosition(id);
        assertEq(p.owner, address(this));
        assertEq(p.strategy, 1);
        assertEq(p.token, address(reth));
        assertEq(p.collateral, 0.1e18);
        assertEq(p.borrow, 800e6);
        assertEq(p.shares, 800e18);
        assertEq(p.basis, 810e18);
        assertEq(i.life(id), 1.09125e18);
    }

    function testEdit() public {
        st.file("rate", 810e18);
        st.file("mint", 800e18);
        st.file("burn", 810e6);
        reth.approve(address(i), 0.2e18);

        st.file("totalShares", 0);
        vm.expectRevert(Investor.StrategyUninitialized.selector);
        i.open(1, address(reth), 0.1e18, 800e6, "");
        st.file("totalShares", 123e18);

        uint256 id = i.open(1, address(reth), 0.1e18, 800e6, "");

        vm.expectRevert(Investor.NoEditingInSameBlock.selector);
        i.edit(id, 5e6, 0, "");

        vm.roll(block.number+1);

        i.file("status", i.STATUS_LIQUIDATE());
        vm.expectRevert(Investor.WrongStatus.selector);
        i.edit(id, 5e6, 0, "");
        i.file("status", i.STATUS_LIVE());

        vm.startPrank(vm.addr(2));
        vm.expectRevert(Investor.NotOwner.selector);
        i.edit(id, 5e6, 0, "");
        vm.stopPrank();

        // too many shares
        vm.expectRevert(Investor.InvalidParameters.selector);
        i.edit(id, -900e18, 0, "");

        // too much collateral
        vm.expectRevert(Investor.InvalidParameters.selector);
        i.edit(id, 0, -2e18, "");

        st.file("totalShares", 0);
        vm.expectRevert(Investor.StrategyUninitialized.selector);
        i.edit(id, 5e6, 0, "");
        st.file("totalShares", 123e18);

        // 1. borrow more
        st.file("mint", 5e18);
        st.file("rate", 815e18);
        i.edit(id, 5e6, 0, "");
        vm.roll(block.number+1);

        Investor.Position memory p = i.getPosition(id);
        assertEq(p.owner, address(this));
        assertEq(p.strategy, 1);
        assertEq(p.token, address(reth));
        assertEq(p.collateral, 0.1e18);
        assertEq(p.borrow, 805e6);
        assertEq(p.shares, 805e18);
        assertEq(p.basis, 1625e18);
        assertEq(i.life(id)/1e15, 1090);

        // 2. add collateral
        i.edit(id, 0, 0.05e18, "");
        vm.roll(block.number+1);
        p = i.getPosition(id);
        assertEq(p.collateral, 0.15e18);
        assertEq(p.borrow, 805e6);
        assertEq(p.shares, 805e18);
        assertEq(p.basis, 1625e18);
        assertEq(i.life(id)/1e15, 1179);

        // 3. remove collateral
        i.edit(id, 0, -0.025e18, "");
        vm.roll(block.number+1);
        p = i.getPosition(id);
        assertEq(p.collateral, 0.125e18);
        assertEq(i.life(id)/1e15, 1134);

        // 4. sell shares
        st.file("burn", 11e6);
        st.file("rate", 805e18);
        i.edit(id, -10e18, 0, "");
        vm.roll(block.number+1);
        p = i.getPosition(id);
        assertEq(p.borrow, 794e6);
        assertEq(p.shares, 795e18);
        assertEq(p.basis, 820e18);
        assertEq(i.life(id)/1e15, 1139);

        // 5. close position
        usdc.transfer(address(st), 10e6);
        uint256 beforeUsdc = usdc.balanceOf(address(this));
        uint256 beforeReth = reth.balanceOf(address(this));
        st.file("burn", 799e6);
        st.file("rate", 799e18);
        i.edit(id, -795e18, -0.125e18, "");
        vm.roll(block.number+1);
        p = i.getPosition(id);
        assertEq(p.collateral, 0);
        assertEq(p.borrow, 0);
        assertEq(p.shares, 0);
        assertEq(p.basis, 0);
        assertEq(i.life(id), 1e18);
        assertEq(usdc.balanceOf(address(this))-beforeUsdc, 4e6);
        assertEq(reth.balanceOf(address(this))-beforeReth, 0.125e18);

        vm.expectRevert(Investor.InvalidParameters.selector);
        i.edit(id, 1, 0, "");
    }

    function testEditCloseNeedingCollateral() public {
        st.file("rate", 810e18);
        st.file("mint", 800e18);
        st.file("burn", 810e6);
        reth.approve(address(i), 0.6e18);
        uint256 id = i.open(1, address(reth), 0.1e18, 800e6, "");
        vm.roll(block.number+1);
        st.file("rate", 400e18);
        st.file("burn", 400e6);
        Investor.Position memory p = i.getPosition(id);
        vm.expectRevert();
        i.edit(id, 0-int256(p.shares), 0, ""); 
        i.edit(id, 0-int256(p.shares), 0.5e18, ""); 
        p = i.getPosition(id);
        assertEq(p.shares, 0);
        assertEq(p.collateral, 0.34e18);
    }

    function testKill() public {
        st.file("rate", 810e18);
        st.file("mint", 800e18);
        st.file("burn", 810e6);
        reth.approve(address(i), 0.2e18);
        uint256 id = i.open(1, address(reth), 0.1e18, 800e6, "");

        vm.expectRevert(Investor.NoEditingInSameBlock.selector);
        i.kill(id, "");

        vm.roll(block.number+1);

        vm.expectRevert(Investor.PositionNotLiquidatable.selector);
        i.kill(id, "");

        st.file("burn", 700e6);
        st.file("rate", 700e18);

        i.file("status", i.STATUS_PAUSED());
        vm.expectRevert(Investor.WrongStatus.selector);
        i.kill(id, "");
        i.file("status", i.STATUS_LIQUIDATE());

        // kill it
        uint256 beforeUsdcKeeper = usdc.balanceOf(vm.addr(2));
        uint256 beforeUsdcInvestor = reth.balanceOf(address(i));
        vm.startPrank(vm.addr(2));
        i.kill(id, "");
        Investor.Position memory p = i.getPosition(id);
        assertEq(p.collateral, 0.0125e18);
        assertEq(p.borrow, 0);
        assertEq(p.shares, 0);
        assertEq(p.basis, 0);
        assertEq(i.life(id), 1e18);
        assertEq(usdc.balanceOf(vm.addr(2))-beforeUsdcKeeper, 20e6);
        assertEq(usdc.balanceOf(address(i))-beforeUsdcInvestor, 20e6);

        vm.stopPrank();
        vm.roll(block.number+1);
        i.file("status", i.STATUS_LIVE());

        // user can still withdraw leftover collateral
        i.edit(id, 0, -0.0125e18, "");
        p = i.getPosition(id);
        assertEq(p.collateral, 0);
    }

    // Helper methods
    function convert(address, address, uint256 amount) external pure returns (uint256) {
        // only used for usdc -> reth
        return amount * 1e30 / 1600e18;
    }
    function price(address) external pure returns (uint256) {
        // only used in file
        return 1600e18;
    }
    function value(address, uint256 amount) external pure returns (uint256) {
        // only used for reth
        return amount * 1600;
    }
    function swap(address tA, address tB, uint256 amount, uint256, address to) external returns (uint256) {
        MockERC20(tA).transferFrom(msg.sender, address(0), amount);
        MockERC20(tB).mint(to, amount * 1600e18 / 1e30);
        return amount * 1600e18 / 1e30;
    }
}
