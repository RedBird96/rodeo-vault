// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {console} from "./utils/console.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {Investor} from "../Investor.sol";
import {InvestorHelper} from "../InvestorHelper.sol";
import {PoolRateModel} from "../PoolRateModel.sol";
import {PositionManager} from "../PositionManager.sol";
import {StrategyHelperUniswapV2, StrategyHelperUniswapV3} from "../StrategyHelper.sol";
import {StrategySushiswap} from "../strategies/StrategySushiswap.sol";
import {StrategyUniswapV3} from "../strategies/StrategyUniswapV3.sol";

import {UniswapV2Factory} from "./vendor/sushiswap/uniswapv2/UniswapV2Factory.sol";
import {UniswapV2Router02} from "./vendor/sushiswap/uniswapv2/UniswapV2Router02.sol";
import {UniswapV2Pair} from "./vendor/sushiswap/uniswapv2/UniswapV2Pair.sol";
import {MiniChefV2} from "./vendor/sushiswap/MiniChefV2.sol";
import {IRewarder} from "./vendor/sushiswap/interfaces/IRewarder.sol";
import {IERC20 as ssIERC20} from "./vendor/sushiswap/boringcrypto/IERC20.sol";

import {UniswapV3Factory} from "./vendor/uniswapv3/UniswapV3Factory.sol";
import {UniswapV3Pool} from "./vendor/uniswapv3/UniswapV3Pool.sol";
import {IUniswapV3Factory} from "./vendor/uniswapv3/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "./vendor/uniswapv3/interfaces/IUniswapV3Pool.sol";
import {ISwapRouter} from "./vendor/uniswapv3/interfaces/ISwapRouter.sol";
import {IERC20Minimal} from "./vendor/uniswapv3/interfaces/IERC20Minimal.sol";

import {NonfungibleTokenPositionDescriptor} from "./vendor/uniswapv3/NonfungibleTokenPositionDescriptor.sol";
import {NonfungiblePositionManager} from "./vendor/uniswapv3/NonfungiblePositionManager.sol";
import "./vendor/uniswapv3/utils/Tick.sol";
import {calcSqrtPriceX96} from "./vendor/uniswapv3/utils/Math.sol";
import {INonfungiblePositionManager} from "./vendor/uniswapv3/interfaces/INonfungiblePositionManager.sol";
import {SwapRouter} from "./vendor/uniswapv3/SwapRouter.sol";
import {TickMath} from "./vendor/uniswapv3/libraries/TickMath.sol";
import {LiquidityAmounts} from "./vendor/uniswapv3/libraries/LiquidityAmounts.sol";
import {WETH9} from "./vendor/uniswapv3/libraries/WETH9.sol";

contract IntegrationTest is Test {
    uint256 private constant ONE_YEAR = 31536000;

    MockERC20 sushi;
    MockOracle sushiOracle;
    StrategyHelperUniswapV2 shss;
    StrategyHelperUniswapV3 shv3;
    StrategySushiswap ss;
    StrategyUniswapV3 su;
    StrategyUniswapV3 su2;

    UniswapV2Factory univ2Factory;
    UniswapV2Router02 univ2Router;
    UniswapV2Pair univ2PairWethUsdc;
    UniswapV2Pair univ2PairWethSushi;
    MiniChefV2 sushiMiniChef;

    UniswapV3Factory public factory;
    WETH9 public weth9;
    SwapRouter public router;
    NonfungibleTokenPositionDescriptor nftDescriptor;
    NonfungiblePositionManager nft;

    function setUp() public override {
        super.setUp();
        sushi = new MockERC20(18);
        sushiOracle = new MockOracle(7e8);
        sh.setOracle(address(sushi), address(sushiOracle));

        // deploy uniswapv2
        univ2Factory = new UniswapV2Factory(address(this));
        univ2Router = new UniswapV2Router02(address(univ2Factory), address(weth));
        univ2PairWethUsdc = UniswapV2Pair(univ2Factory.createPair(address(weth), address(usdc)));
        univ2PairWethSushi = UniswapV2Pair(univ2Factory.createPair(address(weth), address(sushi)));

        // deploy uniswapv3
        weth9 = new WETH9();
        factory = new UniswapV3Factory();
        router = new SwapRouter(address(factory), address(weth9));
        nftDescriptor = new NonfungibleTokenPositionDescriptor(address(weth), bytes32('ETH'));
        nft = new NonfungiblePositionManager(address(factory), address(weth9), address(nftDescriptor));

        // add liquidity to weth/usdc
        weth.mint(address(this), 1000e18);
        usdc.mint(address(this), 1650000e6);
        weth.transfer(address(univ2PairWethUsdc), 1000e18);
        usdc.transfer(address(univ2PairWethUsdc), 1650000e6);
        univ2PairWethUsdc.mint(address(this));

        // add liquidity to weth/sushi
        weth.mint(address(this), 1000e18);
        sushi.mint(address(this), 7000e18);
        weth.transfer(address(univ2PairWethSushi), 1000e18);
        sushi.transfer(address(univ2PairWethSushi), 7000e18);
        univ2PairWethSushi.mint(address(this));

        // deploy sushiswap
        sushiMiniChef = new MiniChefV2(ssIERC20(address(sushi)));
        sushiMiniChef.add(100, ssIERC20(address(univ2PairWethUsdc)), IRewarder(address(0)));

        // create univ3 pool
        address pool = createPool(usdc, weth, 1650000e6, 1000e18);

        shss = new StrategyHelperUniswapV2(address(univ2Router));
        shv3 = new StrategyHelperUniswapV3(address(router));
        sh.setPath(address(usdc), address(weth), address(shss), abi.encodePacked(address(usdc), address(weth)));
        sh.setPath(address(weth), address(usdc), address(shss), abi.encodePacked(address(weth), address(usdc)));
        sh.setPath(address(weth), address(sushi), address(shss), abi.encodePacked(address(weth), address(sushi)));
        sh.setPath(address(sushi), address(weth), address(shss), abi.encodePacked(address(sushi), address(weth)));
        sh.setPath(
            address(usdc), address(sushi), address(shss), abi.encodePacked(address(usdc), address(weth), address(sushi))
        );
        sh.setPath(
            address(sushi), address(usdc), address(shss), abi.encodePacked(address(sushi), address(weth), address(usdc))
        );

        ss = new StrategySushiswap(address(sh), address(sushiMiniChef), 0);
        ss.file("exec", address(iasp));
        investor.setStrategy(1, address(ss));

        su = new StrategyUniswapV3(address(sh), pool, 0);
        su.file("slippage", 200);
        su.setTwapPeriod(1);
        su2 = new StrategyUniswapV3(address(sh), pool, 1280);
        su2.setTwapPeriod(1);
        su.file("exec", address(iasp));
        su2.file("exec", address(iasp));
        investor.setStrategy(2, address(su));
        investor.setStrategy(3, address(su2));
        su2.file("slippage", 200);
    }

    // Tests a somewhat realistic screnario with the least mocks possible
    // Unit tests are still there to account for errors and more precise cases
    function testScenario() public {
        usdc.mint(address(this), 800e6);
        usdc.approve(address(usdcPool), 750e6);
        usdc.approve(address(pm), 50e6);

        // 1st lender
        usdcPool.mint(100e6, vm.addr(1));
        assertEq(usdcPool.totalSupply(), 1099998904);

        // 2nd lender
        usdcPool.mint(450e6, vm.addr(2));
        assertEq(usdcPool.balanceOf(vm.addr(2)), 449995068);
        assertEq(usdcPool.totalSupply(), 1549993972);

        // 1st borrow
        pm.mint(vm.addr(3), address(usdcPool), 1, 50e6, 150e6, "");
        uint256 pid = investor.nextPosition() - 1;
        assertEq(usdcPool.getTotalBorrow(), 250010958);
        assertEq(usdc.balanceOf(address(usdcPool)), 1300e6);
        uint256 utilization = usdcPool.getUtilization();
        // 16% used, 1.9% apr
        assertEq(utilization, 161296251945594309);
        assertEq(usdcPool.rateModel().rate(utilization) * ONE_YEAR / 1e12, 19999);
        assertEq(univ2PairWethUsdc.balanceOf(address(sushiMiniChef)), 2454444330127);
        (uint256 miniChefUserInfoAmount,) = sushiMiniChef.userInfo(0, address(ss));
        assertEq(miniChefUserInfoAmount, 2454444330127);
        (,,,,, uint256 rodeoPositionShares,) = investor.positions(pid);
        assertEq(rodeoPositionShares, 2454444330127);
        assertEq(ss.rate(rodeoPositionShares), 199400035886119044765); // ~200$USD value
        assertEq(investor.life(pid) * 1e4 / 1e18, 12628); // 1.26 health factor

        // 1 month passes
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + (30 * 86400));

        // 2nd borrow
        usdc.mint(address(this), 350e6);
        usdc.approve(address(pm), 350e6);
        pm.mint(vm.addr(4), address(usdcPool), 1, 350e6, 350e6, "");
        assertEq(usdcPool.getTotalBorrow(), 600421934);
        assertEq(usdc.balanceOf(address(usdcPool)), 950e6);
        utilization = usdcPool.getUtilization();
        // 38% used, 1.8% supply apr
        assertEq(utilization, 387263570537179977);
        assertEq(usdcPool.rateModel().rate(utilization) * ONE_YEAR / 1e12, 19999);

        // 3nd lender
        usdcPool.mint(200e6, vm.addr(5));
        // A bit under 200 shares minted because index went up after a month
        assertEq(usdcPool.balanceOf(vm.addr(5)), 199944794);
        assertEq(usdcPool.totalSupply(), 1749938766);
        utilization = usdcPool.getUtilization();
        // 34% used, 1.9% apr
        assertEq(utilization, 343015545187975232);
        assertEq(usdcPool.rateModel().rate(utilization) * ONE_YEAR / 1e12, 19999);

        // 6 month passes
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + (30 * 86400));

        uint256 index = usdcPool.getUpdatedIndex();
        uint256 rodeoPositionBorrow;
        (,,,,, rodeoPositionShares, rodeoPositionBorrow) = investor.positions(pid);
        assertEq(rodeoPositionBorrow * index / 1e18, 150493555); // 150$ borrowed
        assertEq(ss.rate(rodeoPositionShares), 199400158251792037765); // ~200$USD value
        assertEq(investor.life(pid) * 1e4 / 1e18, 12587); // 1.25 health factor

        // move ETH price oracle to 950$
        wethOracle.move(950e8);
        (,,,,, rodeoPositionShares,) = investor.positions(pid);
        assertEq(ss.rate(rodeoPositionShares), 151302230060870415839); // ~151$USD value
        assertEq(investor.life(pid) * 1e4 / 1e18, 9551); // 0.95 health factor

        // Liquidate 1st borrow
        vm.startPrank(vm.addr(6));
        investor.kill(pid, "");
        vm.stopPrank();
        (,,,,, rodeoPositionShares, rodeoPositionBorrow) = investor.positions(pid);
        assertEq(rodeoPositionShares, 0); // no more shares
        assertEq(rodeoPositionBorrow, 0); // no more borrow
        assertEq(investor.life(pid) * 1e4 / 1e18, 10000); // 1 health factor / no borrow
        assertEq(usdc.balanceOf(vm.addr(6)), 4978734); // 5$ payout/fee
        wethOracle.move(1650e8);

        // univ3 1st borrow
        usdc.mint(address(this), 50e6);
        usdc.approve(address(pm), 50e6);
        pm.mint(vm.addr(3), address(usdcPool), 2, 50e6, 150e6, "");
        pid = investor.nextPosition() - 1;
        assertEq(usdc.balanceOf(address(usdcPool)), 1150493555);
        assertEq(su.totalShares(), 2453253562481);

        // univ3 2nd borrow
        usdc.mint(address(this), 350e6);
        usdc.approve(address(pm), 350e6);
        pm.mint(vm.addr(4), address(usdcPool), 2, 350e6, 350e6, "");
        assertEq(su.totalShares(), 11037306380093);

        // earn
        (,,,,, rodeoPositionShares, rodeoPositionBorrow) = investor.positions(pid);
        uint256 rateBefore = su.rate(rodeoPositionShares);
        // perform a trade to earn fees
        usdc.mint(vm.addr(5), 20000e6);
        vm.startPrank(vm.addr(5));
        usdc.approve(address(sh), 10000e6);
        sh.swap(address(usdc), address(weth), 10000e6, 100, vm.addr(5));
        usdc.approve(address(router), 10000e6);
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(address(usdc), uint24(3000), address(weth)),
            recipient: vm.addr(5),
            deadline: type(uint256).max,
            amountIn: 10000e6,
            amountOutMinimum: 0
        });
        router.exactInput(params);
        vm.stopPrank();
        su.earn();
        wethOracle.move(1670e8); // manually update the oracle price (tick -202110)
        uint256 rateAfter = su.rate(rodeoPositionShares);
        assertGt(rateAfter, rateBefore);
        assertEq(rateAfter - rateBefore, 1207957947883198103);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 86400);

        // burn
        uint256 borrow;
        (,,,,, rodeoPositionShares, borrow) = investor.positions(pid);
        uint256 shareAmount = rodeoPositionShares / 2;
        vm.prank(vm.addr(3));
        pm.edit(pid, 0 - int256(shareAmount), -75e6, "");
        assertEq(usdc.balanceOf(vm.addr(3)), 63778126);
        assertEq(su.totalShares(), 9810679598853);

        // burn the rest
        vm.roll(block.number + 1);
        vm.prank(vm.addr(3));
        pm.edit(pid, 0 - int256(rodeoPositionShares - shareAmount), 0 - int256(borrow - 75e6), "");
        assertEq(usdc.balanceOf(vm.addr(3)), 89225634);
        assertEq(su.totalShares(), 8584052817612);
        (,,,,, rodeoPositionShares, rodeoPositionBorrow) = investor.positions(pid);
        assertEq(rodeoPositionShares, 0);
        assertEq(rodeoPositionBorrow, 0);

        // univ3 concentrated 1st borrow
        usdc.mint(address(this), 50e6);
        usdc.approve(address(pm), 50e6);
        pm.mint(vm.addr(3), address(usdcPool), 3, 50e6, 150e6, "");
        pid = investor.nextPosition() - 1;
        assertEq(usdc.balanceOf(address(usdcPool)), 800501773);
        assertEq(su2.totalShares(), 20035181833585);
        vm.roll(block.number + 1);
        // burn
        (,,,,, rodeoPositionShares, borrow) = investor.positions(pid);
        vm.prank(vm.addr(3));
        pm.edit(pid, 0 - int256(rodeoPositionShares), 0 - int256(borrow), "");
        assertEq(usdc.balanceOf(vm.addr(3)), 138503453);
        assertEq(su2.totalShares(), 0);
    }

    function createPool(MockERC20 token0, MockERC20 token1, uint256 balance0, uint256 balance1)
        public
        returns (address poolAddress)
    {
        (balance0, balance1) = (
            address(token0) < address(token1) ? balance0 : balance1,
            address(token0) < address(token1) ? balance1 : balance0
        );
        (token0, token1) =
            (address(token0) < address(token1) ? token0 : token1, address(token0) < address(token1) ? token1 : token0);
        address tokenAddress0 = address(token0);
        address tokenAddress1 = address(token1);

        token0.mint(address(this), balance0);
        token1.mint(address(this), balance1);
        token0.approve(address(nft), balance0);
        token1.approve(address(nft), balance1);
        uint160 sqrtPriceX96 = calcSqrtPriceX96(uint160(balance0), uint160(balance1));
        poolAddress = nft.createAndInitializePoolIfNecessary(tokenAddress0, tokenAddress1, FEE_MEDIUM, sqrtPriceX96);
        IUniswapV3Pool(poolAddress).increaseObservationCardinalityNext(100);

        INonfungiblePositionManager.MintParams memory liquidityParams = INonfungiblePositionManager.MintParams({
            token0: tokenAddress0,
            token1: tokenAddress1,
            fee: FEE_MEDIUM,
            tickLower: getMinTick(TICK_MEDIUM),
            tickUpper: getMaxTick(TICK_MEDIUM),
            recipient: address(this),
            amount0Desired: balance0,
            amount1Desired: balance1,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });

        nft.mint(liquidityParams);
    }
}
