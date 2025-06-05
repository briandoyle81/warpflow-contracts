// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

interface IUniversalCredits {
    function mint(address _to, uint _amount) external;

    function transfer(address _to, uint _amount) external returns (bool);

    function balanceOf(address _account) external view returns (uint);
}
