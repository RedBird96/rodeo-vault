// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../../interfaces/IERC20.sol";
import {Util} from "../../Util.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockCurveGauge is MockERC20, Util {
    MockERC20 public pool;
    MockERC20 public reward;

    constructor(MockERC20 _pool, MockERC20 _reward) MockERC20(18) {
        pool = _pool;
        reward = _reward;
    }

    function getPoolGauge(address) public view returns (address) {
        return address(this);
    }

    function reward_tokens(uint256 i) public view returns (address) {
        if (i == 0) return address(reward);
        return address(0);
    }

    function deposit(uint256 amt) public {
        pull(IERC20(address(pool)), msg.sender, amt);
        mint(msg.sender, amt);
    }

    function withdraw(uint256 amt) public override {
        burn(msg.sender, amt);
        push(IERC20(address(pool)), msg.sender, amt);
    }

    function claim_rewards() public {
        reward.mint(msg.sender, 3e18);
    }
}
