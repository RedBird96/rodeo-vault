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

// InvestorMetaData contains all meta data concerning the Investor contract.
var InvestorMetaData = &bind.MetaData{
	ABI: "[{\"name\":\"nextPosition\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[],\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}]},{\"name\":\"life\",\"type\":\"function\",\"stateMutability\":\"view\",\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\"}],\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}]},{\"name\":\"kill\",\"type\":\"function\",\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\"},{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\"}],\"outputs\":[]},{\"name\":\"Kill\",\"type\":\"event\",\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"keeper\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"fee\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"borrow\",\"type\":\"uint256\"}]},{\"name\":\"Edit\",\"type\":\"event\",\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"int256\",\"name\":\"amount\",\"type\":\"int256\"},{\"indexed\":false,\"internalType\":\"int256\",\"name\":\"borrow\",\"type\":\"int256\"},{\"indexed\":false,\"internalType\":\"int256\",\"name\":\"sharesChange\",\"type\":\"int256\"},{\"indexed\":false,\"internalType\":\"int256\",\"name\":\"borrowChange\",\"type\":\"int256\"}]}]",
}

// InvestorABI is the input ABI used to generate the binding from.
// Deprecated: Use InvestorMetaData.ABI instead.
var InvestorABI = InvestorMetaData.ABI

// Investor is an auto generated Go binding around an Ethereum contract.
type Investor struct {
	InvestorCaller     // Read-only binding to the contract
	InvestorTransactor // Write-only binding to the contract
	InvestorFilterer   // Log filterer for contract events
}

// InvestorCaller is an auto generated read-only Go binding around an Ethereum contract.
type InvestorCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// InvestorTransactor is an auto generated write-only Go binding around an Ethereum contract.
type InvestorTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// InvestorFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type InvestorFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// InvestorSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type InvestorSession struct {
	Contract     *Investor         // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// InvestorCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type InvestorCallerSession struct {
	Contract *InvestorCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts   // Call options to use throughout this session
}

// InvestorTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type InvestorTransactorSession struct {
	Contract     *InvestorTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts   // Transaction auth options to use throughout this session
}

// InvestorRaw is an auto generated low-level Go binding around an Ethereum contract.
type InvestorRaw struct {
	Contract *Investor // Generic contract binding to access the raw methods on
}

// InvestorCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type InvestorCallerRaw struct {
	Contract *InvestorCaller // Generic read-only contract binding to access the raw methods on
}

// InvestorTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type InvestorTransactorRaw struct {
	Contract *InvestorTransactor // Generic write-only contract binding to access the raw methods on
}

// NewInvestor creates a new instance of Investor, bound to a specific deployed contract.
func NewInvestor(address common.Address, backend bind.ContractBackend) (*Investor, error) {
	contract, err := bindInvestor(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Investor{InvestorCaller: InvestorCaller{contract: contract}, InvestorTransactor: InvestorTransactor{contract: contract}, InvestorFilterer: InvestorFilterer{contract: contract}}, nil
}

// NewInvestorCaller creates a new read-only instance of Investor, bound to a specific deployed contract.
func NewInvestorCaller(address common.Address, caller bind.ContractCaller) (*InvestorCaller, error) {
	contract, err := bindInvestor(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &InvestorCaller{contract: contract}, nil
}

// NewInvestorTransactor creates a new write-only instance of Investor, bound to a specific deployed contract.
func NewInvestorTransactor(address common.Address, transactor bind.ContractTransactor) (*InvestorTransactor, error) {
	contract, err := bindInvestor(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &InvestorTransactor{contract: contract}, nil
}

// NewInvestorFilterer creates a new log filterer instance of Investor, bound to a specific deployed contract.
func NewInvestorFilterer(address common.Address, filterer bind.ContractFilterer) (*InvestorFilterer, error) {
	contract, err := bindInvestor(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &InvestorFilterer{contract: contract}, nil
}

// bindInvestor binds a generic wrapper to an already deployed contract.
func bindInvestor(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := abi.JSON(strings.NewReader(InvestorABI))
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Investor *InvestorRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Investor.Contract.InvestorCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Investor *InvestorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Investor.Contract.InvestorTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Investor *InvestorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Investor.Contract.InvestorTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Investor *InvestorCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Investor.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Investor *InvestorTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Investor.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Investor *InvestorTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Investor.Contract.contract.Transact(opts, method, params...)
}

// Life is a free data retrieval call binding the contract method 0x22272024.
//
// Solidity: function life(uint256 index) view returns(uint256)
func (_Investor *InvestorCaller) Life(opts *bind.CallOpts, index *big.Int) (*big.Int, error) {
	var out []interface{}
	err := _Investor.contract.Call(opts, &out, "life", index)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// Life is a free data retrieval call binding the contract method 0x22272024.
//
// Solidity: function life(uint256 index) view returns(uint256)
func (_Investor *InvestorSession) Life(index *big.Int) (*big.Int, error) {
	return _Investor.Contract.Life(&_Investor.CallOpts, index)
}

// Life is a free data retrieval call binding the contract method 0x22272024.
//
// Solidity: function life(uint256 index) view returns(uint256)
func (_Investor *InvestorCallerSession) Life(index *big.Int) (*big.Int, error) {
	return _Investor.Contract.Life(&_Investor.CallOpts, index)
}

// NextPosition is a free data retrieval call binding the contract method 0x1e6c5722.
//
// Solidity: function nextPosition() view returns(uint256)
func (_Investor *InvestorCaller) NextPosition(opts *bind.CallOpts) (*big.Int, error) {
	var out []interface{}
	err := _Investor.contract.Call(opts, &out, "nextPosition")

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// NextPosition is a free data retrieval call binding the contract method 0x1e6c5722.
//
// Solidity: function nextPosition() view returns(uint256)
func (_Investor *InvestorSession) NextPosition() (*big.Int, error) {
	return _Investor.Contract.NextPosition(&_Investor.CallOpts)
}

// NextPosition is a free data retrieval call binding the contract method 0x1e6c5722.
//
// Solidity: function nextPosition() view returns(uint256)
func (_Investor *InvestorCallerSession) NextPosition() (*big.Int, error) {
	return _Investor.Contract.NextPosition(&_Investor.CallOpts)
}

// Kill is a paid mutator transaction binding the contract method 0xe28f6cb9.
//
// Solidity: function kill(uint256 index, bytes data) returns()
func (_Investor *InvestorTransactor) Kill(opts *bind.TransactOpts, index *big.Int, data []byte) (*types.Transaction, error) {
	return _Investor.contract.Transact(opts, "kill", index, data)
}

// Kill is a paid mutator transaction binding the contract method 0xe28f6cb9.
//
// Solidity: function kill(uint256 index, bytes data) returns()
func (_Investor *InvestorSession) Kill(index *big.Int, data []byte) (*types.Transaction, error) {
	return _Investor.Contract.Kill(&_Investor.TransactOpts, index, data)
}

// Kill is a paid mutator transaction binding the contract method 0xe28f6cb9.
//
// Solidity: function kill(uint256 index, bytes data) returns()
func (_Investor *InvestorTransactorSession) Kill(index *big.Int, data []byte) (*types.Transaction, error) {
	return _Investor.Contract.Kill(&_Investor.TransactOpts, index, data)
}

// InvestorEditIterator is returned from FilterEdit and is used to iterate over the raw logs and unpacked data for Edit events raised by the Investor contract.
type InvestorEditIterator struct {
	Event *InvestorEdit // Event containing the contract specifics and raw log

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
func (it *InvestorEditIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(InvestorEdit)
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
		it.Event = new(InvestorEdit)
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
func (it *InvestorEditIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *InvestorEditIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// InvestorEdit represents a Edit event raised by the Investor contract.
type InvestorEdit struct {
	Index        *big.Int
	Amount       *big.Int
	Borrow       *big.Int
	SharesChange *big.Int
	BorrowChange *big.Int
	Raw          types.Log // Blockchain specific contextual infos
}

// FilterEdit is a free log retrieval operation binding the contract event 0x765b651c17da924c0d8127671832786cd0acf8ca08d76d6491fa3378ff790986.
//
// Solidity: event Edit(uint256 indexed index, int256 amount, int256 borrow, int256 sharesChange, int256 borrowChange)
func (_Investor *InvestorFilterer) FilterEdit(opts *bind.FilterOpts, index []*big.Int) (*InvestorEditIterator, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}

	logs, sub, err := _Investor.contract.FilterLogs(opts, "Edit", indexRule)
	if err != nil {
		return nil, err
	}
	return &InvestorEditIterator{contract: _Investor.contract, event: "Edit", logs: logs, sub: sub}, nil
}

// WatchEdit is a free log subscription operation binding the contract event 0x765b651c17da924c0d8127671832786cd0acf8ca08d76d6491fa3378ff790986.
//
// Solidity: event Edit(uint256 indexed index, int256 amount, int256 borrow, int256 sharesChange, int256 borrowChange)
func (_Investor *InvestorFilterer) WatchEdit(opts *bind.WatchOpts, sink chan<- *InvestorEdit, index []*big.Int) (event.Subscription, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}

	logs, sub, err := _Investor.contract.WatchLogs(opts, "Edit", indexRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(InvestorEdit)
				if err := _Investor.contract.UnpackLog(event, "Edit", log); err != nil {
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

// ParseEdit is a log parse operation binding the contract event 0x765b651c17da924c0d8127671832786cd0acf8ca08d76d6491fa3378ff790986.
//
// Solidity: event Edit(uint256 indexed index, int256 amount, int256 borrow, int256 sharesChange, int256 borrowChange)
func (_Investor *InvestorFilterer) ParseEdit(log types.Log) (*InvestorEdit, error) {
	event := new(InvestorEdit)
	if err := _Investor.contract.UnpackLog(event, "Edit", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// InvestorKillIterator is returned from FilterKill and is used to iterate over the raw logs and unpacked data for Kill events raised by the Investor contract.
type InvestorKillIterator struct {
	Event *InvestorKill // Event containing the contract specifics and raw log

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
func (it *InvestorKillIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(InvestorKill)
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
		it.Event = new(InvestorKill)
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
func (it *InvestorKillIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *InvestorKillIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// InvestorKill represents a Kill event raised by the Investor contract.
type InvestorKill struct {
	Index  *big.Int
	Keeper common.Address
	Amount *big.Int
	Fee    *big.Int
	Borrow *big.Int
	Raw    types.Log // Blockchain specific contextual infos
}

// FilterKill is a free log retrieval operation binding the contract event 0x57ee3328f2026eecc0c7a2440fc71c20ee3fb56f0494b843044d759a882432b5.
//
// Solidity: event Kill(uint256 indexed index, address indexed keeper, uint256 amount, uint256 fee, uint256 borrow)
func (_Investor *InvestorFilterer) FilterKill(opts *bind.FilterOpts, index []*big.Int, keeper []common.Address) (*InvestorKillIterator, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}
	var keeperRule []interface{}
	for _, keeperItem := range keeper {
		keeperRule = append(keeperRule, keeperItem)
	}

	logs, sub, err := _Investor.contract.FilterLogs(opts, "Kill", indexRule, keeperRule)
	if err != nil {
		return nil, err
	}
	return &InvestorKillIterator{contract: _Investor.contract, event: "Kill", logs: logs, sub: sub}, nil
}

// WatchKill is a free log subscription operation binding the contract event 0x57ee3328f2026eecc0c7a2440fc71c20ee3fb56f0494b843044d759a882432b5.
//
// Solidity: event Kill(uint256 indexed index, address indexed keeper, uint256 amount, uint256 fee, uint256 borrow)
func (_Investor *InvestorFilterer) WatchKill(opts *bind.WatchOpts, sink chan<- *InvestorKill, index []*big.Int, keeper []common.Address) (event.Subscription, error) {

	var indexRule []interface{}
	for _, indexItem := range index {
		indexRule = append(indexRule, indexItem)
	}
	var keeperRule []interface{}
	for _, keeperItem := range keeper {
		keeperRule = append(keeperRule, keeperItem)
	}

	logs, sub, err := _Investor.contract.WatchLogs(opts, "Kill", indexRule, keeperRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(InvestorKill)
				if err := _Investor.contract.UnpackLog(event, "Kill", log); err != nil {
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

// ParseKill is a log parse operation binding the contract event 0x57ee3328f2026eecc0c7a2440fc71c20ee3fb56f0494b843044d759a882432b5.
//
// Solidity: event Kill(uint256 indexed index, address indexed keeper, uint256 amount, uint256 fee, uint256 borrow)
func (_Investor *InvestorFilterer) ParseKill(log types.Log) (*InvestorKill, error) {
	event := new(InvestorKill)
	if err := _Investor.contract.UnpackLog(event, "Kill", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
