// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ITreehouse {
    function getLatestEsr() external view returns (int256 esr);
    function decimals() external view returns (uint256);
    function getRollingAvgEsrForNdays(uint256 numOfDays) external view returns (int256 esr);
}