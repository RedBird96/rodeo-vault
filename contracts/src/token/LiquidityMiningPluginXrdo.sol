// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../interfaces/IERC20.sol";

interface ITokenStaking {
    function mint(uint256 amount, address to) external;
}

contract LiquidityMiningPluginXrdo {
    address public xrdo;

    constructor(address _xrdo) {
        xrdo = _xrdo;
    }

    function onHarvest(address to, address token, uint256 amount) external {
        IERC20(token).approve(xrdo, amount);
        ITokenStaking(xrdo).mint(amount, to);
    }
}
