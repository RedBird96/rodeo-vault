// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../../interfaces/IERC20.sol";

contract MockStrategy {
    string public constant name = "Mock";
    uint256 _rate = 123e18;
    uint256 _mint = 123e18;
    uint256 _burn = 123e6;
    uint256 _totalShares = 123e18;

    function file(bytes32 what, uint256 data) external {
        if (what == "rate") _rate = data;
        if (what == "mint") _mint = data;
        if (what == "burn") _burn = data;
        if (what == "totalShares") _totalShares = data;
    }

    function totalShares() public view returns (uint256) {
      return _totalShares;
    }

    function rate(uint256) public view returns (uint256) {
        return _rate;
    }

    function mint(address ast, uint256 amt, bytes calldata) external returns (uint256) {
        IERC20(ast).transferFrom(msg.sender, address(this), amt);
        return _mint;
    }

    function burn(address ast, uint256, bytes calldata) external returns (uint256) {
        IERC20(ast).transfer(msg.sender, _burn);
        return _burn;
    }
}
