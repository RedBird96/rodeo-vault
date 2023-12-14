// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {StrategyHelper, StrategyHelperUniswapV3} from "../StrategyHelper.sol";
import {IUniProxy, IHypervisor, IQuoter} from "../interfaces/IGamma.sol";
import {StrategyGamma} from "../strategies/StrategyGamma.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {DSTest} from "./utils/DSTest.sol";

contract StrategyGammaTest is DSTest {
    StrategyHelperUniswapV3 hlpV3;
    StrategyHelper hlp;
    StrategyGamma str;
    IHypervisor hyp;
    IOracle oTok0;
    IOracle oTok1;
    IOracle oAst0;
    IOracle oAst1;
    IUniProxy prx;
    IQuoter qtr;
    IERC20 ast0;
    IERC20 ast1;

    uint256 arbFork;

    bytes pathToLp;

    error WrongTargetAsset();
    error Unauthorized();

    function setUp() public {
        arbFork =
            vm.createSelectFork("https://arb-mainnet.g.alchemy.com/v2/-dVfS3BS-6YZkGd9GC6Ist_Y12-KPFXw", 91_500_000);

        ast0 = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8); // USDC
        ast1 = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9); // USDT

        vm.prank(0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6); // Just an address with positive ast0 balance
        ast0.transfer(address(this), 1000e6);

        vm.prank(0x960ea3e3C7FB317332d990873d354E18d7645590); // Just an address with positive ast1 balance
        ast1.transfer(address(this), 1000e6);

        oTok0 = IOracle(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612); // ETH/USD
        oTok1 = IOracle(0x86E53CF1B870786351Da77A57575e79CB55812CB); // LINK/USD
        oAst0 = IOracle(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3); // USDC/USD
        oAst1 = IOracle(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7); // USDT/USD

        hlp = new StrategyHelper();
        hlpV3 = new StrategyHelperUniswapV3(0xE592427A0AEce92De3Edee1F18E0157C05861564); // UniSwap V3 Router

        prx = IUniProxy(0x22AE0dA638B4c4074A683045cCe759E8Ba990B1f);
        hyp = IHypervisor(0xfA392dbefd2d5ec891eF5aEB87397A89843a8260); // WETH/LINK
        qtr = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

        hlp.setOracle(address(hyp.token0()), address(oTok0));
        hlp.setOracle(address(hyp.token1()), address(oTok1));
        hlp.setOracle(address(ast0), address(oAst0));
        hlp.setOracle(address(ast1), address(oAst1));

        // _mint paths
        pathToLp = abi.encodePacked(address(hyp.token0()), uint24(3000), address(hyp.token1()));
        hlp.setPath(
            address(ast0),
            address(hyp.token0()),
            address(hlpV3),
            abi.encodePacked(address(ast0), uint24(500), address(hyp.token0()))
        );
        hlp.setPath(
            address(ast1),
            address(hyp.token0()),
            address(hlpV3),
            abi.encodePacked(address(ast1), uint24(500), address(hyp.token0()))
        );

        // _burn paths
        hlp.setPath(
            address(hyp.token0()),
            address(ast0),
            address(hlpV3),
            abi.encodePacked(address(hyp.token0()), uint24(500), address(ast0))
        );
        hlp.setPath(
            address(hyp.token1()),
            address(ast0),
            address(hlpV3),
            abi.encodePacked(address(hyp.token1()), uint24(3000), address(ast0))
        );

        str =
        new StrategyGamma(address(hlp), address(hlpV3), address(prx), address(qtr),  address(hyp), address(hyp.token0()), pathToLp);
    }

    function testMintWithUsdcAst() public {
        uint256 val = ast0.balanceOf(address(this));

        ast0.approve(address(str), val);

        assertEq(str.mint(address(ast0), val, ""), 56803881839251015524);
        assertEq(ast0.balanceOf(address(this)), 0);
        assertEq(str.totalShares(), 56803881839251015524);
    }

    function testMintWithUsdtAst() public {
        uint256 val = ast1.balanceOf(address(this));

        ast1.approve(address(str), val);

        assertEq(str.mint(address(ast1), val, ""), 56822794311777263660);
        assertEq(ast1.balanceOf(address(this)), 0);
        assertEq(str.totalShares(), 56822794311777263660);
    }

    function testBurn() public {
        uint256 val = ast0.balanceOf(address(this));

        ast0.approve(address(str), val);

        uint256 shares = str.mint(address(ast0), val, "");
        uint256 expectedBurnedAmount = 994304690;

        vm.mockCall(address(oTok1), abi.encodeWithSelector(IOracle.latestAnswer.selector), abi.encode(67e7));

        assertEq(str.burn(address(ast0), shares, ""), expectedBurnedAmount);
        assertEq(ast0.balanceOf(address(this)), expectedBurnedAmount);
        assertEq(str.totalShares(), 0);
    }

    function testEarn() public {
        uint256 val = ast0.balanceOf(address(this));

        ast0.approve(address(str), val);
        str.mint(address(ast0), val, "");
        str.earn();
    }

    function testExit() public {
        StrategyGamma str2 = new StrategyGamma(
            address(hlp), address(hlpV3), address(prx), address(qtr), address(hyp), address(hyp.token0()), pathToLp
        );
        uint256 val = ast0.balanceOf(address(this));

        ast0.approve(address(str), val);
        str.mint(address(ast0), val, "");

        uint256 sha1 = str.totalShares();

        str.exit(address(str2));
        str2.move(address(str));

        uint256 sha2 = str2.totalShares();

        assertEq(sha1, sha2);
    }

    function testMove() public {
        StrategyGamma str2 = new StrategyGamma(
            address(hlp), address(hlpV3), address(prx), address(qtr), address(hyp), address(hyp.token0()), pathToLp
        );

        str2.move(address(str));
    }

    function testRate() public {
        uint256 val = ast0.balanceOf(address(this));

        ast0.approve(address(str), val);
        str.mint(address(ast0), val, "");

        uint256 sharesAmount = 200;
        uint256 expectedRate = 3514;

        assertEq(str.rate(sharesAmount), expectedRate);
    }

    function testConstructorMustFail() public {
        vm.expectRevert(WrongTargetAsset.selector);

        new StrategyGamma(address(hlp), address(hlpV3), address(prx), address(qtr), address(hyp), address(ast0), pathToLp);
    }

    function testSetTwapPeriod(uint32 twapPeriod) public {
        assertEq(str.twapPeriod(), 1800);

        str.setTwapPeriod(twapPeriod);

        assertEq(str.twapPeriod(), twapPeriod);
    }

    function testSetTwapPeriodMustFail() public {
        vm.prank(address(hyp));
        vm.expectRevert(Unauthorized.selector);

        str.setTwapPeriod(2000);
    }

    function testSetPathToLp(bytes calldata newPathToLp) public {
        checkEq0(str.pathToLp(), pathToLp);

        str.setPathToLp(newPathToLp);

        checkEq0(str.pathToLp(), newPathToLp);
    }

    function testSetPath0MustFail() public {
        vm.prank(address(hyp));
        vm.expectRevert(Unauthorized.selector);

        str.setPathToLp(pathToLp);
    }
}
