// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTest} from "./utils/DSTest.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IBalancerVault} from "../interfaces/IBalancerVault.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockStrategyHelper} from "./mocks/MockStrategyHelper.sol";
import {MockBalancerVaultPool} from "./mocks/MockBalancerVaultPool.sol";
import {Util} from "../Util.sol";
import {OracleBalancerLPStable} from "../oracles/OracleBalancerLPStable.sol";

contract OracleBalancerLPStableTest is DSTest {
    MockERC20 usdc;
    MockERC20 weth;
    MockStrategyHelper sh;
    MockBalancerVaultPool vaultPool;
    OracleBalancerLPStable o;

    function setUp() public {
        usdc = new MockERC20(6);
        weth = new MockERC20(18);
        sh = new MockStrategyHelper();
        sh.setPrice(address(usdc), 0.97e18);
        sh.setPrice(address(weth), 1500e18);
        vaultPool = new MockBalancerVaultPool(usdc, weth);
        o = new OracleBalancerLPStable(
            address(sh),
            address(vaultPool),
            address(vaultPool)
        );
    }

    function testLatestAnswer() public {
        assertEq(o.latestAnswer() / 1e16, 153);
        sh.setPrice(address(vaultPool), 0.01e18);
        sh.setPrice(address(usdc), 1.01e18);
        assertEq(o.latestAnswer() / 1e16, 159);
    }
}
