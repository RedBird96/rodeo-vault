// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "../interfaces/IERC20.sol";
import {IOracle} from "../interfaces/IOracle.sol";

interface IOracleChainlink {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
}

contract OracleChainlink {
    IOracleChainlink public immutable sequencer;
    IOracleChainlink public immutable oracle;
    uint256 public immutable heartbeat;

    error StalePrice();
    error NegativePrice();
    error SequencerUnavailable();

    constructor(address _sequencer, address _oracle, uint256 _heartbeat) {
        sequencer = IOracleChainlink(_sequencer);
        oracle = IOracleChainlink(_oracle);
        heartbeat = _heartbeat;
    }

    function decimals() external view returns (uint8) {
        return oracle.decimals();
    }

    function latestAnswer() external view returns (int256) {
        (, int256 seqAnswer, uint256 startedAt,,) = sequencer.latestRoundData();
        if (block.timestamp - startedAt <= 3600 || seqAnswer == 1) {
            revert SequencerUnavailable();
        }

        (, int256 answer,, uint256 updatedAt,) = oracle.latestRoundData();
        if (block.timestamp - updatedAt >= heartbeat) {
            revert StalePrice();
        }

        if (answer <= 0) {
            revert NegativePrice();
        }

        return answer;
    }
}
