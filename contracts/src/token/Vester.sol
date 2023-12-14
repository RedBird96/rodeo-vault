// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Util} from "../Util.sol";
import {IERC20} from "../interfaces/IERC20.sol";

interface IVesterPlugin {
    function onClaim(address from, uint256 index, address token, uint256 amount) external;
}

contract Vester is Util {
    error NothingToClaim();
    error SchedulePaused();
    error ScheduleNotSetup();
    error SourceNotExitable();

    struct Schedule {
        uint256 source;
        address token;
        uint256 initial;
        uint256 cliff;
        uint256 time;
        uint256 amount;
        uint256 start;
        uint256 claimed;
        bool paused;
    }
    // Source is used in frontend
    // 0 unknown
    // 1 xRDO redeem
    // 2 public sale
    // 3 private sale
    // 4 private RDO from xRDO exits

    address public exitTarget;
    uint256 public exitPenalty = 0.5e18;
    mapping(address => uint256) public schedulesCount;
    mapping(address => mapping(uint256 => Schedule)) public schedules;

    event Vest(
        address target, uint256 index, address token, uint256 amount, uint256 initial, uint256 cliff, uint256 time
    );
    event Claim(address target, uint256 index, uint256 amount);
    event Exit(address target, uint256 index, uint256 left, uint256 gets, uint256 owed);
    event File(bytes32 what, address data);
    event SetPaused(address target, uint256 index, bool paused);

    constructor() {
        exec[msg.sender] = true;
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        emit File(what, data);
    }

    function setExit(address _exitTarget, uint256 _exitPenalty) public auth {
        exitTarget = _exitTarget;
        exitPenalty = _exitPenalty;
    }

    function setPaused(address target, uint256 index, bool paused) public auth {
        Schedule storage s = schedules[target][index];
        s.paused = paused;
        emit SetPaused(target, index, paused);
    }

    function vest(
        uint256 source,
        address target,
        address token,
        uint256 amount,
        uint256 initial,
        uint256 cliff,
        uint256 time
    ) public {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 index = schedulesCount[target];
        schedulesCount[target] += 1;
        Schedule storage s = schedules[target][index];
        s.source = source;
        s.token = token;
        s.initial = initial;
        s.cliff = cliff;
        s.time = time;
        s.amount = amount;
        s.start = block.timestamp;
        emit Vest(target, index, token, amount, initial, cliff, time);
    }

    function claim(uint256 index, address target) external {
        Schedule storage s = schedules[msg.sender][index];
        if (s.paused) revert SchedulePaused();
        if (s.amount == 0) revert ScheduleNotSetup();
        uint256 available = getAvailable(msg.sender, index);
        if (available <= s.claimed) revert NothingToClaim();
        uint256 amount = available - s.claimed;
        s.claimed += amount;
        if (target != address(0)) {
            IERC20(s.token).transfer(target, amount);
            IVesterPlugin(target).onClaim(msg.sender, index, s.token, amount);
        } else {
            IERC20(s.token).transfer(msg.sender, amount);
        }
        emit Claim(msg.sender, index, amount);
    }

    function exit(uint256 index) external {
        Schedule storage s = schedules[msg.sender][index];
        if (s.paused) revert SchedulePaused();
        if (s.source < 100) revert SourceNotExitable();
        uint256 available = getAvailable(msg.sender, index);
        uint256 owed = available - s.claimed;
        uint256 left = s.amount - available;
        uint256 gets = left * (1e18 - exitPenalty) / 1e18;
        s.claimed = s.amount;
        IERC20(s.token).transfer(msg.sender, owed + gets);
        IERC20(s.token).transfer(exitTarget, left - gets);
        emit Exit(msg.sender, index, left, gets, owed);
    }

    function getAvailable(address target, uint256 index) public view returns (uint256) {
        Schedule memory s = schedules[target][index];
        uint256 initial = s.amount * s.initial / 1e18;
        int256 progress = (int256(block.timestamp) - int256(s.start + s.cliff)) * 1e18 / int256(s.time);
        if (progress < 0) progress = 0;
        if (progress > 1e18) progress = 1e18;
        uint256 rest = (s.amount - initial) * uint256(progress) / 1e18;
        return initial + rest;
    }

    function getSchedulesInfo(address target, uint256 first, uint256 last)
        external
        view
        returns (
            uint256[] memory source,
            address[] memory token,
            uint256[] memory initial,
            uint256[] memory time,
            uint256[] memory start
        )
    {
        source = new uint256[](last-first);
        token = new address[](last-first);
        initial = new uint256[](last-first);
        time = new uint256[](last-first);
        start = new uint256[](last-first);
        for (uint256 i = first; i < last; i++) {
            Schedule memory s = schedules[target][i];
            source[i] = s.source;
            token[i] = s.token;
            initial[i] = s.initial;
            time[i] = s.time;
            start[i] = s.start + s.cliff;
        }
        return (source, token, initial, time, start);
    }

    function getSchedules(address target, uint256 first, uint256 last)
        external
        view
        returns (uint256[] memory, uint256[] memory, uint256[] memory)
    {
        uint256[] memory amount = new uint256[](last-first);
        uint256[] memory claimed = new uint256[](last-first);
        uint256[] memory available = new uint256[](last-first);
        for (uint256 i = first; i < last; i++) {
            Schedule memory s = schedules[target][i];
            amount[i] = s.amount;
            claimed[i] = s.claimed;
            available[i] = getAvailable(target, i);
        }
        return (amount, claimed, available);
    }
}
