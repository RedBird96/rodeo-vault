// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {StrategyHelper, StrategyHelperUniswapV2} from "../StrategyHelper.sol";

import {IRewardRouter, IGlpManager} from "../interfaces/IGMX.sol";
import {IERC20} from "../interfaces/IERC20.sol";

import {MockRouterUniV2} from "./mocks/MockRouterUniV2.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

import {StrategyPlutusPlvGlp} from "../strategies/StrategyPlutusPlvGlp.sol";
import {PartnerProxy} from "../PartnerProxy.sol";

import {DSTest} from "./utils/DSTest.sol";

contract PlutusVault is MockERC20 {
    uint256 public plvGLPPriceInGLP;

    constructor() MockERC20(18) {
        plvGLPPriceInGLP = 1.2e18;
    }

    function changePlvPrice(uint256 _plvGLPPriceInGLP) external {
        plvGLPPriceInGLP = _plvGLPPriceInGLP;
    }

    function deposit(uint256 assets, address receiver) public {
        uint256 amountToMint = ((assets * 1e18) / plvGLPPriceInGLP) / 1e18;

        mint(receiver, amountToMint);
    }

    function redeem(uint256 shares, address, address) public returns (uint256) {
        bool success = transferFrom(msg.sender, address(this), shares);

        if (!success) revert TRANSFER_FROM_FAILED();

        burn(address(this), shares);

        return convertToAssets(shares);
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        return shares * plvGLPPriceInGLP;
    }

    error TRANSFER_FROM_FAILED();
}

contract MockGlpDepositor {
    PlutusVault public plvGLP;

    IERC20 public sGLP;
    IERC20 public fsGLP;

    error TRANSFER_FROM_FAILED();
    error UNDER_MIN_AMOUNT();

    constructor(address _sGLP, address _plvGLP) {
        sGLP = IERC20(_sGLP);
        fsGLP = IERC20(_sGLP);
        plvGLP = PlutusVault(_plvGLP);
    }

    function deposit(uint256 _amount) external {
        if (_amount < 1 ether) revert UNDER_MIN_AMOUNT();

        bool success = sGLP.transferFrom(msg.sender, address(this), _amount);

        if (!success) revert TRANSFER_FROM_FAILED();

        plvGLP.deposit(_amount, msg.sender);
    }

    // Recieved the plvGLP and returns staked GLP (sGLP)
    function redeem(uint256 amount) external {
        bool success1 = plvGLP.transferFrom(msg.sender, address(this), amount);

        if (!success1) revert TRANSFER_FROM_FAILED();

        uint256 _assets = plvGLP.redeem(amount, address(this), msg.sender);
        // Calculate fee, it should charge 2% fee
        uint256 _assetsLessFee = (_assets * 2) / 100;
        bool success = sGLP.transferFrom(address(this), msg.sender, _assetsLessFee);

        if (!success) revert TRANSFER_FROM_FAILED();
    }

    // plvGLP
    function vault() external view returns (address) {
        return address(plvGLP);
    }
}

contract MockPlutusChef {
    // Info of each user.
    struct UserInfo {
        uint96 amount; // Staking tokens the user has provided
        int128 plsRewardDebt;
    }

    IERC20 public stakingToken;
    IERC20 public pls;

    mapping(address => UserInfo) public userInfo;

    error WITHDRAW_ERROR();
    error DEPOSIT_ERROR();

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
        pls = stakingToken;
    }

    function deposit(uint96 _amount) external {
        UserInfo storage user = userInfo[msg.sender];

        if (_amount == 0) revert DEPOSIT_ERROR();

        unchecked {
            user.amount += _amount;
        }

        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint96 _amount) external {
        UserInfo storage user = userInfo[msg.sender];

        if (user.amount < _amount || _amount == 0) revert WITHDRAW_ERROR();

        unchecked {
            user.amount -= _amount;
        }

        stakingToken.transfer(msg.sender, _amount);
    }
}

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

    function getPrice(bool) external pure returns (uint256) {
        return 15550000;
    }

    function PRICE_PRECISION() external pure returns (uint256) {
        return 6;
    }
}

contract MockRewardRouter {
    address public glpManager;
    address public feeGlpTracker;
    address public stakedGlpTracker;
    address public usdc;

    uint256 glpPrice = 950000;

    constructor(address _glpManager, address _feeGlpTracker, address _stakedGlpTracker, address _usdc) {
        glpManager = _glpManager;
        feeGlpTracker = _feeGlpTracker;
        stakedGlpTracker = _stakedGlpTracker;
        usdc = _usdc;
    }

    function mintAndStakeGlp(address _token, uint256 _amount, uint256, uint256) external returns (uint256) {
        if (_token == usdc) {
            MockERC20(stakedGlpTracker).mint(address(msg.sender), 2000e18);
            MockERC20(usdc).burn(address(msg.sender), _amount);

            return 0;
        }

        uint256 glpAmount = (_amount * 1e18) / glpPrice;

        MockERC20(stakedGlpTracker).mint(address(msg.sender), glpAmount);

        return glpAmount;
    }

    function unstakeAndRedeemGlp(address _token, uint256 _glpAmount, uint256, address to) external returns (uint256) {
        uint256 amt = (_glpAmount * glpPrice) / 1e18;

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

contract StrategyPlutusPlvGlpTest is DSTest {
    MockERC20 glp;
    MockERC20 sglp;
    MockERC20 asset; // Any ERC20 asset
    MockERC20 usdc;

    MockOracle oUsdc;
    MockOracle oAsset;

    PartnerProxy proxy;
    StrategyPlutusPlvGlp strategy;
    StrategyHelper sh;
    StrategyHelperUniswapV2 shss;
    MockRouterUniV2 router;

    MockGlpManager glpManager;
    MockRewardRouter rewardRouter;
    MockGLPRewardTracker feeGlpTracker;
    MockPlutusChef plvGLPFarm;
    MockGlpDepositor plvDepositor;
    PlutusVault plutusVault;

    uint256 constant assetBalance = 1000e18;

    function setUp() public {
        // ======= Tokens =======
        glp = new MockERC20(18);
        sglp = new MockERC20(18);
        usdc = new MockERC20(6);
        asset = new MockERC20(18);

        // ======= Oracle =======
        oUsdc = new MockOracle(1e8);
        oAsset = new MockOracle(10e8);

        // ======= GMX =======
        glpManager = new MockGlpManager(address(glp));
        feeGlpTracker = new MockGLPRewardTracker();

        // ======= Plutus DAO =======
        plutusVault = new PlutusVault();
        plvDepositor = new MockGlpDepositor(
            address(sglp),
            address(plutusVault)
        );
        plvGLPFarm = new MockPlutusChef(plvDepositor.vault());

        // 235 million tokens
        glp.mint(address(glpManager), 235000000e18);
        // 500 tokens
        usdc.mint(address(this), 500e6);
        // 1000 tokens
        asset.mint(address(this), assetBalance);

        rewardRouter = new MockRewardRouter(
            address(glpManager),
            address(feeGlpTracker),
            address(sglp),
            address(usdc)
        );

        sh = new StrategyHelper();
        sh.setOracle(address(usdc), address(oUsdc));
        sh.setOracle(address(asset), address(oAsset));

        router = new MockRouterUniV2();
        shss = new StrategyHelperUniswapV2(address(router));
        sh.setPath(address(asset), address(usdc), address(shss), abi.encodePacked(address(asset), address(usdc)));
        sh.setPath(address(usdc), address(asset), address(shss), abi.encodePacked(address(usdc), address(asset)));

        proxy = new PartnerProxy();
        strategy = new StrategyPlutusPlvGlp(
            address(sh),
            address(proxy),
            address(rewardRouter),
            address(plvDepositor),
            address(plvGLPFarm),
            address(usdc)
        );
        proxy.setExec(address(strategy), true);

        // Pre-approving the strategy to take the asset token
        asset.approve(address(strategy), assetBalance);
    }

    function testMint() public {
        uint256 expectedShares = 1666;

        assertEq(strategy.mint(address(asset), assetBalance, ""), expectedShares);
        assertEq(asset.balanceOf(address(this)), 0);
        assertEq(asset.balanceOf(address(strategy)), 0);
        assertEq(strategy.totalShares(), expectedShares);
    }

    function testBurn() public {
        uint256 shares = strategy.mint(address(asset), assetBalance, "");
        uint256 expectedBurnedAmount = 3779487600000000001;

        assertEq(strategy.burn(address(asset), shares, ""), expectedBurnedAmount);
        assertEq(asset.balanceOf(address(this)), expectedBurnedAmount);
        assertEq(strategy.totalShares(), 0);
    }

    function testRate() public {
        strategy.mint(address(asset), assetBalance, "");

        uint256 sharesAmount = 200;
        uint256 expectedRate = 609560000 * 1e18;

        assertEq(strategy.rate(sharesAmount), expectedRate);
    }

    function testExit() public {
        StrategyPlutusPlvGlp strategy2 = new StrategyPlutusPlvGlp(
            address(sh),
            address(proxy),
            address(rewardRouter),
            address(plvDepositor),
            address(plvGLPFarm),
            address(usdc)
        );

        strategy.mint(address(asset), assetBalance, "");

        uint256 totalSharesS1 = strategy.totalShares();

        strategy.exit(address(strategy2));
        strategy2.move(address(strategy));

        uint256 totalSharesS2 = strategy2.totalShares();
        assertTrue(totalSharesS1 == totalSharesS2);
    }
}
