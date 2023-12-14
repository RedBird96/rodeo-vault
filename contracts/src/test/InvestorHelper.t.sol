// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";

contract InvestorHelperTest is Test {
    function setUp() public override {
        super.setUp();
    }

    function testPeekPoolInfos() public {
        address[] memory ids = new address[](2);
        ids[0] = address(usdcPool);
        ids[1] = address(wethPool);
        (
            address[] memory asset,
            bool[] memory paused,
            uint256[] memory borrowMin,
            uint256[] memory liquidationFactor,
            uint256[] memory amountCap
        ) = ih.peekPoolInfos(ids);
        assertEq(asset[0], address(usdc));
        assertEq(asset[1], address(weth));
        assertEq(paused[0] ? 1 : 0, 0);
        assertEq(paused[1] ? 1 : 0, 0);
        assertEq(borrowMin[0], 100e6);
        assertEq(borrowMin[1], 1e17);
        assertEq(liquidationFactor[0], 95e16);
        assertEq(liquidationFactor[1], 90e16);
        assertEq(amountCap[0], 1000000e6);
        assertEq(amountCap[1], 1000e18);
    }

    function testPeekPools() public {
        address[] memory ids = new address[](2);
        ids[0] = address(usdcPool);
        ids[1] = address(wethPool);
        (
            uint256[] memory index,
            uint256[] memory share,
            uint256[] memory supply,
            uint256[] memory borrow,
            uint256[] memory rate,
            uint256[] memory price
        ) = ih.peekPools(ids);
        assertEq(index[0], 1000109588406783361);
        assertEq(index[1], 1000109588406783361);
        assertEq(share[0], 1000000000);
        assertEq(share[1], 0);
        assertEq(supply[0], 1000010958);
        assertEq(supply[1], 0);
        assertEq(borrow[0], 100010958);
        assertEq(borrow[1], 0);
        assertEq(rate[0], 634195839);
        assertEq(rate[1], 0);
        assertEq(price[0], 1000000000000000000);
        assertEq(price[1], 1650000000000000000000);
    }

    function testPeekPosition() public {
        (
            address pol,
            uint256 str,
            uint256 sha,
            uint256 bor,
            uint256 val,
            uint256 borval,
            uint256 lif,
            uint256 amt,
            uint256 price
        ) = ih.peekPosition(0);
        assertEq(pol, address(usdcPool));
        assertEq(str, 0);
        assertEq(sha, 123e18);
        assertEq(val, 123e18);
        assertEq(bor, 100000000);
        assertEq(borval, 100010958);
        assertEq(lif, 1168371959978375616);
        assertEq(amt, 23e6);
        assertEq(price, 1000000000000000000);
    }

    function testLifeBatched() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;

        // with a single position
        uint256[] memory lifeArr = ih.lifeBatched(ids);
        assertEq(lifeArr.length, 1);
        assertEq(lifeArr[0], 1168371959978375616);

        // enter another position
        usdcPool.file("borrowMin", 1e6);
        usdc.approve(address(investor), 3e6);
        investor.earn(address(this), address(usdcPool), 0, 1e6, 2e6, "");
        // enter position with 0 borrow
        investor.earn(address(this), address(usdcPool), 0, 1e6, 0, "");
        ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;

        // with multiple positions
        lifeArr = ih.lifeBatched(ids);
        assertEq(lifeArr.length, 3);
        assertEq(lifeArr[0], 1168371959978375616);
        assertEq(lifeArr[1], 58425024751641461429);
        assertEq(lifeArr[2], 0);

        // make positions go underwater
        strategy1.file("rate", 1e6);
        lifeArr = ih.lifeBatched(ids);
        assertEq(lifeArr[0], 9498);
        assertEq(lifeArr[1], 475000);
        assertEq(lifeArr[2], 0);
    }

    function testKillBatched() public {
        // enter another position
        usdc.approve(address(investor), 33e6);
        investor.earn(address(this), address(usdcPool), 0, 33e6, 100e6, "");

        // attempt liquidations when positions are healthy
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;
        bytes[] memory dat = new bytes[](2);

        vm.roll(block.number + 1);
        ih.killBatched(ids, dat, vm.addr(2));
        (,,,,,, uint256 borrow) = investor.positions(0);
        assertEq(borrow, 100000000);
        (,,,,,, borrow) = investor.positions(1);
        assertEq(borrow, 99989042);

        // make positions go underwater
        strategy1.file("rate", 105e18);
        strategy1.file("burn", 105e6);

        // liquidate when positions are underwater
        uint256 liquidatorBalBefore = usdc.balanceOf(vm.addr(2));
        ih.killBatched(ids, dat, vm.addr(2));
        (,,,,,, borrow) = investor.positions(0);
        assertEq(borrow, 0);
        (,,,,,, borrow) = investor.positions(1);
        assertEq(borrow, 0);
        assertEq(usdc.balanceOf(vm.addr(2)) - liquidatorBalBefore, 5250000);
    }
}
