// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TickMath} from "../../vendor/TickMath.sol";
import {BytesLib} from "../../vendor/BytesLib.sol";
import {IUniswapV3Pool} from "../../interfaces/IUniswapV3Pool.sol";
import {IUniswapV3SwapCallback} from "../../interfaces/IUniswapV3SwapCallback.sol";
import {IERC20} from "../../interfaces/IERC20.sol";

contract MockRouterUniV3 {
    using BytesLib for bytes;

    uint256 private constant ADDR_SIZE = 20;
    uint256 private constant FEE_SIZE = 3;
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;

    IUniswapV3Pool public pool0;
    IUniswapV3Pool public pool1;
    address public asset;
    address public token0;
    address public token1;
    address public strategyCaller;
    address public tokenToSwap;

    constructor(address _pool0, address _pool1, address _asset, address _token0, address _token1) {
        pool0 = IUniswapV3Pool(_pool0);
        pool1 = IUniswapV3Pool(_pool1);
        asset = _asset;
        token0 = _token0;
        token1 = _token1;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams memory params) external payable returns (uint256 amountOut) {
        strategyCaller = msg.sender;
        (address tokenA, address tokenB) = decodePath(params.path);
        bool zeroForOne;
        uint160 sqrtPriceLimitX96;

        if (tokenA == asset) {
            zeroForOne = true;
            sqrtPriceLimitX96 = TickMath.MIN_SQRT_RATIO + 1;
        } else {
            zeroForOne = false;
            sqrtPriceLimitX96 = TickMath.MAX_SQRT_RATIO - 1;
        }

        if (tokenA == token0 || tokenB == token0) {
            tokenToSwap = token0;
            pool0.swap(params.recipient, zeroForOne, int256(params.amountIn), sqrtPriceLimitX96, "");
        } else {
            tokenToSwap = token1;
            pool1.swap(params.recipient, zeroForOne, int256(params.amountIn), sqrtPriceLimitX96, "");
        }

        return 0;
    }

    function decodePath(bytes memory path) internal pure returns (address tokenA, address tokenB) {
        bytes memory firstPool = path.slice(0, POP_OFFSET);

        tokenA = firstPool.toAddress(0);
        tokenB = firstPool.toAddress(NEXT_OFFSET);
    }

    function uniswapV3SwapCallback(int256 amount0, int256 amount1, bytes calldata _data) external {
        if (amount0 > 0) {
            IERC20(asset).transferFrom(strategyCaller, msg.sender, uint256(amount0));
        }
        if (amount1 > 0) {
            IERC20(tokenToSwap).transferFrom(strategyCaller, msg.sender, uint256(amount1));
        }
    }
}
