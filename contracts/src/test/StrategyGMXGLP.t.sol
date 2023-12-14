// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTest} from "./utils/DSTest.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {StrategyHelper} from "../StrategyHelper.sol";
import {StrategyGMXGLP} from "../strategies/StrategyGMXGLP.sol";

contract MockGLPRewardTracker {
    constructor() {}

    function claimable(address) external pure returns (uint256) {
        return 50e15;
    }
}

contract MockGlpManager {
    address public glp;

    constructor(address _glp) {
        glp = _glp;
    }

    function getAumInUsdg(bool) external pure returns (uint256) {
        return 200000000e18;
    }

    function vault() external view returns (address) {
        return address(this);
    }

    function mintBurnFeeBasisPoints() external pure returns (uint256) {
        return 25;
    }

    function stableTaxBasisPoints() external pure returns (uint256) {
        return 5;
    }

    function getFeeBasisPoints(address, uint256, uint256, uint256, bool) external pure returns (uint256) {
        return 128;
    }
}

contract MockRewardRouter {
    address public glpManager;
    address public feeGlpTracker;
    address public stakedGlpTracker;
    address public weth;
    uint256 glpPrice = 950000;

    constructor(address _glpManager, address _feeGlpTracker, address _stakedGlpTracker, address _weth) {
        glpManager = _glpManager;
        feeGlpTracker = _feeGlpTracker;
        stakedGlpTracker = _stakedGlpTracker;
        weth = _weth;
    }

    function mintAndStakeGlp(address _token, uint256 _amount, uint256, uint256) external returns (uint256) {
        if (_token == weth) {
            MockERC20(stakedGlpTracker).mint(address(msg.sender), 2000e18);
            MockERC20(weth).burn(address(msg.sender), _amount);

            return 0;
        }

        uint256 glpAmount = _amount * 1e18 / glpPrice;

        MockERC20(stakedGlpTracker).mint(address(msg.sender), glpAmount);

        return glpAmount;
    }

    function unstakeAndRedeemGlp(address _token, uint256 _glpAmount, uint256, address to) external returns (uint256) {
        uint256 amt = _glpAmount * glpPrice / 1e18;
        MockERC20(stakedGlpTracker).burn(address(msg.sender), _glpAmount);
        MockERC20(_token).mint(to, amt);
        return amt;
    }

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external {}
}

contract StrategyGMXGLPTest is DSTest {
    MockERC20 asset;
    MockOracle oAsset;
    MockERC20 glp;
    StrategyHelper sh;
    StrategyGMXGLP strategy;
    MockGlpManager glpManager;
    MockRewardRouter rewardRouter;
    MockGLPRewardTracker feeGlpTracker;
    MockERC20 stakedGlpTracker;
    MockERC20 weth;
    MockOracle oWeth;

    function setUp() public {
        oWeth = new MockOracle(1650e8);
        weth = new MockERC20(18);
        glp = new MockERC20(18);
        glpManager = new MockGlpManager(address(glp));
        feeGlpTracker = new MockGLPRewardTracker();
        stakedGlpTracker = new MockERC20(18);
        rewardRouter =
            new MockRewardRouter(address(glpManager), address(feeGlpTracker), address(stakedGlpTracker), address(weth));
        glp.mint(address(glpManager), 235000000e18);

        asset = new MockERC20(6);
        oAsset = new MockOracle(1e8);
        asset.mint(address(this), 500e6);
        sh = new StrategyHelper();
        sh.setOracle(address(asset), address(oAsset));
        sh.setOracle(address(weth), address(oWeth));
        strategy = new StrategyGMXGLP(
            address(sh),
            address(rewardRouter),
            address(rewardRouter),
            address(glp),
            address(weth),
            address(weth)
        );
        vm.warp(block.timestamp + 3601);
    }

    function testRate() public {
        asset.approve(address(strategy), 500e6);
        strategy.mint(address(asset), 500e6, "");
        assertEq(strategy.rate(200e18), 199384042553191489361);
    }

    function testMint() public {
        asset.approve(address(strategy), 500e6);
        assertEq(strategy.mint(address(asset), 500e6, ""), 526315789473684210526);
        assertEq(asset.balanceOf(address(this)), 0);
        assertEq(strategy.totalShares(), 526315789473684210526);
    }

    function testBurn() public {
        asset.approve(address(strategy), 500e6);
        uint256 sha = strategy.mint(address(asset), 500e6, "");

        assertEq(strategy.burn(address(asset), sha, ""), 499999999);
        assertEq(asset.balanceOf(address(this)), 499999999);
        assertEq(strategy.totalShares(), 0);
    }

    function testCompound() public {
        asset.approve(address(strategy), 500e6);
        strategy.mint(address(asset), 500e6, "");

        // Compound
        uint256 glpBefore = stakedGlpTracker.balanceOf(address(strategy));
        weth.mint(address(strategy), 1e18);
        vm.expectCall(
            address(rewardRouter), abi.encodeCall(MockRewardRouter.mintAndStakeGlp, (address(weth), 1e18, 0, 0))
        );
        strategy.earn();
        assertEq(stakedGlpTracker.balanceOf(address(strategy)) - glpBefore, 2000e18);

        // Mint more, resulting in less shares than GLP
        asset.mint(address(this), 500e6);
        asset.approve(address(strategy), 500e6);
        assertEq(strategy.mint(address(asset), 500e6, ""), 109649122807017543859);
        assertLt(strategy.totalShares(), stakedGlpTracker.balanceOf(address(strategy)));

        // Burn shares, with more GLP burned than shares
        glpBefore = stakedGlpTracker.balanceOf(address(strategy));
        uint256 sharesBefore = strategy.totalShares();
        strategy.burn(address(asset), 100e18, "");
        assertGt(glpBefore - stakedGlpTracker.balanceOf(address(strategy)), sharesBefore - strategy.totalShares());
    }
}
