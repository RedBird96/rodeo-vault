// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {MockERC20} from './MockERC20.sol';
import {MockPairUniV2} from './MockPairUniV2.sol';

contract MockVault is MockERC20 {
    MockPairUniV2 public asset;
    uint256 public totalManagedAssets;

    constructor(MockPairUniV2 _asset) MockERC20(18) {
        asset = _asset;
    }

    function mint(uint256 amt, address usr) external returns (uint256) {
        asset.transferFrom(msg.sender, address(this), amt);
        uint256 tma = totalManagedAssets;
        uint256 sha = tma == 0 ? amt : amt * totalSupply / tma;
        mint(usr, sha);
        totalManagedAssets += amt;
        return sha;
    }

    function burn(uint256 sha, address usr) external returns (uint256) {
        uint256 amt = sha * totalManagedAssets / totalSupply;
        burn(msg.sender, sha);
        asset.transfer(usr, amt);
        totalManagedAssets -= amt;
        return amt;
    }

    function earn() external {
        asset.mint(address(this), 5e18);
        totalManagedAssets += 5e18;
    }
}
