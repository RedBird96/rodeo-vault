// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../interfaces/IERC20.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IRateModel} from "../interfaces/IRateModel.sol";
import {IInvestor} from "../interfaces/IInvestor.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

contract Helper {
    function pool(address pool) public view returns (bool paused, uint256 borrowMin, uint256 amountCap, uint256 index, uint256 shares, uint256 borrow, uint256 supply, uint256 rate, uint256 price) {
        IPool p = IPool(pool);
        paused = p.paused();
        borrowMin = p.borrowMin();
        amountCap = p.amountCap();
        index = p.getUpdatedIndex();
        shares = p.totalSupply();
        borrow = p.totalBorrow() * index / 1e18;
        supply = borrow + IERC20(p.asset()).balanceOf(pool);
        {
            IRateModel rm = IRateModel(p.rateModel());
            rate = supply == 0 ? 0 : rm.rate(borrow * 1e18 / supply);
        }
        {
            IOracle oracle = IOracle(p.oracle());
            price = uint256(oracle.latestAnswer()) * 1e18 / (10 ** oracle.decimals());
        }
    }

    function rateModel(address pool) public view returns (uint256, uint256, uint256, uint256) {
        IPool p = IPool(pool);
        IRateModel rm = IRateModel(p.rateModel());
        return (rm.kink(), rm.base(), rm.low(), rm.high());
    }

    function strategies(address investor, uint256[] calldata indexes) public view returns (address[] memory addresses, uint256[] memory statuses, uint256[] memory slippages, uint256[] memory caps, uint256[] memory tvls) {
        IInvestor i = IInvestor(investor);
        uint256 l = indexes.length;
        addresses = new address[](l);
        statuses = new uint256[](l);
        slippages = new uint256[](l);
        caps = new uint256[](l);
        tvls = new uint256[](l);
        for (uint256 j = 0; j < l; j++) {
            IStrategy s = IStrategy(i.strategies(indexes[j]));
            addresses[j] = address(s);
            statuses[j] = s.status();
            slippages[j] = s.slippage();
            caps[j] = s.cap();
            tvls[j] = s.rate(s.totalShares());
        }
    }
}
