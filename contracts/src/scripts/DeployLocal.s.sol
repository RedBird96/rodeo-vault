// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DSTest} from "../test/utils/DSTest.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";
import {MockOracle} from "../test/mocks/MockOracle.sol";
import {Pool} from "../Pool.sol";
import {PoolRateModel} from "../PoolRateModel.sol";
import {Investor} from "../Investor.sol";
import {InvestorActor} from "../InvestorActor.sol";
import {InvestorActorStrategyProxy} from "../InvestorActorStrategyProxy.sol";
import {InvestorHelper} from "../InvestorHelper.sol";
import {PositionManager} from "../PositionManager.sol";
import {LiquidityMining} from "../token/LiquidityMining.sol";
import {StrategyHelper} from "../StrategyHelper.sol";
import {StrategyTest} from "../strategies/StrategyTest.sol";

contract DeployLocal is DSTest {
    function run() external {
        vm.startBroadcast();
        MockERC20 usdc = new MockERC20(6);
        MockERC20 weth = new MockERC20(18);
        usdc.mint(address(this), 1000e6);
        weth.mint(address(this), 100e18);
        PoolRateModel poolRateModel = new PoolRateModel(0, 634195839, 0, 0);
        MockOracle usdcOracle = new MockOracle(1e8);
        MockOracle wethOracle = new MockOracle(1500e8);
        Pool usdcPool =
            new Pool(address(usdc), address(poolRateModel), address(usdcOracle), 1e6, 95e16, 1000000e6);
        Pool wethPool =
            new Pool(address(weth), address(poolRateModel), address(wethOracle), 1e16, 90e16, 1000e18);
        Investor investor = new Investor();
        InvestorActorStrategyProxy iasp = new InvestorActorStrategyProxy();
        InvestorActor investorActor = new InvestorActor(address(investor), address(iasp));
        iasp.file("exec", address(investorActor));
        investor.file("actor", address(investorActor));
        usdcPool.file("exec", address(investorActor));
        wethPool.file("exec", address(investorActor));
        investor.file("pools", address(usdcPool));
        investor.file("pools", address(wethPool));
        InvestorHelper ih = new InvestorHelper(address(investor));
        PositionManager pm = new PositionManager(address(investor));
        LiquidityMining lm = new LiquidityMining();
        lm.file("rewardPerDay", 10e18);
        lm.file("rewardToken", address(weth));
        lm.poolAdd(1000, address(usdcPool));
        weth.mint(address(lm), 1000e18);

        StrategyHelper sh = new StrategyHelper();
        sh.setOracle(address(usdc), address(usdcOracle));
        sh.setOracle(address(weth), address(wethOracle));

        StrategyTest st = new StrategyTest(address(sh));
        investor.setStrategy(0, address(st));
        st.file("exec", address(iasp));

        {
            address a = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
            usdc.mint(a, 1000e6);
            usdc.mint(address(st), 1000e6);
            usdc.approve(address(usdcPool), 500e6);
            usdcPool.mint(500e6, a);
            usdc.approve(address(pm), 2e6);
            pm.mint(a, address(usdcPool), 0, 2e6, 5e6, "");

            weth.mint(address(st), 1e18);
            weth.mint(a, 15e18);
            weth.approve(address(wethPool), 5e18);
            wethPool.mint(5e18, a);
        }

        vm.stopBroadcast();
        emit log_named_address("USDC", address(usdc));
        emit log_named_address("WETH", address(weth));
        emit log_named_address("PoolRateModel", address(poolRateModel));
        emit log_named_address("USDC Pool", address(usdcPool));
        emit log_named_address("WETH Pool", address(wethPool));
        emit log_named_address("Investor", address(investor));
        emit log_named_address("InvestorHelper", address(ih));
        emit log_named_address("PositionManager", address(pm));
        emit log_named_address("LiquidityMining", address(lm));
        emit log_named_address("StrategyHelper", address(sh));
        emit log_named_address("StrategyTest", address(st));
    }
}
