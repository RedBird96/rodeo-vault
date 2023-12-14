// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../../interfaces/IERC20.sol";
import {IBalancerVault} from "../../interfaces/IBalancerVault.sol";
import {Util} from "../../Util.sol";
import {MockERC20} from "./MockERC20.sol";

contract MockBalancerVaultPool is MockERC20, Util {
    MockERC20 usdc;
    MockERC20 weth;

    constructor(MockERC20 _usdc, MockERC20 _weth) MockERC20(18) {
        usdc = _usdc;
        weth = _weth;
        usdc.mint(address(this), 15000e6);
        weth.mint(address(this), 10e18);
        mint(address(0), 24600e18);
    }

    function getPoolTokens(bytes32) public view returns (address[] memory, uint256[] memory, uint256) {
        address[] memory tokens = new address[](2);
        tokens[0] = address(usdc);
        tokens[1] = address(weth);
        uint256[] memory balances = new uint256[](2);
        balances[0] = 15000e6;
        balances[1] = 10e18;
        return (tokens, balances, 0); 
    }

    function joinPool(
        bytes32,
        address,
        address recipient,
        IBalancerVault.JoinPoolRequest memory request
    ) public payable {
        (, uint256[] memory amts,) = abi.decode(request.userData, (uint256, uint256[], uint256));
        pull(IERC20(address(usdc)), msg.sender, amts[0]);
        mint(recipient, amts[0]*1e12);
    }

    function exitPool(
        bytes32,
        address,
        address payable recipient,
        IBalancerVault.ExitPoolRequest memory request
    ) public {
        (, uint256 amt,) = abi.decode(request.userData, (uint256, uint256, uint256));
        burn(msg.sender, amt);
        push(IERC20(address(usdc)), recipient, amt/1e12);
    }

    function getRate() public view returns (uint256) {
      return 1.58e18;
    }

    function getPoolId() public view returns (bytes32) {
        return hex"64541216bafffeec8ea535bb71fbc927831d0595000100000000000000000002";
    }

    function getNormalizedWeights() public view returns (uint256[] memory) {
        uint256[] memory weights = new uint256[](2);
        weights[0] = 0.8e18;
        weights[1] = 0.2e18;
        return weights;
    }

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    struct UserBalanceOp {
        UserBalanceOpKind kind;
        address asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    function manageUserBalance(UserBalanceOp[] memory ops) external {
    }
}
