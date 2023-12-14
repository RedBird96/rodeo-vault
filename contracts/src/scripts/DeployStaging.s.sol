// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DSTest} from "../test/utils/DSTest.sol";
import {Investor} from "../Investor.sol";
import {StrategyGMXGM} from "../strategies/StrategyGMXGM.sol";

contract DeployStaging is DSTest {
    function run() external {
        vm.startBroadcast();

        Investor investor = Investor(0x3A806d2D7DbdbeE3aA5cD75BA9d737fc682ce367);
        address strategyHelper = 0x72f7101371201CeFd43Af026eEf1403652F115EE;
        address investorActor = 0x0F6eC2f60120105f2BEFdB7Aba1636c14B6575a5;
        address poolUsdc = 0x3AfBAd98a5D76B37cb4d060B18A1B246FbACCFBa;
        address deployer = 0x20dE070F1887f82fcE2bdCf5D6d9874091e6FAe9;
        address keeper = 0x3b1F14068Fa2AF4B08b578e80834bC031a52363D;
        address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        address wsteth = address(0);


        /*
        StrategyGMXGM s = new StrategyGMXGM(
          address(strategyHelper),
          0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8, // ExchangeRouter
          0xf60becbba223EEA9495Da3f606753867eC10d139, // Reader
          0x9Dc4f12Eb2d8405b499FB5B8AF79a5f64aB8a457, // DepoHandler
          0x9E32088F3c1a5EB38D32d1Ec6ba0bCBF499DC9ac, // WithHandler
          0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8, // DataStore
          0x70d95587d40A2caf56bd97485aB3Eec10Bee6336 // ETH Market
        );
        s.file("slippage", 100);
        s.file("keeper", keeper);
        s.file("exec", investorActor);
        s.file("exec", address(investor));
        investor.setStrategy(investor.nextStrategy(), address(s));
        */

        /*
        StrategyPendleLSD s = new StrategyPendleLSD(
            strategyHelper,
            0xA8c2f51433bE6F318FF9e4C9291eaC391cf72987,
            0x0000000001E4ef00d069e71d6bA041b0A16F7eA0, // Pendle Router
            0x08a152834de126d2ef83D612ff36e4523FD0017F, // Pendle Market wstETH
            //0x14FbC760eFaF36781cB0eb3Cb255aD976117B9Bd, // Pendle Market rETH
            wsteth,
            weth,
            weth
        );
        s.file("slippage", 250);
        s.file("keeper", keeper);
        s.file("exec", investorActor);
        s.file("exec", address(investor));
        investor.setStrategy(3, address(s));
        //*/

        /*
        StrategyPendleCamelot s = new StrategyPendleCamelot(
            strategyHelper,
            0xA8c2f51433bE6F318FF9e4C9291eaC391cf72987,
            0x0000000001E4ef00d069e71d6bA041b0A16F7eA0,
            0x24e4Df37ea00C4954d668e3ce19fFdcffDEc2cF6,
            0xBfCa4230115DE8341F3A3d5e8845fFb3337B2Be3,
            weth
        );
        s.file("slippage", 250);
        s.file("keeper", keeper);
        s.file("exec", investorActor);
        s.file("exec", address(investor));
        investor.setStrategy(2, address(s));
        //*/

        //StrategyGamma s = new StrategyGamma(
        //    strategyHelper,
        //    0xaFF008DD677d2a9fd74D27B26Efc10A8e3f7BDaD,
        //    0x22AE0dA638B4c4074A683045cCe759E8Ba990B1f,
        //    0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6,
        //    0xfBE8269F3358bA95a06474fA8324ac594fD7dC9c,
        //    usdc,
        //    abi.encodePacked(usdc, uint24(500), weth)
        //);
    }
}
