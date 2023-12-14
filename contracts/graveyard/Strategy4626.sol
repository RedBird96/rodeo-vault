// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../interfaces/IERC20.sol";
import {Strategy} from "../Strategy.sol";
import {IVault4626} from "../interfaces/IVault4626.sol";

contract Strategy4626 is Strategy {
    string public name;
    IVault4626 public vault;
    IERC20 public asset;

    constructor(address _strategyHelper, address _vault, address _asset, string memory _name)
        Strategy(_strategyHelper)
    {
        vault = IVault4626(_vault);
        asset = IERC20(_asset);
        name = _name;
    }

    function _rate(uint256 sha) internal view override returns (uint256) {
        return strategyHelper.value(address(asset), vault.previewRedeem(sha));
    }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        pull(IERC20(ast), msg.sender, amt);
        uint256 slp = getSlippage(dat);
        IERC20(ast).approve(address(strategyHelper), amt);
        uint256 bal = strategyHelper.swap(ast, address(asset), amt, slp, address(this));
        IERC20(asset).approve(address(vault), bal);
        return vault.deposit(bal, address(this));
    }

    function _burn(address ast, uint256 sha, bytes calldata dat) internal override returns (uint256) {
        uint256 slp = getSlippage(dat);
        uint256 amt = vault.redeem(sha, address(this), address(this));
        asset.approve(address(strategyHelper), amt);
        return strategyHelper.swap(address(asset), ast, amt, slp, msg.sender);
    }

    function _exit(address str) internal override {
        push(IERC20(address(vault)), str, vault.balanceOf(address(this)));
    }
}
