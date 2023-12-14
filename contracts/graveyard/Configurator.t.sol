// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "./utils/Test.sol";
import {Configurator} from "../support/Configurator.sol";

contract ConfiguratorTest is Test {
    Configurator c;

    function setUp() public override {
        c = new Configurator();
    }

    fallback() external {}

    function testAccess() public {
        vm.startPrank(vm.addr(1));

        // Fail tweak
        vm.expectRevert(Configurator.Unauthorized.selector);
        c.file(address(this), "", 0);

        // Succeed tweak
        vm.stopPrank();
        c.setTweaker(vm.addr(1), true);
        vm.startPrank(vm.addr(1));
        c.file(address(this), "", 0);

        // Fail change
        vm.expectRevert(Configurator.Unauthorized.selector);
        c.fileAddress(address(this), "", vm.addr(1));

        // Succeed change
        vm.stopPrank();
        c.setChanger(vm.addr(1), true);
        vm.startPrank(vm.addr(1));
        c.fileAddress(address(this), "", vm.addr(1));

        // Fail own
        vm.expectRevert(Configurator.Unauthorized.selector);
        c.transaction(address(this), 0, "");

        // Succeed own
        vm.stopPrank();
        c.setOwner(vm.addr(1), true);
        vm.startPrank(vm.addr(1));
        c.transaction(address(this), 0, "");

        // Still works without lower roles
        vm.stopPrank();
        c.setTweaker(vm.addr(1), false);
        c.setChanger(vm.addr(1), false);
        vm.startPrank(vm.addr(1));
        c.file(address(this), "", 0);
    }

    function testTransaction() public {
        bytes memory data = hex"ddf99ceb0000";
        c.transaction(address(this), 0, data);
        c.renounceEmergency();
        vm.expectRevert(Configurator.NoEmergency.selector);
        c.transaction(address(this), 0, data);
    }
}
