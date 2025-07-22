// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ICompliance {
    // Identity Registry Interface
    function contains(address _userAddress) external view returns (bool);
    function isVerified(address _userAddress) external view returns (bool);

    // Compliance Interface
    function canTransfer(address _from, address _to, uint256 _amount) external view returns (bool);

    // Token Interface
    function onchainID() external view returns (address);
    function version() external view returns (string memory);
    function compliance() external view returns (ICompliance);
    function paused() external view returns (bool);
    function isFrozen(address _userAddress) external view returns (bool);
    function getFrozenTokens(address _userAddress) external view returns (uint256);
}