// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/**
* @notice This contract simulates the fluctuation of a Floating Rate benchmark
*/

/**
* @author Samuel Edoumou
* @dev This contrat hosts a list of EUR/USD rates (Close) for 5 days (from 2025-08-11 to 2025-08-15).
* The rates are expressed in 6 decimals (e.g., 1.1648 is represented as 1164800)
* The rates are sourced from `finance.yahoo.com`
*/
contract Rates {
    error invalidRateIndex(uint256 _index);

    uint256 public rateCount;
    uint8 private _ratedecimal = 6;
    uint256[5] rates = [11648, 11618, 11677, 11713, 11651];

    function decimals() external view returns(uint8) {
        return _ratedecimal;
    }

    function getRate() external returns(uint256) {
        uint256 index = rateCount;
        rateCount = index + 1;

        if(index >= rates.length) revert invalidRateIndex(index);

        return rates[index];
    }
}