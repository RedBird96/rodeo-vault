// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Strategy} from "../Strategy.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract StrategyTest is Strategy {
    string public constant name = "APY";
    uint256 public last;
    uint256 public index = 1e6;

    constructor(address _strategyHelper) Strategy(_strategyHelper) {
        last = block.timestamp;
    }

    function _rate(uint256 sha) internal view override returns (uint256) {
        uint256 _index = nextIndex();
        return sha * _index / 1e6;
    }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        _earn();
        pull(IERC20(ast), msg.sender, amt);
        return strategyHelper.value(ast, amt) * 1e6 / index;
    }

    function _burn(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        _earn();
        uint256 d = 10 ** IERC20(ast).decimals();
        uint256 bal = ((amt * index / 1e6) * 1e18 / strategyHelper.price(ast)) * d / 1e18;
        push(IERC20(ast), msg.sender, bal);
        return bal;
    }

    function _earn() internal override {
        uint256 _index = nextIndex();
        last = block.timestamp;
        index = _index;
    }

    function nextIndex() internal view returns (uint256) {
        uint256 diff = block.timestamp - last;
        return index + 24 * diff;
    }
}
