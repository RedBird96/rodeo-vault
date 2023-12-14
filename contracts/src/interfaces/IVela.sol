// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
    function stake(address account, address token, uint256 amount) external;
    function unstake(address tokenOut, uint256 vlpAmount) external;
    function getVLPPrice() external view returns (uint256);
}

// Only for tests
interface IOperators {
    function getOperatorLevel(address op) external view returns (uint256);
}

// Only for tests
interface ISettingsManager {
    function setEnableUnstaking(address token, bool isEnabled) external;
    function isWhitelistedFromCooldown(address user) external view returns (bool);
    function isWhitelistedFromTransferCooldown(address user) external view returns (bool);
}
