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

// StrategyMetaData contains all meta data concerning the Strategy contract.
var StrategyMetaData = &bind.MetaData{
	ABI: "[{\"name\":\"Earn\",\"type\":\"event\",\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"tvl\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"profit\",\"type\":\"uint256\"}]},{\"inputs\":[],\"name\":\"earn\",\"outputs\":[],\"type\":\"function\"},{\"inputs\":[],\"name\":\"cap\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"name\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"sha\",\"type\":\"uint256\"}],\"name\":\"rate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"slippage\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"status\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"totalShares\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"}]",
}

// StrategyABI is the input ABI used to generate the binding from.
// Deprecated: Use StrategyMetaData.ABI instead.
var StrategyABI = StrategyMetaData.ABI

// Strategy is an auto generated Go binding around an Ethereum contract.
type Strategy struct {
	StrategyCaller     // Read-only binding to the contract
	StrategyTransactor // Write-only binding to the contract
	StrategyFilterer   // Log filterer for contract events
}

// StrategyCaller is an auto generated read-only Go binding around an Ethereum contract.
type StrategyCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// StrategyTransactor is an auto generated write-only Go binding around an Ethereum contract.
type StrategyTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// StrategyFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type StrategyFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// StrategySession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type StrategySession struct {
	Contract     *Strategy         // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// StrategyCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type StrategyCallerSession struct {
	Contract *StrategyCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts   // Call options to use throughout this session
}

// StrategyTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type StrategyTransactorSession struct {
	Contract     *StrategyTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// StrategyRaw is an auto generated low-level Go binding around an Ethereum contract.
type StrategyRaw struct {
	Contract *Strategy // Generic contract binding to access the raw methods on
}

// StrategyCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type StrategyCallerRaw struct {
	Contract *StrategyCaller // Generic read-only contract binding to access the raw methods on
}

// StrategyTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type StrategyTransactorRaw struct {
	Contract *StrategyTransactor // Generic write-only contract binding to access the raw methods on
}

// NewStrategy creates a new instance of Strategy, bound to a specific deployed contract.
func NewStrategy(address common.Address, backend bind.ContractBackend) (*Strategy, error) {
	contract, err := bindStrategy(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Strategy{StrategyCaller: StrategyCaller{contract: contract}, StrategyTransactor: StrategyTransactor{contract: contract}, StrategyFilterer: StrategyFilterer{contract: contract}}, nil
}

// NewStrategyCaller creates a new read-only instance of Strategy, bound to a specific deployed contract.
func NewStrategyCaller(address common.Address, caller bind.ContractCaller) (*StrategyCaller, error) {
	contract, err := bindStrategy(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &StrategyCaller{contract: contract}, nil
}

// NewStrategyTransactor creates a new write-only instance of Strategy, bound to a specific deployed contract.
func NewStrategyTransactor(address common.Address, transactor bind.ContractTransactor) (*StrategyTransactor, error) {
	contract, err := bindStrategy(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &StrategyTransactor{contract: contract}, nil
}

// NewStrategyFilterer creates a new log filterer instance of Strategy, bound to a specific deployed contract.
func NewStrategyFilterer(address common.Address, filterer bind.ContractFilterer) (*StrategyFilterer, error) {
	contract, err := bindStrategy(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &StrategyFilterer{contract: contract}, nil
}

// bindStrategy binds a generic wrapper to an already deployed contract.
func bindStrategy(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(StrategyABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Strategy *StrategyRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Strategy.Contract.StrategyCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Strategy *StrategyRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Strategy.Contract.StrategyTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Strategy *StrategyRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Strategy.Contract.StrategyTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Strategy *StrategyCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Strategy.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Strategy *StrategyTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Strategy.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Strategy *StrategyTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Strategy.Contract.contract.Transact(opts, method, params...)
}

// Cap is a free data retrieval call binding the contract method 0x355274ea.
//
// Solidity: function cap() view returns(uint256)
func (_Strategy *StrategyCaller) Cap(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Strategy.contract.Call(opts, &out, "cap")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Cap is a free data retrieval call binding the contract method 0x355274ea.
//
// Solidity: function cap() view returns(uint256)
func (_Strategy *StrategySession) Cap() (*big.Int, error) {
	return _Strategy.Contract.Cap(&_Strategy.CallOpts)
}

// Cap is a free data retrieval call binding the contract method 0x355274ea.
//
// Solidity: function cap() view returns(uint256)
func (_Strategy *StrategyCallerSession) Cap() (*big.Int, error) {
	return _Strategy.Contract.Cap(&_Strategy.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Strategy *StrategyCaller) Name(opts *bind.CallOpts) (string, error) {
	var out []interface{}
	err := _Strategy.contract.Call(opts, &out, "name")

	if err != nil {
		return *new(string), err
	}

	out0 := *abi.ConvertType(out[0], new(string)).(*string)

	return out0, err

}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Strategy *StrategySession) Name() (string, error) {
	return _Strategy.Contract.Name(&_Strategy.CallOpts)
}

// Name is a free data retrieval call binding the contract method 0x06fdde03.
//
// Solidity: function name() view returns(string)
func (_Strategy *StrategyCallerSession) Name() (string, error) {
	return _Strategy.Contract.Name(&_Strategy.CallOpts)
}

// Rate is a free data retrieval call binding the contract method 0xe7ee6ad6.
//
// Solidity: function rate(uint256 sha) view returns(uint256)
func (_Strategy *StrategyCaller) Rate(opts *bind.CallOpts, sha *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Strategy.contract.Call(opts, &out, "rate", sha)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Rate is a free data retrieval call binding the contract method 0xe7ee6ad6.
//
// Solidity: function rate(uint256 sha) view returns(uint256)
func (_Strategy *StrategySession) Rate(sha *big.Int) (*big.Int, error) {
	return _Strategy.Contract.Rate(&_Strategy.CallOpts, sha)
}

// Rate is a free data retrieval call binding the contract method 0xe7ee6ad6.
//
// Solidity: function rate(uint256 sha) view returns(uint256)
func (_Strategy *StrategyCallerSession) Rate(sha *big.Int) (*big.Int, error) {
	return _Strategy.Contract.Rate(&_Strategy.CallOpts, sha)
}

// Slippage is a free data retrieval call binding the contract method 0x3e032a3b.
//
// Solidity: function slippage() view returns(uint256)
func (_Strategy *StrategyCaller) Slippage(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Strategy.contract.Call(opts, &out, "slippage")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Slippage is a free data retrieval call binding the contract method 0x3e032a3b.
//
// Solidity: function slippage() view returns(uint256)
func (_Strategy *StrategySession) Slippage() (*big.Int, error) {
	return _Strategy.Contract.Slippage(&_Strategy.CallOpts)
}

// Slippage is a free data retrieval call binding the contract method 0x3e032a3b.
//
// Solidity: function slippage() view returns(uint256)
func (_Strategy *StrategyCallerSession) Slippage() (*big.Int, error) {
	return _Strategy.Contract.Slippage(&_Strategy.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint256)
func (_Strategy *StrategyCaller) Status(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Strategy.contract.Call(opts, &out, "status")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint256)
func (_Strategy *StrategySession) Status() (*big.Int, error) {
	return _Strategy.Contract.Status(&_Strategy.CallOpts)
}

// Status is a free data retrieval call binding the contract method 0x200d2ed2.
//
// Solidity: function status() view returns(uint256)
func (_Strategy *StrategyCallerSession) Status() (*big.Int, error) {
	return _Strategy.Contract.Status(&_Strategy.CallOpts)
}

// TotalShares is a free data retrieval call binding the contract method 0x3a98ef39.
//
// Solidity: function totalShares() view returns(uint256)
func (_Strategy *StrategyCaller) TotalShares(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Strategy.contract.Call(opts, &out, "totalShares")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// TotalShares is a free data retrieval call binding the contract method 0x3a98ef39.
//
// Solidity: function totalShares() view returns(uint256)
func (_Strategy *StrategySession) TotalShares() (*big.Int, error) {
	return _Strategy.Contract.TotalShares(&_Strategy.CallOpts)
}

// TotalShares is a free data retrieval call binding the contract method 0x3a98ef39.
//
// Solidity: function totalShares() view returns(uint256)
func (_Strategy *StrategyCallerSession) TotalShares() (*big.Int, error) {
	return _Strategy.Contract.TotalShares(&_Strategy.CallOpts)
}

// Earn is a paid mutator transaction binding the contract method 0xd389800f.
//
// Solidity: function earn() returns()
func (_Strategy *StrategyTransactor) Earn(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Strategy.contract.Transact(opts, "earn")
}

// Earn is a paid mutator transaction binding the contract method 0xd389800f.
//
// Solidity: function earn() returns()
func (_Strategy *StrategySession) Earn() (*types.Transaction, error) {
	return _Strategy.Contract.Earn(&_Strategy.TransactOpts)
}

// Earn is a paid mutator transaction binding the contract method 0xd389800f.
//
// Solidity: function earn() returns()
func (_Strategy *StrategyTransactorSession) Earn() (*types.Transaction, error) {
	return _Strategy.Contract.Earn(&_Strategy.TransactOpts)
}

// StrategyEarnIterator is returned from FilterEarn and is used to iterate over the raw logs and unpacked data for Earn events raised by the Strategy contract.
type StrategyEarnIterator struct {
	Event *StrategyEarn // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *StrategyEarnIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(StrategyEarn)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(StrategyEarn)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *StrategyEarnIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *StrategyEarnIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// StrategyEarn represents a Earn event raised by the Strategy contract.
type StrategyEarn struct {
	Tvl    *big.Int
	Profit *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterEarn is a free log retrieval operation binding the contract event 0x5850d758e6151f474c145f4f59e8cb315c3f1a9fe82d96dff5bd2d48b5a76f9b.
//
// Solidity: event Earn(uint256 tvl, uint256 profit)
func (_Strategy *StrategyFilterer) FilterEarn(opts *bind.FilterOpts) (*StrategyEarnIterator, error) {

	logs, sub, err := _Strategy.contract.FilterLogs(opts, "Earn")
	if err != nil {
		return nil, err
	}
	return &StrategyEarnIterator{contract: _Strategy.contract, event: "Earn", logs: logs, sub: sub}, nil
}

// WatchEarn is a free log subscription operation binding the contract event 0x5850d758e6151f474c145f4f59e8cb315c3f1a9fe82d96dff5bd2d48b5a76f9b.
//
// Solidity: event Earn(uint256 tvl, uint256 profit)
func (_Strategy *StrategyFilterer) WatchEarn(opts *bind.WatchOpts, sink chan<- *StrategyEarn) (event.Subscription, error) {

	logs, sub, err := _Strategy.contract.WatchLogs(opts, "Earn")
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(StrategyEarn)
				if err := _Strategy.contract.UnpackLog(event, "Earn", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseEarn is a log parse operation binding the contract event 0x5850d758e6151f474c145f4f59e8cb315c3f1a9fe82d96dff5bd2d48b5a76f9b.
//
// Solidity: event Earn(uint256 tvl, uint256 profit)
func (_Strategy *StrategyFilterer) ParseEarn(log types.Log) (*StrategyEarn, error) {
	event := new(StrategyEarn)
	if err := _Strategy.contract.UnpackLog(event, "Earn", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
