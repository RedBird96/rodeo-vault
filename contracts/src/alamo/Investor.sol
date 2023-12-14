// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "../test/utils/console.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IOracle {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}

interface IStore {
    function exec(address) external view returns (bool);
    function getUint(bytes32) external view returns (uint256);
    function getAddress(bytes32) external view returns (address);
    function setUint(bytes32, uint256) external;
    function setUintDelta(bytes32, int256) external returns (uint256);
    function setAddress(bytes32, address) external returns (address);
}

interface IBank {
    function exec(address) external view returns (bool);
    function transfer(address, address, uint256) external;
}

interface IPool {
    function exec(address) external view returns (bool);
    function asset() external view returns (address);
    function oracle() external view returns (address);
    function getUpdatedIndex() external view returns (uint256);
    function borrow(uint256) external returns (uint256);
    function repay(uint256) external returns (uint256);
}

interface IHelper {
    function price(address) external view returns (uint256);
    function value(address, uint256) external view returns (uint256);
    function convert(address, address, uint256) external view returns (uint256);
    function swap(address, address, uint256, uint256, address) external returns (uint256);
}

interface IStrategy {
    function totalShares() external view returns (uint256);
    function rate(uint256) external view returns (uint256);
}

interface IStrategyProxy {
    function exec(address) external view returns (bool);
    function mint(address, address, uint256, bytes calldata) external returns (uint256);
    function burn(address, address, uint256, bytes calldata) external returns (uint256);
}

contract Investor {
    IStore public store;
    IHelper public helper;
    IStrategyProxy public strategyProxy;
    uint256 public slippage = 200;
    uint256 public performanceFee = 2000;
    uint256 public killCollateralPadding = 500;
    uint256 public closeCollateralPadding = 400;
    bool internal entered;
    mapping(uint256 => uint256) private lastBlock;
    mapping(address => bool) public exec;

    uint256 public constant STATUS_LIVE = 4;
    uint256 public constant STATUS_WITHDRAW = 3;
    uint256 public constant STATUS_LIQUIDATE = 2;
    uint256 public constant STATUS_PAUSED = 1;
    bytes32 public constant STATUS = keccak256(abi.encode("STATUS"));
    bytes32 public constant BANK = keccak256(abi.encode("BANK"));
    bytes32 public constant POOL = keccak256(abi.encode("POOL"));
    bytes32 public constant STRATEGIES = keccak256(abi.encode("STRATEGIES"));
    bytes32 public constant COLLATERAL_FACTOR = keccak256(abi.encode("COLLATERAL_FACTOR"));
    bytes32 public constant POSITIONS = keccak256(abi.encode("POSITIONS"));
    bytes32 public constant POSITIONS_OWNER = keccak256(abi.encode("POSITIONS_OWNER"));
    bytes32 public constant POSITIONS_START = keccak256(abi.encode("POSITIONS_START"));
    bytes32 public constant POSITIONS_STRATEGY = keccak256(abi.encode("POSITIONS_STRATEGY"));
    bytes32 public constant POSITIONS_TOKEN = keccak256(abi.encode("POSITIONS_TOKEN"));
    bytes32 public constant POSITIONS_COLLATERAL = keccak256(abi.encode("POSITIONS_COLLATERAL"));
    bytes32 public constant POSITIONS_BASIS = keccak256(abi.encode("POSITIONS_BASIS"));
    bytes32 public constant POSITIONS_SHARES = keccak256(abi.encode("POSITIONS_SHARES"));
    bytes32 public constant POSITIONS_BORROW = keccak256(abi.encode("POSITIONS_BORROW"));

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event Open(uint256 indexed id, uint256 borrow, uint256 collateral, uint256 strategy, address token);
    event Edit(uint256 indexed id, int256 borrow, int256 collateral);
    event Kill(uint256 indexed id, uint256 shares, uint256 borrow, uint256 collateral, uint256 amount, uint256 collateralUsed, uint256 fee);

    error NotOwner();
    error InvalidFile();
    error WrongStatus();
    error NoReentering();
    error Unauthorized();
    error TransferFailed();
    error UnknownStrategy();
    error UnknownCollateral();
    error InvalidParameters();
    error Undercollateralized();
    error NoEditingInSameBlock();
    error StrategyUninitialized();
    error PositionNotLiquidatable();

    struct Position {
        address owner;
        uint256 start;
        uint256 strategy;
        address token;
        uint256 collateral;
        uint256 borrow;
        uint256 shares;
        uint256 basis;
    }

    constructor(address _store, address _helper) {
        store = IStore(_store);
        helper = IHelper(_helper);
        exec[msg.sender] = true;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    modifier loop() {
        if (entered) revert NoReentering();
        entered = true;
        _;
        entered = false;
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") {
            exec[data] = !exec[data];
        } else if (what == "helper") {
            helper = IHelper(data);
            IPool pool = IPool(store.getAddress(POOL));
            address poolAsset = pool.asset();
            if (helper.price(poolAsset) == 0) revert InvalidFile();
        } else if (what == "strategyProxy") {
            strategyProxy = IStrategyProxy(data);
            if (!strategyProxy.exec(address(this))) revert InvalidFile();
        } else if (what == "bank") {
            store.setAddress(BANK, data);
            if (!IBank(data).exec(address(this))) revert InvalidFile();
        } else if (what == "pool") {
            store.setAddress(POOL, data);
            if (!IPool(data).exec(address(this))) revert InvalidFile();
            if (IPool(data).asset() == address(0)) revert InvalidFile();
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "slippage") {
            if (data > 1e18) revert InvalidFile();
            slippage = data;
        } else if (what == "performanceFee") {
            if (data > 0.5e18) revert InvalidFile();
            performanceFee = data;
        } else if (what == "killCollateralPadding") {
            if (data > 1e18) revert InvalidFile();
            killCollateralPadding = data;
        } else if (what == "closeCollateralPadding") {
            if (data > 1e18) revert InvalidFile();
            closeCollateralPadding = data;
        } else if (what == "status") {
            if (data == 0 || data > 4) revert InvalidFile();
            store.setUint(STATUS, data);
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function collect(address token) external auth {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function open(uint256 strategy, address token, uint256 collateral, uint256 borrow, bytes calldata data) external loop returns (uint256) {
        uint256 id = store.setUintDelta(POSITIONS, 1);
        lastBlock[id] = block.number;
        IStrategy s = IStrategy(store.getAddress(keccak256(abi.encode(strategy, STRATEGIES))));
        if (store.getUint(STATUS) < STATUS_LIVE) revert WrongStatus();
        if (address(s) == address(0)) revert UnknownStrategy();
        if (store.getUint(keccak256(abi.encode(token, COLLATERAL_FACTOR))) == 0) revert UnknownCollateral();

        Position memory p;
        p.owner = msg.sender;
        p.start = block.timestamp;
        p.strategy = strategy;
        p.token = token;
        p.collateral = collateral;

        {
            if (s.totalShares() == 0) revert StrategyUninitialized();
            IPool pool = IPool(store.getAddress(POOL));
            address poolAsset = pool.asset();
            pullToBank(token, msg.sender, collateral);
            p.borrow = pool.borrow(borrow);
            push(poolAsset, address(strategyProxy), borrow);
            p.shares = strategyProxy.mint(address(s), poolAsset, borrow, data);
            p.basis = s.rate(p.shares);
        }

        if (_life(p) < 1e18) revert Undercollateralized();
        setPosition(id, p);
        emit Open(id, borrow, collateral, strategy, token);
        return id;
    }

    function edit(uint256 id, int256 borrow, int256 collateral, bytes calldata data) external loop {
        IBank bank = IBank(store.getAddress(BANK));
        IPool pool = IPool(store.getAddress(POOL));
        address poolAsset = pool.asset();
        Position memory p = getPosition(id);
        IStrategy s = IStrategy(store.getAddress(keccak256(abi.encode(p.strategy, STRATEGIES))));
        if (p.owner != msg.sender) revert NotOwner();
        if (borrow < 0 && uint256(-borrow) > p.shares) revert InvalidParameters();
        if (borrow > 0 && p.shares == 0) revert InvalidParameters();
        if (collateral < 0 && uint256(-collateral) > p.collateral) revert InvalidParameters();
        if (lastBlock[id] == block.number) revert NoEditingInSameBlock();
        lastBlock[id] = block.number;
        {
            uint256 status = store.getUint(STATUS);
            if (borrow > 0 && status < STATUS_LIVE) revert WrongStatus();
            if (borrow <= 0 && status < STATUS_WITHDRAW) revert WrongStatus();
        }

        // 1. Adjust collateral
        if (collateral > 0) {
            pullToBank(p.token, msg.sender, uint256(collateral));
            p.collateral = p.collateral + uint256(collateral);
        }

        // 2. Sell strategy shares to repay loan
        if (borrow < 0) {
            p.basis = p.basis - min(p.basis, s.rate(uint256(-borrow)));
            uint256 amount = strategyProxy.burn(address(s), poolAsset, uint256(-borrow), data);
            p.shares = p.shares - uint256(-borrow);
            uint256 index = pool.getUpdatedIndex();
            uint256 repaying = amount * 1e18 / index;
            // If closing the position, make sure we repay the whole borrow
            if (p.shares == 0) {
                p.basis = 0;
                repaying = p.borrow;
                uint256 needed = p.borrow * index / 1e18;
                if (needed > amount) {
                    // If we don't have enough USDC from shares, sell some collateral
                    uint256 cAmount = helper.convert(poolAsset, p.token, needed - amount);
                    cAmount = cAmount * (10000 + closeCollateralPadding) / 10000;
                    if (cAmount > p.collateral) cAmount = p.collateral;
                    bank.transfer(p.token, address(this), cAmount);
                    IERC20(p.token).approve(address(helper), cAmount);
                    uint256 topup = helper.swap(p.token, poolAsset, cAmount, slippage, address(this));
                    amount = amount + topup;
                    p.collateral = p.collateral - cAmount;
                }
            }
            IERC20(poolAsset).approve(address(pool), amount);
            uint256 used = pool.repay(repaying);
            p.borrow = p.borrow - repaying;
            push(poolAsset, msg.sender, (amount - used) * (10000 - performanceFee) / 10000);
        }

        // 3. Borrow more from pool and mint strategy shares
        if (borrow > 0) {
            if (s.totalShares() == 0) revert StrategyUninitialized();
            p.borrow = p.borrow + pool.borrow(uint256(borrow));
            push(poolAsset, address(strategyProxy), uint256(borrow));
            uint256 shares = strategyProxy.mint(address(s), poolAsset, uint256(borrow), data);
            p.shares = p.shares + shares;
            p.basis = p.basis + s.rate(shares);
        }

        // 4. Withdraw collateral asked for
        if (collateral < 0) {
            uint256 amt = uint256(-collateral);
            // Allow a user to ask for all it's collateral but support some being taken away
            // as topup for the repayment of the debt
            if (amt > p.collateral) amt = p.collateral;
            p.collateral = p.collateral - amt;
            bank.transfer(p.token, msg.sender, amt);
        }

        if (_life(p) < 1e18) revert Undercollateralized();
        setPosition(id, p);
        emit Edit(id, borrow, collateral);
    }

    function kill(uint256 id, bytes calldata data) external loop {
        if (store.getUint(STATUS) < STATUS_LIQUIDATE) revert WrongStatus();
        IBank bank = IBank(store.getAddress(BANK));
        IPool pool = IPool(store.getAddress(POOL));
        address poolAsset = pool.asset();

        if (lastBlock[id] == block.number) revert NoEditingInSameBlock();
        lastBlock[id] = block.number;
        Position memory p = getPosition(id);
        uint256 l = _life(p);
        if (l >= 1e18) revert PositionNotLiquidatable();

        // Sell collateral to help cover the shortfall + fee
        address strategy = store.getAddress(keccak256(abi.encode(p.strategy, STRATEGIES)));
        uint256 amount = strategyProxy.burn(strategy, poolAsset, p.shares, data);
        uint256 needed = p.borrow * pool.getUpdatedIndex() / 1e18;
        needed = needed * (10000 + killCollateralPadding) / 10000;
        uint256 collateral = helper.convert(poolAsset, p.token, needed - amount);
        if (collateral > p.collateral) collateral = p.collateral;
        bank.transfer(p.token, address(this), collateral);
        IERC20(p.token).approve(address(helper), collateral);
        uint256 topup = helper.swap(p.token, poolAsset, collateral, slippage, address(this));
        amount = amount + topup;

        // Repay debt best we can
        IERC20(poolAsset).approve(address(pool), amount);
        uint256 used = pool.repay(p.borrow);

        // Distribute fee to keeper and update state
        push(poolAsset, msg.sender, (amount - used) / 2);
        p.collateral = p.collateral - collateral;
        p.shares = 0;
        p.borrow = 0;
        p.basis = 0;
        setPosition(id, p);

        emit Kill(id, p.shares, p.borrow, p.collateral, amount, collateral, amount - used);
    }

    function life(uint256 id) external view returns (uint256) {
        Position memory p = getPosition(id);
        return _life(p);
    }

    function _life(Position memory p) internal view returns (uint256) {
        if (p.borrow == 0) return 1e18;
        IStrategy s = IStrategy(store.getAddress(keccak256(abi.encode(p.strategy, STRATEGIES))));
        IPool pool = IPool(store.getAddress(POOL));
        IOracle oracle = IOracle(pool.oracle());
        uint256 factor = store.getUint(keccak256(abi.encode(p.token, COLLATERAL_FACTOR)));
        uint256 sharesValue = s.rate(p.shares);
        uint256 collateralValue = helper.value(p.token, p.collateral);
        uint256 value = (sharesValue + collateralValue) * factor / 1e18;
        uint256 price = (uint256(oracle.latestAnswer()) * 1e18) / (10 ** oracle.decimals());
        uint256 scaled = (p.borrow * 1e18) / (10 ** IERC20(pool.asset()).decimals());
        uint256 borrow = (scaled * pool.getUpdatedIndex() / 1e18) * price / 1e18;
        return value * 1e18 / borrow;
    }

    function getPosition(uint256 id) public view returns (Position memory p) {
        p.owner = store.getAddress(keccak256(abi.encode(id, POSITIONS_OWNER)));
        p.start = store.getUint(keccak256(abi.encode(id, POSITIONS_START)));
        p.strategy = store.getUint(keccak256(abi.encode(id, POSITIONS_STRATEGY)));
        p.token = store.getAddress(keccak256(abi.encode(id, POSITIONS_TOKEN)));
        p.collateral = store.getUint(keccak256(abi.encode(id, POSITIONS_COLLATERAL)));
        p.borrow = store.getUint(keccak256(abi.encode(id, POSITIONS_BORROW)));
        p.shares = store.getUint(keccak256(abi.encode(id, POSITIONS_SHARES)));
        p.basis = store.getUint(keccak256(abi.encode(id, POSITIONS_BASIS)));
    }

    function setPosition(uint256 id, Position memory p) internal {
        store.setAddress(keccak256(abi.encode(id, POSITIONS_OWNER)), p.owner);
        store.setUint(keccak256(abi.encode(id, POSITIONS_START)), p.start);
        store.setUint(keccak256(abi.encode(id, POSITIONS_STRATEGY)), p.strategy);
        store.setAddress(keccak256(abi.encode(id, POSITIONS_TOKEN)), p.token);
        store.setUint(keccak256(abi.encode(id, POSITIONS_COLLATERAL)), p.collateral);
        store.setUint(keccak256(abi.encode(id, POSITIONS_BORROW)), p.borrow);
        store.setUint(keccak256(abi.encode(id, POSITIONS_SHARES)), p.shares);
        store.setUint(keccak256(abi.encode(id, POSITIONS_BASIS)), p.basis);
    }

    function push(address asset, address user, uint256 amount) internal {
        if (amount == 0) return;
        if (!IERC20(asset).transfer(user, amount)) {
            revert TransferFailed();
        }
    }

    function pullToBank(address asset, address user, uint256 amount) internal {
        if (amount == 0) return;
        if (!IERC20(asset).transferFrom(user, store.getAddress(BANK), amount)) {
            revert TransferFailed();
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
