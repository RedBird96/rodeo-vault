// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOracle {
    function lastUpdate() external view returns (uint256);
}

contract OracleIsOutdatedHelper {
    function checker(address oracle, uint256 ttl) external view returns (bool) {
        uint256 last = IOracle(oracle).lastUpdate();
        return (block.timestamp > last + ttl);
    }
}
