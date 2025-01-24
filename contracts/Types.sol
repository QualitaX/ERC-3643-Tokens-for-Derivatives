// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract Types {
    struct IRS {
        address fixedRatePayer;
        address floatingRatePayer;
        address settlementCurrency;
        int256 swapRate;
        int256 spread;
        uint256 notionalAmount;
        uint256 startingDate;
        uint256 maturityDate;
    }

    struct MarginRequirement {
        uint256 marginBuffer;
        uint256 terminationFee;
    }
    
    struct IRSReceipt {
        address from;
        address to;
        uint256 netAmount;
        uint256 timestamp;
        uint256 fixedRatePayment;
        uint256 floatingRatePayment;
    }
}