// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {INonfungiblePositionManager} from "./vendor/uniswapv3/interfaces/INonfungiblePositionManager.sol";
import {FEE_LOW, TICK_LOW, getMinTick, getMaxTick} from "./vendor/uniswapv3/utils/Tick.sol";
import {IUniswapV3Pool} from "./vendor/uniswapv3/interfaces/IUniswapV3Pool.sol";
import {StrategyHelper, StrategyHelperUniswapV3} from "../StrategyHelper.sol";
import {IExchangeRouter, IReader, IPrice} from "../interfaces/IGMXGM.sol";
import {calcSqrtPriceX96} from "./vendor/uniswapv3/utils/Math.sol";
import {StrategyGMXGM} from "../strategies/StrategyGMXGM.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {IMarket} from "../interfaces/IGMXGM.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {DSTest} from "./utils/DSTest.sol";

import {console} from "./utils/console.sol";

contract StrategyGMXGMTest is DSTest {
    StrategyHelperUniswapV3 hlpV3;
    IExchangeRouter rtr;
    StrategyHelper hlp;
    StrategyGMXGM str;
    MockOracle oWeth;
    MockOracle oUsdc;
    MockOracle oDai;
    address dtstr;
    address dhan;
    address whan;
    address dvlt;
    address wvlt;
    address mrkt;
    IERC20 aWeth;
    IERC20 aUsdc;
    IERC20 aDai;
    IReader rdr;

    error WrongReserveRatio();
    error Unauthorized();

    function setUp() external {
        vm.createSelectFork("https://arb-mainnet.g.alchemy.com/v2/-dVfS3BS-6YZkGd9GC6Ist_Y12-KPFXw", 153_138_398);
        aWeth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        aUsdc = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
        aDai = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);

        vm.deal(address(this), 2000e18);
        IWETH(address(aWeth)).deposit{value: 1000e18}();

        vm.prank(0x489ee077994B6658eAfA855C308275EAd8097C4A); // Address with positive USDC balance
        aUsdc.transfer(address(this), 2500e6);
        vm.prank(0x489ee077994B6658eAfA855C308275EAd8097C4A); // Address with positive DAI balance
        aDai.transfer(address(this), 2500e18);

        //mintNewPosition(address(aWeth), 1000e18, address(aUsdc), 1900000e6);
        //mintNewPosition(address(aWeth), 1000e18, address(aDai), 1900000e18);

        oWeth = new MockOracle(2065e8);
        oUsdc = new MockOracle(1e8);
        oDai = new MockOracle(1e8);

        hlp = new StrategyHelper();
        hlpV3 = new StrategyHelperUniswapV3(0xE592427A0AEce92De3Edee1F18E0157C05861564); // UniSwap V3 Router

        rtr = IExchangeRouter(0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8);
        rdr = IReader(0xf60becbba223EEA9495Da3f606753867eC10d139);
        dhan = 0x9Dc4f12Eb2d8405b499FB5B8AF79a5f64aB8a457;
        whan = 0x9E32088F3c1a5EB38D32d1Ec6ba0bCBF499DC9ac;
        dvlt = 0xF89e77e8Dc11691C9e8757e84aaFbCD8A67d7A55;
        wvlt = 0x0628D46b5D145f183AdB6Ef1f2c97eD1C4701C55;
        dtstr = 0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8;
        mrkt = 0x70d95587d40A2caf56bd97485aB3Eec10Bee6336; // ETH/USD

        hlp.setOracle(address(aWeth), address(oWeth));
        hlp.setOracle(address(aUsdc), address(oUsdc));
        hlp.setOracle(address(aDai), address(oDai));

        // _mint paths
        hlp.setPath(
            address(aUsdc), address(aWeth), address(hlpV3), abi.encodePacked(address(aUsdc), FEE_LOW, address(aWeth))
        );

        // _burn paths
        hlp.setPath(
            address(aWeth), address(aUsdc), address(hlpV3), abi.encodePacked(address(aWeth), FEE_LOW, address(aUsdc))
        );

        // _earn paths
        hlp.setPath(
            address(aWeth), address(aUsdc), address(hlpV3), abi.encodePacked(address(aWeth), FEE_LOW, address(aUsdc))
        );

        str = new StrategyGMXGM(address(hlp), address(rtr), address(rdr), dhan, whan, dtstr, mrkt);
    }

    function testConstructor() external {
        assertEq(address(str.strategyHelper()), address(hlp));
        assertEq(address(str.exchangeRouter()), address(rtr));
        assertEq(address(str.reader()), address(rdr));
        assertEq(str.depositVault(), dvlt);
        assertEq(str.withdrawalVault(), wvlt);
        assertEq(str.dataStore(), dtstr);
        assertEq(str.market(), mrkt);

        IMarket.Props memory marketInfo = rdr.getMarket(dtstr, mrkt);

        assertEq(
            str.name(),
            string(
                abi.encodePacked(
                    "GMX GM ", IERC20(marketInfo.longToken).symbol(), "/", IERC20(marketInfo.shortToken).symbol()
                )
            )
        );
    }

    function testMint() external {
        uint256 astBal = aUsdc.balanceOf(address(this));
        uint256 expectedSha = 2.5e21;
        uint256 expectedBal = 2.5e9;

        aUsdc.approve(address(str), astBal);

        assertEq(str.mint(address(aUsdc), astBal, ""), expectedSha);
        assertEq(str.totalShares(), expectedSha);

        assertEq(IERC20(str.tokenShort()).balanceOf(address(str)), expectedBal);
        assertEq(aUsdc.balanceOf(address(this)), 0);
    }

    function testBurn() external {
        // console.log("PRICE:", getGmTokenPrice());
        uint256 astBal = aUsdc.balanceOf(address(this));

        aUsdc.approve(address(str), astBal);

        uint256 shares = str.mint(address(aUsdc), astBal, "");
        uint256 expectedBurnedAmount = 172413247;

        vm.deal(address(this), 2e14);
        vm.chainId(1);

        str.earn{value: 1e14}();

        // console.log("PRICE:", getGmTokenPrice());

        vm.mockCall(
            address(mrkt),
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(str)),
            abi.encode(getGmTokenPrice() * astBal / 10 ** aUsdc.decimals())
        );

        assertEq(str.burn(address(aUsdc), shares / 25, ""), expectedBurnedAmount);
        assertEq(aUsdc.balanceOf(address(this)), expectedBurnedAmount);
        assertEq(str.totalShares(), 2400e18);

        // IMarket(mrkt).mint(address(sgtr), 22092113142650845592);

        // str.earn{value: 1e14}();
    }

    function testEarn() external {
        aUsdc.approve(address(str), 1000e6);
        str.mint(address(aUsdc), 1000e6, "");
        vm.deal(address(this), 2e14);
        vm.chainId(1);

        str.earn{value: 1e14}();

        vm.expectRevert(StrategyGMXGM.ActionPending.selector);
        str.earn{value: 1e14}();
    }

    function testExit() external {
        aUsdc.approve(address(str), 1000e6);
        str.mint(address(aUsdc), 1000e6, "");

        str.exit(vm.addr(1));
        assertEq(aUsdc.balanceOf(vm.addr(1)), 1000e6);
    }

    function testExitWithActionPending() external {
        aUsdc.approve(address(str), 1000e6);
        str.mint(address(aUsdc), 1000e6, "");
        vm.deal(address(this), 1e14);
        vm.chainId(1);
        str.earn{value: 1e14}();

        vm.expectRevert(StrategyGMXGM.ActionPending.selector);
        str.exit(vm.addr(1));
    }

    function testMove() external {}

    function testRate() external {
        // vm.mockCall(
        //     address(mrkt),
        //     abi.encodeWithSelector(IERC20.balanceOf.selector, address(str)),
        //     abi.encode(astBal / 10 ** aUsdc.decimals() * 10 ** IERC20(mrkt).decimals())
        // );

        // console.log(str.rate(sha));
    }

    function testSetReserveRatioMustFailUnauthorized() external {
        vm.prank(address(0));
        vm.expectRevert(Unauthorized.selector);

        str.setReserveRatio(2000);
    }

    function testSetReserveRatioMustFailWrongReserveRatio() external {
        vm.expectRevert(WrongReserveRatio.selector);

        str.setReserveRatio(10001);
    }

    function testSetReserveRatio(uint16 newReserveRatio) external {
        vm.assume(newReserveRatio <= 10000);

        assertEq(str.reserveRatio(), 1000);

        str.setReserveRatio(newReserveRatio);

        assertEq(str.reserveRatio(), newReserveRatio);
    }

    function mintNewPosition(address tok0, uint256 amt0, address tok1, uint256 amt1) private {
        (amt0, amt1) = (tok0 < tok1 ? amt0 : amt1, tok0 < tok1 ? amt1 : amt0);
        (tok0, tok1) = (tok0 < tok1 ? tok0 : tok1, tok0 < tok1 ? tok1 : tok0);

        address nonfungiblePositionManager = 0x622e4726a167799826d1E1D150b076A7725f5D81;
        address pool = INonfungiblePositionManager(nonfungiblePositionManager).createAndInitializePoolIfNecessary(
            tok0, tok1, FEE_LOW, calcSqrtPriceX96(uint160(amt0), uint160(amt1))
        );

        IUniswapV3Pool(pool).increaseObservationCardinalityNext(100);

        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams({
            token0: tok0,
            token1: tok1,
            fee: FEE_LOW,
            tickLower: getMinTick(TICK_LOW),
            tickUpper: getMaxTick(TICK_LOW),
            recipient: address(this),
            amount0Desired: amt0,
            amount1Desired: amt1,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });

        IERC20(tok0).approve(nonfungiblePositionManager, amt0);
        IERC20(tok1).approve(nonfungiblePositionManager, amt1);
        INonfungiblePositionManager(nonfungiblePositionManager).mint(mintParams);
    }

    function getGmTokenPrice() private view returns (uint256) {
        IReader reader = rdr;
        address dataStore = dtstr;
        IMarket.Props memory marketInfo = reader.getMarket(dataStore, mrkt);

        uint256 price0 = hlp.price(marketInfo.indexToken);
        uint256 price1 = hlp.price(marketInfo.longToken);
        uint256 price2 = hlp.price(marketInfo.shortToken);

        IPrice.Props memory indexTokenPrice = IPrice.Props({min: price0, max: price0});
        IPrice.Props memory longTokenPrice = IPrice.Props({min: price1, max: price1});
        IPrice.Props memory shortTokenPrice = IPrice.Props({min: price2, max: price2});

        bytes32 pnlFactor = keccak256(abi.encode("MAX_PNL_FACTOR"));
        (int256 price,) = reader.getMarketTokenPrice(
            dataStore, marketInfo, indexTokenPrice, longTokenPrice, shortTokenPrice, pnlFactor, false
        );

        return uint256(price) / 1e18;
    }
}
