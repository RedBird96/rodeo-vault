// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVault {
    function asset() external view returns (address);
    function totalManagedAssets() external view returns (uint256);
    function mint(uint256, address) external returns (uint256);
    function burn(uint256, address) external returns (uint256);
}
