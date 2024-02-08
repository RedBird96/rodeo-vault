package main

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
)

// VaultLogicMetaData contains all meta data concerning the VaultLogic contract.
var VaultLogicMetaData = &bind.MetaData{
	ABI: "[{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"address\",\"name\":\"previousAdmin\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"address\",\"name\":\"newAdmin\",\"type\":\"address\"}],\"name\":\"AdminChanged\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"beacon\",\"type\":\"address\"}],\"name\":\"BeaconUpgraded\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"repayAmount\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"withdrawAmount\",\"type\":\"uint256\"}],\"name\":\"Deleverage\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_amount\",\"type\":\"uint256\"}],\"name\":\"Deposit\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint8\",\"name\":\"version\",\"type\":\"uint8\"}],\"name\":\"Initialized\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"debitAmount\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"borrowAmount\",\"type\":\"uint256\"}],\"name\":\"Leverage\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"previousOwner\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"newOwner\",\"type\":\"address\"}],\"name\":\"OwnershipTransferred\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\"}],\"name\":\"Paused\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\"}],\"name\":\"Unpaused\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"newExchangePrice\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"newRevenue\",\"type\":\"uint256\"}],\"name\":\"UpdateExchangePrice\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"implementation\",\"type\":\"address\"}],\"name\":\"Upgraded\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"_amount\",\"type\":\"uint256\"}],\"name\":\"Withdraw\",\"type\":\"event\"},{\"inputs\":[],\"name\":\"AAVE_ORACLE_V3\",\"outputs\":[{\"internalType\":\"contract IAaveOracle\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"AAVE_POOL_V3\",\"outputs\":[{\"internalType\":\"contract IPoolV3\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"A_WSTETH_ADDR_AAVEV3\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"D_WETH_ADDR_AAVEV3\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"ETH_ADDR\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"MAX_SAFE_AGGREGATED_RATIO\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"MINIMUM_AMOUNT\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"MIN_SAFE_AGGREGATED_RATIO\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"PERMISSIBLE_LIMIT\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"WETH_ADDR\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"WSTETH_ADDR\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_vault\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"_lendingLogic\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"_flashloanHelper\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"_safeAggregatedRatio\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_safeRatio\",\"type\":\"uint256\"}],\"name\":\"__Strategy_init\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_admin\",\"type\":\"address\"}],\"name\":\"addAdmin\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_stETHWithdrawAmount\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_wEthDebtDeleverageAmount\",\"type\":\"uint256\"},{\"internalType\":\"bytes\",\"name\":\"_swapData\",\"type\":\"bytes\"},{\"internalType\":\"uint256\",\"name\":\"_minimumAmount\",\"type\":\"uint256\"}],\"name\":\"deleverage\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_amount\",\"type\":\"uint256\"}],\"name\":\"deposit\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"operateExchangePrice\",\"type\":\"uint256\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"exchangePrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"flashloanHelper\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_token\",\"type\":\"address\"}],\"name\":\"getAssestPrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getAvailableLogicBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"balance\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getNetAssets\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getProtocolCollateralRatio\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"collateralRatio\",\"type\":\"uint256\"},{\"internalType\":\"bool\",\"name\":\"isOK\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getProtocolNetAssets\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"net\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getProtocolRatio\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"ratio\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"lendingLogic\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_stETHDepositAmount\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_wEthDebtAmount\",\"type\":\"uint256\"},{\"internalType\":\"bytes\",\"name\":\"_swapData\",\"type\":\"bytes\"},{\"internalType\":\"uint256\",\"name\":\"_minimumAmount\",\"type\":\"uint256\"}],\"name\":\"leverage\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"logicDepositAmount\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"logicWithdrawAmount\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_initiator\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"_token\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"_amount\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_fee\",\"type\":\"uint256\"},{\"internalType\":\"bytes\",\"name\":\"_params\",\"type\":\"bytes\"}],\"name\":\"onFlashLoanOne\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"oneInchRouter\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"owner\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"paused\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"proxiableUUID\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_admin\",\"type\":\"address\"}],\"name\":\"removeAdmin\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"renounceOwnership\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"revenue\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"revenueExchangePrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"revenueRate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"safeAggregatedRatio\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"safeRatio\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newOwner\",\"type\":\"address\"}],\"name\":\"transferOwnership\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"updateExchangePrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"newExchangePrice\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"newRevenue\",\"type\":\"uint256\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"_newFlashloanHelper\",\"type\":\"address\"}],\"name\":\"updateFlashloanHelper\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_safeAggregatorRatio\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"_safeRatio\",\"type\":\"uint256\"}],\"name\":\"updateSafeRatio\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newImplementation\",\"type\":\"address\"}],\"name\":\"upgradeTo\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"newImplementation\",\"type\":\"address\"},{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\"}],\"name\":\"upgradeToAndCall\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"vault\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_amount\",\"type\":\"uint256\"}],\"name\":\"withdraw\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"withdrawAmount\",\"type\":\"uint256\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]",
}

// VaultLogicABI is the input ABI used to generate the binding from.
// Deprecated: Use VaultLogicMetaData.ABI instead.
var VaultLogicABI = VaultLogicMetaData.ABI

// VaultLogic is an auto generated Go binding around an Ethereum contract.
type VaultLogic struct {
	VaultLogicCaller     // Read-only binding to the contract
	VaultLogicTransactor // Write-only binding to the contract
	VaultLogicFilterer   // Log filterer for contract events
}

// VaultLogicCaller is an auto generated read-only Go binding around an Ethereum contract.
type VaultLogicCaller struct {
	contract *bind.BoundContract
}

// VaultLogicTransactor is an auto generated write-only Go binding around an Ethereum contract.
type VaultLogicTransactor struct {
	contract *bind.BoundContract
}

// VaultLogicFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type VaultLogicFilterer struct {
	contract *bind.BoundContract
}

type VaultLogicSession struct {
	Contract     *VaultLogic
	CallOpts     bind.CallOpts
	TransactOpts bind.TransactOpts
}

type VaultLogicCallerSession struct {
	Contract *VaultLogicCaller
	CallOpts bind.CallOpts
}

type VaultLogicTransactorSession struct {
	Contract     *VaultLogicTransactor
	TransactOpts bind.TransactOpts
}

// VaultLogicRaw is an auto generated low-level Go binding around an Ethereum contract.
type VaultLogicRaw struct {
	Contract *VaultLogic // Generic contract binding to access the raw methods on
}

// VaultLogicCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type VaultLogicCallerRaw struct {
	Contract *VaultLogicCaller // Generic read-only contract binding to access the raw methods on
}

// VaultLogicTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type VaultLogicTransactorRaw struct {
	Contract *VaultLogicTransactor // Generic write-only contract binding to access the raw methods on
}

// NewVaultLogic creates a new instance of VaultLogic, bound to a specific deployed contract.
func NewVaultLogic(address common.Address, backend bind.ContractBackend) (*VaultLogic, error) {
	contract, err := bindVaultLogic(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &VaultLogic{VaultLogicCaller: VaultLogicCaller{contract: contract}, VaultLogicTransactor: VaultLogicTransactor{contract: contract}, VaultLogicFilterer: VaultLogicFilterer{contract: contract}}, nil
}

// NewVaultLogicCaller creates a new read-only instance of Strategy, bound to a specific deployed contract.
func NewVaultLogicCaller(address common.Address, caller bind.ContractCaller) (*VaultLogicCaller, error) {
	contract, err := bindVaultLogic(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &VaultLogicCaller{contract: contract}, nil
}

// NewVaultLogicTransactor creates a new write-only instance of Strategy, bound to a specific deployed contract.
func NewVaultLogicTransactor(address common.Address, transactor bind.ContractTransactor) (*VaultLogicTransactor, error) {
	contract, err := bindVaultLogic(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &VaultLogicTransactor{contract: contract}, nil
}

// NewVaultLogicFilterer creates a new log filterer instance of Strategy, bound to a specific deployed contract.
func NewVaultLogicFilterer(address common.Address, filterer bind.ContractFilterer) (*VaultLogicFilterer, error) {
	contract, err := bindVaultLogic(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &VaultLogicFilterer{contract: contract}, nil
}

// bindVaultLogic binds a generic wrapper to an already deployed contract.
func bindVaultLogic(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(VaultLogicABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_VaultLogic *VaultLogicRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _VaultLogic.Contract.VaultLogicCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_VaultLogic *VaultLogicRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _VaultLogic.Contract.VaultLogicTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_VaultLogic *VaultLogicRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _VaultLogic.Contract.VaultLogicTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_VaultLogic *VaultLogicCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _VaultLogic.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_VaultLogic *VaultLogicTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _VaultLogic.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_VaultLogic *VaultLogicTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _VaultLogic.Contract.contract.Transact(opts, method, params...)
}

// Solidity: function getNetAssets() public view returns(uint256,uint256,uint256,uint256)
func (_VaultLogic *VaultLogicCaller) Collateral(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _VaultLogic.contract.Call(opts, &out, "getNetAssets")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err
}

func (_VaultLogic *VaultLogicSession) Collateral() (*big.Int, error) {
	return _VaultLogic.Contract.Collateral(&_VaultLogic.CallOpts)
}

func (_VaultLogic *VaultLogicCallerSession) Collateral() (*big.Int, error) {
	return _VaultLogic.Contract.Collateral(&_VaultLogic.CallOpts)
}

// function getAvailableLogicBalance() external returns (uint256)
func (_VaultLogic *VaultLogicCaller) AvailableLogicAmount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}

	err := _VaultLogic.contract.Call(opts, &out, "getAvailableLogicBalance")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// function getAvailableLogicBalance() external returns (uint256)
func (_VaultLogic *VaultLogicSession) AvailableLogicAmount() (*big.Int, error) {
	return _VaultLogic.Contract.AvailableLogicAmount(&_VaultLogic.CallOpts)
}

// function getAvailableLogicBalance() external returns (uint256)
func (_VaultLogic *VaultLogicCallerSession) AvailableLogicAmount() (*big.Int, error) {
	return _VaultLogic.Contract.AvailableLogicAmount(&_VaultLogic.CallOpts)
}

// Solidity: function leverage(uint8, uint256, uint256, bytes calldata, uint256) returns()
func (_VaultLogic *VaultLogicTransactor) Leverage(opts *bind.TransactOpts, depositAmount *big.Int, debitAmount *big.Int, data []byte, miniAmount *big.Int) (*types.Transaction, error) {
	return _VaultLogic.contract.Transact(opts, "leverage", depositAmount, debitAmount, data, miniAmount)
}

// Solidity: function leverage(uint8, uint256, uint256, bytes calldata, uint256) returns()
func (_VaultLogic *VaultLogicSession) Leverage(depositAmount *big.Int, debitAmount *big.Int, data []byte, miniAmount *big.Int) (*types.Transaction, error) {
	return _VaultLogic.Contract.Leverage(&_VaultLogic.TransactOpts, depositAmount, debitAmount, data, miniAmount)
}

// Solidity: function leverage(uint8, uint256, uint256, bytes calldata, uint256) returns()
func (_VaultLogic *VaultLogicTransactorSession) Leverage(depositAmount *big.Int, debitAmount *big.Int, data []byte, miniAmount *big.Int) (*types.Transaction, error) {
	return _VaultLogic.Contract.Leverage(&_VaultLogic.TransactOpts, depositAmount, debitAmount, data, miniAmount)
}

// Solidity: function deleverage(uint8, uint256, uint256, bytes calldata, uint256) returns()
func (_VaultLogic *VaultLogicTransactor) Deleverage(opts *bind.TransactOpts, depositAmount *big.Int, debitAmount *big.Int, data []byte, miniAmount *big.Int) (*types.Transaction, error) {
	return _VaultLogic.contract.Transact(opts, "deleverage", depositAmount, debitAmount, data, miniAmount)
}

// Solidity: function leverage() returns()
func (_VaultLogic *VaultLogicSession) Deleverage(depositAmount *big.Int, debitAmount *big.Int, data []byte, miniAmount *big.Int) (*types.Transaction, error) {
	return _VaultLogic.Contract.Deleverage(&_VaultLogic.TransactOpts, depositAmount, debitAmount, data, miniAmount)
}

// Solidity: function leverage() returns()
func (_VaultLogic *VaultLogicTransactorSession) Deleverage(depositAmount *big.Int, debitAmount *big.Int, data []byte, miniAmount *big.Int) (*types.Transaction, error) {
	return _VaultLogic.Contract.Deleverage(&_VaultLogic.TransactOpts, depositAmount, debitAmount, data, miniAmount)
}

func (_VaultLogic *VaultLogicCaller) TotalLockedAmount(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _VaultLogic.contract.Call(opts, &out, "totalLockedAmount")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

func (_VaultLogic *VaultLogicCaller) GetAssestPrice(opts *bind.CallOpts, token *common.Address) (*big.Int, error) {
	var out []interface{}
	err := _VaultLogic.contract.Call(opts, &out, "getAssestPrice", token)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Solidity: function leverage(uint8, uint256, uint256, bytes calldata, uint256) returns()
func (_VaultLogic *VaultLogicTransactor) UpdateExchangePrice(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _VaultLogic.contract.Transact(opts, "updateExchangePrice")
}
