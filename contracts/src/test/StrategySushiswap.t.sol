// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTest} from "./utils/DSTest.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockOracle} from "./mocks/MockOracle.sol";
import {MockPairUniV2} from "./mocks/MockPairUniV2.sol";
import {MockRewarderMiniChefV2} from "./mocks/MockRewarderMiniChefV2.sol";
import {MockRouterUniV2} from "./mocks/MockRouterUniV2.sol";
import {StrategyHelper, StrategyHelperUniswapV2} from "../StrategyHelper.sol";
import {StrategySushiswap} from "../strategies/StrategySushiswap.sol";

contract StrategySushiswapTest is DSTest {
    MockERC20 aUsdc;
    MockERC20 aWeth;
    MockOracle oUsdc;
    MockOracle oWeth;
    MockOracle oSushi;
    MockPairUniV2 pair;
    MockRewarderMiniChefV2 rewarder;
    MockRouterUniV2 router;
    StrategyHelper sh;
    StrategyHelperUniswapV2 shss;
    StrategySushiswap strategy;

    function setUp() public {
        aUsdc = new MockERC20(6);
        aWeth = new MockERC20(18);
        oUsdc = new MockOracle(1e8);
        oWeth = new MockOracle(1650e8);
        oSushi = new MockOracle(7e8);
        aUsdc.mint(address(this), 1000e6);
        pair = new MockPairUniV2(aUsdc, aWeth);
        rewarder = new MockRewarderMiniChefV2(address(pair));
        router = new MockRouterUniV2();
        sh = new StrategyHelper();
        shss = new StrategyHelperUniswapV2(address(router));
        sh.setOracle(address(aUsdc), address(oUsdc));
        sh.setOracle(address(aWeth), address(oWeth));
        sh.setOracle(rewarder.SUSHI(), address(oSushi));
        sh.setPath(address(aUsdc), address(aWeth), address(shss), abi.encodePacked(address(aUsdc), address(aWeth)));
        sh.setPath(address(aWeth), address(aUsdc), address(shss), abi.encodePacked(address(aWeth), address(aUsdc)));
        sh.setPath(
            address(rewarder.SUSHI()),
            address(aUsdc),
            address(shss),
            abi.encodePacked(address(rewarder.SUSHI()), address(aWeth), address(aUsdc))
        );
        sh.setPath(
            address(rewarder.SUSHI()),
            address(aWeth),
            address(shss),
            abi.encodePacked(address(rewarder.SUSHI()), address(aWeth))
        );
        strategy = new StrategySushiswap(
            address(sh),
            address(rewarder),
            0
        );
    }

    function testAll() public {
        aUsdc.approve(address(strategy), 5e6);
        strategy.mint(address(aUsdc), 5e6, "");
        assertEq(uint256(2), 2);
    }
}
