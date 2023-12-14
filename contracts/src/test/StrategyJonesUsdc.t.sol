// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTest} from "./utils/DSTest.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {MockRewarderMiniChefV2} from "./mocks/MockRewarderMiniChefV2.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {StrategyHelper} from "../StrategyHelper.sol";
import {PartnerProxy} from "../PartnerProxy.sol";
import {StrategyJonesUsdc} from "../strategies/StrategyJonesUsdc.sol";

contract MockJones {
    address public usdc;

    constructor(address _usdc) {
        usdc = _usdc;
    }

    function vaultRouter() public view returns (address) {
        return address(this);
    }

    function stableVault() public view returns (address) {
        return address(this);
    }

    function EXIT_COOLDOWN() public pure returns (uint256) {
        return 24 hours;
    }

    function stableRewardTracker() public view returns (address) {
        return address(this);
    }

    function depositStable(uint256 amt, bool) public {
        IERC20(usdc).transferFrom(msg.sender, address(this), amt);
    }

    uint256 public stableWithdrawalSignalAmout;

    function stableWithdrawalSignal(uint256 amt, bool) public returns (uint256) {
        stableWithdrawalSignalAmout = amt;
        return 123;
    }

    function cancelStableWithdrawalSignal(uint256, bool) public {
        stableWithdrawalSignalAmout = 0;
    }

    uint256 public redeemStableEpoch;

    function redeemStable(uint256 eph) public returns (uint256) {
        redeemStableEpoch = eph;
        MockERC20(usdc).mint(msg.sender, stableWithdrawalSignalAmout);
        return stableWithdrawalSignalAmout;
    }

    function claimRewards() external returns (uint256, uint256, uint256) {
        MockERC20(usdc).mint(msg.sender, 2e6);
        return (0, 0, 0);
    }

    function stakedAmount(address) external view returns (uint256) {
        return IERC20(usdc).balanceOf(address(this));
    }

    function previewRedeem(uint256 amt) external view returns (uint256) {
        return amt;
    }
}

contract StrategyJonesUsdcTest is DSTest {
    MockERC20 usdc;
    MockOracle oUsdc;
    StrategyHelper sh;
    PartnerProxy proxy;
    MockJones adapter;
    StrategyJonesUsdc s;
    MockRewarderMiniChefV2 farming;

    function setUp() public {
        usdc = new MockERC20(6);
        oUsdc = new MockOracle(0.99e8);
        sh = new StrategyHelper();
        sh.setOracle(address(usdc), address(oUsdc));
        proxy = new PartnerProxy();
        adapter = new MockJones(address(usdc));
        farming = new MockRewarderMiniChefV2(address(adapter));
        s = new StrategyJonesUsdc(address(sh), address(proxy), address(adapter), address(farming));
        proxy.setExec(address(s), true);
        usdc.mint(address(this), 500e6);
        usdc.approve(address(s), 500e6);
    }

    function testMint() public {
        assertEq(s.mint(address(usdc), 100e6, ""), 99e18);
        usdc.transfer(address(s), 15e6);
        assertEq(s.mint(address(usdc), 50e6, "") / 1e16, 4304);
    }

    function testRate() public {
        s.mint(address(usdc), 100e6, "");
        s.earn();
        assertEq(s.rate(s.totalShares()), 99970200000000000000);
    }

    function testBurn() public {
        s.mint(address(usdc), 100e6, "");
        s.earn();
        assertEq(s.burn(address(usdc), s.totalShares() * 5 / 100, ""), 5049000);
    }

    function testExit() public {
        s.mint(address(usdc), 25e6, "");
        s.exit(vm.addr(1));
        assertEq(usdc.balanceOf(vm.addr(1)), 25e6);
    }
}
