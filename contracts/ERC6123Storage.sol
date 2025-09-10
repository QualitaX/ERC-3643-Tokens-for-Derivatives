// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Types.sol";
abstract contract ERC6123Storage {
    error obseleteFunction();
    error allSettlementsDone();
    error stateMustBeConfirmedOrSettled();
    error invalidTrade(string _tradeID);
    error invalidPaymentAmount(int256 _amount);
    error invalidPositionValue(int256 _position);
    error nothingToSwap(int256 _fixedRate, int256 _floatingRate);
    error mustBeOtherParty(address _withParty, address _otherParty);
    error cannotInceptWithYourself(address _caller, address _withParty);
    error inconsistentTradeDataOrWrongAddress(address _inceptor, uint256 _dataHash);
    error mustBePayerOrReceiver(address _withParty, address _payer, address _receiver);
    error notEnoughMarginBuffer(uint256 _settlementAmount, uint256 _availableMarginBuffer);

    /*
     * Trade States
     */
    enum TradeState {

        /*
         * State before the trade is incepted.
         */
        Inactive,

        /*
         * Incepted: Trade data submitted by one party. Market data for initial valuation is set.
         */
        Incepted,

        /*
         * Confirmed: Trade data accepted by other party.
         */
        Confirmed,

        /*
         * Valuation Phase: The contract is awaiting a valuation for the next settlement.
         */
        Valuation,

        /*
         * Token-based Transfer is in Progress. Contracts awaits termination of token transfer (allows async transfers).
         */
        InTransfer,

        /*
         * Settlement is Completed.
         */
        Settled,

        /*
         * Termination is in Progress.
         */
        InTermination,
        /*
         * Terminated.
         */
        Terminated,
        /**
        * Has reached Maturity 
        */
       Matured
    }

    modifier onlyWhenTradeInactive() {
        require(
            tradeState == TradeState.Inactive,
            "Trade state is not 'Inactive'."
        ); 
        _;
    }

    modifier onlyWhenTradeIncepted() {
        require(
            tradeState == TradeState.Incepted,
            "Trade state is not 'Incepted'."
        );
        _;
    }

    modifier onlyWhenTradeConfirmed() {
        require(
            tradeState == TradeState.Confirmed,
            "Trade state is not 'Confirmed'." 
        );
        _;
    }

    modifier onlyWhenSettled() {
        require(
            tradeState == TradeState.Settled,
            "Trade state is not 'Settled'."
        );
        _;
    }

    modifier onlyWhenValuation() {
        require(
            tradeState == TradeState.Valuation,
            "Trade state is not 'Valuation'."
        );
        _;
    }

    modifier onlyWhenInTermination () {
        require(
            tradeState == TradeState.InTermination,
            "Trade state is not 'InTermination'."
        );
        _;
    }

    modifier onlyWhenInTransfer() {
        require(
            tradeState == TradeState.InTransfer,
            "Trade state is not 'InTransfer'."
        );
        _;
    }

    modifier onlyWhenMatured() {
        require(
            tradeState == TradeState.Matured,
            "Trade state is not 'Matured'."
        );
        _;
    }

    modifier onlyWhenConfirmedOrSettled() {
        if(tradeState != TradeState.Confirmed) {
            if(tradeState != TradeState.Settled) {
                revert stateMustBeConfirmedOrSettled();
            }
        }
        _;
    }

    modifier onlyWithinConfirmationTime() {
        require(
            block.timestamp - inceptingTime <= confirmationTime,
            "Confimartion time is over"
        );
        _;
    }

    mapping(address => uint256) internal marginCalls;
    mapping(uint256 => address) internal pendingRequests;
    mapping(address => Types.MarginRequirement) internal marginRequirements;

    TradeState internal tradeState;

    string public tradeID;
    string tradeHash;

    uint256 internal initialMarginBuffer;
    uint256 internal initialTerminationFee;
    uint256 internal inceptingTime;
    uint256 internal confirmationTime;
    uint256 internal fixedRatePayment;
    uint256 internal floatingRatePayment;
    uint256 internal settlementAmount;
    
    address internal receiverParty;
    address public collateralAdjustementForwarderAddress;
    address public settlementForwarderAddress;

    Types.IRSReceipt[] internal irsReceipts;
}