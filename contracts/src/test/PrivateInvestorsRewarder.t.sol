// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {PrivateInvestorsRewarder} from "../token/PrivateInvestorsRewarder.sol";
import {PrivateInvestors} from "../token/PrivateInvestors.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {DSTest} from "./utils/DSTest.sol";
import {Vester} from "../token/Vester.sol";
import {Token} from "../token/Token.sol";

contract PrivateInvestorsRewarderTest is DSTest {
    Token public rdo;
    Vester public vester;
    MockERC20 public mockToken;
    PrivateInvestors public privateInvestors;
    PrivateInvestorsRewarder public privateInvestorsRewarder;
    uint32 depositsDuration = 86400; // 1 day (in secodns)

    error Unauthorized();
    error DepositsTimeIsNotOver();

    event File(bytes32 indexed what, uint256 data);
    event Donated(uint256 amount);
    event Claimed(address indexed target, uint256 amount);

    function setUp() external {
        rdo = new Token();
        vester = new Vester();
        mockToken = new MockERC20(18);
        privateInvestors = new PrivateInvestors(address(mockToken), block.timestamp + depositsDuration);
        privateInvestorsRewarder =
            new PrivateInvestorsRewarder(address(privateInvestors), address(vester), address(rdo));
        privateInvestorsRewarder.file("scheduleDuration", 7_776_000); // 90 days (in seconds)

        privateInvestors.file("depositStart", block.timestamp);
    }

    function testConstructor() external {
        assertEq(address(privateInvestorsRewarder.privateInvestors()), address(privateInvestors));
        assertEq(address(privateInvestorsRewarder.vester()), address(vester));
        assertEq(address(privateInvestorsRewarder.token()), address(rdo));
        assertEq(privateInvestorsRewarder.scheduleDuration(), 7_776_000); // 90 days (in seconds)
        assertTrue(privateInvestorsRewarder.exec(address(this)));
    }

    function testFileScheduleDurationMustFailUnauthorized() external {
        vm.prank(address(0));
        vm.expectRevert(Unauthorized.selector);

        privateInvestorsRewarder.file("scheduleDuration", 0);
    }

    function testFileScheduleDuration() external {
        vm.expectEmit(true, true, false, true, address(privateInvestorsRewarder));
        emit File("scheduleDuration", 123);
        privateInvestorsRewarder.file("scheduleDuration", 123);
        assertEq(privateInvestorsRewarder.scheduleDuration(), 123);
    }

    function testDonateMustFailUnauthorized() external {
        vm.prank(address(0));
        vm.expectRevert(Unauthorized.selector);

        privateInvestorsRewarder.donate(0);
    }

    function testDonateMustFailDepositsTimeIsNotOver() external {
        vm.warp(block.timestamp + depositsDuration - 1);
        vm.expectRevert(DepositsTimeIsNotOver.selector);

        privateInvestorsRewarder.donate(0);
    }

    function testDonate(uint256 amount) external {
        rdo.mint(address(this), amount);
        rdo.approve(address(privateInvestorsRewarder), amount);

        vm.warp(block.timestamp + depositsDuration);
        vm.expectEmit(true, true, false, true, address(privateInvestorsRewarder));

        emit Donated(amount);

        privateInvestorsRewarder.donate(amount);

        assertEq(privateInvestorsRewarder.totalRewards(), amount);
    }

    function testClaimOneUser(uint256 depositAmount, uint256 donateAmount) external {
        vm.assume(depositAmount > 0 && depositAmount < type(uint128).max);
        vm.assume(donateAmount > 0 && donateAmount < type(uint128).max);

        address[] memory whitelist = new address[](1);

        whitelist[0] = address(this);

        mockToken.mint(address(this), depositAmount);
        mockToken.approve(address(privateInvestors), depositAmount);

        privateInvestors.setWhitelist(whitelist, depositAmount);
        privateInvestors.file("depositCap", depositAmount);
        privateInvestors.deposit(depositAmount);

        vm.warp(block.timestamp + depositsDuration);

        rdo.mint(address(this), donateAmount);
        rdo.approve(address(privateInvestorsRewarder), donateAmount);

        privateInvestorsRewarder.donate(donateAmount);

        (uint256 depositedAmount,) = privateInvestors.users(address(this));
        uint256 claimable = (
            privateInvestorsRewarder.totalRewards() * depositedAmount / privateInvestors.totalDeposits()
        ) - privateInvestorsRewarder.claimed(address(this));

        vm.expectEmit(true, true, false, true, address(privateInvestorsRewarder));
        emit Claimed(address(this), claimable);

        privateInvestorsRewarder.claim();

        assertEq(privateInvestorsRewarder.totalClaimed(), claimable);
        assertEq(privateInvestorsRewarder.claimed(address(this)), claimable);
        assertEq(privateInvestorsRewarder.token().balanceOf(address(privateInvestorsRewarder)), 0);
    }

    function testClaimMultipleUsers(uint8 usersNumber, uint256 depositAmount, uint256 donateAmount) external {
        vm.assume(depositAmount > 0 && depositAmount < type(uint128).max);
        vm.assume(donateAmount > 0 && donateAmount < type(uint128).max);

        address[] memory users = new address[](usersNumber);
        address[] memory whitelist = new address[](usersNumber);

        for (uint8 i = 0; i < usersNumber; ++i) {
            users[i] = vm.addr(i + 1);
            whitelist[i] = users[i];

            mockToken.mint(users[i], depositAmount);
        }

        privateInvestors.setWhitelist(whitelist, depositAmount);
        privateInvestors.file("depositCap", depositAmount * usersNumber);
        privateInvestors.file("defaultCap", depositAmount);
        privateInvestors.file("defaultPartnerCap", depositAmount);

        for (uint8 i = 0; i < usersNumber; ++i) {
            vm.startPrank(users[i]);

            mockToken.approve(address(privateInvestors), depositAmount);
            privateInvestors.deposit(depositAmount);

            vm.stopPrank();
        }

        vm.warp(block.timestamp + depositsDuration);

        rdo.mint(address(this), donateAmount);
        rdo.approve(address(privateInvestorsRewarder), donateAmount);

        privateInvestorsRewarder.donate(donateAmount);

        uint256 rewarderTokenBalance = privateInvestorsRewarder.token().balanceOf(address(privateInvestorsRewarder));
        uint256 totalClaimed = 0;

        for (uint8 i = 0; i < usersNumber; ++i) {
            (uint256 depositedAmount,) = privateInvestors.users(users[i]);
            uint256 claimable = (
                privateInvestorsRewarder.totalRewards() * depositedAmount / privateInvestors.totalDeposits()
            ) - privateInvestorsRewarder.claimed(users[i]);

            if (claimable > 0) {
                vm.expectEmit(true, true, false, true, address(privateInvestorsRewarder));
                emit Claimed(users[i], claimable);
            }

            vm.prank(users[i]);

            privateInvestorsRewarder.claim();

            rewarderTokenBalance -= claimable;
            totalClaimed += claimable;

            assertEq(privateInvestorsRewarder.totalClaimed(), totalClaimed);
            assertEq(privateInvestorsRewarder.claimed(users[i]), claimable);
        }

        assertEq(privateInvestorsRewarder.totalClaimed(), totalClaimed);
        assertEq(privateInvestorsRewarder.token().balanceOf(address(privateInvestorsRewarder)), rewarderTokenBalance);
    }

    function testGetInfo(uint256 depositAmount, uint256 donateAmount) external {
        vm.assume(depositAmount > 0 && depositAmount < type(uint128).max);
        vm.assume(donateAmount > 0 && donateAmount < type(uint128).max);

        address[] memory whitelist = new address[](1);

        whitelist[0] = address(this);

        mockToken.mint(address(this), depositAmount);
        mockToken.approve(address(privateInvestors), depositAmount);

        privateInvestors.setWhitelist(whitelist, depositAmount);
        privateInvestors.file("depositCap", depositAmount);
        privateInvestors.deposit(depositAmount);

        (uint256 totalRewards, uint256 investorRewards, uint256 totalClaimed, uint256 investorClaimed) =
            privateInvestorsRewarder.getInfo(address(this));

        assertEq(totalRewards, 0);
        assertEq(investorRewards, 0);
        assertEq(totalClaimed, 0);
        assertEq(investorClaimed, 0);

        vm.warp(block.timestamp + depositsDuration);

        rdo.mint(address(this), donateAmount * 2);
        rdo.approve(address(privateInvestorsRewarder), donateAmount * 2);

        privateInvestorsRewarder.donate(donateAmount);

        (totalRewards, investorRewards, totalClaimed, investorClaimed) = privateInvestorsRewarder.getInfo(address(this));

        assertEq(totalRewards, donateAmount);
        assertEq(investorRewards, donateAmount);
        assertEq(totalClaimed, 0);
        assertEq(investorClaimed, 0);

        privateInvestorsRewarder.donate(donateAmount);

        (totalRewards, investorRewards, totalClaimed, investorClaimed) = privateInvestorsRewarder.getInfo(address(this));

        assertEq(totalRewards, donateAmount * 2);
        assertEq(investorRewards, donateAmount * 2);
        assertEq(totalClaimed, 0);
        assertEq(investorClaimed, 0);

        privateInvestorsRewarder.claim();

        (totalRewards, investorRewards, totalClaimed, investorClaimed) = privateInvestorsRewarder.getInfo(address(this));

        assertEq(totalRewards, donateAmount * 2);
        assertEq(investorRewards, donateAmount * 2);
        assertEq(totalClaimed, donateAmount * 2);
        assertEq(investorClaimed, donateAmount * 2);
    }
}
