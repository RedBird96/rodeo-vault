// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {Multisig} from "../support/Multisig.sol";

contract MultisigTest is Test {
    Multisig m;

    function setUp() public override {
        m = new Multisig(vm.addr(1));
        vm.startPrank(vm.addr(1));
        m.add(address(m), 0, abi.encodeWithSelector(Multisig.addOwner.selector, vm.addr(2), 2));
        m.add(address(m), 0, abi.encodeWithSelector(Multisig.setProposer.selector, vm.addr(3), true));
        m.add(address(m), 0, abi.encodeWithSelector(Multisig.setExecuter.selector, vm.addr(4), true));
        m.add(address(m), 0, abi.encodeWithSelector(Multisig.setDelay.selector, 60));
        vm.warp(block.timestamp + 61);
        m.execute(1);
        m.execute(2);
        m.execute(3);
        m.execute(0);
        vm.stopPrank();
    }

    fallback() external {}

    uint256 sampleCallValue = 0;

    function sampleCall(uint256 value) public payable {
        sampleCallValue = value;
    }

    function testAccessControl() public {
        vm.expectRevert("unauthorized");
        m.add(address(m), 0, "");

        vm.startPrank(vm.addr(3));
        uint256 id = m.add(address(this), 0, "");

        vm.expectRevert("unauthorized");
        m.confirm(id, false);

        vm.stopPrank();
        vm.startPrank(vm.addr(1));
        m.confirm(id, false);
        vm.stopPrank();
        vm.startPrank(vm.addr(2));
        m.confirm(id, false);

        vm.stopPrank();
        vm.startPrank(vm.addr(3));
        vm.expectRevert("unauthorized");
        m.execute(id);

        vm.stopPrank();
        vm.startPrank(vm.addr(4));
        vm.warp(block.timestamp + 61);
        m.execute(id);

        vm.stopPrank();

        vm.expectRevert("not wallet");
        m.setThreshold(1);
        vm.expectRevert("not wallet");
        m.setDelay(1);
        vm.expectRevert("not wallet");
        m.addOwner(address(0), 1);
    }

    function testExecute() public {
        vm.startPrank(vm.addr(1));
        vm.deal(address(m), 3e18);
        uint256 id = m.add(address(this), 1e18, abi.encodeWithSignature("sampleCall(uint256)", 5));
        vm.expectRevert("under threshold");
        m.execute(id);
        vm.stopPrank();
        vm.startPrank(vm.addr(2));
        uint256 balanceBefore = address(this).balance;
        vm.expectRevert("before delay");
        m.confirm(id, true);
        vm.warp(block.timestamp + 61);
        m.confirm(id, true);
        vm.expectRevert("already confirmed");
        m.confirm(id, true);
        vm.expectRevert("already executed");
        m.execute(id);
        vm.stopPrank();
        assertEq(sampleCallValue, 5);
        assertEq(address(this).balance - balanceBefore, 1e18);
        assertEq(address(m).balance, 2e18);
        address(m).call{value: 1}("");
    }

    function testCancel() public {
        vm.startPrank(vm.addr(1));
        uint256 id = m.add(address(m), 0, "");
        vm.expectRevert("before grace");
        m.cancel(id);
        vm.warp(block.timestamp + (16 * 60));
        m.cancel(id);
        vm.stopPrank();
        (uint256 time,,,,) = m.transactions(id);
        assertEq(time, type(uint256).max);
    }

    function testGetInfo() public {
        (uint256 count, bool[] memory yeses) = m.getInfo(3);
        assertEq(count, 1);
        assertTrue(yeses[0]);
        assertTrue(!yeses[1]);
    }

    function testGetPage() public {
        (, address[] memory target,,,, uint256[] memory count) = m.getPage(1, 3);
        assertEq(target.length, 2);
        assertEq(target[0], address(m));
        assertEq(count[1], 1);
    }

    function testGetSummary() public {
        (uint256 transactionCount, uint256 threshold, uint256 ownersCount, uint256 delay) = m.getSummary();
        assertEq(transactionCount, 4);
        assertEq(threshold, 2);
        assertEq(ownersCount, 2);
        assertEq(delay, 60);
    }

    function testGetOwners() public {
        (address[] memory owners) = m.getOwners();
        assertEq(owners.length, 2);
        assertEq(owners[0], vm.addr(1));
        assertEq(owners[1], vm.addr(2));
    }
}
