// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPrivateInvestors {
    function users(address) external view returns (uint256, bool);
    function totalDeposits() external view returns (uint256);
    function depositEnd() external view returns (uint256);
}
