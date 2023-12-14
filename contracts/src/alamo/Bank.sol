// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
}

contract Bank {
    mapping(address => bool) public exec;

    event File(bytes32 indexed what, address data);

    error InvalidFile();
    error Unauthorized();
    error TransferFailed();

    constructor() {
        exec[msg.sender] = true;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") {
            exec[data] = !exec[data];
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function transferNative(address to, uint256 amount) external auth {
        if (amount == 0) return;
        (bool s,) = to.call{value: amount}("");
        if (!s) revert TransferFailed();
    }

    function transfer(address token, address to, uint256 amount) external auth {
        if (amount == 0) return;
        if (!IERC20(token).transfer(to, amount)) revert TransferFailed();
    }
}
