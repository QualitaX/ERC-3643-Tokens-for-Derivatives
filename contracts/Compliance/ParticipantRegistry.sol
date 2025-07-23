// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/ICompliance.sol";
import "./interfaces/ITREXSuite.sol";

contract ParticipantRegistry {
    address trexSuiteAddress;

    error userNotVerified(address user);
    error transferNotAllowed(address from, address to, uint256 amount);
    error tokenPaused();
    error walletFrozen(address user);

    constructor (address _trexSuiteAddress) {
        require(_trexSuiteAddress != address(0), "Invalid TREX Suite address");
        trexSuiteAddress = _trexSuiteAddress;
    }

    function checkUserVerification(address _user) external view {
        address identityRegistryAddress = ITREXSuite(trexSuiteAddress).getIdentityRegistryAddress();
        require(identityRegistryAddress != address(0), "Identity registry address is not set");
        ICompliance identityRegistry = ICompliance(identityRegistryAddress);
        if (!identityRegistry.isVerified(_user)) {
            revert userNotVerified(_user);
        }
    }

    function checkTransferCompliance(address _from, address _to, uint256 _amount) external view {
        address complianceContractAddress = ITREXSuite(trexSuiteAddress).getComplianceContractAddress();
        require(complianceContractAddress != address(0), "Compliance contract address is not set");
        ICompliance compliance = ICompliance(complianceContractAddress);
        if (!compliance.canTransfer(_from, _to, _amount)) {
            revert transferNotAllowed(_from, _to, _amount);
        }
    }

    function checkTokenPaused() external view {
        address tokenAddress = ITREXSuite(trexSuiteAddress).getTokenAddress();
        require(tokenAddress != address(0), "Token address is not set");
        ICompliance token = ICompliance(tokenAddress);
        if (token.paused()) {
            revert tokenPaused();
        }
    }

    function checkWalletFrozen(address _user) external view {
        address tokenAddress = ITREXSuite(trexSuiteAddress).getTokenAddress();
        require(tokenAddress != address(0), "Token address is not set");
        ICompliance token = ICompliance(tokenAddress);
        if(token.isFrozen(_user)) {
            revert walletFrozen(_user);
        }
    }
}