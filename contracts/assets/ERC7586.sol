// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/IERC7586.sol";
import "../interfaces/ITreehouse.sol";
import "../interfaces/ICompliance.sol";
import "../interfaces/IParticipantRegistry.sol";
import "./IRSToken.sol";
import "../Compliance/interfaces/IToken.sol";

abstract contract ERC7586 is IERC7586, IRSToken {
    uint256 internal settlementAmount;
    uint256 internal terminationAmount;

    address participantRegistyAddress;
    //address complianceContractAddress;
    address identityRegistryAddress;
    
    address internal receiverParty;
    address internal payerParty;
    address internal terminationReceiver;
    address treehouseContractAddress = 0x6D8e3A744cc18E803B7a2fC95A44a3b0483703eb;

    constructor(
        string memory _irsTokenName,
        string memory _irsTokenSymbol,
        Types.IRS memory _irs,
        address _participantRegistyAddress,
        //address _complianceContractAddress,
        address _identityRegistryAddress
    ) IRSToken(_irsTokenName, _irsTokenSymbol) {
        irs = _irs;
        participantRegistyAddress = _participantRegistryAddress;
        //complianceContractAddress = _complianceContractAddress;
        identityRegistryAddress = _identityRegistryAddress;

        require(_irs.fixedRatePayer != address(0), "Fixed rate payer cannot be zero address");
        require(_irs.floatingRatePayer != address(0), "Floating rate payer cannot be zero address");
        require(_irs.settlementCurrency != address(0), "Settlement currency cannot be zero address");
        require(_irs.notionalAmount > 0, "Notional amount must be greater than zero");
        require(_irs.startingDate < _irs.maturityDate, "Starting date must be before maturity date");

        // one token minted for each settlement cycle per counterparty
        uint256 balance =  1 ether;
        _maxSupply = 2 * balance;

        mint(_irs.fixedRatePayer, balance);
        mint(_irs.floatingRatePayer, balance);
    }

    function fixedRatePayer() external view returns(address) {
        return irs.fixedRatePayer;
    }

    function floatingRatePayer() external view returns(address) {
        return irs.floatingRatePayer;
    }

    function swapRate() external view returns(int256) {
        return irs.swapRate;
    }

    function spread() external view returns(int256) {
        return irs.spread;
    }

    function settlementCurrency() external view returns(address) {
        return irs.settlementCurrency;
    }

    function notionalAmount() external view returns(uint256) {
        return irs.notionalAmount;
    }

    function startingDate() external view returns(uint256) {
        return irs.startingDate;
    }

    function maturityDate() external view returns(uint256) {
        return irs.maturityDate;
    }

    function benchmark() public view returns(int256) {
        return ITreehouse(treehouseContractAddress).getRollingAvgEsrForNdays(7);
    }

    /**
    * @notice Transfer the net settlement amount to the receiver account.
    * @notice All compliance checks are performed by the token contract.
    */
    function swap() public returns(bool) {
        IToken(irs.settlementCurrency).transfer(receiverParty, settlementAmount);

        emit Swap(receiverParty, settlementAmount);

        // Prevents the transfer of funds from the outside of ERC6123 contrat
        // This is possible because the receipient of the transferFrom function in ERC20 must not be the zero address
        receiverParty = address(0);

        return true;
    }

    /**
    * @notice Terminate the Swap and Transfer the termination amount to the termination receiver account.
    * @notice All compliance checks are performed by the token contract.
    * @dev This function is called when the swap is terminated before maturity.
    * @dev The termination receiver is the party that receives the termination amount.
    */
    function terminateSwap() public {
        IToken(irs.settlementCurrency).transfer(terminationReceiver, terminationAmount);
    }
}