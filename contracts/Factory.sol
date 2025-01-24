// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Types.sol";
import "./ERC6123.sol";

contract Factory {
    event contractDeployed(string tradeID,  address contractAddress);
    error alreadyDeployed(string tradeID);
    mapping(string => bool) public isDeployed;

    function deployForwardContract(
        string memory _tradeID,
        string memory _irsTokenName,
        string memory _irsTokenSymbol,
        Types.IRS memory _irs,
        uint256 _initialMarginBuffer,
        uint256 _initialTerminationFee
    ) public {
        if (isDeployed[_tradeID]) revert alreadyDeployed(_tradeID);

        ERC6123 forwardContract = new ERC6123{salt: bytes32(abi.encodePacked(_tradeID))}(
            _tradeID,
            _irsTokenName,
            _irsTokenSymbol,
            _irs,
            _initialMarginBuffer,
            _initialTerminationFee
        );

        isDeployed[_tradeID] = true;
        emit contractDeployed(_tradeID, address(forwardContract));
    }
}