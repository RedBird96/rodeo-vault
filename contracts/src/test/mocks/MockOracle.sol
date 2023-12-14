// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MockOracle {
    int256 public latestAnswer;
    uint8 public decimals = 8;

    constructor(int256 _latestAnswer) {
        latestAnswer = _latestAnswer;
    }

    function move(int256 next) public {
        latestAnswer = next;
    }
}
