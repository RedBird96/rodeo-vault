// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../interfaces/IERC20.sol";
import {IVault} from "../interfaces/IVela.sol";
import {Strategy} from "../Strategy.sol";
 
contract StrategyVela is Strategy {
    string public constant name = "Vela VLP";
    IVault public vault;
    IERC20 public usdc;
    IERC20 public vlp;

    error PriceSlipped();

    constructor(address _strategyHelper, address _vault, address _vlp, address _usdc) Strategy(_strategyHelper) {
        vault = IVault(_vault);
        usdc = IERC20(_usdc);
        vlp = IERC20(_vlp);
    }

    function _mint(address ast, uint256 amt, bytes calldata dat) internal override returns (uint256) {
        pull(IERC20(ast), msg.sender, amt);

        address usdcAddress = address(usdc);
        uint256 tma = totalManagedAssets();
        uint256 slp = getSlippage(dat);

        IERC20(ast).approve(address(strategyHelper), amt);

        uint256 bal = strategyHelper.swap(ast, usdcAddress, amt, slp, address(this));

        usdc.approve(address(vault), bal);
        vault.stake(address(this), usdcAddress, bal);

        uint256 vlpAmt = totalManagedAssets() - tma;

        if (valueLiquidity(vlpAmt) < strategyHelper.value(ast, amt) * (10000 - slp) / 10000) revert PriceSlipped();

        return tma == 0 ? vlpAmt : vlpAmt * totalShares / tma;
    }

    function _burn(address ast, uint256 sha, bytes calldata dat) internal override returns (uint256) {
        address usdcAddress = address(usdc);
        uint256 vlpAmt = sha * totalManagedAssets() / totalShares;
        uint256 rate = valueLiquidity(vlpAmt);

        vault.unstake(usdcAddress, vlpAmt);

        uint256 bal = usdc.balanceOf(address(this));

        usdc.approve(address(strategyHelper), bal);

        uint256 slp = getSlippage(dat);
        uint256 amt = strategyHelper.swap(usdcAddress, ast, bal, slp, msg.sender);

        if (rate < strategyHelper.value(ast, amt) * (10000 - slp) / 10000) revert PriceSlipped();

        return amt;
    }

    // Is empty because vault pays earned fees (yield) in time of unstaking.
    function _earn() internal override {}

    function _exit(address str) internal override {
        uint256 amt = totalManagedAssets();

        vlp.approve(address(this), amt);
        pullTo(vlp, address(this), str, amt);
    }

    // Is empty because Vela's LPs are not staked somewhere else.
    function _move(address old) internal override {}

    function _rate(uint256 sha) internal view override returns (uint256) {
        return sha * valueLiquidity(totalManagedAssets()) / totalShares;
    }

    function valueLiquidity(uint256 amt) private view returns (uint256) {
        return strategyHelper.value(address(usdc), amt * 1e6 / 1e18 * vault.getVLPPrice() / 1e5);
    }

    function totalManagedAssets() private view returns (uint256) {
        return vlp.balanceOf(address(this));
    }
}
