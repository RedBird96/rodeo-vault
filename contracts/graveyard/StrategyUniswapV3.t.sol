// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTest} from "./utils/DSTest.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {MockPoolUniV3} from "./mocks/MockPoolUniV3.sol";
import {MockRouterUniV3} from "./mocks/MockRouterUniV3.sol";
import {StrategyHelper, StrategyHelperUniswapV3} from "../StrategyHelper.sol";
import {StrategyUniswapV3} from "../strategies/StrategyUniswapV3.sol";
import {TickMath} from "../vendor/TickMath.sol";
import {BytesLib} from "../vendor/BytesLib.sol";

contract MockStrategy is StrategyUniswapV3 {
    constructor(address _strategyHelper, address _pool, int24 _tickScale)
        StrategyUniswapV3(_strategyHelper, _pool, _tickScale)
    {}

    function tickRange(int24 scale, address poolAddress) public view returns (int24, int24) {
        return super.getTickRange(scale, poolAddress);
    }
}

contract StrategyUniswapV3Test is DSTest {
    using BytesLib for bytes;

    MockERC20 aUsdc;
    MockERC20 aWeth;
    MockERC20 aWbtc;
    StrategyHelper sh;
    StrategyHelperUniswapV3 shv3;
    StrategyUniswapV3 strategy1;
    StrategyUniswapV3 strategy2;
    StrategyUniswapV3 strategy3;
    MockOracle oUsdc;
    MockOracle oWeth;
    MockOracle oWbtc;
    MockPoolUniV3 pool1;
    MockPoolUniV3 pool2;
    MockPoolUniV3 pool3;
    bytes32 positionID;
    bytes32 positionID2;
    bytes public path0;
    bytes public path1;
    bytes public pathWbtc;
    bytes public pathWeth;
    MockRouterUniV3 router;
    MockStrategy mockStrategy;

    function setUp() public {
        aUsdc = new MockERC20(6);
        aWeth = new MockERC20(18);
        aWbtc = new MockERC20(18);
        oUsdc = new MockOracle(1e8);
        oWeth = new MockOracle(1567e8);
        oWbtc = new MockOracle(20397e8);
        sh = new StrategyHelper();
        sh.setOracle(address(aUsdc), address(oUsdc));
        sh.setOracle(address(aWeth), address(oWeth));
        sh.setOracle(address(aWbtc), address(oWbtc));
        pool1 = new MockPoolUniV3(aUsdc, aWeth, 156763750000, 2151463975097189509894620648138251, 204196);
        pool2 = new MockPoolUniV3(aWbtc, aWeth, 12880568e12, 30392158675702179169997063756498876, 257160);
        pool3 = new MockPoolUniV3(aUsdc, aWbtc, 2048786806634, 1100070821315188242191396967810, 52618);
        router = new MockRouterUniV3(address(pool3), address(pool1), address(aUsdc), address(aWbtc), address(aWeth));
        pathWbtc = abi.encodePacked(address(aUsdc), uint24(3000), address(aWbtc));
        pathWeth = abi.encodePacked(address(aUsdc), uint24(3000), address(aWeth));
        shv3 = new StrategyHelperUniswapV3(address(router));
        sh.setPath(
            address(aUsdc),
            address(aWeth),
            address(shv3),
            abi.encodePacked(address(aUsdc), uint24(3000), address(aWeth))
        );
        sh.setPath(
            address(aWeth),
            address(aUsdc),
            address(shv3),
            abi.encodePacked(address(aWeth), uint24(3000), address(aUsdc))
        );
        sh.setPath(
            address(aUsdc),
            address(aWbtc),
            address(shv3),
            abi.encodePacked(address(aUsdc), uint24(3000), address(aWbtc))
        );
        sh.setPath(
            address(aWbtc),
            address(aUsdc),
            address(shv3),
            abi.encodePacked(address(aWbtc), uint24(3000), address(aUsdc))
        );
        sh.setPath(
            address(aWbtc),
            address(aWeth),
            address(shv3),
            abi.encodePacked(address(aWbtc), uint24(3000), address(aWeth))
        );

        mockStrategy = new MockStrategy(
            address(sh),
            address(pool1),
            0
        );

        strategy1 = new StrategyUniswapV3(
            address(sh),
            address(pool1),
            0
        );

        strategy2 = new StrategyUniswapV3(
            address(sh),
            address(pool2),
            0
        );

        strategy3 = new StrategyUniswapV3(
            address(sh),
            address(pool1),
            1280
        );

        positionID = keccak256(abi.encodePacked(address(strategy1), int24(-887220), int24(887220)));
        pool1.setPosition(positionID, 0, 2000e30, 1000000000000e30, 0, 0);

        positionID2 = keccak256(abi.encodePacked(address(strategy3), int24(201600), int24(206820)));
        pool1.setPosition(positionID2, 0, 2000e30, 1000000000000e30, 0, 0);

        aUsdc.mint(address(this), 500e6);
        aUsdc.mint(address(pool1), 10000e6);
        aWeth.mint(address(pool1), 6e18);

        aWbtc.mint(address(pool2), 6e18);
        aWeth.mint(address(pool2), 6e18);

        aUsdc.mint(address(pool3), 10000e6);
        aWbtc.mint(address(pool3), 6e18);
    }

    function testRate() public {
        aUsdc.approve(address(strategy1), 500e6);
        uint256 totalShares = strategy1.mint(address(aUsdc), 500e6, "");
        uint256 rate = strategy1.rate(totalShares / 2);
        assertEq(rate, 233080817633686192827);

        // concentrated liquidity strategy
        aUsdc.mint(address(this), 500e6);
        aUsdc.approve(address(strategy3), 500e6);
        uint256 totalShares2 = strategy3.mint(address(aUsdc), 500e6, "");
        uint256 rate2 = strategy3.rate(totalShares2 / 2);
        assertEq(rate2, 234108623649808742817);

        // increasing the global fee growth value by 1%
        pool1.setFeeGrowthGlobal(2020e30, 1010000000000e30);
        uint256 newRate = strategy1.rate(totalShares / 2);
        assertGt(newRate, rate);
        uint256 newRate2 = strategy3.rate(totalShares2 / 2);
        assertGt(newRate2, rate2);
    }

    function testMint() public {
        aUsdc.approve(address(strategy1), 500e6);

        vm.expectRevert(StrategyUniswapV3.NoLiquidity.selector);
        strategy1.mint(address(aUsdc), 0, "");

        assertEq(strategy1.mint(address(aUsdc), 500e6, ""), 5872727776371);
        assertEq(strategy1.totalShares(), 5872727776371);

        // Mint with a non-USDC pool strategy
        aUsdc.mint(address(this), 500e6);
        aUsdc.approve(address(strategy2), 500e6);
        assertEq(strategy2.mint(address(aUsdc), 500e6, ""), 415730991050);
        assertEq(strategy2.totalShares(), 415730991050);

        // Concentrated liquidity strategy
        aUsdc.mint(address(this), 500e6);
        aUsdc.approve(address(strategy3), 500e6);
        assertEq(strategy3.mint(address(aUsdc), 500e6, ""), 48233437125289);
        assertEq(strategy3.totalShares(), 48233437125289);
    }

    function testBurn() public {
        aUsdc.approve(address(strategy1), 500e6);
        uint256 sha = strategy1.mint(address(aUsdc), 500e6, "");

        assertEq(strategy1.burn(address(aUsdc), sha, ""), 499999999);
        assertEq(aUsdc.balanceOf(address(this)), 499999999);
        assertEq(strategy1.totalShares(), 0);
        aUsdc.burn(address(this), 499999999);

        // Burn with a non-USDC pool strategy
        aUsdc.mint(address(this), 500e6);
        aUsdc.approve(address(strategy2), 500e6);
        strategy2.mint(address(aUsdc), 500e6, "");
        assertEq(strategy2.burn(address(aUsdc), 415730991050, ""), 374999999);
        assertEq(aUsdc.balanceOf(address(this)), 374999999);
        assertEq(strategy2.totalShares(), 0);

        // Burn with a concentrated liquidity strategy
        aUsdc.transfer(address(0), aUsdc.balanceOf(address(this)));
        aUsdc.mint(address(this), 500e6);
        aUsdc.approve(address(strategy3), 500e6);
        strategy3.mint(address(aUsdc), 500e6, "");
        assertEq(strategy3.burn(address(aUsdc), 48233437125289, ""), 499999999);
        assertEq(aUsdc.balanceOf(address(this)), 499999999);
        assertEq(strategy3.totalShares(), 0);
    }

    function testEarn() public {
        aUsdc.approve(address(strategy1), 500e6);
        strategy1.mint(address(aUsdc), 500e6, "");

        // Earn - 1% ($5) in extra tokens
        (uint128 liquidityBefore,,,,) = pool1.positions(positionID);
        pool1.setCollect(2500000, 1595405232929164);
        strategy1.earn();
        (uint128 liquidityAfter,,,,) = pool1.positions(positionID);
        assertGt(liquidityAfter, liquidityBefore);

        // Mint more, resulting in less shares than liquidity
        aUsdc.mint(address(this), 500e6);
        aUsdc.approve(address(strategy1), 500e6);
        assertEq(strategy1.mint(address(aUsdc), 500e6, ""), 5396974021591);
        (uint128 liquidity,,,,) = pool1.positions(positionID);
        assertLt(strategy1.totalShares(), liquidity);

        // Burn shares, with more liquidity removed than shares
        (liquidityBefore,,,,) = pool1.positions(positionID);
        uint256 sharesBefore = strategy1.totalShares();
        strategy1.burn(address(aUsdc), 5e12, "");
        (liquidityAfter,,,,) = pool1.positions(positionID);
        assertGt(liquidityBefore - liquidityAfter, sharesBefore - strategy1.totalShares());

        pool1.setSlot0Values(2261680925455353669247996680163507, 205196);
        strategy3.earn();
        // Min/max ticks get updated for concentrated liquidity strategy
        assertEq(strategy3.minTick(), 201600);
        assertEq(strategy3.maxTick(), 206820);
        strategy1.earn();
        // Ticks stay the same for non-concentrated strategy
        assertEq(strategy1.minTick(), -887220);
        assertEq(strategy1.maxTick(), 887220);
    }

    function testGetTickRange() public {
        // Narrow range (1.28%)
        (int24 minTick, int24 maxTick) = mockStrategy.tickRange(1280, address(pool1));
        assertEq(minTick, 201600);
        assertEq(maxTick, 206820);

        // Wide range (3.5%)
        (minTick, maxTick) = mockStrategy.tickRange(3500, address(pool1));
        assertEq(minTick, 197040);
        assertEq(maxTick, 211320);

        // Tick value is negative
        pool1.setSlot0Values(0, -205196);
        (minTick, maxTick) = mockStrategy.tickRange(3500, address(pool1));
        assertEq(minTick, -212400);
        assertEq(maxTick, -198060);
    }
}
