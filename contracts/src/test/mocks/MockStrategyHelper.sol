// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../../interfaces/IERC20.sol";
import {Util} from "../../Util.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockStrategyHelper is Util {
    error UnknownOracle();

    mapping(address => uint256) public prices;

    function setPrice(address ast, uint256 amt) public {
        prices[ast] = amt;
    }

    function price(address ast) public view returns (uint256) {
        if (prices[ast] == 0) revert UnknownOracle();
        return prices[ast];
    }

    function value(address ast, uint256 amt) public view returns (uint256) {
        return amt * price(ast) / (10 ** IERC20(ast).decimals());
    }

    function convert(address ast0, address ast1, uint256 amt) public view returns (uint256) {
        return value(ast0, amt) * (10 ** IERC20(ast1).decimals()) / price(ast1);
    }

    function swap(address ast0, address ast1, uint256 amt, uint256, address to) external returns (uint256) {
        pull(IERC20(ast0), msg.sender, amt);
        uint256 out = convert(ast0, ast1, amt);
        MockERC20(ast1).mint(to, out);
        return out;
    }
}
