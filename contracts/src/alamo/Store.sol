// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Store {
    mapping(address => bool) public exec;
    mapping(bytes32 => uint256) public uintValues;
    mapping(bytes32 => int256) public intValues;
    mapping(bytes32 => address) public addressValues;
    mapping(bytes32 => bool) public boolValues;
    mapping(bytes32 => string) public stringValues;
    mapping(bytes32 => bytes32) public bytes32Values;
    mapping(bytes32 => bytes32[]) public bytes32ArrayValues;
    mapping(bytes32 => Bytes32Set) internal bytes32Sets;

    struct Bytes32Set {
        bytes32[] values;
        mapping(bytes32 => uint256) positions;
    }

    event File(bytes32 indexed what, address data);

    error InvalidFile();
    error Unauthorized();
    error OverOrUnderflow();

    constructor() {
        exec[msg.sender] = true;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") {
            exec[data] = !exec[data];
        } else {
            revert InvalidFile();
        }
        emit File(what, data);
    }

    function getUint(bytes32 key) external view returns (uint256) {
        return uintValues[key];
    }
    function setUint(bytes32 key, uint256 value) external auth returns (uint256) {
        uintValues[key] = value;
        return value;
    }
    function setUintDelta(bytes32 key, int256 value) external auth returns (uint256) {
        uint256 prev = uintValues[key];
        uint256 next = uint256(int256(prev) + value);
        if (value > 0 && next < prev) revert OverOrUnderflow();
        if (value < 0 && next > prev) revert OverOrUnderflow();
        uintValues[key] = next;
        return next;
    }
    function removeUint(bytes32 key) external auth {
        delete uintValues[key];
    }
    function getInt(bytes32 key) external view returns (int256) {
        return intValues[key];
    }
    function setInt(bytes32 key, int256 value) external auth returns (int256) {
        intValues[key] = value;
        return value;
    }
    function setIntDelta(bytes32 key, int256 value) external auth returns (int256) {
        int256 next = intValues[key] + value;
        intValues[key] = next;
        return next;
    }
    function removeInt(bytes32 key) external auth {
        delete intValues[key];
    }
    function getAddress(bytes32 key) external view returns (address) {
        return addressValues[key];
    }
    function setAddress(bytes32 key, address value) external auth returns (address) {
        addressValues[key] = value;
        return value;
    }
    function removeAddress(bytes32 key) external auth {
        delete addressValues[key];
    }
    function getBool(bytes32 key) external view returns (bool) {
        return boolValues[key];
    }
    function setBool(bytes32 key, bool value) external auth returns (bool) {
        boolValues[key] = value;
        return value;
    }
    function removeBool(bytes32 key) external auth {
        delete boolValues[key];
    }
    function getString(bytes32 key) external view returns (string memory) {
        return stringValues[key];
    }
    function setString(bytes32 key, string memory value) external auth returns (string memory) {
        stringValues[key] = value;
        return value;
    }
    function removeString(bytes32 key) external auth {
        delete stringValues[key];
    }
    function getBytes32(bytes32 key) external view returns (bytes32) {
        return bytes32Values[key];
    }
    function setBytes32(bytes32 key, bytes32 value) external auth returns (bytes32) {
        bytes32Values[key] = value;
        return value;
    }
    function removeBytes32(bytes32 key) external auth {
        delete bytes32Values[key];
    }

    function getBytes32Array(bytes32 key) external view returns (bytes32[] memory) {
        return bytes32ArrayValues[key];
    }
    function setBytes32Array(bytes32 key, bytes32[] memory value) external auth {
        bytes32ArrayValues[key] = value;
    }
    function removeBytes32Array(bytes32 key) external auth {
        delete bytes32ArrayValues[key];
    }

    function containsBytes32(bytes32 key, bytes32 value) external view returns (bool) {
        return bytes32Sets[key].positions[value] != 0;
    }
    function getBytes32Count(bytes32 key) external view returns (uint256) {
        return bytes32Sets[key].values.length;
    }
    function getBytes32ValuesAt(bytes32 key, uint256 start, uint256 end) external view returns (bytes32[] memory v) {
        v = new bytes32[](end-start);
        for (uint256 i = start; i < end; i++) {
            v[i - start] = bytes32Sets[key].values[i];
        }
    }
    function addBytes32(bytes32 key, bytes32 value) external auth {
        Bytes32Set storage s = bytes32Sets[key];
        if (s.positions[value] == 0) {
            s.values.push(value);
            s.positions[value] = s.values.length;
        }
    }
    function removeBytes32(bytes32 key, bytes32 value) external auth {
        Bytes32Set storage s = bytes32Sets[key];
        uint256 position = s.positions[value];
        if (position != 0) {
            uint256 valueIndex = position-1;
            uint256 lastIndex = s.values.length-1;
            if (valueIndex != lastIndex) {
                bytes32 lastValue = s.values[lastIndex];
                s.values[valueIndex] = lastValue;
                s.positions[lastValue] = position;
            }
            s.values.pop();
            delete s.positions[value];
        }
    }
}
