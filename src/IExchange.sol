interface IExchange {
    struct Order {
        uint256 id;
        address user;
        address tokenGet;
        uint256 amountGet;
        address tokenGive;
        uint256 amountGive;
        uint256 timestamp;
    }
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

    function depositEther() external payable;

    function depositToken(address token, uint256 amount)
        external
        returns (bool);

    function withdrawEther(uint256 amount) external returns (bool);

    function withdwarToken(address token, uint256 amount)
        external
        returns (bool);

    function balanceOf(address token, address user)
        external
        view
        returns (uint256);

    function makeOrder(
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive
    ) external;

    function cancelOrder(uint256 orderId) external;

    function viewOrderDetail(uint256 orderId)
        external
        view
        returns (
            uint256 id,
            address user,
            address tokenGet,
            uint256 amountGet,
            address tokenGive,
            uint256 amountGive,
            uint256 timestamp
        );

    function fillOrder(uint256 orderId) external;
}
