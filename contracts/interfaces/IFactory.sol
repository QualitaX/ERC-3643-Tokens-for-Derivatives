// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ifactory {
    function deployForwardContract() external returns (address);
}