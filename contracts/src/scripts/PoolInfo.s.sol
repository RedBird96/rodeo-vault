// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {DSTest} from "../test/utils/DSTest.sol";
import {console} from "../test/utils/console.sol";
import {TickLib} from "../vendor/TickLib.sol";
import {TickMath} from "../vendor/TickMath.sol";
import {LiquidityAmounts} from "../vendor/LiquidityAmounts.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IUniswapV3Pool} from "../interfaces/IUniswapV3Pool.sol";

contract PoolInfo is DSTest {
    function run() external {
        address pool = 0xC31E54c7a869B9FcBEcc14363CF510d1c41fa443;
        info(pool, 10e4);
        info(pool, 20e4);
        info(pool, 40e4);

        /*
        uint128 slot0Liquidity = p.liquidity();
        {
            int24 roundedTick = (tick / tickSpacing) * tickSpacing;
            uint256 slot0Amount0 = LiquidityAmounts.getAmount0ForLiquidity(
                TickMath.getSqrtRatioAtTick(roundedTick),
                TickMath.getSqrtRatioAtTick(roundedTick + tickSpacing),
                slot0Liquidity
            );
            uint256 slot0Amount1 = LiquidityAmounts.getAmount1ForLiquidity(
                TickMath.getSqrtRatioAtTick(roundedTick),
                TickMath.getSqrtRatioAtTick(roundedTick + tickSpacing),
                slot0Liquidity
            );
            emit log_named_uint("slot0Amount0", uint256(slot0Amount0) / (10 ** (token0Decimals - 2)));
            emit log_named_uint("slot0Amount1", uint256(slot0Amount1) / (10 ** (token1Decimals - 2)));
        }

        {
            uint256 fees = 15000; // 24h usd fees in $
            address usdc = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
            //address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
            uint256 liquidity;
            if (p.token0() == usdc) {
                liquidity = LiquidityAmounts.getLiquidityForAmount0(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tick),
                    100000 * (10 ** token0Decimals)
                );
            } else {
                liquidity = LiquidityAmounts.getLiquidityForAmount1(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tick),
                    100000 * (10 ** token1Decimals)
                );
            }
            uint256 feeOwnership = (liquidity * 1e8) / 2 / slot0Liquidity;
            console.log("feeOwnership % ", fn(feeOwnership * 100, 8, 4));
            console.log("apr % ", fn((fees * feeOwnership) * 365 * 100 / 100000, 8, 4));
            console.log("24h fees $ ", fn(fees * feeOwnership, 8, 2));
            console.log("30d fees $ ", fn(fees * feeOwnership * 30, 8, 2));
            console.log("1y fees $ ", fn(fees * feeOwnership * 365, 8, 2));
        }
        */
    }

    function info(address pool, uint24 rangeSize) internal {
        IUniswapV3Pool p = IUniswapV3Pool(pool);
        uint8 token0Decimals;
        uint8 token1Decimals;
        {
            IERC20 token0 = IERC20(p.token0());
            IERC20 token1 = IERC20(p.token1());
            token0Decimals = token0.decimals();
            token1Decimals = token1.decimals();
            //console.log("pool", pool);
            //console.log("token0", address(token0));
            //console.log("token1", address(token1));
        }

        int24 tickSpacing = p.tickSpacing();
        (uint160 price, int24 tick,,,,,) = p.slot0();
        //emit log_named_int("tickSpacing", int256(tickSpacing));
        //emit log_named_int("tick", int256(tick));
        //console.log("price", uint256(price));

        uint160 priceLower = uint160(mulDiv(uint256(price), sqrt(1000000 - rangeSize), 1000));
        uint160 priceUpper = uint160(mulDiv(uint256(price), sqrt(1000000 + rangeSize), 1000));
        int24 tickLower = TickLib.nearestUsableTick(TickMath.getTickAtSqrtRatio(priceLower), tickSpacing);
        int24 tickUpper = TickLib.nearestUsableTick(TickMath.getTickAtSqrtRatio(priceUpper), tickSpacing);
        emit log_named_int("tickLower", int256(tickLower));
        emit log_named_int("tickUpper", int256(tickUpper));
        emit log_named_uint("sqrtLower", uint256(TickMath.getSqrtRatioAtTick(tickLower)));
        emit log_named_uint("sqrtUpper", uint256(TickMath.getSqrtRatioAtTick(tickUpper)));
        uint256 priceLower0 = uint256(TickMath.getSqrtRatioAtTick(tickLower)) ** 2 * 1e18 / 2 ** 192;
        uint256 priceUpper0 = uint256(TickMath.getSqrtRatioAtTick(tickUpper)) ** 2 * 1e18 / 2 ** 192;
        //priceLower0 = 1e18 * 1e18 / priceLower0;
        //priceUpper0 = 1e18 * 1e18 / priceUpper0;
        emit log_named_uint(string(abi.encodePacked("token0 price ", fn(priceLower0, 6, 4))), priceLower0);
        emit log_named_uint(string(abi.encodePacked("token0 price ", fn(priceUpper0, 6, 4))), priceUpper0);
        emit log_named_uint(
            string(abi.encodePacked("tickScale ", fn(rangeSize, 4, 2))),
            (abs(int256(tick)) - min(abs(int256(tickLower)), abs(int256(tickUpper)))) * 1e5 / abs(int256(tick))
        );
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function abs(int256 n) internal pure returns (uint256) {
        if (n < 0) {
            return uint256(0 - n);
        }
        return uint256(n < 0 ? 0 - n : n);
    }

    function fn(uint256 n, uint256 d, uint256 f) internal pure returns (string memory) {
        uint256 x = 10 ** d;
        uint256 r = n / (10 ** (d - f)) % (10 ** f);
        return string(abi.encodePacked(toString(n / x), ".", toString(r)));
    }

    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    function sqrtX96PriceToPrice(uint160 price) internal pure returns (uint256) {
        return mulDiv(uint256(price) ** 2, 1e18, 1 << 192);
    }

    function priceToSqrtX96Price(uint256 price) internal pure returns (uint160) {
        return uint160(mulDiv(sqrt(price), 1 << 192, 1e18));
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }
}
