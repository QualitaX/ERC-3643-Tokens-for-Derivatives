// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IRates {
    function decimals() external view returns(uint8);
    function getRate() external returns(uint256);
}