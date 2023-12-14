// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../../interfaces/IERC20.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockRewarderMiniChefV2 {
    MockERC20 public rewardToken;
    address public pair;

    constructor(address _pair) {
        rewardToken = new MockERC20(18);
        rewardToken.mint(address(this), 1000e18);
        pair = _pair;
    }

    function SUSHI() external view returns (address) {
        return address(rewardToken);
    }

    function lpToken(uint256) external view returns (address) {
        return pair;
    }

    function pendingSushi(uint256, address) external pure returns (uint256) {
        return 3e18;
    }

    function userInfo(uint256, address)
        external
        pure
        returns (uint256, int256)
    {
        return (10e18, 1);
    }

    function deposit(uint256, uint256 amount, address) public {
        IERC20(pair).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256, uint256, address to) public {
        IERC20(pair).transfer(to, 10e18);
    }

    function harvest(uint256, address to) public {
        rewardToken.mint(to, 3e18);
    }
}
