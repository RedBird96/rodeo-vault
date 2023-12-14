// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {PrivateInvestors} from "../token/PrivateInvestors.sol";

contract PrivateInvestorsTest is Test {
    MockERC20 rdo;
    MockERC20 xrdo;
    MockERC20 rbcNft;
    PrivateInvestors c;

    function setUp() public override {
        usdc = new MockERC20(6);
        rdo = new MockERC20(18);
        xrdo = new MockERC20(18);
        rbcNft = new MockERC20(18);
        c = new PrivateInvestors(address(usdc), block.timestamp + 86400);
        c.file("rdo", address(rdo));
        c.file("xrdo", address(xrdo));
        c.file("rbcCap", 10e6);
        c.file("rbcNft", address(rbcNft));
        c.file("depositCap", 500e6);
        rdo.mint(address(c), 100000e18);
    }

    function testFile() public {
        assertEq(c.rbcCap(), 10e6);
        assertEq(address(c.rbcNft()), address(rbcNft));
        c.file("paused", 1);
        assert(c.paused());
        c.file("depositStart", 100000);
        assertEq(c.depositStart(), 100000);
        c.file("depositEnd", 100000);
        assertEq(c.depositEnd(), 100000);
        c.file("depositCap", 88);
        assertEq(c.depositCap(), 88);
        c.file("defaultCap", 88);
        assertEq(c.defaultCap(), 88);
        c.file("defaultPartnerCap", 88);
        assertEq(c.defaultPartnerCap(), 88);
        c.file("price", 88);
        assertEq(c.price(), 88);
        c.file("percent", 88);
        assertEq(c.percent(), 88);
        c.file("initial", 88);
        assertEq(c.initial(), 88);
        c.file("vesting", 88);
        assertEq(c.vesting(), 88);
        c.file("rbcCap", 88);
        assertEq(c.rbcCap(), 88);
        c.file("rbcStart", 88);
        assertEq(c.rbcStart(), 88);
        c.file("exec", vm.addr(1));
        assert(c.exec(vm.addr(1)));
        c.file("exec", vm.addr(1));
        assert(!c.exec(vm.addr(1)));
        c.file("rdo", vm.addr(1));
        assertEq(address(c.rdo()), vm.addr(1));
        c.file("xrdo", vm.addr(1));
        assertEq(address(c.xrdo()), vm.addr(1));
        c.file("vester", vm.addr(1));
        assertEq(address(c.vester()), vm.addr(1));
    }

    function testSetUser() public {
        address target = vm.addr(1);
        c.setUser(target, 88);
        (uint256 amount, uint256 cap, bool claimed) = c.getUser(target);
        assertEq(amount, 88);
        assertEq(cap, 0);
        assert(!claimed);
        c.setUser(target, 40);
        (amount,,) = c.getUser(target);
        assertEq(amount, 40);
        assertEq(c.totalDeposits(), 40);
        assertEq(c.totalUsers(), 1);
        vm.startPrank(vm.addr(1));
        vm.expectRevert();
        c.setUser(target, 88);
    }

    function testSetWhitelist() public {
        address target = vm.addr(1);
        address[] memory targets = new address[](1);
        targets[0] = target;
        c.setWhitelist(targets, 88);
        (uint256 a, uint256 b, bool cc) = c.getUser(target);
        assertEq(a, 0);
        assertEq(b, 88);
        assert(!cc);
        vm.startPrank(vm.addr(1));
        vm.expectRevert();
        c.setWhitelist(targets, 88);
    }

    function testCollect() public {
        usdc.mint(address(c), 100e6);
        uint256 before = usdc.balanceOf(address(this));
        c.collect(address(usdc), 50e6, address(this));
        assertEq(usdc.balanceOf(address(this)) - before, 50e6);
    }

    function testDeposit() public {
        usdc.mint(address(this), 1000e6);
        usdc.approve(address(c), 1000e6);
        vm.expectRevert();
        c.deposit(100e6);

        rbcNft.mint(address(this), 1);
        c.deposit(9e6);
        (uint256 amount, uint256 cap,) = c.getUser(address(this));
        assertEq(amount, 9e6);
        assertEq(cap, 10e6);
        vm.expectRevert();
        c.deposit(2e6);

        address[] memory targets = new address[](1);
        targets[0] = address(this);
        c.setWhitelist(targets, 100e6);
        c.deposit(90e6);
        (amount, cap,) = c.getUser(address(this));
        assertEq(amount, 99e6);
        assertEq(cap, 100e6);
        vm.expectRevert();
        c.deposit(2e6);

        assertEq(c.totalUsers(), 1);
        assertEq(c.totalDeposits(), 99e6);
        assertEq(usdc.balanceOf(address(c)), 99e6);

        c.file("depositCap", 50e6);
        vm.expectRevert();
        c.deposit(1e6);
        c.file("depositCap", 500e6);

        c.file("paused", 1);
        vm.expectRevert();
        c.deposit(1e6);
        c.file("paused", 0);

        c.file("depositEnd", block.timestamp - 1);
        vm.expectRevert();
        c.deposit(1e6);
        c.file("depositEnd", block.timestamp + 1000);

        c.file("depositStart", block.timestamp + 1000);
        vm.expectRevert();
        c.deposit(1e6);
    }

    function testVest() public {
        c.file("vester", address(this));
        c.file("price", 0.075e18);
        c.file("percent", 0.6e18);
        c.file("initial", 0.25e18);
        c.file("vesting", 180 days);
        c.setUser(address(this), 120e6);

        vm.expectRevert();
        c.vest(address(this));

        c.file("depositEnd", 0);

        vm.expectRevert();
        c.vest(address(0));

        vm.startPrank(vm.addr(1));
        vm.expectRevert();
        c.vest(address(this));
        vm.stopPrank();

        c.vest(address(this));
        assertEq(rdo.balanceOf(address(this)), 960e18);
        assertEq(xrdo.balanceOf(address(this)), 640e18);
        assertEq(rdo.balanceOf(address(c)), 99040e18);
        assertEq(vestTarget, address(this));
        assertEq(vestToken, address(xrdo));
        assertEq(vestAmount, 640e18);
        assertEq(vestInitial, 0.25e18);
        assertEq(vestVesting, 180 days);

        vm.expectRevert();
        c.vest(address(this));
    }

    function testGetCap() public {
        assertEq(c.getCap(address(this)), 0);
        rbcNft.mint(address(this), 1);
        assertEq(c.getCap(address(this)), 10e6);
        c.file("rbcStart", block.timestamp + 1000);
        assertEq(c.getCap(address(this)), 0);
        c.file("defaultCap", 50e6);
        assertEq(c.getCap(address(0)), 50e6);

        address[] memory targets = new address[](1);
        targets[0] = address(this);
        c.setWhitelist(targets, 999e6);
        assertEq(c.getCap(address(this)), 999e6);
        c.file("rbcStart", block.timestamp);
        c.file("defaultPartnerCap", 2000e6);
        assertEq(c.getCap(address(this)), 2000e6);
    }

    address vestTarget;
    address vestToken;
    uint256 vestAmount;
    uint256 vestInitial;
    uint256 vestVesting;

    function vest(address target, address token, uint256 amount, uint256 initial, uint256 vesting) public {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
        vestTarget = target;
        vestToken = token;
        vestAmount = amount;
        vestInitial = initial;
        vestVesting = vesting;
    }
}
