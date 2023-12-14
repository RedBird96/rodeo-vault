// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {Util} from "../Util.sol";
import {Strategy} from "../Strategy.sol";

contract MockStrategy is Strategy {
    string public constant name = "Mock";
    uint256 _rateAmount = 123e18;
    uint256 _mintAmount = 123e18;
    uint256 _burnAmount = 123e6;

    constructor(address _sh) Strategy(_sh) {}

    function testFile(bytes32 what, uint256 data) external {
        if (what == "rate") _rateAmount = data;
        if (what == "mint") _mintAmount = data;
        if (what == "burn") _burnAmount = data;
    }

    function _rate(uint256) internal view override returns (uint256) {
        return _rateAmount;
    }

    function _mint(address, uint256, bytes calldata) internal view override returns (uint256) {
        return _mintAmount;
    }

    function _burn(address, uint256, bytes calldata) internal view override returns (uint256) {
        return _burnAmount;
    }
}

contract StrategyTest is Test {
    MockStrategy strategy;

    function setUp() public override {
        super.setUp();
        strategy = new MockStrategy(address(sh));
    }

    function testMint() public {
        usdc.mint(address(this), 6e6);
        usdc.approve(address(strategy), 6e6);
        uint256 sha = strategy.mint(address(usdc), 5e6, "");
        assertEq(sha, 123e18);
        assertEq(strategy.totalShares(), 123e18);

        sha = strategy.mint(address(usdc), 1e6, "");
        assertEq(sha, 123e18);
        assertEq(strategy.totalShares(), 246e18);

        vm.startPrank(vm.addr(1));
        vm.expectRevert(Util.Unauthorized.selector);
        strategy.mint(address(usdc), 1, "");
        vm.stopPrank();

        strategy.file("status", strategy.S_PAUSE());
        vm.expectRevert(Strategy.WrongStatus.selector);
        strategy.mint(address(usdc), 1, "");
    }

    function testBurn() public {
        usdc.mint(address(this), 6e6);
        usdc.approve(address(strategy), 6e6);
        strategy.mint(address(usdc), 6e6, "");
        strategy.testFile("burn", 3e6);

        uint256 amt = strategy.burn(address(usdc), 62e18, "");
        assertEq(amt, 3e6);
        assertEq(strategy.totalShares(), 61e18);

        vm.startPrank(vm.addr(1));
        vm.expectRevert(Util.Unauthorized.selector);
        strategy.mint(address(usdc), 1, "");
        vm.stopPrank();

        strategy.file("status", strategy.S_PAUSE());
        vm.expectRevert(Strategy.WrongStatus.selector);
        strategy.mint(address(usdc), 1, "");
    }
}
