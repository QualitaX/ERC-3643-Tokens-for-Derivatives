// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IERC7586 {
    //-------------------------- Events --------------------------
    /**
    * @notice MUST be emitted when interest rates are swapped
    * @param _account the recipient account to send the interest difference to. MUST be either the `payer` or the `receiver`
    * @param _amount the interest difference to be transferred
    */
    event Swap(address _account, uint256 _amount);

    /**
    * @notice MUST be emitted when the swap contract is terminated
    * @param _payer the swap payer
    * @param _receiver the swap receiver
    */
    event TerminateSwap(address indexed _payer, address indexed _receiver);

    //-------------------------- Functions --------------------------
    /**
    *  @notice Returns the IRS `payer` account address. The party who agreed to pay fixed interest
    */
    function fixedRatePayer() external view returns(address);

    /**
    *  @notice Returns the IRS `receiver` account address. The party who agreed to pay floating interest
    */
    function floatingRatePayer() external view returns(address);

    /**
    *  @notice Returns the fixed interest rate. All rates MUST be multiplied by 10^(ratesDecimals)
    */
    function swapRate() external view returns(int256);

    /**
    *  @notice Returns the floating rate spread, i.e. the fixed part of the floating interest rate. All rates MUST be multiplied by 10^(ratesDecimals)
    *          floatingRate = benchmark + spread
    */
    function spread() external view returns(int256);

    /**
    *  @notice Returns the contract address of the settlement currency(Example: USDC contract address).
    *          Returns the zero address if the contracct is settled in FIAT currency like USD
    */
    function settlementCurrency() external view returns(address);

    /**
    *  @notice Returns the notional amount in unit of asset to be transferred when swapping IRS. This amount serves as the basis for calculating the interest payments, and may not be exchanged
    *          Example: If the two parties aggreed to swap interest rates in USDC, then the notional amount may be equal to 1,000,000 USDC 
    */
    function notionalAmount() external view returns(uint256);

    /**
    *  @notice Returns the starting date of the swap contract. This is a Unix Timestamp like the one returned by block.timestamp
    */
    function startingDate() external view returns(uint256);

    /**
    *  @notice Returns the maturity date of the swap contract. This is a Unix Timestamp like the one returned by block.timestamp
    */
    function maturityDate() external view returns(uint256);

    /**
    *  @notice Makes swap calculation and transfers the payment to counterparties
    */
    function swap() external returns(bool);

    /**
    *  @notice Terminates the swap contract before its maturity date. MUST be called by either the `payer`or the `receiver`.
    */
    function terminateSwap() external;
}