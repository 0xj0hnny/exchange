// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Exchange.sol";
import "./Mock/erc20.t.sol";

contract ExchangeTest is Test {
    address feeAccount = address(1234);
    uint256 feePercent = 10;
    address user1 = address(1);
    address user2 = address(2);

    Exchange public exchange;
    MockERC20 public mockToken;
    MockERC20 public mockToken2;

    function setUp() public {
        uint256 initialAmount = 1e18;
        exchange = new Exchange(feeAccount, feePercent);
        mockToken = new MockERC20();
        mockToken2 = new MockERC20();
    }

    function testFeeAccount() public {
        assertEq(exchange.feeAccount(), feeAccount);
    }

    function testFeePercentage() public {
        assertEq(exchange.feePercent(), feePercent);
    }

    function testDepositTokenSuccess() public {
        uint256 amount = 1e18;
        mockToken.approve(address(exchange), amount);
        bool success = exchange.depositToken(address(mockToken), amount);
        assertTrue(success);

        uint256 balance = exchange.balanceOf(address(mockToken), address(this));
        assertEq(balance, amount);
    }

    function testDepositTokenRevert() public {
        vm.expectRevert(bytes("Not Address 0"));
        uint256 amount = 1e18;
        bool success = exchange.depositToken(address(0), amount);
        assertFalse(success);
    }

    function testDepositEther() public {
        uint256 amount = 0.1 ether;
        exchange.depositEther{value: amount}();
        uint256 balance = exchange.balanceOf(address(0), address(this));
        assertEq(balance, amount);
    }

    function testFallback() public {
        uint256 amount = 0.1 ether;
        (bool sent, ) = address(exchange).call{value: amount}("");
        require(sent, "");
    }

    function testWithdrawEther() public {
        vm.deal(user1, 0.6 ether);
        assertEq(user1.balance, 0.6 ether);
        vm.prank(user1);
        exchange.depositEther{value: 0.1 ether}();
        uint256 balance = exchange.balanceOf(address(0), user1);
        assertEq(balance, 0.1 ether);
        assertEq(user1.balance, 0.5 ether);

        // WITHDRAW
        vm.prank(user1);
        exchange.withdrawEther(0.05 ether);
        balance = exchange.balanceOf(address(0), user1);
        assertEq(balance, 0.05 ether);
        assertEq(user1.balance, 0.55 ether);
        vm.stopPrank();
    }

    function testWithdrawTokenSuccess() public {
        uint256 amount = 1e18;
        mockToken.approve(address(exchange), amount);
        bool success = exchange.depositToken(address(mockToken), amount);
        assertTrue(success);

        uint256 balance = exchange.balanceOf(address(mockToken), address(this));
        assertEq(balance, amount);

        success = exchange.withdwarToken(address(mockToken), amount);
        assertTrue(success);

        balance = exchange.balanceOf(address(mockToken), address(this));
        assertEq(balance, 0);
    }

    function testWithdrawTokenRevert() public {
        uint256 amount = 1e18;
        mockToken.approve(address(exchange), amount);
        bool success = exchange.depositToken(address(mockToken), amount);
        assertTrue(success);

        uint256 balance = exchange.balanceOf(address(mockToken), address(this));
        assertEq(balance, amount);

        vm.expectRevert(bytes("Not Address 0"));
        success = exchange.withdwarToken(address(0), amount);
        assertFalse(success);

        vm.expectRevert(bytes("Withdraw out of bound"));
        success = exchange.withdwarToken(address(mockToken), 2e18);
        assertFalse(success);
    }

    function testMakeOrder() public {
        uint256 _amountGive = 1e18;
        uint256 _amountGet = 0.5e18;
        exchange.makeOrder(
            address(mockToken),
            _amountGet,
            address(mockToken2),
            _amountGive
        );
        (
            uint256 id,
            address user,
            address tokenGet,
            uint256 amountGet,
            address tokenGive,
            uint256 amountGive,
            uint256 timestamp
        ) = exchange.viewOrderDetail(1);
        assertEq(id, 1);
        assertEq(user, address(this));
        assertEq(tokenGet, address(mockToken));
        assertEq(amountGet, _amountGet);
        assertEq(tokenGive, address(mockToken2));
        assertEq(amountGive, _amountGive);
        assertEq(timestamp, block.timestamp);
    }

    function testCancelOrder() public {
        uint256 _amountGive = 1e18;
        uint256 _amountGet = 0.5e18;
        exchange.makeOrder(
            address(mockToken),
            _amountGet,
            address(mockToken2),
            _amountGive
        );
        exchange.cancelOrder(1);
        bool isCancel = exchange.cancelOrders(1);
        assertTrue(isCancel);
    }

    function testTrade() public {
        vm.deal(user1, 1 ether);
        assertEq(user1.balance, 1 ether);
        vm.deal(user2, 1 ether);
        assertEq(user2.balance, 1 ether);

        vm.prank(user1);
        exchange.depositEther{value: 0.1 ether}();
        assertEq(user1.balance, 0.9 ether);
        assertEq(exchange.balanceOf(address(0), user1), 0.1 ether);

        vm.prank(user2);
        exchange.depositEther{value: 0.2 ether}();
        assertEq(user2.balance, 0.8 ether);
        assertEq(exchange.balanceOf(address(0), user2), 0.2 ether);

        vm.prank(user1);
        exchange.makeOrder(address(0), 0.05 ether, address(0), 0.01 ether);
        (
            uint256 id,
            address user,
            address tokenGet,
            uint256 amountGet,
            address tokenGive,
            uint256 amountGive,
            uint256 timestamp
        ) = exchange.viewOrderDetail(1);
        assertEq(id, 1);
        assertEq(user, user1);

        vm.prank(user2);
        exchange.fillOrder(id);

        assertEq(exchange.balanceOf(address(0), user1), 0.14 ether);
        assertEq(exchange.balanceOf(address(0), user2), 0.159 ether);
    }
}
