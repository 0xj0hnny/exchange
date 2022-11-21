// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

error DepositTokenFail();
error WithdrawTokenFail();

contract Exchange {
    struct Order {
        uint256 id;
        address user;
        address tokenGet;
        uint256 amountGet;
        address tokenGive;
        uint256 amountGive;
        uint256 timestamp;
    }

    address public immutable feeAccount;
    uint256 public immutable feePercent;

    mapping(address => mapping(address => uint256)) public balance;
    mapping(uint256 => Order) public orders;
    mapping(uint256 => bool) public cancelOrders;
    mapping(uint256 => bool) public ordersFilled;
    uint256 public orderCount;

    event Deposit(
        address indexed token,
        address indexed sender,
        uint256 amount
    );
    event Withdraw(
        address indexed token,
        address indexed sender,
        uint256 amount
    );
    event MakeOrder(
        uint256 id,
        address indexed user,
        address indexed tokenGet,
        uint256 amountGet,
        address indexed tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    event CancelOrder(
        uint256 id,
        address indexed user,
        address indexed tokenGet,
        uint256 amountGet,
        address indexed tokenGive,
        uint256 amountGive,
        uint256 timestamp
    );
    event Trade(
        uint256 id,
        address user,
        address indexed tokenGet,
        uint256 amountGet,
        address indexed tokenGive,
        uint256 amountGive,
        address indexed trader,
        uint256 timestamp
    );

    constructor(address _feeAccount, uint256 _feePercent) {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    fallback() external payable {}

    receive() external payable {}

    function depositEther() external payable {
        balance[address(0)][msg.sender] += msg.value;
        emit Deposit(address(0), msg.sender, msg.value);
    }

    function depositToken(address token, uint256 amount)
        external
        returns (bool)
    {
        require(token != address(0), "Not Address 0");
        bool success = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) revert DepositTokenFail();
        balance[token][msg.sender] += amount;

        emit Deposit(token, msg.sender, amount);
        return success;
    }

    function withdrawEther(uint256 amount) public returns (bool) {
        console.log("withdraw sender: ", msg.sender);
        require(
            balance[address(0)][msg.sender] >= amount,
            "Withdraw out of bound"
        );

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success);

        balance[address(0)][msg.sender] -= amount;
        emit Withdraw(address(0), msg.sender, amount);

        return success;
    }

    function withdwarToken(address token, uint256 amount)
        external
        returns (bool)
    {
        require(token != address(0), "Not Address 0");
        require(balance[token][msg.sender] >= amount, "Withdraw out of bound");

        bool success = IERC20(token).transfer(msg.sender, amount);
        if (!success) revert WithdrawTokenFail();

        balance[token][msg.sender] -= amount;
        emit Withdraw(token, msg.sender, amount);

        return success;
    }

    function balanceOf(address token, address user)
        public
        view
        returns (uint256)
    {
        return balance[token][user];
    }

    function makeOrder(
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive
    ) public {
        orderCount = orderCount + 1;
        orders[orderCount] = Order(
            orderCount,
            msg.sender,
            tokenGet,
            amountGet,
            tokenGive,
            amountGive,
            block.timestamp
        );
        emit MakeOrder(
            orderCount,
            msg.sender,
            tokenGet,
            amountGet,
            tokenGive,
            amountGive,
            block.timestamp
        );
    }

    function cancelOrder(uint256 orderId) public {
        Order storage order = orders[orderId];
        require(order.user == msg.sender, "Not order owner");
        require(order.id == orderId, "Order doesn't exist");

        cancelOrders[orderId] = true;
        emit CancelOrder(
            orderId,
            order.user,
            order.tokenGet,
            order.amountGet,
            order.tokenGive,
            order.amountGive,
            block.timestamp
        );
    }

    function viewOrderDetail(uint256 orderId)
        public
        view
        returns (
            uint256 id,
            address user,
            address tokenGet,
            uint256 amountGet,
            address tokenGive,
            uint256 amountGive,
            uint256 timestamp
        )
    {
        Order memory order = orders[orderId];
        id = order.id;
        user = order.user;
        tokenGet = order.tokenGet;
        amountGet = order.amountGet;
        tokenGive = order.tokenGive;
        amountGive = order.amountGive;
        timestamp = order.timestamp;
    }

    function fillOrder(uint256 orderId) public {
        require(orderId > 0 && orderId <= orderCount, "orderId out of bound");
        require(!ordersFilled[orderId], "order already filled");
        require(!cancelOrders[orderId], "order already cancelled");

        Order storage order = orders[orderId];
        _trade(
            order.id,
            order.user,
            order.tokenGet,
            order.amountGet,
            order.tokenGive,
            order.amountGive
        );
        ordersFilled[orderId] = true;
    }

    function _trade(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive
    ) internal {
        uint256 feeAmount = (amountGive * feePercent) / 100;

        console.log("feeAmount: ", feeAmount);
        console.log("msg.sender: ", msg.sender);
        console.log("tokenGET, ", balance[tokenGet][msg.sender]);

        balance[tokenGet][msg.sender] -= (amountGet + feeAmount);
        balance[tokenGet][user] = balance[tokenGet][user] + amountGet;
        balance[tokenGive][user] = balance[tokenGive][user] - amountGive;
        balance[tokenGive][msg.sender] =
            balance[tokenGive][msg.sender] +
            amountGive;

        balance[tokenGet][feeAccount] =
            balance[tokenGet][feeAccount] +
            feeAmount;
        emit Trade(
            id,
            user,
            tokenGet,
            amountGet,
            tokenGive,
            amountGive,
            msg.sender,
            block.timestamp
        );
    }
}
