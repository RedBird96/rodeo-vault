// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Util} from "../Util.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPositionManager} from "../interfaces/IPositionManager.sol";
import {IStrategyHelper} from "../interfaces/IStrategyHelper.sol";
import {ERC721TokenReceiver} from "../ERC721TokenReceiver.sol";

contract ZapInOutHelper is Util, ERC721TokenReceiver {
    mapping(address => bool) public whitelist;
    IPositionManager public positionManager;
    IStrategyHelper public strategyHelper;
    uint16 public slippage;
    uint16 public fee;

    struct ZapIn {
        address token;
        uint256 amount;
        address swapApprovalTarget;
        address swapVenue;
        bytes swapData;
        address pool;
        uint256 strategy;
        uint256 borrow;
        bytes data;
    }

    struct ZapOut {
        uint256 position;
        int256 amount;
        int256 borrow;
        bytes data;
        address token;
        address pool;
    }

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event FeeWithdrawn(address indexed token, uint256 fee);
    event ExecutedIn(
        address indexed user, address indexed pool, uint256 indexed strategy, address token, uint256 amount
    );
    event ExecutedOut(
        address indexed user, address indexed pool, uint256 indexed position, address token, uint256 amount
    );

    error SlippageTooHigh(uint16 current, uint16 maximum);
    error FeeTooHigh(uint16 current, uint16 maximum);
    error NotWhitelistedToken(address token);
    error CallFailed(bytes result);

    constructor(address _positionManager, address _strategyHelper, uint16 _slippage, uint16 _fee) {
        positionManager = IPositionManager(_positionManager);
        strategyHelper = IStrategyHelper(_strategyHelper);

        onlyValidSlippage(_slippage);
        onlyValidFee(_fee);

        slippage = _slippage;
        fee = _fee;
        exec[msg.sender] = true;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "fee") {
            onlyValidFee(uint16(data));

            fee = uint16(data);
        } else if (what == "slippage") {
            onlyValidSlippage(uint16(data));

            slippage = uint16(data);
        }

        emit File(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "whitelist") whitelist[data] = !whitelist[data];
        else if (what == "exec") exec[data] = !exec[data];

        emit File(what, data);
    }

    function withdrawFees(address token, address recipient) external auth {
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance > 0) {
            IERC20(token).transfer(recipient, balance);

            emit FeeWithdrawn(token, balance);
        }
    }

    function executeIn(ZapIn calldata params) external loop {
        onlyWhitelistedToken(params.token);

        IERC20 asset = IERC20(IPool(params.pool).asset());
        uint256 prevAstBal = asset.balanceOf(address(this));

        pull(IERC20(params.token), msg.sender, params.amount);
        IERC20(params.token).approve(params.swapApprovalTarget, params.amount);

        (bool success, bytes memory result) = params.swapVenue.call(params.swapData);

        if (!success) revert CallFailed(result);

        uint256 amt = asset.balanceOf(address(this)) - prevAstBal;
        uint256 inAmt = amt - (amt * fee / 10000);

        asset.approve(address(positionManager), inAmt);
        positionManager.mint(msg.sender, params.pool, params.strategy, inAmt, params.borrow, params.data);

        emit ExecutedIn(msg.sender, params.pool, params.strategy, params.token, inAmt);
    }

    function executeOut(ZapOut calldata params) external loop {
        onlyWhitelistedToken(params.token);

        IERC20 asset = IERC20(IPool(params.pool).asset());
        uint256 prevAstBal = asset.balanceOf(address(this));

        positionManager.safeTransferFrom(msg.sender, address(this), params.position);
        positionManager.edit(params.position, params.amount, params.borrow, params.data);
        positionManager.burn(params.position);

        uint256 amt = asset.balanceOf(address(this)) - prevAstBal;
        uint256 outAmt = amt - (amt * fee / 10000);

        asset.approve(address(strategyHelper), outAmt);

        uint256 tokOutAmt =
            strategyHelper.swap(address(asset), params.token, outAmt, getSlippage(params.data), msg.sender);

        emit ExecutedOut(msg.sender, params.pool, params.position, params.token, tokOutAmt);
    }

    function getSlippage(bytes memory data) private view returns (uint256) {
        if (data.length > 0) {
            uint256 slp = abi.decode(data, (uint256));

            onlyValidSlippage(uint16(slp));

            return slp;
        }

        return slippage;
    }

    function onlyWhitelistedToken(address tokenToCheck) private view {
        if (!whitelist[tokenToCheck]) revert NotWhitelistedToken(tokenToCheck);
    }

    function onlyValidFee(uint16 feeToCheck) private pure {
        uint16 maxFee = 10000;

        if (feeToCheck > maxFee) revert FeeTooHigh(feeToCheck, maxFee);
    }

    function onlyValidSlippage(uint16 slippageToCheck) private pure {
        uint16 maxSlippage = 500;

        if (slippageToCheck > maxSlippage) revert SlippageTooHigh(slippageToCheck, maxSlippage);
    }
}
