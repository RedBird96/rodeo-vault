// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "../utils/Test.sol";
import {Store} from "../../alamo/Store.sol";

contract AStoreTest is Test {
    Store private s;

    function setUp() public override {
        s = new Store();
    }

    function testBytes32Set() public {
        bytes32 key = "key";
        bytes32 a = "a";
        bytes32 b = "b";
        bytes32 c = "c";

        assertTrue(!s.containsBytes32(key, a));
        s.addBytes32(key, a);
        assertTrue(s.containsBytes32(key, a));
        assertEq(s.getBytes32Count(key), 1);

        s.addBytes32(key, c);
        assertTrue(s.containsBytes32(key, c));
        assertTrue(s.containsBytes32(key, a));
        assertEq(s.getBytes32Count(key), 2);

        s.addBytes32(key, a);
        s.addBytes32(key, a);
        assertEq(s.getBytes32Count(key), 2);

        s.addBytes32(key, b);
        assertTrue(s.containsBytes32(key, b));
        assertEq(s.getBytes32Count(key), 3);
        bytes32[] memory list = s.getBytes32ValuesAt(key, 0, 3);
        assertEq(list[0], a);
        assertEq(list[1], c);
        assertEq(list[2], b);

        s.removeBytes32(key, a);
        assertEq(s.getBytes32Count(key), 2);
        assertTrue(!s.containsBytes32(key, a));
        s.removeBytes32(key, b);
        assertEq(s.getBytes32Count(key), 1);
        assertTrue(s.containsBytes32(key, c));
        assertTrue(!s.containsBytes32(key, a));
        assertTrue(!s.containsBytes32(key, b));
        list = s.getBytes32ValuesAt(key, 0, 1);
        assertEq(list[0], c);

        s.removeBytes32(key, c);
        assertEq(s.getBytes32Count(key), 0);
    }
}
