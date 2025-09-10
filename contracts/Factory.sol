// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Types.sol";
import "./ERC6123.sol";

contract Factory {
    struct Deployed {
        string tradeID;
        address contractAddress;
    }

    error alreadyDeployed(string tradeID);

    mapping(string => bool) public isDeployed;
    Deployed[] internal deployedContracts;

    event ContractDeployed(string tradeID, address deployer, address contractAddress);

    function deployForwardContract(
        string memory _tradeID,
        string memory _irsTokenName,
        string memory _irsTokenSymbol,
        Types.IRS memory _irs,
        uint256 _initialMarginBuffer,
        uint256 _initialTerminationFee,
        address _participantRegistryContractAddress,
        address _ratesContractAddress,
        address _identityRegistryContractAddress
    ) external {
        if (isDeployed[_tradeID]) revert alreadyDeployed(_tradeID);

        ERC6123 forwardContract = new ERC6123{salt: bytes32(abi.encodePacked(_tradeID))}(
            _tradeID,
            _irsTokenName,
            _irsTokenSymbol,
            _irs,
            _initialMarginBuffer,
            _initialTerminationFee,
            _participantRegistryContractAddress,
            _ratesContractAddress,
            _identityRegistryContractAddress
        );

        deployedContracts.push(Deployed({
            tradeID: _tradeID,
            contractAddress: address(forwardContract)
        }));
        isDeployed[_tradeID] = true;

        emit ContractDeployed(_tradeID, msg.sender, address(forwardContract));
    }

    function getDeployedContracts() external view returns (Deployed[] memory) {
        return deployedContracts;
    }
}