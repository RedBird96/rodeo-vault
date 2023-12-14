// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTest} from "./utils/DSTest.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockStrategyHelper} from "./mocks/MockStrategyHelper.sol";
import {MockCurveGauge} from "./mocks/MockCurveGauge.sol";
import {MockCurvePoolV2} from "./mocks/MockCurvePoolV2.sol";
import {StrategyCurveV2} from "../strategies/StrategyCurveV2.sol";

contract StrategyCurveV2Test is DSTest {
    MockERC20 wbtc;
    MockERC20 weth;
    MockERC20 usdc;
    MockERC20 crv;
    MockStrategyHelper sh;
    MockCurvePoolV2 pool;
    MockCurveGauge gauge;
    StrategyCurveV2 s;

    function setUp() public {
        wbtc = new MockERC20(18);
        weth = new MockERC20(18);
        usdc = new MockERC20(6);
        crv = new MockERC20(18);
        sh = new MockStrategyHelper();
        sh.setPrice(address(wbtc), 16000e18);
        sh.setPrice(address(weth), 1200e18);
        sh.setPrice(address(usdc), 1e18);
        sh.setPrice(address(crv), 0.523e18);
        pool = new MockCurvePoolV2(address(wbtc), address(weth), address(usdc));
        gauge = new MockCurveGauge(pool, crv);
        s = new StrategyCurveV2(
            address(sh),
            address(pool),
            address(gauge),
            0
        );
        usdc.mint(address(this), 1000e6);
        usdc.approve(address(s), 1000e6);
    }

    function testRate() public {
        uint256 sha = s.mint(address(usdc), 50e6, "");
        assertEq(s.rate(sha) / 1e16, 5366);
    }

    function testMint() public {
        uint256 shares = s.mint(address(usdc), 50e6, "");
        assertEq(shares, 0.06025e18);
        assertEq(pool.balanceOf(address(gauge)), 0.06025e18);
        assertEq(gauge.balanceOf(address(s)), 0.06025e18);
    }

    function testBurn() public {
        uint256 sha = s.mint(address(usdc), 50e6, "");
        uint256 amt = s.burn(address(usdc), sha / 2, "");
        assertEq(amt, 25784500);
        assertEq(pool.balanceOf(address(gauge)), 31070322500000000);
        assertEq(gauge.balanceOf(address(s)), 31070322500000000);
        assertEq(s.totalShares(), sha - (sha / 2));
    }

    function testEarn() public {
        uint256 sha = s.mint(address(usdc), 1e6, "");
        s.earn();
        s.earn();
        s.earn();
        assertEq(s.rate(sha) / 1e16, 612);
        s.earn();
        assertEq(s.totalShares(), 0.001205e18);
        assertEq(s.rate(sha) / 1e16, 780);
        assertEq(gauge.balanceOf(address(s)), 0.00876758e18);
    }

    function testExitMove() public {
        StrategyCurveV2 s2 = new StrategyCurveV2(
            address(sh),
            address(pool),
            address(gauge),
            2
        );
        s.mint(address(usdc), 50e6, "");
        s.exit(address(s2));
        assertEq(gauge.balanceOf(address(s)), 0);
        assertEq(pool.balanceOf(address(s2)), 62140645000000000);
        s2.move(address(s));
        assertEq(pool.balanceOf(address(s2)), 0);
        assertEq(gauge.balanceOf(address(s2)), 62140645000000000);
        assertEq(s2.totalShares(), 62140645000000000);
    }
}
