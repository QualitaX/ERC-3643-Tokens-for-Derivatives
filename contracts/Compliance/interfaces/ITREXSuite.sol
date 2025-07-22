// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ITREXSuite {
    /**
     * @dev Get the address of the compliance contract.
     * @return Address of the compliance contract.
     */
    function getComplianceContractAddress() external view returns (address);

    /**
     * @dev Get the address of the identity registry contract.
     * @return Address of the identity registry contract.
     */
    function getIdentityRegistryAddress() external view returns (address);

    /**
     * @dev Get the address of the claim topics registry contract.
     * @return Address of the claim topics registry contract.
     */
    function getClaimTopicsRegistryAddress() external view returns (address);

    /**
     * @dev Get the address of the trusted issuers registry contract.
     * @return Address of the trusted issuers registry contract.
     */
    function getTrustedIssuersRegistryAddress() external view returns (address);

    /**
     * @dev Get the address of the token contract.
     * @return Address of the token contract.
     */
    function getTokenAddress() external view returns (address);
}