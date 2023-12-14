// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVault, IOperators, ISettingsManager} from "../interfaces/IVela.sol";
import {IStrategyHelper} from "../interfaces/IStrategyHelper.sol";
import {StrategyVela} from "../strategies/StrategyVela.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {DSTest} from "./utils/DSTest.sol";

contract StrategyVelaTest is DSTest {
    ISettingsManager mngr;
    IStrategyHelper hlp;
    StrategyVela str;
    IOperators op;
    IVault vault;
    IERC20 vlp;
    IERC20 ast;

    uint256 arbFork;

    function setUp() external {
        arbFork =
            vm.createSelectFork("https://arb-mainnet.g.alchemy.com/v2/-dVfS3BS-6YZkGd9GC6Ist_Y12-KPFXw", 107_000_000);

        ast = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

        vm.prank(0x489ee077994B6658eAfA855C308275EAd8097C4A); // Just an address with positive ast balance

        ast.transfer(address(this), 1000e6);

        hlp = IStrategyHelper(0x72f7101371201CeFd43Af026eEf1403652F115EE);

        vault = IVault(0xC4ABADE3a15064F9E3596943c699032748b13352);
        vlp = IERC20(0xC5b2D9FDa8A82E8DcECD5e9e6e99b78a9188eB05);
        mngr = ISettingsManager(0x6F2c6010A438546242cAb29Bb755c1F0AfaCa5AA);
        op = IOperators(0x23fc7c88402Fe3314d4E76AC42F4c5A3e01aE684);

        str = new StrategyVela(address(hlp), address(vault), address(vlp), address(ast));

        vm.mockCall(
            address(op), abi.encodeWithSelector(IOperators.getOperatorLevel.selector, address(this)), abi.encode(3)
        );
        vm.mockCall(
            address(mngr),
            abi.encodeWithSelector(ISettingsManager.isWhitelistedFromCooldown.selector, address(str)),
            abi.encode(true)
        );

        mngr.setEnableUnstaking(address(ast), true);
    }

    function testMint() external {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        uint256 expectedSha = 1000356410893438539149;

        assertEq(str.mint(address(ast), astBal, ""), expectedSha);
        assertEq(ast.balanceOf(address(this)), 0);
        assertEq(str.totalShares(), expectedSha);
    }

    function testBurn() external {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        uint256 shares = str.mint(address(ast), astBal, "");
        uint256 expectedBurnedAmount = 999999999;

        assertEq(str.burn(address(ast), shares, ""), expectedBurnedAmount);
        assertEq(ast.balanceOf(address(this)), expectedBurnedAmount);
        assertEq(str.totalShares(), 0);
    }

    function testEarn() external {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);
        str.mint(address(ast), astBal, "");
        str.earn();
    }

    function testExit() external {
        StrategyVela str2 = new StrategyVela(address(hlp), address(vault), address(vlp), address(ast));
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);
        str.mint(address(ast), astBal, "");

        uint256 sha1 = str.totalShares();

        vm.mockCall(
            address(mngr),
            abi.encodeWithSelector(ISettingsManager.isWhitelistedFromTransferCooldown.selector, address(str2)),
            abi.encode(true)
        );

        vm.warp(block.timestamp+84000);
        str.exit(address(str2));
        str2.move(address(str));

        uint256 sha2 = str2.totalShares();

        assertEq(sha1, sha2);
    }

    function testMove() external {
        StrategyVela str2 = new StrategyVela(address(hlp), address(vault), address(vlp), address(ast));

        str2.move(address(str));
    }

    function testRate() external {
        uint256 astBal = ast.balanceOf(address(this));

        ast.approve(address(str), astBal);

        uint256 sha = str.mint(address(ast), astBal, "");
        uint256 expectedRate = 500048140814099999999;

        assertEq(str.rate(sha / 2), expectedRate);
    }
}
