// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {StrategyPendleCamelot} from "../strategies/StrategyPendleCamelot.sol";
import {IPRouter, IPMarket, ILpOracleHelper} from "../interfaces/IPendle.sol";
import {StrategyHelper, StrategyHelperCamelot} from "../StrategyHelper.sol";
import {IPairUniV2} from "../interfaces/IPairUniV2.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {DSTest} from "./utils/DSTest.sol";

contract StrategyPendleCamelotTest is DSTest {
    StrategyHelperCamelot hlpc;
    StrategyPendleCamelot str;
    ILpOracleHelper lphlp;
    StrategyHelper hlp;
    IPairUniV2 cpr;
    IOracle oGrail;
    IPRouter prtr;
    IPMarket mrkt;
    IOracle oTok0;
    IOracle oTok1;
    IOracle oAst;
    IERC20 grail;
    IERC20 weth;
    IERC20 ast;

    uint256 arbFork;

    error PriceSlipped();
    error Unauthorized();

    function setUp() public {
        arbFork =
            vm.createSelectFork("https://arb-mainnet.g.alchemy.com/v2/-dVfS3BS-6YZkGd9GC6Ist_Y12-KPFXw", 100_745_102);

        grail = IERC20(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
        weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        ast = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8); // USDC

        vm.prank(0x489ee077994B6658eAfA855C308275EAd8097C4A); // Just an address with positive ast balance

        ast.transfer(address(this), 1000e6);

        oTok0 = IOracle(0x5e26601c1C0AACF0F588f4B24c433990B728D65a); // PENDLE/USD
        oTok1 = IOracle(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612); // ETH/USD
        oAst = IOracle(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3); // USDC/USD
        oGrail = IOracle(0x63dd6107bbF26d03a0eF1f6EeC2aCe28C9FE37f0); // GRAIL/USD

        hlp = new StrategyHelper();
        hlpc = new StrategyHelperCamelot(0xc873fEcbd354f5A56E00E710B90EF4201db2448d); // Camelot V2 Router
        lphlp = ILpOracleHelper(0xA8c2f51433bE6F318FF9e4C9291eaC391cf72987);

        prtr = IPRouter(0x0000000001E4ef00d069e71d6bA041b0A16F7eA0); // Pendle Router
        mrkt = IPMarket(0x24e4Df37ea00C4954d668e3ce19fFdcffDEc2cF6); // PT-Camelot-PENDLE-ETH-27JUN24/SY-Camelot-PENDLE-ETH Market
        cpr = IPairUniV2(0xBfCa4230115DE8341F3A3d5e8845fFb3337B2Be3); // Camelot PENDLE-WETH Pair

        hlp.setOracle(address(cpr.token0()), address(oTok0));
        hlp.setOracle(address(cpr.token1()), address(oTok1));
        hlp.setOracle(address(ast), address(oAst));
        hlp.setOracle(address(grail), address(oGrail));

        // _mint paths
        hlp.setPath(
            address(ast),
            address(cpr.token0()),
            address(hlpc),
            abi.encodePacked(address(ast), weth, address(cpr.token0()))
        );
        hlp.setPath(
            address(ast), address(cpr.token1()), address(hlpc), abi.encodePacked(address(ast), address(cpr.token1()))
        );

        // _burn paths
        hlp.setPath(
            address(cpr.token0()),
            address(ast),
            address(hlpc),
            abi.encodePacked(address(cpr.token0()), weth, address(ast))
        );
        hlp.setPath(
            address(cpr.token1()), address(ast), address(hlpc), abi.encodePacked(address(cpr.token1()), address(ast))
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
        new StrategyPendleCamelot(address(hlp), address(lphlp), address(prtr), address(mrkt), address(cpr), address(ast));

        str.file("slippage", 600);
        str.setTwapPeriod(5);
    }

    function testMint() public {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        uint256 expectedSha = 9029811389296069838;

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
        uint256 expectedBurnedAmount = 986572426;

        assertEq(str.burn(address(ast), shares, ""), expectedBurnedAmount);
        assertEq(ast.balanceOf(address(this)), expectedBurnedAmount);
        assertEq(str.totalShares(), 0);
    }

    function testEarn() public {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        str.mint(address(ast), astBal, "");

        uint256 mrktBal1 = mrkt.balanceOf(address(str));

        vm.warp(block.timestamp + 432_000); // +5 days
        vm.roll(block.number + 1000000); // +1000000 blocks

        str.earn();

        uint256 mrktBal2 = mrkt.balanceOf(address(str));

        assert(mrktBal1 < mrktBal2);
    }

    function testExit() public {
        StrategyPendleCamelot str2 =
        new StrategyPendleCamelot(address(hlp), address(lphlp), address(prtr), address(mrkt), address(cpr), address(ast));
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
        StrategyPendleCamelot str2 =
        new StrategyPendleCamelot(address(hlp), address(lphlp), address(prtr), address(mrkt), address(cpr), address(ast));

        str2.move(address(str));
    }

    function testRate() public {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        uint256 sha = str.mint(address(ast), astBal, "");
        uint256 expectedRate = 990862901072258694031;

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
