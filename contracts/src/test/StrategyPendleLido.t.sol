// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {StrategyHelper, StrategyHelperUniswapV3, StrategyHelperCamelot} from "../StrategyHelper.sol";
import {IPRouter, IPMarket, ILpOracleHelper} from "../interfaces/IPendle.sol";
import {StrategyPendleLSD} from "../strategies/StrategyPendleLSD.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {DSTest} from "./utils/DSTest.sol";

contract StrategyPendleLidoTest is DSTest {
    StrategyHelperUniswapV3 hlpV3;
    StrategyHelperCamelot hlpc;
    StrategyPendleLSD str;
    ILpOracleHelper lphlp;
    StrategyHelper hlp;
    IOracle oPendle;
    IOracle oWstEth;
    IPRouter prtr;
    IPMarket mrkt;
    IERC20 pendle;
    IERC20 wsteth;
    IOracle oEth;
    IOracle oAst;
    IERC20 weth;
    IERC20 ast;

    uint256 arbFork;

    error PriceSlipped();
    error Unauthorized();

    function setUp() public {
        arbFork =
            vm.createSelectFork("https://arb-mainnet.g.alchemy.com/v2/-dVfS3BS-6YZkGd9GC6Ist_Y12-KPFXw", 101_110_380);

        pendle = IERC20(0x0c880f6761F1af8d9Aa9C466984b80DAb9a8c9e8);
        wsteth = IERC20(0x5979D7b546E38E414F7E9822514be443A4800529);
        weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        ast = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8); // USDC

        vm.prank(0x489ee077994B6658eAfA855C308275EAd8097C4A); // Just an address with positive ast balance

        ast.transfer(address(this), 1000e6);

        oWstEth = IOracle(0xDde8d7C6BEeb9D59eFAEee2a2Be2BA500E451d5d); // wstETH/USD
        oEth = IOracle(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612); // ETH/USD
        oAst = IOracle(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3); // USDC/USD
        oPendle = IOracle(0x5e26601c1C0AACF0F588f4B24c433990B728D65a); // PENDLE/USD

        hlp = new StrategyHelper();
        hlpc = new StrategyHelperCamelot(0xc873fEcbd354f5A56E00E710B90EF4201db2448d); // Camelot V2 Router
        hlpV3 = new StrategyHelperUniswapV3(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Uniswap V3 Router
        lphlp = ILpOracleHelper(0xA8c2f51433bE6F318FF9e4C9291eaC391cf72987);

        prtr = IPRouter(0x0000000001E4ef00d069e71d6bA041b0A16F7eA0); // Pendle Router
        mrkt = IPMarket(0x08a152834de126d2ef83D612ff36e4523FD0017F); // PT-wstETH-26JUN25/SY-wstETH Market

        hlp.setOracle(address(wsteth), address(oWstEth));
        hlp.setOracle(address(weth), address(oEth));
        hlp.setOracle(address(ast), address(oAst));
        hlp.setOracle(address(pendle), address(oPendle));

        // _mint paths
        hlp.setPath(
            address(ast),
            address(wsteth),
            address(hlpV3),
            abi.encodePacked(address(ast), uint24(500), address(weth), uint24(100), address(wsteth))
        );

        // _burn paths
        hlp.setPath(
            address(wsteth),
            address(ast),
            address(hlpV3),
            abi.encodePacked(address(wsteth), uint24(100), address(weth), uint24(500), address(ast))
        );

        // _earn paths
        address[] memory rewardTokens = mrkt.getRewardTokens();
        uint256 len = rewardTokens.length;

        for (uint256 i = 0; i < len; ++i) {
            hlp.setPath(
                rewardTokens[i], address(ast), address(hlpc), abi.encodePacked(rewardTokens[i], weth, address(ast))
            );
        }

        str =
        new StrategyPendleLSD(address(hlp), address(lphlp), address(prtr), address(mrkt), address(wsteth), address(weth), address(ast));

        str.setTwapPeriod(5);
    }

    function testMint() public {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        uint256 expectedSha = 279773212286808808;

        assertEq(str.mint(address(ast), astBal, ""), expectedSha);
        assertEq(ast.balanceOf(address(this)), 0);
        assertEq(str.totalShares(), expectedSha);
    }

    function testMintMustFailPriceSlipped() public {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        vm.mockCall(address(hlp), abi.encodeWithSelector(StrategyHelper.value.selector), abi.encode(1e25));
        vm.expectRevert(PriceSlipped.selector);

        str.mint(address(ast), astBal, "");
    }

    function testBurn() public {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        uint256 shares = str.mint(address(ast), astBal, "");
        uint256 expectedBurnedAmount = 998138965;

        assertEq(str.burn(address(ast), shares, ""), expectedBurnedAmount);
        assertEq(ast.balanceOf(address(this)), expectedBurnedAmount);
        assertEq(str.totalShares(), 0);
    }

    function testEarn() public {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        str.mint(address(ast), astBal, "");

        uint256 mrktBal1 = mrkt.balanceOf(address(str));

        vm.warp(block.timestamp + 864_000); // +10 days
        vm.roll(block.number + 10000000000); // +10000000000 blocks

        str.earn();

        uint256 mrktBal2 = mrkt.balanceOf(address(str));

        assert(mrktBal1 <= mrktBal2);
    }

    function testExit() public {
        StrategyPendleLSD str2 =
        new StrategyPendleLSD(address(hlp), address(lphlp), address(prtr), address(mrkt), address(wsteth), address(weth), address(ast));
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        str.mint(address(ast), astBal, "");

        uint256 bal = mrkt.balanceOf(address(str));

        str.exit(address(str2));
        str2.move(address(str));

        assertEq(mrkt.balanceOf(address(str)), 0);
        assertEq(mrkt.balanceOf(address(str2)), bal);
    }

    function testMove() public {
        StrategyPendleLSD str2 =
        new StrategyPendleLSD(address(hlp), address(lphlp), address(prtr), address(mrkt), address(wsteth), address(weth), address(ast));

        str2.move(address(str));
    }

    function testRate() public {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        uint256 sha = str.mint(address(ast), astBal, "");
        uint256 expectedRate = 998623443201127881600;

        assertEq(str.rate(sha), expectedRate);
    }

    function testSetTargetAsset(address newTargetAsset) public {
        vm.assume(newTargetAsset != address(0));

        assertEq(str.targetAsset(), address(ast));

        str.setTargetAsset(newTargetAsset);

        assertEq(str.targetAsset(), newTargetAsset);
    }

    function testSetTargetAssetMustFailUnauthorized() public {
        vm.prank(address(hlp));
        vm.expectRevert(Unauthorized.selector);

        str.setTargetAsset(address(ast));
    }

    function testSetTwapPeriod(uint32 twapPeriod) public {
        assertEq(str.twapPeriod(), 5);

        str.setTwapPeriod(twapPeriod);

        assertEq(str.twapPeriod(), twapPeriod);
    }

    function testSetTwapPeriodMustFailUnauthorized() public {
        vm.prank(address(hlp));
        vm.expectRevert(Unauthorized.selector);

        str.setTwapPeriod(2000);
    }
}
