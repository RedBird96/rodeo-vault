// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {MockERC20} from "./MockERC20.sol";

contract MockRouterUniV2 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
    {
        MockERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        MockERC20(path[path.length-1]).mint(to, amountOutMin+1);
    }
}
