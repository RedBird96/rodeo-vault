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

// HelperMetaData contains all meta data concerning the Helper contract.
var HelperMetaData = &bind.MetaData{
	ABI: "[{\"name\":\"pool\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[{\"internalType\":\"address\",\"name\":\"pool\",\"type\":\"address\"}],\"outputs\":[{\"internalType\":\"bool\",\"name\":\"paused\",\"type\":\"bool\"},{\"internalType\":\"uint256\",\"name\":\"borrowMin\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"cap\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"shares\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"borrow\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"supply\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"rate\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"}]},{\"name\":\"rateModel\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[{\"internalType\":\"address\",\"name\":\"pool\",\"type\":\"address\"}],\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"kink\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"base\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"low\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"high\",\"type\":\"uint256\"}]},{\"name\":\"strategies\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[{\"internalType\":\"address\",\"name\":\"investor\",\"type\":\"address\"},{\"internalType\":\"uint256[]\",\"name\":\"indexes\",\"type\":\"uint256[]\"}],\"outputs\":[{\"internalType\":\"address[]\",\"name\":\"addresses\",\"type\":\"address[]\"},{\"internalType\":\"uint256[]\",\"name\":\"statuses\",\"type\":\"uint256[]\"},{\"internalType\":\"uint256[]\",\"name\":\"slippages\",\"type\":\"uint256[]\"},{\"internalType\":\"uint256[]\",\"name\":\"caps\",\"type\":\"uint256[]\"},{\"internalType\":\"uint256[]\",\"name\":\"tvls\",\"type\":\"uint256[]\"}]},{\"name\":\"peekPosition\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\"}],\"outputs\":[{\"internalType\":\"address\",\"name\":\"pool\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"strategy\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"shares\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"borrow\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"sharesValue\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"borrowValue\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"life\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"}]}]",
}

// HelperABI is the input ABI used to generate the binding from.
// Deprecated: Use HelperMetaData.ABI instead.
var HelperABI = HelperMetaData.ABI

// Helper is an auto generated Go binding around an Ethereum contract.
type Helper struct {
	HelperCaller     // Read-only binding to the contract
	HelperTransactor // Write-only binding to the contract
	HelperFilterer   // Log filterer for contract events
}

// HelperCaller is an auto generated read-only Go binding around an Ethereum contract.
type HelperCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// HelperTransactor is an auto generated write-only Go binding around an Ethereum contract.
type HelperTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// HelperFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type HelperFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// HelperSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type HelperSession struct {
	Contract     *Helper           // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// HelperCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type HelperCallerSession struct {
	Contract *HelperCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts // Call options to use throughout this session
}

// HelperTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type HelperTransactorSession struct {
	Contract     *HelperTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// HelperRaw is an auto generated low-level Go binding around an Ethereum contract.
type HelperRaw struct {
	Contract *Helper // Generic contract binding to access the raw methods on
}

// HelperCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type HelperCallerRaw struct {
	Contract *HelperCaller // Generic read-only contract binding to access the raw methods on
}

// HelperTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type HelperTransactorRaw struct {
	Contract *HelperTransactor // Generic write-only contract binding to access the raw methods on
}

// NewHelper creates a new instance of Helper, bound to a specific deployed contract.
func NewHelper(address common.Address, backend bind.ContractBackend) (*Helper, error) {
	contract, err := bindHelper(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Helper{HelperCaller: HelperCaller{contract: contract}, HelperTransactor: HelperTransactor{contract: contract}, HelperFilterer: HelperFilterer{contract: contract}}, nil
}

// NewHelperCaller creates a new read-only instance of Helper, bound to a specific deployed contract.
func NewHelperCaller(address common.Address, caller bind.ContractCaller) (*HelperCaller, error) {
	contract, err := bindHelper(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &HelperCaller{contract: contract}, nil
}

// NewHelperTransactor creates a new write-only instance of Helper, bound to a specific deployed contract.
func NewHelperTransactor(address common.Address, transactor bind.ContractTransactor) (*HelperTransactor, error) {
	contract, err := bindHelper(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &HelperTransactor{contract: contract}, nil
}

// NewHelperFilterer creates a new log filterer instance of Helper, bound to a specific deployed contract.
func NewHelperFilterer(address common.Address, filterer bind.ContractFilterer) (*HelperFilterer, error) {
	contract, err := bindHelper(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &HelperFilterer{contract: contract}, nil
}

// bindHelper binds a generic wrapper to an already deployed contract.
func bindHelper(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(HelperABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Helper *HelperRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Helper.Contract.HelperCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Helper *HelperRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Helper.Contract.HelperTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Helper *HelperRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Helper.Contract.HelperTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Helper *HelperCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Helper.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Helper *HelperTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Helper.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Helper *HelperTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Helper.Contract.contract.Transact(opts, method, params...)
}

// PeekPosition is a free data retrieval call binding the contract method 0x4875f049.
//
// Solidity: function peekPosition(uint256 index) view returns(address pool, uint256 strategy, uint256 shares, uint256 borrow, uint256 sharesValue, uint256 borrowValue, uint256 life, uint256 amount, uint256 price)
func (_Helper *HelperCaller) PeekPosition(opts *bind.CallOpts, index *big.Int) (struct {
	Pool        common.Address
	Strategy    *big.Int
	Shares      *big.Int
	Borrow      *big.Int
	SharesValue *big.Int
	BorrowValue *big.Int
	Life        *big.Int
	Amount      *big.Int
	Price       *big.Int
}, error) {
	var out []interface{}
	err := _Helper.contract.Call(opts, &out, "peekPosition", index)

	outstruct := new(struct {
		Pool        common.Address
		Strategy    *big.Int
		Shares      *big.Int
		Borrow      *big.Int
		SharesValue *big.Int
		BorrowValue *big.Int
		Life        *big.Int
		Amount      *big.Int
		Price       *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Pool = *abi.ConvertType(out[0], new(common.Address)).(*common.Address)
	outstruct.Strategy = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.Shares = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.Borrow = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.SharesValue = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)
	outstruct.BorrowValue = *abi.ConvertType(out[5], new(*big.Int)).(**big.Int)
	outstruct.Life = *abi.ConvertType(out[6], new(*big.Int)).(**big.Int)
	outstruct.Amount = *abi.ConvertType(out[7], new(*big.Int)).(**big.Int)
	outstruct.Price = *abi.ConvertType(out[8], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// PeekPosition is a free data retrieval call binding the contract method 0x4875f049.
//
// Solidity: function peekPosition(uint256 index) view returns(address pool, uint256 strategy, uint256 shares, uint256 borrow, uint256 sharesValue, uint256 borrowValue, uint256 life, uint256 amount, uint256 price)
func (_Helper *HelperSession) PeekPosition(index *big.Int) (struct {
	Pool        common.Address
	Strategy    *big.Int
	Shares      *big.Int
	Borrow      *big.Int
	SharesValue *big.Int
	BorrowValue *big.Int
	Life        *big.Int
	Amount      *big.Int
	Price       *big.Int
}, error) {
	return _Helper.Contract.PeekPosition(&_Helper.CallOpts, index)
}

// PeekPosition is a free data retrieval call binding the contract method 0x4875f049.
//
// Solidity: function peekPosition(uint256 index) view returns(address pool, uint256 strategy, uint256 shares, uint256 borrow, uint256 sharesValue, uint256 borrowValue, uint256 life, uint256 amount, uint256 price)
func (_Helper *HelperCallerSession) PeekPosition(index *big.Int) (struct {
	Pool        common.Address
	Strategy    *big.Int
	Shares      *big.Int
	Borrow      *big.Int
	SharesValue *big.Int
	BorrowValue *big.Int
	Life        *big.Int
	Amount      *big.Int
	Price       *big.Int
}, error) {
	return _Helper.Contract.PeekPosition(&_Helper.CallOpts, index)
}

// Pool is a free data retrieval call binding the contract method 0x156522a8.
//
// Solidity: function pool(address pool) view returns(bool paused, uint256 borrowMin, uint256 cap, uint256 index, uint256 shares, uint256 borrow, uint256 supply, uint256 rate, uint256 price)
func (_Helper *HelperCaller) Pool(opts *bind.CallOpts, pool common.Address) (struct {
	Paused    bool
	BorrowMin *big.Int
	Cap       *big.Int
	Index     *big.Int
	Shares    *big.Int
	Borrow    *big.Int
	Supply    *big.Int
	Rate      *big.Int
	Price     *big.Int
}, error) {
	var out []interface{}
	err := _Helper.contract.Call(opts, &out, "pool", pool)

	outstruct := new(struct {
		Paused    bool
		BorrowMin *big.Int
		Cap       *big.Int
		Index     *big.Int
		Shares    *big.Int
		Borrow    *big.Int
		Supply    *big.Int
		Rate      *big.Int
		Price     *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Paused = *abi.ConvertType(out[0], new(bool)).(*bool)
	outstruct.BorrowMin = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.Cap = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.Index = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)
	outstruct.Shares = *abi.ConvertType(out[4], new(*big.Int)).(**big.Int)
	outstruct.Borrow = *abi.ConvertType(out[5], new(*big.Int)).(**big.Int)
	outstruct.Supply = *abi.ConvertType(out[6], new(*big.Int)).(**big.Int)
	outstruct.Rate = *abi.ConvertType(out[7], new(*big.Int)).(**big.Int)
	outstruct.Price = *abi.ConvertType(out[8], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// Pool is a free data retrieval call binding the contract method 0x156522a8.
//
// Solidity: function pool(address pool) view returns(bool paused, uint256 borrowMin, uint256 cap, uint256 index, uint256 shares, uint256 borrow, uint256 supply, uint256 rate, uint256 price)
func (_Helper *HelperSession) Pool(pool common.Address) (struct {
	Paused    bool
	BorrowMin *big.Int
	Cap       *big.Int
	Index     *big.Int
	Shares    *big.Int
	Borrow    *big.Int
	Supply    *big.Int
	Rate      *big.Int
	Price     *big.Int
}, error) {
	return _Helper.Contract.Pool(&_Helper.CallOpts, pool)
}

// Pool is a free data retrieval call binding the contract method 0x156522a8.
//
// Solidity: function pool(address pool) view returns(bool paused, uint256 borrowMin, uint256 cap, uint256 index, uint256 shares, uint256 borrow, uint256 supply, uint256 rate, uint256 price)
func (_Helper *HelperCallerSession) Pool(pool common.Address) (struct {
	Paused    bool
	BorrowMin *big.Int
	Cap       *big.Int
	Index     *big.Int
	Shares    *big.Int
	Borrow    *big.Int
	Supply    *big.Int
	Rate      *big.Int
	Price     *big.Int
}, error) {
	return _Helper.Contract.Pool(&_Helper.CallOpts, pool)
}

// RateModel is a free data retrieval call binding the contract method 0x0d806000.
//
// Solidity: function rateModel(address pool) view returns(uint256 kink, uint256 base, uint256 low, uint256 high)
func (_Helper *HelperCaller) RateModel(opts *bind.CallOpts, pool common.Address) (struct {
	Kink *big.Int
	Base *big.Int
	Low  *big.Int
	High *big.Int
}, error) {
	var out []interface{}
	err := _Helper.contract.Call(opts, &out, "rateModel", pool)

	outstruct := new(struct {
		Kink *big.Int
		Base *big.Int
		Low  *big.Int
		High *big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Kink = *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)
	outstruct.Base = *abi.ConvertType(out[1], new(*big.Int)).(**big.Int)
	outstruct.Low = *abi.ConvertType(out[2], new(*big.Int)).(**big.Int)
	outstruct.High = *abi.ConvertType(out[3], new(*big.Int)).(**big.Int)

	return *outstruct, err

}

// RateModel is a free data retrieval call binding the contract method 0x0d806000.
//
// Solidity: function rateModel(address pool) view returns(uint256 kink, uint256 base, uint256 low, uint256 high)
func (_Helper *HelperSession) RateModel(pool common.Address) (struct {
	Kink *big.Int
	Base *big.Int
	Low  *big.Int
	High *big.Int
}, error) {
	return _Helper.Contract.RateModel(&_Helper.CallOpts, pool)
}

// RateModel is a free data retrieval call binding the contract method 0x0d806000.
//
// Solidity: function rateModel(address pool) view returns(uint256 kink, uint256 base, uint256 low, uint256 high)
func (_Helper *HelperCallerSession) RateModel(pool common.Address) (struct {
	Kink *big.Int
	Base *big.Int
	Low  *big.Int
	High *big.Int
}, error) {
	return _Helper.Contract.RateModel(&_Helper.CallOpts, pool)
}

// Strategies is a free data retrieval call binding the contract method 0x7a71f544.
//
// Solidity: function strategies(address investor, uint256[] indexes) view returns(address[] addresses, uint256[] statuses, uint256[] slippages, uint256[] caps, uint256[] tvls)
func (_Helper *HelperCaller) Strategies(opts *bind.CallOpts, investor common.Address, indexes []*big.Int) (struct {
	Addresses []common.Address
	Statuses  []*big.Int
	Slippages []*big.Int
	Caps      []*big.Int
	Tvls      []*big.Int
}, error) {
	var out []interface{}
	err := _Helper.contract.Call(opts, &out, "strategies", investor, indexes)

	outstruct := new(struct {
		Addresses []common.Address
		Statuses  []*big.Int
		Slippages []*big.Int
		Caps      []*big.Int
		Tvls      []*big.Int
	})
	if err != nil {
		return *outstruct, err
	}

	outstruct.Addresses = *abi.ConvertType(out[0], new([]common.Address)).(*[]common.Address)
	outstruct.Statuses = *abi.ConvertType(out[1], new([]*big.Int)).(*[]*big.Int)
	outstruct.Slippages = *abi.ConvertType(out[2], new([]*big.Int)).(*[]*big.Int)
	outstruct.Caps = *abi.ConvertType(out[3], new([]*big.Int)).(*[]*big.Int)
	outstruct.Tvls = *abi.ConvertType(out[4], new([]*big.Int)).(*[]*big.Int)

	return *outstruct, err

}

// Strategies is a free data retrieval call binding the contract method 0x7a71f544.
//
// Solidity: function strategies(address investor, uint256[] indexes) view returns(address[] addresses, uint256[] statuses, uint256[] slippages, uint256[] caps, uint256[] tvls)
func (_Helper *HelperSession) Strategies(investor common.Address, indexes []*big.Int) (struct {
	Addresses []common.Address
	Statuses  []*big.Int
	Slippages []*big.Int
	Caps      []*big.Int
	Tvls      []*big.Int
}, error) {
	return _Helper.Contract.Strategies(&_Helper.CallOpts, investor, indexes)
}

// Strategies is a free data retrieval call binding the contract method 0x7a71f544.
//
// Solidity: function strategies(address investor, uint256[] indexes) view returns(address[] addresses, uint256[] statuses, uint256[] slippages, uint256[] caps, uint256[] tvls)
func (_Helper *HelperCallerSession) Strategies(investor common.Address, indexes []*big.Int) (struct {
	Addresses []common.Address
	Statuses  []*big.Int
	Slippages []*big.Int
	Caps      []*big.Int
	Tvls      []*big.Int
}, error) {
	return _Helper.Contract.Strategies(&_Helper.CallOpts, investor, indexes)
}
