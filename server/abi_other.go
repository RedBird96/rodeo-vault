// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

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

// OtherMetaData contains all meta data concerning the Other contract.
var OtherMetaData = &bind.MetaData{
	ABI: "[{\"name\":\"totalSupply\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[],\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}]},{\"name\":\"balanceOf\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[{\"internalType\":\"address\",\"name\":\"user\",\"type\":\"address\"}],\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}]},{\"name\":\"rate\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[],\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}]},{\"name\":\"getAumInUsdg\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[{\"internalType\":\"bool\",\"name\":\"maximise\",\"type\":\"bool\"}],\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}]},{\"name\":\"latestAnswer\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[],\"outputs\":[{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\"}]},{\"name\":\"plsPerSecond\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[],\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}]},{\"name\":\"tokensPerInterval\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[],\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}]},{\"name\":\"pool\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[],\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}]},{\"name\":\"nftPool\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[],\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}]}]",
}

// OtherABI is the input ABI used to generate the binding from.
// Deprecated: Use OtherMetaData.ABI instead.
var OtherABI = OtherMetaData.ABI

// Other is an auto generated Go binding around an Ethereum contract.
type Other struct {
	OtherCaller     // Read-only binding to the contract
	OtherTransactor // Write-only binding to the contract
	OtherFilterer   // Log filterer for contract events
}

// OtherCaller is an auto generated read-only Go binding around an Ethereum contract.
type OtherCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// OtherTransactor is an auto generated write-only Go binding around an Ethereum contract.
type OtherTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// OtherFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type OtherFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// OtherSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type OtherSession struct {
	Contract     *Other            // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// OtherCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type OtherCallerSession struct {
	Contract *OtherCaller  // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts // Call options to use throughout this session
}

// OtherTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type OtherTransactorSession struct {
	Contract     *OtherTransactor  // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// OtherRaw is an auto generated low-level Go binding around an Ethereum contract.
type OtherRaw struct {
	Contract *Other // Generic contract binding to access the raw methods on
}

// OtherCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type OtherCallerRaw struct {
	Contract *OtherCaller // Generic read-only contract binding to access the raw methods on
}

// OtherTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type OtherTransactorRaw struct {
	Contract *OtherTransactor // Generic write-only contract binding to access the raw methods on
}

// NewOther creates a new instance of Other, bound to a specific deployed contract.
func NewOther(address common.Address, backend bind.ContractBackend) (*Other, error) {
	contract, err := bindOther(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Other{OtherCaller: OtherCaller{contract: contract}, OtherTransactor: OtherTransactor{contract: contract}, OtherFilterer: OtherFilterer{contract: contract}}, nil
}

// NewOtherCaller creates a new read-only instance of Other, bound to a specific deployed contract.
func NewOtherCaller(address common.Address, caller bind.ContractCaller) (*OtherCaller, error) {
	contract, err := bindOther(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &OtherCaller{contract: contract}, nil
}

// NewOtherTransactor creates a new write-only instance of Other, bound to a specific deployed contract.
func NewOtherTransactor(address common.Address, transactor bind.ContractTransactor) (*OtherTransactor, error) {
	contract, err := bindOther(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &OtherTransactor{contract: contract}, nil
}

// NewOtherFilterer creates a new log filterer instance of Other, bound to a specific deployed contract.
func NewOtherFilterer(address common.Address, filterer bind.ContractFilterer) (*OtherFilterer, error) {
	contract, err := bindOther(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &OtherFilterer{contract: contract}, nil
}

// bindOther binds a generic wrapper to an already deployed contract.
func bindOther(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(OtherABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Other *OtherRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Other.Contract.OtherCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Other *OtherRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Other.Contract.OtherTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Other *OtherRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Other.Contract.OtherTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Other *OtherCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Other.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Other *OtherTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Other.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Other *OtherTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Other.Contract.contract.Transact(opts, method, params...)
}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address user) view returns(uint256)
func (_Other *OtherCaller) BalanceOf(opts *bind.CallOpts, user common.Address) (*big.Int, error) {
	var out []interface{}
	err := _Other.contract.Call(opts, &out, "balanceOf", user)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address user) view returns(uint256)
func (_Other *OtherSession) BalanceOf(user common.Address) (*big.Int, error) {
	return _Other.Contract.BalanceOf(&_Other.CallOpts, user)
}

// BalanceOf is a free data retrieval call binding the contract method 0x70a08231.
//
// Solidity: function balanceOf(address user) view returns(uint256)
func (_Other *OtherCallerSession) BalanceOf(user common.Address) (*big.Int, error) {
	return _Other.Contract.BalanceOf(&_Other.CallOpts, user)
}

// GetAumInUsdg is a free data retrieval call binding the contract method 0x68a0a3e0.
//
// Solidity: function getAumInUsdg(bool maximise) view returns(uint256)
func (_Other *OtherCaller) GetAumInUsdg(opts *bind.CallOpts, maximise bool) (*big.Int, error) {
	var out []interface{}
	err := _Other.contract.Call(opts, &out, "getAumInUsdg", maximise)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// GetAumInUsdg is a free data retrieval call binding the contract method 0x68a0a3e0.
//
// Solidity: function getAumInUsdg(bool maximise) view returns(uint256)
func (_Other *OtherSession) GetAumInUsdg(maximise bool) (*big.Int, error) {
	return _Other.Contract.GetAumInUsdg(&_Other.CallOpts, maximise)
}

// GetAumInUsdg is a free data retrieval call binding the contract method 0x68a0a3e0.
//
// Solidity: function getAumInUsdg(bool maximise) view returns(uint256)
func (_Other *OtherCallerSession) GetAumInUsdg(maximise bool) (*big.Int, error) {
	return _Other.Contract.GetAumInUsdg(&_Other.CallOpts, maximise)
}

// LatestAnswer is a free data retrieval call binding the contract method 0x50d25bcd.
//
// Solidity: function latestAnswer() view returns(int256)
func (_Other *OtherCaller) LatestAnswer(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Other.contract.Call(opts, &out, "latestAnswer")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// LatestAnswer is a free data retrieval call binding the contract method 0x50d25bcd.
//
// Solidity: function latestAnswer() view returns(int256)
func (_Other *OtherSession) LatestAnswer() (*big.Int, error) {
	return _Other.Contract.LatestAnswer(&_Other.CallOpts)
}

// LatestAnswer is a free data retrieval call binding the contract method 0x50d25bcd.
//
// Solidity: function latestAnswer() view returns(int256)
func (_Other *OtherCallerSession) LatestAnswer() (*big.Int, error) {
	return _Other.Contract.LatestAnswer(&_Other.CallOpts)
}

// NftPool is a free data retrieval call binding the contract method 0x0828862d.
//
// Solidity: function nftPool() view returns(address)
func (_Other *OtherCaller) NftPool(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Other.contract.Call(opts, &out, "nftPool")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// NftPool is a free data retrieval call binding the contract method 0x0828862d.
//
// Solidity: function nftPool() view returns(address)
func (_Other *OtherSession) NftPool() (common.Address, error) {
	return _Other.Contract.NftPool(&_Other.CallOpts)
}

// NftPool is a free data retrieval call binding the contract method 0x0828862d.
//
// Solidity: function nftPool() view returns(address)
func (_Other *OtherCallerSession) NftPool() (common.Address, error) {
	return _Other.Contract.NftPool(&_Other.CallOpts)
}

// PlsPerSecond is a free data retrieval call binding the contract method 0x7de35002.
//
// Solidity: function plsPerSecond() view returns(uint256)
func (_Other *OtherCaller) PlsPerSecond(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Other.contract.Call(opts, &out, "plsPerSecond")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// PlsPerSecond is a free data retrieval call binding the contract method 0x7de35002.
//
// Solidity: function plsPerSecond() view returns(uint256)
func (_Other *OtherSession) PlsPerSecond() (*big.Int, error) {
	return _Other.Contract.PlsPerSecond(&_Other.CallOpts)
}

// PlsPerSecond is a free data retrieval call binding the contract method 0x7de35002.
//
// Solidity: function plsPerSecond() view returns(uint256)
func (_Other *OtherCallerSession) PlsPerSecond() (*big.Int, error) {
	return _Other.Contract.PlsPerSecond(&_Other.CallOpts)
}

// Pool is a free data retrieval call binding the contract method 0x16f0115b.
//
// Solidity: function pool() view returns(address)
func (_Other *OtherCaller) Pool(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Other.contract.Call(opts, &out, "pool")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Pool is a free data retrieval call binding the contract method 0x16f0115b.
//
// Solidity: function pool() view returns(address)
func (_Other *OtherSession) Pool() (common.Address, error) {
	return _Other.Contract.Pool(&_Other.CallOpts)
}

// Pool is a free data retrieval call binding the contract method 0x16f0115b.
//
// Solidity: function pool() view returns(address)
func (_Other *OtherCallerSession) Pool() (common.Address, error) {
	return _Other.Contract.Pool(&_Other.CallOpts)
}

// Rate is a free data retrieval call binding the contract method 0x2c4e722e.
//
// Solidity: function rate() view returns(uint256)
func (_Other *OtherCaller) Rate(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Other.contract.Call(opts, &out, "rate")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Rate is a free data retrieval call binding the contract method 0x2c4e722e.
//
// Solidity: function rate() view returns(uint256)
func (_Other *OtherSession) Rate() (*big.Int, error) {
	return _Other.Contract.Rate(&_Other.CallOpts)
}

// Rate is a free data retrieval call binding the contract method 0x2c4e722e.
//
// Solidity: function rate() view returns(uint256)
func (_Other *OtherCallerSession) Rate() (*big.Int, error) {
	return _Other.Contract.Rate(&_Other.CallOpts)
}

// TokensPerInterval is a free data retrieval call binding the contract method 0xa8d93627.
//
// Solidity: function tokensPerInterval() view returns(uint256)
func (_Other *OtherCaller) TokensPerInterval(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Other.contract.Call(opts, &out, "tokensPerInterval")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TokensPerInterval is a free data retrieval call binding the contract method 0xa8d93627.
//
// Solidity: function tokensPerInterval() view returns(uint256)
func (_Other *OtherSession) TokensPerInterval() (*big.Int, error) {
	return _Other.Contract.TokensPerInterval(&_Other.CallOpts)
}

// TokensPerInterval is a free data retrieval call binding the contract method 0xa8d93627.
//
// Solidity: function tokensPerInterval() view returns(uint256)
func (_Other *OtherCallerSession) TokensPerInterval() (*big.Int, error) {
	return _Other.Contract.TokensPerInterval(&_Other.CallOpts)
}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_Other *OtherCaller) TotalSupply(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Other.contract.Call(opts, &out, "totalSupply")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_Other *OtherSession) TotalSupply() (*big.Int, error) {
	return _Other.Contract.TotalSupply(&_Other.CallOpts)
}

// TotalSupply is a free data retrieval call binding the contract method 0x18160ddd.
//
// Solidity: function totalSupply() view returns(uint256)
func (_Other *OtherCallerSession) TotalSupply() (*big.Int, error) {
	return _Other.Contract.TotalSupply(&_Other.CallOpts)
}
