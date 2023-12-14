// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {DSTest} from "./utils/DSTest.sol";
import {OracleTWAP} from "../oracles/OracleTWAP.sol";

contract OracleTWAPTest is DSTest {
    OracleTWAP o;
    int256 price = 50e18;

    function setUp() public {
        vm.warp(2 hours);
        o = new OracleTWAP(address(this));
    }

    function testLatestAnswer() public {
        assertEq(o.latestAnswer(), 50e18);
        price = 60e18;
        assertEq(o.latestAnswer(), 50e18);
        vm.warp(block.timestamp + o.updateInterval() + 1);
        o.update();
        assertEq(o.latestAnswer(), 52.5e18);
        vm.warp(block.timestamp + o.updateInterval() + 1);
        o.update();
        vm.warp(block.timestamp + o.updateInterval() + 1);
        o.update();
        assertEq(o.latestAnswer(), 57.5e18);
        assertEq(o.prices(0), 50e18);
        assertEq(o.prices(1), 60e18);
        assertEq(o.prices(2), 60e18);
        assertEq(o.prices(3), 60e18);
        vm.warp(block.timestamp + (3 * o.updateInterval()));
        vm.expectRevert("stale price");
        o.latestAnswer();
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function latestAnswer() public view returns (int256) {
        return price;
    }
}
