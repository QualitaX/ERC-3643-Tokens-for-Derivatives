## EXPERIMENTAL PROOF OF CONCEPT - NOT FOR PRODUCTION USE️

**WARNING: This codebase is an experimental proof of concept and contains known security vulnerabilities. DO NOT deploy to mainnet or use with real funds.**

## Known Critical Issues
- **Security vulnerabilities** that could result in complete loss of funds
- **Missing access controls** and reentrancy protections
- **Unaudited smart contracts** with potential logic errors

**This code is intended for research purposes only. The smart contracts have not been audited and contain known vulnerabilities. Use only for testing purposes.**


## Research & Documentation

For comprehensive analysis of the opportunities and challenges in implementing smart derivative contracts with compliant tokenized assets, see our detailed research paper:

**[ERC-3643 Tokens for Derivative Collateralization](docs/ERC-3643-Tokens-for-Derivative-Collateralization.pdf)**

---

# Overview

This project implements a smart contract for OTC Bilateral Trading of Uncleared Cash-Settled Forwards that removes counterparty credit risk and automates settlement processes. 
The system enables two parties to exchange fixed and floating interest rate payments based on a notional amount, with automatic margin calls and settlement through Chainlink oracles.

### Key Benefits

- **Trustless OTC Bilateral Trading**: No intermediaries required
- **Automated Settlement**: Daily margin calls and maturity settlement via Chainlink
- **Regulatory Compliance**: Identity verification and compliance checks
- **Risk Management**: Automatic collateral management and termination mechanisms
- **Audit**: Full on-chain audit trail

# Features

### Core Functionality
- **Trade Inception & Confirmation**: Secure trade initiation with matching validation
- **Automated Margin Calls**: Daily collateral adjustments based on rate movements
- **Settlement Automation**: Chainlink-powered settlement at maturity
- **Early Termination**: Mutual termination with agreed settlement amounts
- **Collateral Management**: Dynamic margin requirements and collateral posting

### Compliance & Security
- **Identity Verification**: ERC-3643 compatible identity registry integration
- **Access Control**: Role-based permissions with counterparty validation
- **Pausable Operations**: Emergency controls for risk management
- **Audit Trail**: Comprehensive event logging for all operations

### Risk Management

- **Pre-funded margin requirements**
- **Automatic termination on insufficient collateral**
- **Emergency pause functionality**
- **Multi-signature controls for critical operations**

### Token Standards
- **ERC-6123 inspired**: Cash-Settled Forward Derivative Contract implementation
- **ERC-7586**: Interest Rate Swap specific functionality
- **ERC-3643**: Security token compliance for regulated environments

##  Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Factory      │    │ Forward Contract│    │   ERC7586       │
│   Contract      │───▶│                 │───▶│  (Logic)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Participant   │    │  ERC6123Storage │    │   Chainlink     │
│   Registry      │◀──▶│    (State)      │───▶│   Oracles     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```


### Contract Components

| Contract | Purpose | Standard |
|----------|---------|----------|
| `ERC6123.sol` | Main derivative contract implementation | ERC-6123 |
| `ERC7586.sol` | Dorward/IRS-specific functionality | ERC-7586 |
| `Factory.sol` | Contract deployment factory | Custom |
| `ERC6123Storage.sol` | State management | Custom |
| `ParticipantRegistry.sol` | Identity & compliance | ERC-3643 |


## License

This experimental software is provided as-is for educational purposes. See LICENSE file for details.

## Contact

For questions about this proof of concept or collaboration opportunities, please open an issue in this repository.

---

**Remember: This is experimental software. Never use with real funds or deploy to production environments.**
