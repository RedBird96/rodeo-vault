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
import {StrategyBalancerStable} from "../strategies/StrategyBalancerStable.sol";

contract StrategyBalancerStableTest is DSTest {
    MockERC20 usdc;
    MockERC20 weth;
    MockERC20 bal;
    MockStrategyHelper sh;
    MockBalancerVaultPool vaultPool;
    MockCurveGauge gauge;
    StrategyBalancerStable s;

    function setUp() public {
        usdc = new MockERC20(6);
        weth = new MockERC20(18);
        bal = new MockERC20(18);
        vaultPool = new MockBalancerVaultPool(usdc, weth);
        vaultPool.mint(address(0), 77e18);
        gauge = new MockCurveGauge(vaultPool, bal);
        sh = new MockStrategyHelper();
        sh.setPrice(address(usdc), 1e18);
        sh.setPrice(address(weth), 1500e18);
        sh.setPrice(address(bal), 5.5e18);
        sh.setPrice(address(vaultPool), 8.88e18);
        s = new StrategyBalancerStable(
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
        uint256 sha = s.mint(address(usdc), 50e6, "");
        assertEq(s.rate(sha) / 1e16, 4999);
    }

    function testMint() public {
        uint256 shares = s.mint(address(usdc), 50e6, "");
        assertEq(shares, 5630630630630630630);
        assertEq(vaultPool.balanceOf(address(gauge)), 5630630630630630630);
        assertEq(gauge.balanceOf(address(s)), 5630630630630630630);
    }

    function testBurn() public {
        s.mint(address(usdc), 50e6, "");
        uint256 amt = s.burn(address(usdc), 5e18, "");
        assertEq(amt, 59052000);
        assertEq(vaultPool.balanceOf(address(gauge)), 838738738738738738);
        assertEq(gauge.balanceOf(address(s)), 838738738738738738);
        assertEq(s.totalShares(), 630630630630630630);
    }

    function testEarn() public {
        uint256 sha = s.mint(address(usdc), 1e6, "");
        s.earn();
        s.earn();
        s.earn();
        assertEq(s.rate(sha) / 1e16, 5049);
        s.earn();
        assertEq(s.totalShares(), 112612612612612612);
        assertEq(s.rate(sha) / 1e16, 6699);
        assertEq(gauge.balanceOf(address(s)), 7545045045045045044);
    }

    function testExitMove() public {
        StrategyBalancerStable s2 = new StrategyBalancerStable(
            address(sh),
            address(vaultPool),
            address(gauge),
            address(vaultPool),
            address(usdc)
        );
        s.mint(address(usdc), 50e6, "");
        s.exit(address(s2));
        assertEq(gauge.balanceOf(address(s)), 0);
        assertEq(vaultPool.balanceOf(address(s2)), 7488738738738738738);
        s2.move(address(s));
        assertEq(vaultPool.balanceOf(address(s2)), 0);
        assertEq(gauge.balanceOf(address(s2)), 7488738738738738738);
        assertEq(s2.totalShares(), 7488738738738738738);
    }
}
