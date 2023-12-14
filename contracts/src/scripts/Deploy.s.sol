// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {console} from "../test/utils/console.sol";
import {DSTest} from "../test/utils/DSTest.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {Investor} from "../Investor.sol";
import {Multisig} from "../support/Multisig.sol";

import {Vester} from "../token/Vester.sol";
import {Helper} from "../support/Helper.sol";
import {StrategyJonesUsdc} from "../strategies/StrategyJonesUsdc.sol";

contract Deploy is DSTest {
    function run() external {
        vm.startBroadcast();

        address rdo = 0x033f193b3Fceb22a440e89A2867E8FEE181594D9;
        address usdce = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
        address usdc = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
        //address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
        //address usdt = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
        //address sushi = 0xd4d42F0b6DEF4CE0383636770eF773390d85c61A;
        //address magic = 0x539bdE0d7Dbd336b79148AA742883198BBF60342;
        //address pls = 0x51318B7D00db7ACc4026C88c3952B66278B6A67F;
        //address vsta = 0xa684cd057951541187f288294a1e1C2646aA2d24;
        //address grail = 0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8;
        //address arb = 0x912CE59144191C1204E64559FE8253a0e49E6548;
        //address pendle = 0x0c880f6761F1af8d9Aa9C466984b80DAb9a8c9e8;
        //address joe = 0x371c7ec6D8039ff7933a2AA28EB827Ffe1F52f07;
        //address camRdoEth = 0x5180Dce8F532f40d84363737858E2C5Fd0C8aB39;
        //address wsteth = 0x5979D7b546E38E414F7E9822514be443A4800529;
        //address reth = 0xEC70Dcb4A1EFa46b8F2D97C310C9c4790ba5ffA8;
        //address unsheth = 0x0Ae38f7E10A43B5b2fB064B42a2f4514cbA909ef;

        Investor investor = Investor(0x8accf43Dd31DfCd4919cc7d65912A475BfA60369);
        address strategyHelper = 0x72f7101371201CeFd43Af026eEf1403652F115EE;
        //address investorActor = 0xeF6a8aF699671B35EcA1231d0c769a72CbcE3a92;
        address iasp = 0x023be37efd018Ce6B2707eA7452012642B6A5000;
        //address poolUsdc = 0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE;
        //address ethOracle = 0xC3Fa00136EFa7B7c39F6B6f4Ed4fb8de18480712;
        //address shss = 0x4cA2a8cC7B1110CF3961D1F4AAB195d3Ab61BF9b;
        address shv3 = 0xaFF008DD677d2a9fd74D27B26Efc10A8e3f7BDaD;
        //address shb = 0xb1Ae664e23332eE54e0C029937e26058a08708cC;
        //address shc = 0x5C0B2558e38410ee11C942694914F1780F504f82;
        //address shCam = 0x7FC67A688F464538259E3F559dc63F00D64F3c0b;
        //address shJoe = 0x64DDae490517ffE00E193120e31C56e1e60B1cbc;
        //address shv2lp = 0xca13f7D2D840EbbC7742B72e4D45aACD9AAb4AdC;

        Multisig multisig = Multisig(payable(0xaB7d6293CE715F12879B9fa7CBaBbFCE3BAc0A5a));
        address deployer = 0x20dE070F1887f82fcE2bdCf5D6d9874091e6FAe9;
        address keeper = 0x3b1F14068Fa2AF4B08b578e80834bC031a52363D;
        //address admin = 0x5d52C98D4B2B9725D9a1ea3CcAf44871a34EFB96;
        //address rbcNft = 0xBba59A5DD11fc0958F0AB802500c2929AbABB956;

        /*
        StrategyJonesUsdc s = new StrategyJonesUsdc(
          address(strategyHelper),
          0x5859731D7b7e413A958eA1cDb9020C611b016395, // Proxy
          0x42EfE3E686808ccA051A49BCDE34C5CbA2EBEfc1, // Adapter
          0x0aEfaD19aA454bCc1B1Dd86e18A7d58D0a6FAC38 // Farming
        );
        s.file("slippage", 150);
        s.file("keeper", keeper);
        s.file("exec", iasp);
        s.file("exec", address(investor));
        s.file("exec", address(multisig));
        s.file("exec", address(deployer));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 42, address(s)));
        //multisig.add(0x5859731D7b7e413A958eA1cDb9020C611b016395, 0, abi.encodeWithSignature("setExec(address,bool)", address(s), true));
        */

        /*
        //PartnerProxy p = new PartnerProxy();
        StrategyGMXGM s = new StrategyGMXGM(
          address(strategyHelper),
          0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8, // ExchangeRouter
          0xf60becbba223EEA9495Da3f606753867eC10d139, // Reader
          0x9Dc4f12Eb2d8405b499FB5B8AF79a5f64aB8a457, // DepoHandler
          0x9E32088F3c1a5EB38D32d1Ec6ba0bCBF499DC9ac, // WithHandler
          0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8, // DataStore
          0x70d95587d40A2caf56bd97485aB3Eec10Bee6336 // ETH Market
        );
        //p.setExec(address(s), true);
        //p.setExec(address(multisig), true);
        //p.setExec(address(deployer), false);
        s.file("slippage", 100);
        s.file("keeper", keeper);
        s.file("exec", iasp);
        s.file("exec", address(investor));
        s.file("exec", address(multisig));
        s.file("exec", address(deployer));
        console.log("strategy index", investor.nextStrategy());
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", investor.nextStrategy(), address(s)));
        */

        /*
        LiquidityMiningPluginOrdo o = new LiquidityMiningPluginOrdo(0xF507733f260a42bB2c8108dE87B7B0Ce5826A9cD, 0xbB12Db28715B45199DC83E1dF756fDf27954244B, 0xaB7d6293CE715F12879B9fa7CBaBbFCE3BAc0A5a, 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
        o.file("exec", address(multisig));
        o.file("exec", 0x3aEe6cA602C060883201B89c64cb5F782F964879);
        //*/
        //new LiquidityMiningPluginOrdoHelper(0xF507733f260a42bB2c8108dE87B7B0Ce5826A9cD);


        /*
        //LiquidityMining lm = new LiquidityMining();
        LiquidityMining lm = LiquidityMining(0x3aEe6cA602C060883201B89c64cb5F782F964879);
        lm.file("rewardPerDay", 7_500e18);
        lm.file("strategyHelper", strategyHelper);
        lm.file("lpToken", 0x5180Dce8F532f40d84363737858E2C5Fd0C8aB39);
        lm.file("rewardToken", 0x033f193b3Fceb22a440e89A2867E8FEE181594D9);
        lm.poolAdd(10000, 0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE);
        lm.file("exec", address(multisig));
        lm.file("exec", deployer);
        LiquidityMining(0xDb08658e207C68FaB77af69d76388f06C5Bb5351).file("liquidityMining", address(lm));
        //*/


        //StrategyJonesUsdc c = new StrategyJonesUsdc(strategyHelper, 0x5859731D7b7e413A958eA1cDb9020C611b016395, 0x42EfE3E686808ccA051A49BCDE34C5CbA2EBEfc1);
        //StrategyJonesUsdc c = StrategyJonesUsdc(0xDC34bE34Af0459c336b68b58b7B0aD2CB755b42c);
        //c.file("exec", address(multisig));
        //c.file("exec", address(investor));
        //c.file("exec", address(iasp));
        //c.file("exec", deployer);
        //multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 20, address(c)));

        /*
        // SALARIES
        address xrdo = 0x45a58482c3B8Ce0e8435E407fC7d34266f0A010D;
        address frank = 0xef93C8cb3318D782c70bD674e3D21636064F8ddE;
        address farmerc = 0xd6185a66F17Fce9016216931785eC5baf8F1D1e9;
        address jimbo = 0x055B29979f6BC27669Ebd54182588FeF12ffBFc0;
        address yieldl = 0x097F2358142F0C5fE544d8015E003ceD3C20f024;
        uint256 rdop = 0.05e18;
        multisig.add(rdo, 0, abi.encodeWithSignature("approve(address,uint256)", xrdo, 7500e18*1e18/rdop));
        multisig.add(usdc, 0, abi.encodeWithSignature("transfer(address,uint256)", frank, 4000e6));
        multisig.add(xrdo, 0, abi.encodeWithSignature("mint(uint256,address)", 2000e18*1e18/rdop, frank));
        multisig.add(usdc, 0, abi.encodeWithSignature("transfer(address,uint256)", farmerc, 6000e6));
        multisig.add(xrdo, 0, abi.encodeWithSignature("mint(uint256,address)", 2000e18*1e18/rdop, farmerc));
        multisig.add(usdc, 0, abi.encodeWithSignature("transfer(address,uint256)", jimbo, 3000e6));
        multisig.add(xrdo, 0, abi.encodeWithSignature("mint(uint256,address)", 2000e18*1e18/rdop, jimbo));
        multisig.add(usdc, 0, abi.encodeWithSignature("transfer(address,uint256)", 0x84eA891dEE0D8D2832da3D840f1F119b52D81254, 42200));
        multisig.add(usdc, 0, abi.encodeWithSignature("transfer(address,uint256)", yieldl, 2000e6));
        multisig.add(xrdo, 0, abi.encodeWithSignature("mint(uint256,address)", 1500e18*1e18/rdop, yieldl));
        //*/

        //// UNPAUSE
        //address spell = address(new OneOffUnpause());
        //multisig.add(poolUsdc, 0, abi.encodeWithSignature("file(bytes32,address)", bytes32("exec"), spell));
        //multisig.add(spell, 0, abi.encodeWithSignature("run()"));
        //multisig.add(poolUsdc, 0, abi.encodeWithSignature("file(bytes32,uint256)", bytes32("paused"), 0));
        //multisig.add(address(investor), 0, abi.encodeWithSignature("file(bytes32,uint256)", bytes32("status"), 4));

        //OracleUniswapV2Unsafe o0 = new OracleUniswapV2Unsafe(weth, 0x5180Dce8F532f40d84363737858E2C5Fd0C8aB39);
        //OracleEthToUsd o1 = new OracleEthToUsd(ethOracle, address(o0));
        //OracleOffchain o = new OracleOffchain();
        //o.file("exec", address(multisig));
        //o.file("exec", address(keeper));
        //o.file("exec", address(deployer));
        //multisig.add(strategyHelper, 0, abi.encodeWithSignature("setOracle(address,address)", pls, o));

        //// ORACLES
        //address chainlinkArbitrumSequencer = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
        //OracleChainlink o = new OracleChainlink(chainlinkArbitrumSequencer, 0xF3272CAfe65b190e76caAF483db13424a3e23dD2, 86460);
        //OracleChainlinkETH o2 = new OracleChainlinkETH(ethOracle, address(o));
        //multisig.add(strategyHelper, 0, abi.encodeWithSignature("setOracle(address,address)", reth, o));

        //address spell = address(new OneOffUnpause());
        //multisig.add(poolUsdc, 0, abi.encodeWithSignature("file(bytes32,address)", bytes32("exec"), spell));
        //multisig.add(usdc, 0, abi.encodeWithSignature("approve(address,uint256)", spell, 500_000e6));
        //multisig.add(spell, 0, abi.encodeWithSignature("run()"));

        //// Pause strategy
        //multisig.add(0x1C64dFF353A52Ba09fb4ae0CfF07e6d97D8868D4, 0, abi.encodeWithSignature("file(bytes32,uint256)", bytes32("status"), 2));
        //// Blacklist strategy
        //multisig.add(0x167643771f2599fBCE4c2B2654d17Cd311C7E223, 0, abi.encodeWithSignature("setStrategy(uint256,bool,uint256,uint256,uint256,uint256,uint256,uint256)", 20, true, 0, 0, 0, 0, 0, 0));

        // VESTING
        //Vester v = Vester(0xbb5032d20b689d9eE69A7C490Bd02Fc9efC734c2);
        //IERC20(rdo).approve(address(v), 10_000e18);
        //v.vest(5, 0xbc2609bBEe01731AE8867AbB60E5e31799B8e84f , rdo, 10_000e18, 0.1e18, 0, 329 days);

        /*
        StrategyJonesUsdc s = new StrategyJonesUsdc(address(strategyHelper), 0x5859731D7b7e413A958eA1cDb9020C611b016395, 0x42EfE3E686808ccA051A49BCDE34C5CbA2EBEfc1);
        //s.file("slippage", 250);
        s.file("keeper", keeper);
        s.file("exec", address(iasp));
        s.file("exec", address(investor));
        s.file("exec", address(multisig));
        s.file("exec", address(deployer));
        multisig.add(0x5859731D7b7e413A958eA1cDb9020C611b016395, 0, abi.encodeWithSignature("setExec(address,bool)", address(s), true));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 20, address(s)));
        */

        //multisig.add(poolUsdc, 0, abi.encodeWithSignature("file(bytes32,uint256)", bytes32("amountCap"), 2_100_000e6));

        /*
        StrategyHold c = new StrategyHold(strategyHelper, usdc);
        c.file("slippage", 500);
        c.file("exec", address(multisig));
        c.file("exec", address(investor));
        c.file("exec", address(investorActor));
        c.file("exec", deployer);
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 39, address(c)));
        */

        /*
        multisig.add(0x627571923E4638Ed2da9861e504951cF89aB5bb3, 0, abi.encodeWithSignature("file(bytes32,address)", bytes32("keeper"), address(investor)));
        StrategyHold(0xa22632d7C3C56EDB07dBD15eb9774a36a2D455bB).file("exec", address(investor));
        StrategyHold(0x1d58d6dC12869758759ACf2Eb5Fb082145E950F3).file("exec", address(investor));
        Configurator(0x169309c133cd21A1e6B0Bb396b97F0aa76FAc3FD).fileAddressExec(0xDbD2eBad83F831341d7daA6547adeDf81C36e0c3, "exec", address(investor));
        Configurator(0x169309c133cd21A1e6B0Bb396b97F0aa76FAc3FD).fileAddressExec(0x7F163e77BCcB6762fAa2F7d1C4B5bE885bCa8cEC, "exec", address(investor));
        Configurator(0x169309c133cd21A1e6B0Bb396b97F0aa76FAc3FD).fileAddressExec(0x30816F63cca09EB572EdE2E09d8f6b87720Ca2f1, "exec", address(investor));
        Configurator(0x169309c133cd21A1e6B0Bb396b97F0aa76FAc3FD).fileAddressExec(0x34Db1Ee7695f1d44534e4a0a4DEB060685EefEd7, "exec", address(investor));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 0, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 1, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 2, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 3, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 6, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 7, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 8, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 9, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 10, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 11, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 13, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 14, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 15, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 16, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 17, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 18, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 24, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 29, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 38, 0x7dD41e74f44175fBf148a9E7fc18dF69EdF9cda6));
        //*/

        /*
        // NEW STRATEGY
        //PartnerProxy p = new PartnerProxy();
        StrategyDead s = new StrategyDead(
            address(strategyHelper)
        );
        //p.setExec(address(s), true);
        //p.setExec(address(multisig), true);
        //p.setExec(address(deployer), false);
        //s.file("slippage", 250);
        //s.file("keeper", keeper);
        s.file("exec", investorActor);
        s.file("exec", address(investor));
        //s.file("exec", address(multisig));
        //s.file("exec", address(deployer));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", /*investor.nextStrategy()* /18, address(s)));
        //*/

        //multisig.add(address(strategyHelper), 0, abi.encodeWithSignature("setOracle(address,address)", magic, 0xb7AD108628B8876f68349d4F150f33e97f5DAE03));
        //bytes memory b = abi.encodePacked(magic, weth, usdc);
        //multisig.add(address(strategyHelper), 0, abi.encodeWithSignature("setPath(address,address,address,bytes)", magic, usdc, shss, b));

        // PRIVATE INVESTORS
        //PrivateInvestors c = new PrivateInvestors(usdc, 1687186800);
        //c.file("depositStart", 1686668400);
        //c.file("depositCap", 1312500e6);
        //c.file("defaultPartnerCap", 50000e6);
        //c.file("rbcNft", rbcNft);
        //PrivateInvestors(0xDF06ffa8bd87aa7138277DFB001D33Eae49F0463).file("depositEnd", 1687086000);
        //PrivateInvestors(0xDF06ffa8bd87aa7138277DFB001D33Eae49F0463).file("defaultCap", 5000e6);
        //c.file("rbcStart", 1686841200);
        //PrivateInvestors(0xDF06ffa8bd87aa7138277DFB001D33Eae49F0463).file("price", 0.0625e18);
        //c.file("percent", 0.2e18);
        //c.file("initial", 0.25e18);
        //c.file("vesting", 365 days);
        //c.file("exec", address(multisig));
        //address[] memory addresses = new address[](1);
        //uint256 i = 0;
        //addresses[i++] = 0x71c2cF4877c991f5B7047636C8ebc04408a8312d;
        //PrivateInvestors(0xDF06ffa8bd87aa7138277DFB001D33Eae49F0463).setWhitelist(addresses, 5000e6);
        //PrivateInvestors(0xDF06ffa8bd87aa7138277DFB001D33Eae49F0463).setUser(0x013040BCc92Ca0bec2670d61f06DA7c36678222A, 10000e6);

        /*
        // PROTOCOL UPGRADE
        address guard = 0x167643771f2599fBCE4c2B2654d17Cd311C7E223;
        address iasp = 0x023be37efd018Ce6B2707eA7452012642B6A5000;
        InvestorActor ia = new InvestorActor(address(investor), address(iasp));
        ia.file("guard", guard);
        ia.file("exec", address(multisig));
        ia.file("exec", address(deployer));
        multisig.add(guard, 0, abi.encodeWithSignature("file(bytes32,address)", bytes32("exec"), address(ia)));
        multisig.add(iasp, 0, abi.encodeWithSignature("file(bytes32,address)", bytes32("exec"), address(ia)));
        multisig.add(poolUsdc, 0, abi.encodeWithSignature("file(bytes32,address)", bytes32("exec"), address(ia)));
        multisig.add(address(investor), 0, abi.encodeWithSignature("file(bytes32,address)", bytes32("actor"), address(ia)));
        */

        //// POOL RATE MODEL
        //address m = address(new PoolRateModel(0.9e18, 317097919, 1585489599, 126839167935));
        //multisig.add(poolUsdc, 0, abi.encodeWithSignature("file(bytes32,address)", bytes32("rateModel"), m));

        //// LIQUIDITY MINING
        //LiquidityMining lm = new LiquidityMining();
        //lm.file("rewardPerDay", 10_000e18);
        //lm.file("lpToken", 0x5180Dce8F532f40d84363737858E2C5Fd0C8aB39);
        //lm.file("rewardToken", 0x033f193b3Fceb22a440e89A2867E8FEE181594D9);
        //lm.poolAdd(10000, 0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE);
        //lm.file("exec", address(multisig));
        //lm.file("exec", deployer);
        //LiquidityMining(0xDb08658e207C68FaB77af69d76388f06C5Bb5351).file("liquidityMining", 0xDb08658e207C68FaB77af69d76388f06C5Bb5351);

        //multisig.add(0x88C907770735B1fc9d9cCB1A8F73dC17e75C0699, 0, abi.encodeWithSignature("file(bytes32,address)", bytes32("exec"), investorActor));

        //OracleTWAP o = new OracleTWAP(0x51A82477154d8ae7c97784F141ab2B56088c435d);
        //o.file("exec", address(multisig));
        //o.file("exec", keeper);
        //o.file("exec", deployer);

        /*
        OracleCurveStable2 o = new OracleCurveStable2(strategyHelper, 0x59bF0545FCa0E5Ad48E13DA269faCD2E8C886Ba4, 0);
        OracleTWAP o2 = new OracleTWAP(address(o));
        o2.file("exec", address(multisig));
        o2.file("exec", keeper);
        o2.file("exec", deployer);
        multisig.add(address(strategyHelper), 0, abi.encodeWithSignature("setOracle(address,address)", 0x64343594Ab9b56e99087BfA6F2335Db24c2d1F17, address(o2)));
        */

        /*
        StrategyJonesUsdc s = new StrategyJonesUsdc(
          address(strategyHelper),
          0x5859731D7b7e413A958eA1cDb9020C611b016395,
          0x42EfE3E686808ccA051A49BCDE34C5CbA2EBEfc1
        );
        //s.file("slippage", 100);
        s.file("exec", investorActor);
        s.file("exec", address(investor));
        s.file("exec", address(multisig));
        s.file("exec", address(deployer));
        multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", 20, address(s)));
        //multisig.add(address(investor), 0, abi.encodeWithSignature("setStrategy(uint256,address)", investor.nextStrategy(), address(s)));
        //*/

        /*
        address pls = 0x51318B7D00db7ACc4026C88c3952B66278B6A67F;
        address pool = 0xbFD465E270F8D6bA62b5000cD27D155FB5aE70f0;
        address chainlinkEthUsd = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        OracleUniswapV3 o = new OracleUniswapV3(pool, weth, chainlinkEthUsd);
        multisig.add(address(strategyHelper), 0, abi.encodeWithSignature("setOracle(address,address)", pls, address(o)));
        multisig.add(address(strategyHelper), 0, abi.encodeWithSignature("setPath(address,address,address,bytes)", pls, weth, shv3, abi.encodePacked(pls, uint24(3000), weth)));
        */

        /*
        // JOE PATH
        uint256[] memory pairBinSteps = new uint256[](1);
        JoeVersion[] memory versions = new JoeVersion[](1);
        address[] memory tokenPath = new address[](2);
        pairBinSteps[0] = 20;
        //pairBinSteps[1] = 15;
        versions[0] = JoeVersion.V2_1;
        //versions[1] = JoeVersion.V2_1;
        tokenPath[0] = weth;
        tokenPath[1] = joe;
        //tokenPath[2] = usdc;
        bytes memory b = abi.encode(JoePath(pairBinSteps, versions, tokenPath));
        multisig.add(address(strategyHelper), 0, abi.encodeWithSignature("setPath(address,address,address,bytes)", weth, joe, shJoe, b));
        //*/

        //StrategyUniswapV3 s = new StrategyUniswapV3(
        //    strategyHelper,
        //    0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443,
        //    1654
        //);
        //s.file("exec", investorActor);
        //s.file("exec", address(investor));
        //s.file("exec", address(configurator));
        //s.file("exec", deployer);
        //uint256 sid = investor.nextStrategy();
        //configurator.setStrategy(address(investor), sid, address(s));

        //StrategyCurveV2 s = new StrategyCurveV2(
        //    strategyHelper,
        //    0x960ea3e3C7FB317332d990873d354E18d7645590,
        //    0x97E2768e8E73511cA874545DC5Ff8067eB19B787,
        //    2
        //);

        //StrategyBalancer s = new StrategyBalancer(
        //    strategyHelper,
        //    0xBA12222222228d8Ba445958a75a0704d566BF2C8,
        //    0xb08E16cFc07C684dAA2f93C70323BAdb2A6CBFd2,
        //    0x64541216bAFFFEec8ea535BB71Fbc927831d0595,
        //    0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8
        //);

        //StrategyBalancerStable s = new StrategyBalancerStable(
        //    strategyHelper,
        //    0xBA12222222228d8Ba445958a75a0704d566BF2C8,
        //    0xb08E16cFc07C684dAA2f93C70323BAdb2A6CBFd2,
        //    0xFB5e6d0c1DfeD2BA000fBC040Ab8DF3615AC329c,
        //    0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
        //);

        //StrategyGMXGLP s = new StrategyGMXGLP(
        //  address(sh),
        //  0xB95DB5B167D75e6d04227CfFFA61069348d271F5,
        //  0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1,
        //  0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf,
        //  weth
        //);

        // SETSTRATEGY Sushiswap
        //StrategySushiswap s = new StrategySushiswap(
        //    address(sh),
        //    0xF4d73326C13a4Fc5FD7A064217e12780e9Bd62c3,
        //    4
        //);
        //address s = 0xeEb9702F972890fE06F3f6f2A1f7f38C2679E7Aa;
        //IFileable(address(s)).file("exec", investorActor);
        //IFileable(address(s)).file("exec", investor);
        //IFileable(address(s)).file("exec", address(configurator));
        //IFileable(address(s)).file("exec", deployer);
        //configurator.setStrategy(address(investor), 16, address(s));
        //emit log_named_uint("nextStrategy", investor.nextStrategy());
        //investor.setStrategy(investor.nextStrategy(), address(s));
        //IFileable(0xeEb9702F972890fE06F3f6f2A1f7f38C2679E7Aa).file("slippage", 200);

        // SETORACLE UniswapV3
        //address chainlinkEthUsd = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        //OracleUniswapV3 o = new OracleUniswapV3(pool, weth, chainlinkEthUsd);
        //sh.setOracle(usdt, address(o));
        //sh.setPath(weth, gmx, shv3, abi.encodePacked(weth, uint24(3000), gmx));

        // SETPATH Curce
        //{
        //address[] memory pathPools = new address[](3);
        //uint256[] memory pathCoinIn = new uint256[](3);
        //uint256[] memory pathCoinOut = new uint256[](3);
        //pathPools[0] = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
        //pathCoinIn[0] = 0;
        //pathCoinOut[0] = 1;
        //pathPools[1] = 0x960ea3e3C7FB317332d990873d354E18d7645590;
        //pathCoinIn[1] = 0;
        //pathCoinOut[1] = 2;
        //pathPools[2] = 0x6eB2dc694eB516B16Dc9FBc678C60052BbdD7d80;
        //pathCoinIn[2] = 0;
        //pathCoinOut[2] = 1;
        //bytes memory path = abi.encode(pathPools, pathCoinIn, pathCoinOut);
        //configurator.setPath(strategyHelper, 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, 0x5979D7b546E38E414F7E9822514be443A4800529, address(shc), path);
        //}

        // SETPATH CURVE STETH-{USDC/ETH}
        //bytes memory path = hex"000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000030000000000000000000000007f90122bf0700f9e7e1f688fe926940e8839f353000000000000000000000000960ea3e3c7fb317332d990873d354e18d76455900000000000000000000000006eb2dc694eb516b16dc9fbc678c60052bbdd7d8000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001";
        //uint256 id = multisig.add(strategyHelper, 0, abi.encodeWithSignature("setPath(address,address,address,bytes)", 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, 0x5979D7b546E38E414F7E9822514be443A4800529, shc, path));
        //multisig.execute(id);
        //path = hex"000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000030000000000000000000000006eb2dc694eb516b16dc9fbc678c60052bbdd7d80000000000000000000000000960ea3e3c7fb317332d990873d354e18d76455900000000000000000000000007f90122bf0700f9e7e1f688fe926940e8839f35300000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        //id = multisig.add(strategyHelper, 0, abi.encodeWithSignature("setPath(address,address,address,bytes)", 0x5979D7b546E38E414F7E9822514be443A4800529, 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8, shc, path));
        //multisig.execute(id);
        //path = hex"000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000010000000000000000000000006eb2dc694eb516b16dc9fbc678c60052bbdd7d800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000";
        //id = multisig.add(strategyHelper, 0, abi.encodeWithSignature("setPath(address,address,address,bytes)", 0x5979D7b546E38E414F7E9822514be443A4800529, weth, shc, path));
        //multisig.execute(id);
        //path = hex"000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000000010000000000000000000000006eb2dc694eb516b16dc9fbc678c60052bbdd7d800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001";
        //id = multisig.add(strategyHelper, 0, abi.encodeWithSignature("setPath(address,address,address,bytes)", weth, 0x5979D7b546E38E414F7E9822514be443A4800529, shc, path));
        //multisig.execute(id);

        //// UPDATE INVESTOR ACTOR
        //address[18] memory strategies = [
        //  0x70116D50c89FC060203d1fA50374CF1B816Bd0f5,
        //  0x6d98F80D9Cfb549264B4B7deD12426eb6Ea47800,
        //  0x390358DEf53f2316671ed3B13D4F4731618Ff6A3,
        //  0x9FA6CaCcE3f868E56Bdab9be85b0a90e2568104d,
        //  0x05CBD8C4F171247aa8F4dE87b3d9e09883beD511,
        //  0xFE280C65c328524132205cDd360781484D981e42,
        //  0xd170cFfd7501bEc329B0c90427f06C9156845Be4,
        //  0xcF03B33851F088d58E921d8aB5D60Dc1c3238758,
        //  0x7174aD2d9C836B845ba5611dc5b90740707060eA,
        //  0xeF22614C3BDeA15b42434eb5F481D722D7e904dB,
        //  0xCE0488a9FfD70156d8914C02D95fA320DbBE93Ab,
        //  0xbA8A58Fd6fbc9fAcB8BCf349C94B87717a4BC00f,
        //  0x82bE2F89460581F20A4964Fd91c3376d9952a9FF,
        //  0x8D8627f0bb5A73035678289E5692766EDce341eA,
        //  0xc45a107f742B7dA6E9e48c5cc29ead668AF295F7,
        //  0x91308b8d5e2352C7953D88A55D1012D68bF1EfD0,
        //  0x32403558E7E386b79bB68bb942523e8c0A018B63,
        //  0xeB40EA021841d3d6191B76A0056863f52a71b2C5
        //];
        //for (uint256 i = 0; i < strategies.length; i++) {
        //    if (!StrategyPlutusPlvGlp(strategies[i]).exec(investorActor)) {
        //        console.log("___", strategies[i]);
        //        multisig.add(strategies[i], 0, abi.encodeWithSignature("file(bytes32,address)", bytes32("exec"), investorActor));
        //    } else {
        //        console.log("NOT", strategies[i]);
        //    }
        //}

        vm.stopBroadcast();
    }
}

/*
//PROTOCOL DEPLOY
address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
address usdcOracle = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
uint256 year = 365*24*60*60;
PoolRateModel poolRateModel = new PoolRateModel(85e16, 1e16/year, 3e16/year, 120e16/year);
Pool usdcPool = new Pool(address(usdc), address(poolRateModel), address(usdcOracle), 10e6, 90e16, 95e16, 100000e6);
Investor investor = new Investor();
InvestorActor investorActor = new InvestorActor(address(investor));
usdcPool.file("exec", address(investor));
usdcPool.file("exec", address(investorActor));
investor.file("pools", address(usdcPool));
investor.file("actor", address(investorActor));
InvestorHelper ih = new InvestorHelper(address(investor));
PositionManager pm = new PositionManager(address(investor));
*/

/*
// DEPLOY BALANCER FARM
address vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
address gaugeFactory = 0xb08E16cFc07C684dAA2f93C70323BAdb2A6CBFd2;
address pool = 0xFB5e6d0c1DfeD2BA000fBC040Ab8DF3615AC329c;
address shb = 0xb1Ae664e23332eE54e0C029937e26058a08708cC;
address o = 0x198c2CC46a17E023Fa7c76909E4a6858FbC87B71;
//StrategyHelperBalancer shb = new StrategyHelperBalancer(vault);
//OracleBalancerLPStable o = new OracleBalancerLPStable(
//    address(sh),
//    vault,
//    pool
//);
//sh.setOracle(pool, address(o));
//sh.setOracle(0x5979D7b546E38E414F7E9822514be443A4800529, 0x07C5b924399cc23c24a95c8743DE4006a32b7f2a);
//sh.setPath(weth, pool, address(shb), abi.encode(pool, IBalancerPool(pool).getPoolId()));
//sh.setPath(pool, weth, address(shb), abi.encode(weth, IBalancerPool(pool).getPoolId()));
//sh.setPath(0x040d1EdC9569d4Bab2D15287Dc5A4F10F56a56B8, weth, shb, abi.encode(weth, IBalancerPool(0xcC65A812ce382aB909a11E434dbf75B34f1cc59D).getPoolId())); // bal
//sh.setPath(0x13Ad51ed4F1B7e9Dc168d8a00cB3f4dDD85EfA60, weth, shb, abi.encode(weth, IBalancerPool(pool).getPoolId())); // ldo
//StrategyBalancerStable s = new StrategyBalancerStable(
//    address(sh),
//    vault,
//    gaugeFactory,
//    pool,
//    weth
//);
//address s = 0xa1d0c80981f35b5Da52D9deA546b93C9943614D6;
//uint256 sid = investor.nextStrategy();
//investor.setStrategy(sid, address(s));
//IFileable(0xa1d0c80981f35b5Da52D9deA546b93C9943614D6).file("exec", investorActor);

// WEIGHTED
//address vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
//address gaugeFactory = 0xb08E16cFc07C684dAA2f93C70323BAdb2A6CBFd2;
//address pool = 0x64541216bAFFFEec8ea535BB71Fbc927831d0595;
//StrategyBalancer s = new StrategyBalancer(
//    address(sh),
//    vault,
//    gaugeFactory,
//    pool,
//    usdc
//);
//address s = 0x8ffC6FfEC753F58fE0a30059028340DDA5e2d889;
//IFileable(s).file("exec", address(investorActor));
//emit log_named_uint("nextStrategy", investor.nextStrategy());
//investor.setStrategy(investor.nextStrategy(), address(s));*/
