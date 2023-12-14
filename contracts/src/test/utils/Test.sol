// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTest} from './DSTest.sol';
import {IERC20} from "../../interfaces/IERC20.sol";
import {MockERC20} from "../mocks/MockERC20.sol";
import {MockOracle} from "../mocks/MockOracle.sol";
import {MockStrategy} from "../mocks/MockStrategy.sol";
import {Pool} from "../../Pool.sol";
import {PoolRateModel} from "../../PoolRateModel.sol";
import {Investor} from "../../Investor.sol";
import {InvestorActor} from "../../InvestorActor.sol";
import {InvestorActorStrategyProxy} from "../../InvestorActorStrategyProxy.sol";
import {InvestorHelper} from "../../InvestorHelper.sol";
import {PositionManager} from "../../PositionManager.sol";
import {StrategyHelper} from "../../StrategyHelper.sol";
import {Guard} from "../../Guard.sol";

contract Test is DSTest {
    address t;
    MockERC20 usdc;
    MockERC20 weth;
    MockOracle usdcOracle;
    MockOracle wethOracle;
    PoolRateModel poolRateModel;
    Pool usdcPool;
    Pool wethPool;
    MockStrategy strategy1;
    Investor investor;
    InvestorActor investorActor;
    InvestorActorStrategyProxy iasp;
    InvestorHelper ih;
    PositionManager pm;
    StrategyHelper sh;
    Guard guard;
    MockERC20 guardToken;

    function setUp() virtual public {
        t = address(this);
        usdc = new MockERC20(6);
        weth = new MockERC20(18);
        usdc.mint(address(this), 2000e6);
        weth.mint(address(this), 100e18);
        poolRateModel = new PoolRateModel(0, 634195839, 0, 0);
        usdcOracle = new MockOracle(1e8);
        wethOracle = new MockOracle(1650e8);
        usdcPool = new Pool(address(usdc), address(poolRateModel), address(usdcOracle), 10e6, 95e16, 1000000e6);
        wethPool = new Pool(address(weth), address(poolRateModel), address(wethOracle), 1e17, 90e16, 1000e18);
        investor = new Investor();
        iasp = new InvestorActorStrategyProxy();
        investorActor = new InvestorActor(address(investor), address(iasp));
        iasp.file("exec", address(investorActor));
        investor.file("actor", address(investorActor));
        investorActor.file("softLiquidationThreshold", 1e18);
        usdcPool.file("exec", address(investorActor));
        wethPool.file("exec", address(investorActor));
        investor.file("pools", address(usdcPool));
        investor.file("pools", address(wethPool));
        strategy1 = new MockStrategy();
        usdc.approve(address(usdcPool), 1000e6);
        usdc.approve(address(investor), 50e6);
        investor.setStrategy(0, address(strategy1));
        usdcPool.mint(1000e6, vm.addr(1));
        investor.earn(address(this), address(usdcPool), 0, 50e6, 100e6, "");
        vm.warp(2 * 86400);
        ih = new InvestorHelper(address(investor));
        pm = new PositionManager(address(investor));
        investorActor.file("positionManager", address(pm));
        sh = new StrategyHelper();
        sh.setOracle(address(usdc), address(usdcOracle));
        sh.setOracle(address(weth), address(wethOracle));

        guardToken = new MockERC20(18);
        guard = new Guard(address(guardToken));
        guard.file("exec", address(investorActor));
    }
}
