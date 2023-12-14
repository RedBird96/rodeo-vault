pragma solidity 0.8.17;

function calcSqrtPriceX96(uint160 amount0, uint160 amount1) pure returns(uint160) {
    return (sqrt(amount1) << 96) / sqrt(amount0);
}

function sqrt(uint160 x) pure returns (uint160 y) {
    uint160 z = (x + 1) / 2;
    y = x;
    while (z < y) {
        y = z;
        z = (x / z + z) / 2;
    }
}
