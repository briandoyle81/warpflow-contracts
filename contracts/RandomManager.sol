// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// TODO: Update to CadenceRandomConsumer
// import {CadenceRandomConsumer} from "@onflow/flow-sol-utils/src/random/CadenceRandomConsumer.sol";

contract RandomManager {
    uint private counter;

    // For now basically mocking the randomness contracts

    function requestRandomness() external returns (uint) {
        counter++;

        uint id = uint(keccak256(abi.encodePacked(block.prevrandao, counter)));

        return id;
    }

    function fulfillRandomRequest(uint _requestId) external returns (uint64) {
        counter++;

        // Truncates to 64 bits
        uint64 badRandom = uint64(
            uint(keccak256(abi.encodePacked(block.prevrandao, _requestId)))
        );

        return badRandom;
    }
}
