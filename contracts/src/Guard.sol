// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "./interfaces/IERC20.sol";
import {Util} from "./Util.sol";

// Contract used by InvestorActor to determine if a user has enough Rodeo tokens to open/edit a position
// Allowing the protocol to gate access, high leverage, fee rebates with tokens
// (and blacklist lending pools per strategies)
contract Guard is Util {
    struct Config {
        bool disabled;
        uint256 cooldown;
        uint256 valueMin;
        uint256 accessRate;
        uint256 leverageMin;
        uint256 leverageMax;
        uint256 leverageRate;
        mapping(address => bool) poolBlacklist;
    }

    uint256 public feeRebateMax = 0.5e18; // 50% is the max rebate on fees
    uint256 public feeRebateRate = 0.5e18; // To get the max you need 50% of position value in tokens
    IERC20 public token; // Contract that implements balanceOf(usr), doesn't need to be a full token
    mapping(uint256 => Config) public strategies;
    mapping(uint256 => uint256) public positionsLastEdit;

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event SetStrategy(uint256 indexed str, bool disabled, uint256 vmin, uint256 arate, uint256 lmin, uint256 lmax, uint256 lrate);
    event SetStrategyBlacklist(uint256 indexed str, address tkn, bool on);

    constructor(address _token) {
        token = IERC20(_token);
        exec[msg.sender] = true;
    }

    function getStrategyPoolBlacklist(uint256 str, address tkn) public view returns (bool) {
        return strategies[str].poolBlacklist[tkn];
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "feeRebateMax") feeRebateMax = data;
        if (what == "feeRebateRate") feeRebateRate = data;
        emit File(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        if (what == "token") token = IERC20(data);
        emit File(what, data);
    }

    function setStrategy(uint256 str, bool disabled, uint256 cooldown, uint256 vmin, uint256 arate, uint256 lmin, uint256 lmax, uint256 lrate)
        external
        auth
    {
        Config storage config = strategies[str];
        config.disabled = disabled;
        config.cooldown = cooldown;
        config.valueMin = vmin;
        config.accessRate = arate;
        config.leverageMin = lmin;
        config.leverageMax = lmax;
        config.leverageRate = lrate;
        emit SetStrategy(str, disabled, vmin, arate, lmin, lmax, lrate);
    }

    function setStrategyBlacklist(uint256 str, address tkn, bool on) external auth {
        Config storage config = strategies[str];
        config.poolBlacklist[tkn] = on;
        emit SetStrategyBlacklist(str, tkn, on);
    }

    // Method for InvestorActor to use to check if a user position can be edited given their RODEO balance
    // A user's balance can affect 3 things: Access, Leverage, Performance fee rebate
    // Returns if check passed, tokens needed to pay for leverage, rebate percent
    function check(uint256 id, address usr, uint256 str, address pol, uint256 val, uint256 bor)
        public
        auth
        returns (bool, uint256, uint256)
    {
        uint256 lastEdit = positionsLastEdit[id];
        positionsLastEdit[id] = block.timestamp;

        // In case check ever gets called by a strategy rating a position as 0
        // (like when on liquidate only) return early to avoid divide by 0 errors
        if (val == 0) return (true, 0, 0);

        Config storage c = strategies[str];
        uint256 have = token.balanceOf(usr);
        uint256 need = val * c.accessRate / 1e18;
        uint256 leverage = type(uint256).max;
        if (bor < val) leverage = val * 1e18 / (val - bor);

        // costOfMaxRebateForPosition = positionValue * feeRebateRate
        // percentageOfMaxRebatePaid = tokensOwned / costOfMaxRebateForPosition
        // rebate = percentageOfMaxRebatePaid * feeRebateMax
        uint256 rebate = 0;
        if (feeRebateRate > 0) rebate = (have * 1e18 / (val * feeRebateRate / 1e18)) * feeRebateMax / 1e18;
        if (rebate > feeRebateMax) rebate = feeRebateMax;

        if (leverage > 11e18) {
            return (false, 1, rebate);
        }
        if (c.disabled) {
            return (false, 2, rebate);
        }
        if (c.poolBlacklist[pol]) {
            return (false, 3, rebate);
        }
        if (val < c.valueMin) {
            return (false, 4, rebate);
        }
        if (have < need) {
            return (false, need, rebate);
        }
        if (c.leverageRate == 0) {
            return (true, 0, rebate);
        }
        if (leverage < c.leverageMin) {
            return (true, 0, rebate);
        }
        if (leverage > c.leverageMax) {
            return (false, 5, rebate);
        }
        if (lastEdit != 0 && (block.timestamp - lastEdit) < c.cooldown) {
            return (false, 6, rebate);
        }
        uint256 percent = (leverage - c.leverageMin) * 1e18 / (c.leverageMax - c.leverageMin);
        need = val * (percent * c.leverageRate / 1e18) / 1e18;
        return (have >= need, need, rebate);
    }
}
