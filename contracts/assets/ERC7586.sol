// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/IERC7586.sol";
import "../interfaces/ITreehouse.sol";
import "./IRSToken.sol";

abstract contract ERC7586 is IERC7586, IRSToken {
    uint256 internal settlementAmount;
    uint256 internal terminationAmount;
    
    address internal receiverParty;
    address internal payerParty;
    address internal terminationReceiver;
    address treehouseContractAddress = 0x6D8e3A744cc18E803B7a2fC95A44a3b0483703eb;

    constructor(
        string memory _irsTokenName,
        string memory _irsTokenSymbol,
        Types.IRS memory _irs
    ) IRSToken(_irsTokenName, _irsTokenSymbol) {
        irs = _irs;

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
    */
    function swap() public returns(bool) {
        IERC20(irs.settlementCurrency).transfer(receiverParty, settlementAmount);

        emit Swap(receiverParty, settlementAmount);

        // Prevents the transfer of funds from the outside of ERC6123 contrat
        // This is possible because the receipient of the transferFrom function in ERC20 must not be the zero address
        receiverParty = address(0);

        return true;
    }

    function terminateSwap() public {
        IERC20(irs.settlementCurrency).transfer(terminationReceiver, terminationAmount);
    }
}