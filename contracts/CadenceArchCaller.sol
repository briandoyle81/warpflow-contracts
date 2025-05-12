// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract CadenceArchCaller {
    error FailedToFetchRandomNumber();
    // Address of the Cadence Arch contract
    address public constant cadenceArch =
        0x0000000000000000000000010000000000000001;

    // Function to fetch a pseudo-random value
    function revertibleRandom() public view returns (uint64) {
        // Static call to the Cadence Arch contract's revertibleRandom function
        (bool ok, bytes memory data) = cadenceArch.staticcall(
            abi.encodeWithSignature("revertibleRandom()")
        );
        if (!ok) {
            revert FailedToFetchRandomNumber();
        }
        uint64 output = abi.decode(data, (uint64));
        // Return the random value
        return output;
    }
}
