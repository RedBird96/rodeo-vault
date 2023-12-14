// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IPositionManager} from "../interfaces/IPositionManager.sol";
import {IStrategyHelper} from "../interfaces/IStrategyHelper.sol";
import {ERC721TokenReceiver} from "../ERC721TokenReceiver.sol";
import {IInvestor} from "../interfaces/IInvestor.sol";
import {ZapInOutHelper} from "../token/ZapInOutHelper.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPool} from "../interfaces/IPool.sol";
import {DSTest} from "./utils/DSTest.sol";

contract ZapInOutHelperTest is DSTest, ERC721TokenReceiver {
    IPositionManager public positionManager;
    IStrategyHelper public strategyHelper;
    ZapInOutHelper public helper;
    IERC20 public usdt;
    IPool public pool;
    ZapInOutHelper.ZapIn public inParams;
    ZapInOutHelper.ZapOut public outParams;

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event FeeWithdrawn(address indexed token, uint256 fee);
    event ExecutedIn(
        address indexed user, address indexed pool, uint256 indexed strategy, address token, uint256 amount
    );
    event ExecutedOut(
        address indexed user, address indexed pool, uint256 indexed position, address token, uint256 amount
    );

    error SlippageTooHigh(uint16 current, uint16 maximum);
    error FeeTooHigh(uint16 current, uint16 maximum);
    error NotWhitelistedToken(address token);
    error CallFailed(bytes result);
    error Unauthorized();

    function setUp() external {
        vm.createSelectFork("https://arb-mainnet.g.alchemy.com/v2/-dVfS3BS-6YZkGd9GC6Ist_Y12-KPFXw", 105_339_954);

        positionManager = IPositionManager(0x5e4d7F61cC608485A2E4F105713D26D58a9D0cF6);
        strategyHelper = IStrategyHelper(0x72f7101371201CeFd43Af026eEf1403652F115EE);
        helper = new ZapInOutHelper(address(positionManager), address(strategyHelper), 50, 100);
        usdt = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
        pool = IPool(0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE);

        vm.prank(0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6); // Just an address with a positive USDT balance

        usdt.transfer(address(this), 1000e6);

        inParams = ZapInOutHelper.ZapIn({
            token: address(usdt),
            amount: usdt.balanceOf(address(this)),
            swapApprovalTarget: 0x216B4B4Ba9F3e719726886d34a177484278Bfcae, // TokenTransferProxy (ParaSwap)
            swapVenue: 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57, // AugustusSwapper (ParaSwap)
            swapData: hex"a6886da90000000000000000000000000000000000000000000000000000000000000020000000000000000000000000fd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9000000000000000000000000ff970a61a04b1ca14834a43f5de4533ebddb5cc8000000000000000000000000e592427a0aece92de3edee1f18e0157c05861564000000000000000000000000000000000000000000000000000000003b9aca00000000000000000000000000000000000000000000000000000000003a1cc962000000000000000000000000000000000000000000000000000000003b9a3e22010000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000649b1d2c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005615deb798bb3e4dfa0139dfa1b3d433cc23b72f00000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000002209d9540d4ec5143c9980096efa12a046300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002bfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9000064ff970a61a04b1ca14834a43f5de4533ebddb5cc80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            pool: address(pool),
            strategy: 35, // Balancer RDNT/WETH
            borrow: 0,
            data: ""
        });

        outParams = ZapInOutHelper.ZapOut({
            position: 0,
            amount: 0,
            borrow: 0,
            data: "",
            token: address(usdt),
            pool: address(pool)
        });

        usdt.approve(address(helper), inParams.amount);

        helper.file("whitelist", address(usdt));
    }

    function testConstructorMustFailSlippageTooHigh() external {
        uint16 slippage = 501;

        vm.expectRevert(abi.encodeWithSelector(SlippageTooHigh.selector, slippage, uint16(500)));

        new ZapInOutHelper(address(0x0), address(0x0), slippage, 0);
    }

    function testConstructorMustFailFeeTooHigh() external {
        uint16 fee = 10001;

        vm.expectRevert(abi.encodeWithSelector(FeeTooHigh.selector, fee, uint16(10000)));

        new ZapInOutHelper(address(0x0), address(0x0), 0, fee);
    }

    function testConstructor(address posManager, address strHelper, uint16 slippage, uint16 fee) external {
        vm.assume(slippage <= 500);
        vm.assume(fee <= 10000);

        ZapInOutHelper newHelper = new ZapInOutHelper(posManager, strHelper, slippage, fee);

        assertEq(address(newHelper.positionManager()), posManager);
        assertEq(address(newHelper.strategyHelper()), strHelper);
        assertEq(newHelper.slippage(), slippage);
        assertEq(newHelper.fee(), fee);
        assertTrue(newHelper.exec(address(this)));
    }

    function testFileFeeMustFailUnauthorized() external {
        vm.prank(address(0));
        vm.expectRevert(Unauthorized.selector);

        helper.file("fee", 0);
    }

    function testFileFeeMustFailFeeTooHigh() external {
        uint256 newFee = 10001;

        vm.expectRevert(abi.encodeWithSelector(FeeTooHigh.selector, uint16(newFee), uint16(10000)));

        helper.file("fee", newFee);
    }

    function testFileFee(uint256 newFee) external {
        vm.assume(newFee <= 10000);
        vm.expectEmit(true, true, true, true, address(helper));

        emit File("fee", newFee);

        helper.file("fee", newFee);

        assertEq(helper.fee(), newFee);
    }

    function testFileSlippageMustFailUnauthorized() external {
        vm.prank(address(0));
        vm.expectRevert(Unauthorized.selector);

        helper.file("slippage", 0);
    }

    function testFileslippageMustFailSlippageTooHigh() external {
        uint256 newSlippage = 501;

        vm.expectRevert(abi.encodeWithSelector(SlippageTooHigh.selector, uint16(newSlippage), uint16(500)));

        helper.file("slippage", newSlippage);
    }

    function testFileSlippage(uint16 newSlippage) external {
        vm.assume(newSlippage <= 500);
        vm.expectEmit(true, true, true, true, address(helper));

        emit File("slippage", newSlippage);

        helper.file("slippage", newSlippage);

        assertEq(helper.slippage(), newSlippage);
    }

    function testFileWhitelistMustFailUnauthorized() external {
        vm.prank(address(0));
        vm.expectRevert(Unauthorized.selector);

        helper.file("whitelist", address(0));
    }

    function testFileWhitelist(address token) external {
        vm.assume(token != address(0));
        vm.assume(!helper.whitelist(token));
        vm.expectEmit(true, true, true, true, address(helper));

        emit File("whitelist", token);

        helper.file("whitelist", token);

        assertTrue(helper.whitelist(token));

        vm.expectEmit(true, true, true, true, address(helper));

        emit File("whitelist", token);

        helper.file("whitelist", token);

        assertTrue(!helper.whitelist(token));
    }

    function testFileExecMustFailUnauthorized() external {
        vm.prank(address(0));
        vm.expectRevert(Unauthorized.selector);

        helper.file("exec", address(0));
    }

    function testFileExec(address user) external {
        vm.assume(user != address(0));
        vm.assume(!helper.exec(user));
        vm.expectEmit(true, true, true, true, address(helper));

        emit File("exec", user);

        helper.file("exec", user);

        assertTrue(helper.exec(user));

        vm.expectEmit(true, true, true, true, address(helper));

        emit File("exec", user);

        helper.file("exec", user);

        assertTrue(!helper.exec(user));
    }

    function testExecuteInMustFailNotWhitelistedToken() external {
        inParams.token = address(0);

        vm.expectRevert(abi.encodeWithSelector(NotWhitelistedToken.selector, inParams.token));

        helper.executeIn(inParams);
    }

    function testExecuteInMustFailCallFailed() external {
        inParams.swapData = hex"00";

        vm.expectRevert(
            abi.encodeWithSelector(
                CallFailed.selector, hex"734e6e1c0000000000000000000000000000000000000000000000000000000000000000"
            )
        );

        helper.executeIn(inParams);
    }

    function testExecuteInParaSwap() external {
        uint256 prevBal = positionManager.balanceOf(address(this));

        vm.expectEmit(true, true, true, false, address(helper));

        emit ExecutedIn(address(this), inParams.pool, inParams.strategy, inParams.token, 0);

        helper.executeIn(inParams);

        uint256 currBal = positionManager.balanceOf(address(this));

        assertEq(currBal, prevBal + 1);
    }

    function testExecuteIn1inch() external {
        uint256 prevBal = positionManager.balanceOf(address(this));

        inParams.swapApprovalTarget = 0x1111111254EEB25477B68fb85Ed929f73A960582; // AggregationRouterV5 (1inch)
        inParams.swapVenue = 0x1111111254EEB25477B68fb85Ed929f73A960582; // AggregationRouterV5 (1inch)
        inParams.swapData =
            hex"e449022e000000000000000000000000000000000000000000000000000000003b9aca00000000000000000000000000000000000000000000000000000000003b017856000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000010000000000000000000000008c9d230d45d6cfee39a6680fb7cb7e8de7ea8e71cfee7c08";

        vm.expectEmit(true, true, true, false, address(helper));

        emit ExecutedIn(address(this), inParams.pool, inParams.strategy, inParams.token, 0);

        helper.executeIn(inParams);

        uint256 currBal = positionManager.balanceOf(address(this));

        assertEq(currBal, prevBal + 1);
    }

    function testExecuteInShouldChargeFeeProperly() external {
        uint256 prevFeeBal = IERC20(pool.asset()).balanceOf(address(helper));

        helper.executeIn(inParams);

        uint256 currFeeBal = IERC20(pool.asset()).balanceOf(address(helper));

        assertEq(currFeeBal, prevFeeBal + 9999641);
    }

    function testExecuteOutMustFailNotWhitelistedToken() external {
        outParams.token = address(0);

        vm.expectRevert(abi.encodeWithSelector(NotWhitelistedToken.selector, outParams.token));

        helper.executeOut(outParams);
    }

    function testExecuteOut() external {
        helper.executeIn(inParams);

        uint256 id = IInvestor(positionManager.investor()).nextPosition() - 1;
        (,,,,, uint256 shares,) = IInvestor(positionManager.investor()).positions(id);

        outParams.position = id;
        outParams.amount = 0 - int256(shares);

        vm.roll(block.number + 1);

        uint256 prevBal = positionManager.balanceOf(address(this));

        positionManager.approve(address(helper), outParams.position);

        vm.expectEmit(true, true, true, false, address(helper));

        emit ExecutedOut(address(this), outParams.pool, outParams.position, outParams.token, 0);

        helper.executeOut(outParams);

        uint256 currBal = positionManager.balanceOf(address(this));

        assertEq(currBal, prevBal - 1);
    }

    function testExecuteOutShouldChargeFeeProperly() external {
        helper.executeIn(inParams);

        uint256 prevFeeBal = IERC20(pool.asset()).balanceOf(address(helper));
        uint256 id = IInvestor(positionManager.investor()).nextPosition() - 1;
        (,,,,, uint256 shares,) = IInvestor(positionManager.investor()).positions(id);

        outParams.position = id;
        outParams.amount = 0 - int256(shares);

        vm.roll(block.number + 1);

        positionManager.approve(address(helper), outParams.position);

        helper.executeOut(outParams);

        uint256 currFeeBal = IERC20(pool.asset()).balanceOf(address(helper));

        assertEq(currFeeBal, prevFeeBal + 9810792);
    }

    function testWithdrawFeesMustFailUnauthorized() external {
        vm.prank(address(0));
        vm.expectRevert(Unauthorized.selector);

        helper.withdrawFees(address(0), address(0));
    }

    function testWithdrawFees() external {
        uint256 expectedWithdraw = 9999641;

        helper.executeIn(inParams);

        uint256 prevFeeBal = IERC20(pool.asset()).balanceOf(address(this));

        assertEq(IERC20(pool.asset()).balanceOf(address(helper)), expectedWithdraw);

        vm.expectEmit(true, true, true, true, address(helper));

        emit FeeWithdrawn(pool.asset(), expectedWithdraw);

        helper.withdrawFees(pool.asset(), address(this));

        uint256 currFeeBal = IERC20(pool.asset()).balanceOf(address(this));

        assertEq(currFeeBal, prevFeeBal + expectedWithdraw);
        assertEq(IERC20(pool.asset()).balanceOf(address(helper)), 0);
    }
}
