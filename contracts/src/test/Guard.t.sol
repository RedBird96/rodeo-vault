// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {Guard} from "../Guard.sol";

contract GuardTest is Test {
    Guard g;
    uint256 str;
    address pol;

    function setUp() public override {
        g = new Guard(address(this));
        str = 8;
        g.setStrategy(str, false, 0, 100, 0.01e18, 5e18, 8e18, 0.025e18);
        g.setStrategy(str+1, true, 0, 100, 0.01e18, 5e18, 8e18, 0.025e18);
        g.setStrategyBlacklist(str, vm.addr(8), true);
    }

    function testSetExec() public {
        g.file("exec", vm.addr(1));
        assertEq(g.exec(vm.addr(1)) ? 1 : 0, 1);
    }

    function testSetFeeRebate() public {
        g.file("feeRebateMax", 1);
        assertEq(g.feeRebateMax(), 1);
        g.file("feeRebateRate", 2);
        assertEq(g.feeRebateRate(), 2);
    }

    function testToken() public {
        g.file("token", vm.addr(1));
        assertEq(address(g.token()), vm.addr(1));
    }

    function testSetStrategy() public {
        g.setStrategy(123, true, 42, 1, 2, 3, 4, 5);
        (bool disabled, uint256 cooldown, uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) = g.strategies(123);
        assert(disabled);
        assertEq(cooldown, 42);
        assertEq(a, 1);
        assertEq(b, 2);
        assertEq(c, 3);
        assertEq(d, 4);
        assertEq(e, 5);
    }

    function testSetStrategyPoolBlacklist() public {
        g.setStrategyBlacklist(9, vm.addr(2), true);
        assertEq(g.getStrategyPoolBlacklist(9, vm.addr(2)) ? 1 : 0, 1);
        g.setStrategyBlacklist(9, vm.addr(2), false);
        assertEq(g.getStrategyPoolBlacklist(9, vm.addr(2)) ? 1 : 0, 0);
    }

    function testCheck() public {
        bool ok;
        uint256 need;
        uint256 rebate;

        // Fail on high lev
        (ok, need, rebate) = g.check(9, vm.addr(1), str, pol, 101e18, 100e18);
        assertTrue(!ok);
        assertEq(need, 1);

        // Fail on disabled
        (ok, need, rebate) = g.check(9, vm.addr(1), str+1, pol, 10e18, 0e18);
        assertTrue(!ok);
        assertEq(need, 2);

        // Fail on blacklisted pool
        (ok, need, rebate) = g.check(9, vm.addr(1), str, vm.addr(8), 1e18, 0);
        assertTrue(!ok);
        assertEq(need, 3);

        // Fail too low amount
        (ok, need, rebate) = g.check(9, vm.addr(1), str, pol, 15, 0);
        assertTrue(!ok);
        assertEq(need, 4);

        // Fail on access
        (ok, need, rebate) = g.check(9, vm.addr(1), str, pol, 10e18, 0e18);
        assertTrue(!ok);
        assertEq(need, 0.1e18);

        // Pass access
        (ok, need, rebate) = g.check(9, vm.addr(3), str, pol, 10e18, 0e18);
        assertTrue(ok);
        assertEq(need, 0);
        assertEq(rebate, 0.014e18);

        // Pass access, max rebate
        (ok, need, rebate) = g.check(9, vm.addr(4), str, pol, 10e18, 0e18);
        assertTrue(ok);
        assertEq(rebate, 0.5e18);

        // Pass on low leverage
        (ok, need, rebate) = g.check(9, vm.addr(3), str, pol, 10e18, 5e18);
        assertTrue(ok);
        assertEq(need, 0);

        // Fail on high leverage
        (ok, need, rebate) = g.check(9, vm.addr(3), str, pol, 10.1e18, 9e18);
        assertTrue(!ok);
        assertEq(need, 5);

        // Fail on leverage but no token
        (ok, need, rebate) = g.check(9, vm.addr(2), str, pol, 10e18, 8.5e18);
        assertTrue(!ok);
        assertEq(need, 138888888888888880);

        // Pass on high leverage w/ token
        (ok, need, rebate) = g.check(9, vm.addr(4), str, pol, 10e18, 8.5e18);
        assertTrue(ok);
        assertEq(need, 138888888888888880);
    }

    function balanceOf(address usr) public returns (uint256) {
        if (usr == vm.addr(4)) {
            return 10000e18;
        }
        if (usr == vm.addr(3)) {
            return 0.14e18;
        }
        if (usr == vm.addr(2)) {
            return 0.1e18;
        }
        return 0;
    }

    fallback() external {}
}
