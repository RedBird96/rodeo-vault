// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DSTest} from "../test/utils/DSTest.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Investor} from "../Investor.sol";
import {InvestorHelper} from "../InvestorHelper.sol";
import {PositionManager} from "../PositionManager.sol";
import {Pool} from "../Pool.sol";
import {Strategy} from "../Strategy.sol";
import {Multisig} from "../support/Multisig.sol";
import {StrategyHelper, StrategyHelperMulti} from "../StrategyHelper.sol";
import {PositionManager, ERC721TokenReceiver} from "../PositionManager.sol";
import {PartnerProxy} from "../PartnerProxy.sol";
import {StrategyHelper} from "../StrategyHelper.sol";
import {JoePath, JoeVersion} from "../interfaces/IJoe.sol";
import {StrategyJoe} from "../strategies/StrategyJoe.sol";
import {StrategyHold} from "../strategies/StrategyHold.sol";
import {LiquidityMining} from "../token/LiquidityMining.sol";
import {OneOffUnpause} from "../support/OneOffUnpause.sol";
import {Pool} from "../Pool.sol";
import {StrategyJonesUsdc} from "../strategies/StrategyJonesUsdc.sol";

import {console} from "../test/utils/console.sol";

contract Debug is DSTest, ERC721TokenReceiver {
    function run() external {
        address rdo = 0x033f193b3Fceb22a440e89A2867E8FEE181594D9;
        address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        address poolUsdc = 0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE;
        address investorActor = 0xeF6a8aF699671B35EcA1231d0c769a72CbcE3a92;
        address iasp = 0x023be37efd018Ce6B2707eA7452012642B6A5000;
        address strategyHelper = 0x72f7101371201CeFd43Af026eEf1403652F115EE;
        Investor investor = Investor(0x8accf43Dd31DfCd4919cc7d65912A475BfA60369);
        Multisig multisig = Multisig(payable(0xaB7d6293CE715F12879B9fa7CBaBbFCE3BAc0A5a));

        //PositionManager positionManager = PositionManager(0x5e4d7F61cC608485A2E4F105713D26D58a9D0cF6);

        //vm.startPrank(0x59b670e9fA9D0A427751Af201D676719a970857b); // Local
        address deployer = 0x20dE070F1887f82fcE2bdCf5D6d9874091e6FAe9;
        //vm.startPrank(deployer);
        vm.startPrank(address(multisig));

        StrategyJonesUsdc s = new StrategyJonesUsdc(
          address(strategyHelper),
          0x5859731D7b7e413A958eA1cDb9020C611b016395, // Proxy
          0x42EfE3E686808ccA051A49BCDE34C5CbA2EBEfc1, // Adapter
          0x0aEfaD19aA454bCc1B1Dd86e18A7d58D0a6FAC38 // Farming
        );
        s.file("slippage", 100);
        //s.file("keeper", keeper);
        s.file("exec", iasp);
        s.file("exec", address(investor));
        PartnerProxy(payable(0x5859731D7b7e413A958eA1cDb9020C611b016395)).setExec(address(s), true);
        uint256 sid = investor.nextStrategy();
        investor.setStrategy(sid, address(s));
        IERC20(usdc).approve(address(investor), 100e6);
        uint256 pid = investor.earn(address(multisig), 0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE, sid, 100e6, 0, "");
        (,,,,,uint256 sha,) = investor.positions(pid);
        Strategy oj = Strategy(0xDC34bE34Af0459c336b68b58b7B0aD2CB755b42c);
        console.log("sha", sha);
        console.log("value", s.rate(sha));
        console.log("value-o", oj.rate(oj.totalShares())/1e16);
        s.earn();
        console.log("value2", s.rate(sha));
        console.log("value2-o", oj.rate(oj.totalShares())/1e16);
        vm.roll(block.number+1);
        vm.warp(block.timestamp+40000);
        s.earn();
        investor.edit(pid, 0 - int256(sha / 100), 0, "");
        (,,,,,sha,) = investor.positions(pid);
        console.log("value3", s.rate(sha));
        console.log("value3-o", oj.rate(oj.totalShares())/1e16);



        //// UNPAUSE
        //Pool pool = Pool(poolUsdc);
        //console.log("before", pool.getTotalLiquidity() * 1e18 / pool.totalSupply() / 1e14);
        //OneOffUnpause spell = new OneOffUnpause();
        //pool.file("exec", address(spell));
        //spell.run();
        //console.log("after", pool.getTotalLiquidity() * 1e18 / pool.totalSupply() / 1e14);

        //StrategyHold s = new StrategyHold(strategyHelper, usdc);
        //s.file("exec", address(investor));
        //s.file("exec", address(investorActor));
        //s.file("exec", address(multisig));
        //s.file("exec", address(deployer));
        //s.file("keeper", address(keeper));
        //multisig.add(address(strategyHelper), 0, abi.encodeWithSignature("setPath(address,address,address,bytes)", weth, joe, shJoe, b));
        //investor.setStrategy(34, address(s));
        //address joe = 0x371c7ec6D8039ff7933a2AA28EB827Ffe1F52f07;
        //console.log("value", IERC20(joe).balanceOf(deployer)/1e14);

        /*
        TokenStakingDividends tsd = TokenStakingDividends(0x40aDa8CE51aD45a0211a7f495A526E26e4b3b5Ea);
        IERC20(rdo).approve(address(tsd), 4612e18);
        tsd.donate(0, 4612e18);
        (uint256 owed, int256 claimed) = tsd.claimable(deployer, 0);
        console.log("claimable", owed/1e14);
        console.log("claimed", uint256(claimed));
        (owed, claimed) = tsd.claimable(deployer, 1);
        console.log("claimable2", owed);
        console.log("claimed2", uint256(claimed));
        */


        /*
        IERC20(usdc).transfer(poolUsdc, 950000e6);
        console.log("shares       ", p.totalSupply());
        console.log("borrow       ", p.getTotalBorrow()/1e6);
        console.log("liquidity    ", p.getTotalLiquidity()/1e6);
        console.log("utilization  ", p.getUtilization()/1e14);
        console.log("ribusdc      ", 1e4 * p.getTotalLiquidity() / p.totalSupply());
        */

        /*
        // DEPLOY NEW STRATEGY
        StrategyBalancer s = new StrategyBalancer(
            address(strategyHelper),
            0xBA12222222228d8Ba445958a75a0704d566BF2C8,
            0xb08E16cFc07C684dAA2f93C70323BAdb2A6CBFd2,
            0x32dF62dc3aEd2cD6224193052Ce665DC18165841,
            weth
        );
        //vm.stopPrank();
        //vm.startPrank(0xa5c1c5a67Ba16430547FEA9D608Ef81119bE1876);
        //address(0x97247DE3fe7c5aA718b2be4d454E42de11eAfc6d).call(abi.encodeWithSignature("whitelistAdd(address)", address(s)));
        //address(0x4E5Cf54FdE5E1237e80E87fcbA555d829e1307CE).call(abi.encodeWithSignature("setWhitelist(address)", 0x97247DE3fe7c5aA718b2be4d454E42de11eAfc6d));
        s.file("slippage", 200);
        s.file("exec", investorActor);
        s.file("exec", address(investor));
        vm.stopPrank();
        vm.startPrank(address(multisig));
        //address o = address(new OracleUniswapV2Usdc(0x87425D8812f44726091831a9A109f4bDc3eA34b4, usdc));
        //StrategyHelper(strategyHelper).setOracle(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8, o);
        uint256 sid = investor.nextStrategy();
        investor.setStrategy(sid, address(s));
        vm.stopPrank();
        vm.startPrank(deployer);
        IERC20(usdc).approve(address(investor), type(uint256).max);
        investor.earn(deployer, poolUsdc, sid, 50e6, 0, "");
        s.earn();
        console.log("value", s.rate(s.totalShares())/1e16);
        investor.earn(deployer, poolUsdc, sid, 10e6, 0, "");
        console.log("value", s.rate(s.totalShares())/1e16);
        investor.earn(deployer, poolUsdc, sid, 10e6, 0, "");
        console.log("value", s.rate(s.totalShares())/1e16);
        vm.warp(block.timestamp+1800);
        s.earn();
        uint256 pid = investor.nextPosition()-2;
        (,,,,,uint256 sha,) = investor.positions(pid);
        investor.edit(pid, 0-int256(sha), 0, "");
        console.log("value", s.rate(s.totalShares())/1e16);
        //*/

        /*
        // UPDATE STRATEGY
        //PartnerProxy p = new PartnerProxy();
        StrategyJoe s = new StrategyJoe(
          address(strategyHelper),
          0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30,
          0x94d53BE52706a155d27440C4a2434BEa772a6f7C,
          8
        );
        //p.setExec(address(s), true);
        //p.setExec(address(multisig), true);
        //p.setExec(address(deployer), false);
        s.file("slippage", 200);
        s.file("exec", investorActor);
        s.file("exec", address(investor));
        //vm.stopPrank();
        //vm.startPrank(0xa5c1c5a67Ba16430547FEA9D608Ef81119bE1876);
        //address(0x97247DE3fe7c5aA718b2be4d454E42de11eAfc6d).call(abi.encodeWithSignature("whitelistAdd(address)", address(p)));
        //address(0x16240aC2fBD41F4087421E1525f74338Bc95Cf64).call(abi.encodeWithSignature("whitelistAdd(address)", address(p)));
        //vm.stopPrank();
        //vm.startPrank(deployer);
        StrategyJoe os = StrategyJoe(investor.strategies(22));
        console.log("value old", os.rate(os.totalShares())/1e16);
        vm.stopPrank();
        vm.startPrank(address(multisig));
        investor.setStrategy(22, address(s));
        vm.stopPrank();
        vm.startPrank(deployer);
        console.log("value new", s.rate(s.totalShares())/1e16);
        IERC20(usdc).approve(address(investor), type(uint256).max);
        investor.earn(deployer, poolUsdc, 22, 50e6, 0, "");
        console.log("value after", s.rate(s.totalShares())/1e16);
        //uint256 id = investor.nextPosition()-1;
        //(,,,,,uint256 sha,) = investor.positions(id);
        //console.log("value sha", os.rate(sha)/1e16);
        //uint256 before = IERC20(usdc).balanceOf(deployer);
        //investor.edit(id, 0-int256(sha), 0, "");
        //console.log("change", (IERC20(usdc).balanceOf(deployer) - before) / 1e4);
        //*/

        /*
        address shm = address(new StrategyHelperMulti(address(strategyHelper)));
        vm.stopPrank();
        vm.startPrank(address(multisig));
        StrategyGMXGLP(0x390358DEf53f2316671ed3B13D4F4731618Ff6A3).file("slippage", 200);
        StrategyHelper(strategyHelper).setPath(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8, weth, 0xb1Ae664e23332eE54e0C029937e26058a08708cC, abi.encode(weth, bytes32(hex"cc65a812ce382ab909a11e434dbf75b34f1cc59d000200000000000000000001")));
        address[] memory assets = new address[](3);
        assets[0] = 0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8;
        assets[1] = weth;
        assets[2] = usdc;
        StrategyHelper(strategyHelper).setPath(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8, usdc, shm, abi.encode(assets));
        */

        //StrategyJoe s = new StrategyJoe(strategyHelper, 0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30, 0xee1D31Ab646056f549a78FEacb73be45332fA078, 8);
        //vm.etch(0x7Cc6Cd617c5d25C7B25dF1719306b17d061Bf0E7, address(s).code);

        /*
        // DEBUG PM ACTION STAGING
        //StrategyPendleCamelot s = new StrategyPendleCamelot(
        //    strategyHelper,
        //    0xA8c2f51433bE6F318FF9e4C9291eaC391cf72987,
        //    0x0000000001E4ef00d069e71d6bA041b0A16F7eA0,
        //    0x24e4Df37ea00C4954d668e3ce19fFdcffDEc2cF6,
        //    0xBfCa4230115DE8341F3A3d5e8845fFb3337B2Be3,
        //    weth
        //);
        //vm.etch(0x7a645027604A0423dA26ef363A27E9d913A92480, address(s).code);
        vm.stopPrank();
        vm.startPrank(0x20dE070F1887f82fcE2bdCf5D6d9874091e6FAe9);
        address(0xbb2c59E4ea21f15cD43F915ed470C78E647F55eb).call(
            hex"d79c2f7a00000000000000000000000020de070f1887f82fce2bdcf5d6d9874091e6fae90000000000000000000000003afbad98a5d76b37cb4d060b18a1b246fbaccfba00000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000001312d00000000000000000000000000000000000000000000000000000000000098968000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000064"
        );
        //*/

        /*
        // DEBUG PM ACTION
        //StrategyJoe c = new StrategyJoe(
        //  strategyHelper,
        //  0xb4315e873dBcf96Ffd0acd8EA43f689D8c20fB30,
        //  0x94d53BE52706a155d27440C4a2434BEa772a6f7C,
        //  8
        //);
        //vm.etch(0x160639DE10ABb21CD9D3E1c4CdFA5ea6BfA82872, address(c).code);
        vm.stopPrank();
        //vm.startPrank(0x4877809ac00cFdc0B81Eaed6f715189983a41B7E);
        vm.startPrank(0x20dE070F1887f82fcE2bdCf5D6d9874091e6FAe9);
        address(0x5e4d7F61cC608485A2E4F105713D26D58a9D0cF6).call(
        //address(0xF507733f260a42bB2c8108dE87B7B0Ce5826A9cD).call(
            hex"20f11719000000000000000000000000000000000000000000000000000000000000020400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001312d00000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000032"
        );
        //*/

        /*
        OracleChainlinkETH owst = new OracleChainlinkETH(0xB1552C5e96B312d0Bf8b554186F846C40614a540, 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
        sh.setOracle(0x5979D7b546E38E414F7E9822514be443A4800529, address(owst));
        StrategyHelperCurve shc = new StrategyHelperCurve(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
        {
        address[] memory pathPools = new address[](3);
        uint256[] memory pathCoinIn = new uint256[](3);
        uint256[] memory pathCoinOut = new uint256[](3);
        pathPools[0] = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
        pathCoinIn[0] = 0;
        pathCoinOut[0] = 1;
        pathPools[1] = 0x960ea3e3C7FB317332d990873d354E18d7645590;
        pathCoinIn[1] = 0;
        pathCoinOut[1] = 2;
        pathPools[2] = 0x6eB2dc694eB516B16Dc9FBc678C60052BbdD7d80;
        pathCoinIn[2] = 0;
        pathCoinOut[2] = 1;
        bytes memory path = abi.encode(pathPools, pathCoinIn, pathCoinOut);
        sh.setPath(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, 0x5979D7b546E38E414F7E9822514be443A4800529, address(shc), path);
        }
        {
        address[] memory pathPools = new address[](3);
        uint256[] memory pathCoinIn = new uint256[](3);
        uint256[] memory pathCoinOut = new uint256[](3);
        pathPools[0] = 0x6eB2dc694eB516B16Dc9FBc678C60052BbdD7d80;
        pathCoinIn[0] = 1;
        pathCoinOut[0] = 0;
        pathPools[1] = 0x960ea3e3C7FB317332d990873d354E18d7645590;
        pathCoinIn[1] = 2;
        pathCoinOut[1] = 0;
        pathPools[2] = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
        pathCoinIn[2] = 1;
        pathCoinOut[2] = 0;
        bytes memory path = abi.encode(pathPools, pathCoinIn, pathCoinOut);
        sh.setPath(0x5979D7b546E38E414F7E9822514be443A4800529, 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, address(shc), path);
        }
        {
        address[] memory pathPools1 = new address[](1);
        uint256[] memory pathCoinIn1 = new uint256[](1);
        uint256[] memory pathCoinOut1 = new uint256[](1);
        pathPools1[0] = 0x6eB2dc694eB516B16Dc9FBc678C60052BbdD7d80;
        pathCoinIn1[0] = 1;
        pathCoinOut1[0] = 0;
        bytes memory path1 = abi.encode(pathPools1, pathCoinIn1, pathCoinOut1);
        sh.setPath(0x5979D7b546E38E414F7E9822514be443A4800529, weth, address(shc), path1);
        }
        StrategyKyber s = new StrategyKyber(
            address(sh),
            0x2B1c7b41f6A8F2b2bc45C3233a5d5FB3cD6dC9A8,
            0xBdEc4a045446F583dc564C0A227FFd475b329bf0,
            0x114DE2aFFc6A335433dbe9D3D51A8F31a5591fdF,
            800
        );
        s.file("exec", investorActor);
        s.file("slippage", 1000);
        //sh.setOracle(0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978, 0xaebDA2c976cfd1eE1977Eac079B4382acb849325);

        IERC20(usdc).approve(address(investor), 1000e6);
        investor.earn(a, poolUsdc, sid, 1000e6, 0, "");
        console.log("value", s.rate(s.totalShares())/1e16);
        */

        /*
        vm.warp(block.timestamp+1);
        (,,,,,uint256 sha,) = investor.positions(investor.nextPosition()-1);
        investor.edit(investor.nextPosition()-1, 0-int256(sha), 0, "");
        */

        /*
        s.file("exec", address(investor));
        StrategyKyber s2 = new StrategyKyber(
            address(sh),
            0x2B1c7b41f6A8F2b2bc45C3233a5d5FB3cD6dC9A8,
            0xBdEc4a045446F583dc564C0A227FFd475b329bf0,
            0x114DE2aFFc6A335433dbe9D3D51A8F31a5591fdF,
            800
        );
        s2.file("exec", address(investor));
        s2.file("exec", address(investorActor));
        investor.setStrategy(sid, address(s2));
        console.log("value s", s.rate(s.totalShares())/1e16);
        console.log("value s2", s2.rate(s2.totalShares())/1e16, s2.totalShares());
        */

        /*
        IERC20(usdc).approve(address(investor), 1000e6);
        investor.earn(deployer, poolUsdc, sid, 1000e6, 0, "");
        (,,,,, uint256 sha,) = investor.positions(investor.nextPosition() - 1);
        console.log("value", s.rate(sha) / 1e16);
        console.log("total", s.rate(s.totalShares()) / 1e16);

        vm.warp(block.timestamp + 1);
        investor.edit(investor.nextPosition() - 1, 0 - int256(sha), 0, "");
        */
    }
}
