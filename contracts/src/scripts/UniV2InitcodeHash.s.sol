// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DSTest} from "../test/utils/DSTest.sol";
import {UniswapV2Pair} from "../test/vendor/sushiswap/uniswapv2/UniswapV2Pair.sol";
import {UniswapV3Pool} from "../test/vendor/uniswapv3/UniswapV3Pool.sol";

contract UniV2InitcodeHash is DSTest {
    function run() external {
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 hash = keccak256(abi.encodePacked(bytecode));
        emit log_named_bytes32("v2 initcode hash", hash);

        bytecode = type(UniswapV3Pool).creationCode;
        hash = keccak256(abi.encodePacked(bytecode));
        emit log_named_bytes32("v3 initcode hash", hash);
    }
}
