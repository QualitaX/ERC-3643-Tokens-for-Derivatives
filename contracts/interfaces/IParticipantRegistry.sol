// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IParticipantRegistry {
    /**
     * @dev Check if the user is verified in the Identity Registry.
     * @param _user The address of the user to check.
     */
    function checkUserVerification(address _user) external view;

    /**
     * @dev Check if the transfer is allowed by compliance rules.
     * @param _from The address of the sender.
     * @param _to The address of the recipient.
     * @param _amount The amount to transfer.
     */
    function checkTransferCompliance(address _from, address _to, uint256 _amount) external view;

    /**
     * @dev Check if the token is paused.
     */
    function checkTokenPaused() external view;

    /**
     * @dev Check if the user's wallet is frozen.
     * @param _user The address of the user to check.
     */
    function checkWalletFrozen(address _user) external view;
}