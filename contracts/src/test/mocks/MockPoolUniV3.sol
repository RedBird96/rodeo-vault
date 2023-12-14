// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {MockERC20} from "./MockERC20.sol";
import {TickMath} from "../../vendor/TickMath.sol";
import {TickLib} from "../../vendor/TickLib.sol";
import {LiquidityAmounts} from "../../vendor/LiquidityAmounts.sol";

interface IUniswapV3MintCallback {
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

contract MockPoolUniV3 {
    MockERC20 public token0;
    MockERC20 public token1;
    uint256 public tokenExchangeRate;
    uint256 public collectToken0 = 0;
    uint256 public collectToken1 = 0;
    uint256 public feeGrowthGlobal0X128;
    uint256 public feeGrowthGlobal1X128;
    int24 public tickSpacing = 60;
    int24 public fee = 3000;
    int24 public minTick;
    int24 public maxTick;
    uint160 public minSqrtRatio;
    uint160 public maxSqrtRatio;

    mapping(int24 => TickInfo) public ticks;

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;
    }

    struct Info {
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    struct TickInfo {
        uint128 liquidityGross;
        int128 liquidityNet;
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        int56 tickCumulativeOutside;
        uint160 secondsPerLiquidityOutsideX128;
        uint32 secondsOutside;
        bool initialized;
    }

    Slot0 public slot0;
    mapping(bytes32 => Info) public positions;

    constructor(MockERC20 _token0, MockERC20 _token1, uint256 _tokenExchangeRate, uint160 _sqrtPriceX96, int24 _tick) {
        token0 = _token0;
        token1 = _token1;
        tokenExchangeRate = _tokenExchangeRate;

        slot0 = Slot0(_sqrtPriceX96, _tick, 0, 0, 0, 0, true);

        feeGrowthGlobal0X128 = 2000e30;
        feeGrowthGlobal1X128 = 1000000000000e30;

        minTick = TickLib.nearestUsableTick(TickMath.MIN_TICK, 60);
        maxTick = TickLib.nearestUsableTick(TickMath.MAX_TICK, 60);
        minSqrtRatio = TickMath.getSqrtRatioAtTick(minTick);
        maxSqrtRatio = TickMath.getSqrtRatioAtTick(maxTick);
    }

    function setPosition(
        bytes32 positionID,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    ) public {
        positions[positionID] = Info(liquidity, feeGrowthInside0LastX128, feeGrowthInside1LastX128, tokensOwed0, tokensOwed1);
    }

    function setFeeGrowthGlobal(uint256 newFeeGrowthGlobal0X128, uint256 newFeeGrowthGlobal1X128) public {
        feeGrowthGlobal0X128 = newFeeGrowthGlobal0X128;
        feeGrowthGlobal1X128 = newFeeGrowthGlobal1X128;
    }

    function setCollect(uint256 newCollectToken0, uint256 newCollectToken1) public {
        collectToken0 = newCollectToken0;
        collectToken1 = newCollectToken1;
    }

    function setSlot0Values(uint160 _sqrtPriceX96, int24 _tick) public {
        slot0 = Slot0(_sqrtPriceX96, _tick, 0, 0, 0, 0, true);
    }

    function observe(uint32[] calldata secondsAgos) public view returns (int56[] memory, uint160[] memory) {
        uint160[] memory x = new uint160[](0);
        int56[] memory tickCumulatives = new int56[](2);
        tickCumulatives[1] = slot0.tick * int32(secondsAgos[0]);
        return (tickCumulatives, x);
    }

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1) {
        positions[keccak256(abi.encodePacked(msg.sender, tickLower, tickUpper))].liquidity += amount;

        minSqrtRatio = TickMath.getSqrtRatioAtTick(tickLower);
        maxSqrtRatio = TickMath.getSqrtRatioAtTick(tickUpper);

        (amount0, amount1) =
            LiquidityAmounts.getAmountsForLiquidity(slot0.sqrtPriceX96, minSqrtRatio, maxSqrtRatio, amount);

        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);

        return (0, 0);
    }

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1) {
        positions[keccak256(abi.encodePacked(msg.sender, tickLower, tickUpper))].liquidity -= amount;

        minSqrtRatio = TickMath.getSqrtRatioAtTick(tickLower);
        maxSqrtRatio = TickMath.getSqrtRatioAtTick(tickUpper);

        (amount0, amount1) =
            LiquidityAmounts.getAmountsForLiquidity(slot0.sqrtPriceX96, minSqrtRatio, maxSqrtRatio, amount);

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);

        return (0, 0);
    }

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1) {
        if (zeroForOne) {
            uint256 amountOut = uint256(amountSpecified) * 1e20 / tokenExchangeRate;
            amount0 = 0;
            amount1 = -int256(amountOut);
            token1.transfer(recipient, amountOut);
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amountSpecified, 0, data);
        } else {
            uint256 amountOut = uint256(amountSpecified) * tokenExchangeRate / 1e20;
            amount0 = -int256(amountOut);
            amount1 = 0;
            token0.transfer(recipient, amountOut);
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(0, amountSpecified, data);
        }
    }

    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1) {
        if (collectToken0 > 0) {
            token0.transfer(msg.sender, collectToken0);
        }

        if (collectToken1 > 0) {
            token1.transfer(msg.sender, collectToken1);
        }

        return (0, 0);
    }
}
