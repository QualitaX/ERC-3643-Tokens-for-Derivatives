// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../interfaces/ICompliance.sol";
import "./interfaces/ITREXSuite.sol";

contract ParticipantRegistry {
    address trexSuiteAddress;
    address constant internal identityRegistryAddress = address(0x71a027b89bd4fc5245cf38faC4b02C68fD0A9018);
    address constant internal tokenAddress = address(0x97d66cb700D69F3059F2ad482A49A5429F67b7f7);

    error userNotVerified(address user);
    error transferNotAllowed(address from, address to, uint256 amount);
    error tokenPaused();
    error walletFrozen(address user);

    constructor (address _trexSuiteAddress) {
        require(_trexSuiteAddress != address(0), "Invalid TREX Suite address");
        trexSuiteAddress = _trexSuiteAddress;
    }

    function checkUserVerification(address _user) external view {
        //address identityRegistryAddress = ITREXSuite(trexSuiteAddress).getIdentityRegistryAddress();
        require(identityRegistryAddress != address(0), "Identity registry address is not set");
        ICompliance identityRegistry = ICompliance(identityRegistryAddress);
        if (!identityRegistry.isVerified(_user)) {
            revert userNotVerified(_user);
        }
    }

    function checkTokenPaused() external view {
        //address tokenAddress = ITREXSuite(trexSuiteAddress).getTokenAddress();
        require(tokenAddress != address(0), "Token address is not set");
        ICompliance token = ICompliance(tokenAddress);
        if (token.paused()) {
            revert tokenPaused();
        }
    }

    function checkWalletFrozen(address _user) external view {
        //address tokenAddress = ITREXSuite(trexSuiteAddress).getTokenAddress();
        require(tokenAddress != address(0), "Token address is not set");
        ICompliance token = ICompliance(tokenAddress);
        if(token.isFrozen(_user)) {
            revert walletFrozen(_user);
        }
    }
}