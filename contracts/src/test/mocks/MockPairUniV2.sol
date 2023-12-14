// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {MockERC20} from "./MockERC20.sol";

contract MockPairUniV2 is MockERC20 {
    MockERC20 public token0;
    MockERC20 public token1;
    uint256 public reserve0;
    uint256 public reserve1;

    constructor(MockERC20 _token0, MockERC20 _token1) MockERC20(18) {
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (
            uint112(token0.balanceOf(address(this))),
            uint112(token1.balanceOf(address(this))),
            0
        );
    }

    function mint(address to) external returns (uint256) {
        uint256 amt0 = token0.balanceOf(address(this)) - reserve0;
        uint256 liq =
            amt0 * totalSupply / max(token0.balanceOf(address(this)), 1);
        mint(to, liq);
        reserve0 = token0.balanceOf(address(this));
        return liq;
    }

    function burn(address to) external returns (uint256, uint256) {
        uint256 liq = balanceOf[address(this)];
        uint256 amt0 = liq * token0.balanceOf(address(this)) / totalSupply;
        uint256 amt1 = liq * token1.balanceOf(address(this)) / totalSupply;
        burn(address(this), liq);
        token0.transfer(to, amt0);
        token1.transfer(to, amt1);
        return (amt0, amt1);
    }

    function swap(uint256, uint256, address, bytes calldata) external {}

    function skim(address to) external {}

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
