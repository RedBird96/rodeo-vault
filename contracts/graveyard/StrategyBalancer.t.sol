// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTest} from "./utils/DSTest.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IBalancerVault} from "../interfaces/IBalancerVault.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockStrategyHelper} from "./mocks/MockStrategyHelper.sol";
import {MockCurveGauge} from "./mocks/MockCurveGauge.sol";
import {MockBalancerVaultPool} from "./mocks/MockBalancerVaultPool.sol";
import {Util} from "../Util.sol";
import {StrategyBalancer} from "../strategies/StrategyBalancer.sol";

contract StrategyBalancerTest is DSTest {
    MockERC20 usdc;
    MockERC20 weth;
    MockERC20 bal;
    MockStrategyHelper sh;
    MockBalancerVaultPool vaultPool;
    MockCurveGauge gauge;
    StrategyBalancer s;

    function setUp() public {
        usdc = new MockERC20(6);
        weth = new MockERC20(18);
        bal = new MockERC20(18);
        sh = new MockStrategyHelper();
        sh.setPrice(address(usdc), 1e18);
        sh.setPrice(address(weth), 1500e18);
        sh.setPrice(address(bal), 5.5e18);
        vaultPool = new MockBalancerVaultPool(usdc, weth);
        vaultPool.mint(address(0), 77e18);
        gauge = new MockCurveGauge(vaultPool, bal);
        s = new StrategyBalancer(
            address(sh),
            address(vaultPool),
            address(gauge),
            address(vaultPool),
            address(usdc)
        );
        usdc.mint(address(this), 1000e6);
        usdc.approve(address(s), 1000e6);
    }

    function testRate() public {
        s.mint(address(usdc), 50e6, "");
        assertEq(s.rate(50e18) / 1e16, 5002);
    }

    function testMint() public {
        uint256 shares = s.mint(address(usdc), 50e6, "");
        assertEq(shares, 50e18);
        assertEq(vaultPool.balanceOf(address(gauge)), 50e18);
        assertEq(gauge.balanceOf(address(s)), 50e18);
    }

    function testBurn() public {
        s.mint(address(usdc), 50e6, "");
        uint256 amt = s.burn(address(usdc), 25e18, "");
        assertEq(amt, 33250000);
        assertEq(vaultPool.balanceOf(address(gauge)), 33.25e18);
        assertEq(gauge.balanceOf(address(s)), 33.25e18);
        assertEq(s.totalShares(), 25e18);
    }

    function testEarn() public {
        s.mint(address(usdc), 1e6, "");
        s.earn();
        s.earn();
        s.earn();
        assertEq(s.rate(1e18) / 1e16, 5052);
        s.earn();
        assertEq(s.totalShares(), 1e18);
        assertEq(s.rate(1e18) / 1e16, 6699);
        assertEq(gauge.balanceOf(address(s)), 67e18);
    }

    function testExitMove() public {
        StrategyBalancer s2 = new StrategyBalancer(
            address(sh),
            address(vaultPool),
            address(gauge),
            address(vaultPool),
            address(usdc)
        );
        s.mint(address(usdc), 50e6, "");
        s.exit(address(s2));
        assertEq(gauge.balanceOf(address(s)), 0);
        assertEq(vaultPool.balanceOf(address(s2)), 66.5e18);
        s2.move(address(s));
        assertEq(vaultPool.balanceOf(address(s2)), 0);
        assertEq(gauge.balanceOf(address(s2)), 66.5e18);
        assertEq(s2.totalShares(), 66.5e18);
    }
}
