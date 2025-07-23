// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

import "./interfaces/IERC6123.sol";
import "./ERC6123Storage.sol";
import "./assets/ERC7586.sol";

contract ERC6123 is IERC6123, ERC6123Storage, ERC7586 {
    event CollateralUpdated(string tradeID, address updater, uint256 collateralAmount);
    event LinkWithdrawn(string tradeID, address account, uint256 amount);
    event ContractSettled(string tradeID, address payer, address receiver, uint256 netSettlementAmount, uint256 fixedRatePayment, uint256 floatingRatePayment);
    event MarginAndFeesWithdrawn(string tradeID, address account, uint256 margin, uint256 fees);
    event SettlementForwderSet(string tradeID, address account, address forwarderAddress);
    event CollateralAdjustementForwaderSet(string tradeID, address account, address forwarderAddress);

    modifier onlyCounterparty() {
        require(
            msg.sender == irs.fixedRatePayer || msg.sender == irs.floatingRatePayer,
            "You are not a counterparty."
        );
        _;
    }

    modifier onlyAfterMaturity() {
        require(
            block.timestamp > irs.maturityDate,
            "Trade is not matured yet."
        );
        _;
    }

    constructor (
        string memory _tradeID,
        string memory _irsTokenName,
        string memory _irsTokenSymbol,
        Types.IRS memory _irs,
        uint256 _initialMarginBuffer,
        uint256 _initialTerminationFee,
        address _identityCheckAddress,
        address _identityRegistryAddress,
        address _complianceContractAddress
    ) ERC7586(_irsTokenName, _irsTokenSymbol, _irs, _identityCheckAddress, _complianceContractAddress, _identityRegistryAddress) {
        IParticipantRegistry(_identityCheckAddress).checkUserVerification(_irs.fixedRatePayer);
        IParticipantRegistry(_identityCheckAddress).checkUserVerification(_irs.floatingRatePayer);

        initialMarginBuffer = _initialMarginBuffer;
        initialTerminationFee = _initialTerminationFee;
        confirmationTime = 1 days;
        tradeID = _tradeID;
    }

    function inceptTrade(
        address _withParty,
        string memory _tradeData,
        int _position,
        int256 _paymentAmount,
        string memory _initialSettlementData
    ) external override onlyCounterparty onlyWhenTradeInactive onlyBeforeMaturity returns (string memory) {
        address inceptor = msg.sender;

        require(_withParty != address(0), "Invalid party address");
        if(inceptor == _withParty)
            revert cannotInceptWithYourself(msg.sender, _withParty);
        require(
            _withParty == irs.fixedRatePayer || _withParty == irs.floatingRatePayer,
            "Wrong 'withParty' address, MUST BE the counterparty"
        );
        require(_position == 1 || _position == -1, "invalid position");

        IParticipantRegistry(identityCheckAddress).checkUserVerification(inceptor);
        IParticipantRegistry(identityCheckAddress).checkUserVerification(_withParty);
        IParticipantRegistry(identityCheckAddress).checkTokenPaused();
        IParticipantRegistry(identityCheckAddress).checkWalletFrozen(inceptor);

        if(_position == 1) {
            irs.fixedRatePayer = msg.sender;
            irs.floatingRatePayer = _withParty;
        } else {
            irs.floatingRatePayer = msg.sender;
            irs.fixedRatePayer = _withParty;
        }

        tradeState = TradeState.Incepted;

        uint256 dataHash = uint256(keccak256(
            abi.encode(
                msg.sender,
                _withParty,
                _tradeData,
                _position,
                _paymentAmount,
                _initialSettlementData
            )
        ));

        pendingRequests[dataHash] = msg.sender;
        tradeHash = Strings.toString(dataHash);
        inceptingTime = block.timestamp;

        uint8 decimal = IERC20(irs.settlementCurrency).decimals();

        marginRequirements[msg.sender] = Types.MarginRequirement({
            marginBuffer: initialMarginBuffer * 10**decimal,
            terminationFee: initialTerminationFee * 10**decimal
        });

        //The initial margin (collateral) and the termination fee must be deposited into the contract
        uint256 marginAndFee = (initialMarginBuffer + initialTerminationFee) * 10**decimal;
        uint256 upfrontPayment = uint256(_paymentAmount) * 10**decimal;

        require(upfrontPayment == marginAndFee, "Invalid payment amount");
        IParticipantRegistry(identityCheckAddress).checkTransferCompliance(inceptor, address(this), marginAndFee);

        require(
            IERC20(irs.settlementCurrency).transferFrom(msg.sender, address(this), marginAndFee),
            "Failed to transfer the initial margin + the termination fee"
        );

        emit TradeIncepted(
            msg.sender,
            _withParty,
            tradeHash,
            tradeID,
            _position,
            _paymentAmount,
            _initialSettlementData
        );

        return tradeHash;
    }

    
    function confirmTrade(
        address _withParty,
        string memory _tradeData,
        int _position,
        int256 _paymentAmount,
        string memory _initialSettlementData
    ) external override onlyWhenTradeIncepted onlyWithinConfirmationTime {
        address inceptingParty = otherParty();

        IParticipantRegistry(identityCheckAddress).checkUserVerification(msg.sender);
        IParticipantRegistry(identityCheckAddress).checkUserVerification(_withParty);
        IParticipantRegistry(identityCheckAddress).checkTokenPaused();
        IParticipantRegistry(identityCheckAddress).checkWalletFrozen(msg.sender);

        uint256 confirmationHash = uint256(keccak256(
            abi.encode(
                _withParty,
                msg.sender,
                _tradeData,
                -_position,
                -_paymentAmount,
                _initialSettlementData
            )
        ));

        if(pendingRequests[confirmationHash] != inceptingParty)
            revert inconsistentTradeDataOrWrongAddress(inceptingParty, confirmationHash);

        delete pendingRequests[confirmationHash];
        tradeState = TradeState.Confirmed;

        uint256 decimal = IERC20(irs.settlementCurrency).decimals();

        marginRequirements[msg.sender] = Types.MarginRequirement({
            marginBuffer: initialMarginBuffer * 10**decimal,
            terminationFee: initialTerminationFee * 10**decimal
        });

        //The initial margin and the termination fee must be deposited into the contract
        uint256 marginAndFee = (initialMarginBuffer + initialTerminationFee) * 10**decimal;

        uint256 upfrontPayment = uint256(_paymentAmount) * 10**decimal;
        
        require(upfrontPayment == marginAndFee, "Invalid payment amount");
        IParticipantRegistry(identityCheckAddress).checkTransferCompliance(msg.sender, address(this), marginAndFee);

        require(
            IERC20(irs.settlementCurrency).transferFrom(msg.sender, address(this), marginAndFee),
            "Failed to transfer the initial margin + the termination fee"
        );

        emit TradeConfirmed(msg.sender, tradeID);
    }

    function cancelTrade(
        address _withParty,
        string memory _tradeData,
        int _position,
        int256 _paymentAmount,
        string memory _initialSettlementData
    ) external override onlyWhenTradeIncepted onlyBeforeMaturity {
        address inceptingParty = msg.sender;

        uint256 confirmationHash = uint256(keccak256(
            abi.encode(
                msg.sender,
                _withParty,
                _tradeData,
                _position,
                _paymentAmount,
                _initialSettlementData
            )
        ));

        if(pendingRequests[confirmationHash] != inceptingParty)
            revert inconsistentTradeDataOrWrongAddress(inceptingParty, confirmationHash);

        delete pendingRequests[confirmationHash];
        tradeState = TradeState.Inactive;

        emit TradeCanceled(msg.sender, tradeID);
    }

    /**
    * @notice We don't implement the `initiateSettlement` function since this is done automatically
    */
    function initiateSettlement() external pure override {
        revert obseleteFunction();
    }
    
    /**
    * @notice In case of Chainlink ETH Staking Rate, the rateMultiplier = 3. And the result MUST be devided by 10^7
    *         We assume rates are input in basis point
    */
    function performSettlement(
        int256 _settlementAmount,
        string memory _settlementData
    ) public override {
        swap();

        tradeState = TradeState.Matured;
        emit SettlementEvaluated(msg.sender, _settlementAmount, _settlementData);
    }

    /**
    * @notice We don't implement the `afterTransfer` function since the transfer of the contract
    *         net present value is transferred in the `performSettlement function`.
    */
    function afterTransfer(bool /**success*/, string memory /*transactionData*/) external pure override {
        revert obseleteFunction();
    }

    /**-> NOT CLEAR: Why requesting trade termination after the trade has been settled ? */
    function requestTradeTermination(
        string memory _tradeHash,
        int256 _terminationPayment,
        string memory _terminationTerms
    ) external override onlyCounterparty onlyWhenSettled onlyBeforeMaturity {
        if(
            keccak256(abi.encodePacked(_tradeHash)) != keccak256(abi.encodePacked(tradeHash))
        ) revert invalidTrade(_tradeHash);

        uint256 terminationHash = uint256(keccak256(
            abi.encode(
                _tradeHash,
                "terminate",
                _terminationPayment,
                _terminationTerms
            )
        ));

        pendingRequests[terminationHash] = msg.sender;

        emit TradeTerminationRequest(msg.sender, tradeID, _terminationPayment, _terminationTerms);
    }

    function confirmTradeTermination(
        string memory _tradeHash,
        int256 _terminationPayment,
        string memory _terminationTerms
    ) external onlyCounterparty onlyWhenSettled onlyBeforeMaturity {
        address pendingRequestParty = otherParty();

        uint256 confirmationhash = uint256(keccak256(
            abi.encode(
                _tradeHash,
                "terminate",
                _terminationPayment,
                _terminationTerms
            )
        ));

        if(pendingRequests[confirmationhash] != pendingRequestParty)
            revert inconsistentTradeDataOrWrongAddress(pendingRequestParty, confirmationhash);

        delete pendingRequests[confirmationhash];

        address terminationPayer = otherParty();
        terminationReceiver = msg.sender;
        uint256 buffer = marginRequirements[terminationReceiver].marginBuffer + marginRequirements[terminationPayer].marginBuffer;
        uint256 fees = marginRequirements[terminationReceiver].terminationFee + marginRequirements[terminationPayer].terminationFee;
        terminationAmount = buffer + fees;

        _updateMargin(terminationPayer, terminationReceiver);

        terminateSwap();

        tradeState = TradeState.Terminated;

        emit TradeTerminationConfirmed(msg.sender, tradeID, int256(terminationAmount), _terminationTerms);
    }

    function cancelTradeTermination(
        string memory _tradeHash,
        int256 _terminationPayment,
        string memory _terminationTerms
    ) external onlyWhenSettled onlyBeforeMaturity {
        address pendingRequestParty = msg.sender;

        uint256 confirmationHash = uint256(keccak256(
            abi.encode(
                _tradeHash,
                "terminate",
                _terminationPayment,
                _terminationTerms
            )
        ));

        if(pendingRequests[confirmationHash] != pendingRequestParty)
            revert inconsistentTradeDataOrWrongAddress(pendingRequestParty, confirmationHash);

        delete pendingRequests[confirmationHash];

        emit TradeTerminationCanceled(msg.sender, tradeID, _terminationTerms);
    }

    /**
     * @notice Checks if collateral needs to be posted by either party. This function is called daily.
     *         Automatically called by the Chainlink Keeper.
    */
    function CheckMarginCall() external onlyWhenTradeConfirmed onlyBeforeMaturity {
        require(
            msg.sender == collateralAdjustementForwarderAddress,
            "Only the settlement forwarder can call this function"
        );

        uint256 notional = irs.notionalAmount;
        int256 fixedRate = irs.swapRate;
        int256 floatingRate = ITreehouse(treehouseContractAddress).getRollingAvgEsrForNdays(7) + irs.spread;
        uint256 principalDecimal = IERC20(irs.settlementCurrency).decimals();
        uint256 rateDecimal = ITreehouse(treehouseContractAddress).decimals();

        uint256 fixedPayment = notional * uint256(fixedRate) * 10**principalDecimal * 100 / (10**rateDecimal * 36525);
        uint256 floatingPayment = notional * uint256(floatingRate) * 10**principalDecimal * 100 / (10**rateDecimal * 36525); // spread = 0

        uint256 netCollateralAmount;
        if(fixedRate == floatingRate) {
            emit CollateralUpdated(tradeID, address(0), 0);
        } else if(fixedRate > floatingRate) {
            uint256 currentCollateralAmount = marginCalls[irs.fixedRatePayer];
            netCollateralAmount = fixedPayment - floatingPayment;
            marginCalls[irs.fixedRatePayer] = currentCollateralAmount + netCollateralAmount;

            emit CollateralUpdated(tradeID, irs.fixedRatePayer, netCollateralAmount);
        } else {
            uint256 currentCollateralAmount = marginCalls[irs.floatingRatePayer];
            netCollateralAmount = floatingPayment - fixedPayment;
            marginCalls[irs.floatingRatePayer] = currentCollateralAmount + netCollateralAmount;

            emit CollateralUpdated(tradeID, irs.floatingRatePayer, netCollateralAmount);
        }
    }

    /**
     * @notice Settles the SDC contract after it matures
     *         This function is called by the Chainlink Keeper.
    */
    function settle() external onlyAfterMaturity {
        require(
            msg.sender == settlementForwarderAddress,
            "Only the settlement forwarder can call this function"
        );

        uint256 principalDecimal = IERC20(irs.settlementCurrency).decimals();

        fixedRatePayment = marginRequirements[irs.fixedRatePayer].marginBuffer - initialMarginBuffer;
        floatingRatePayment = marginRequirements[irs.floatingRatePayer].marginBuffer - initialMarginBuffer;

        if(fixedRatePayment == floatingRatePayment) {
            burn(irs.fixedRatePayer, 10**principalDecimal);
            burn(irs.floatingRatePayer, 10**principalDecimal);

            marginCalls[irs.fixedRatePayer] = 0;
            marginCalls[irs.floatingRatePayer] = 0;

            irsReceipts.push(
                Types.IRSReceipt({
                    from: address(0),
                    to: address(0),
                    netAmount: 0,
                    timestamp: block.timestamp,
                    fixedRatePayment: fixedRatePayment,
                    floatingRatePayment: floatingRatePayment
                })
            );
        } else if(fixedRatePayment > floatingRatePayment) {
            settlementAmount = fixedRatePayment - floatingRatePayment;
            payerParty = irs.fixedRatePayer;
            receiverParty = irs.floatingRatePayer;

            marginRequirements[payerParty].marginBuffer = marginRequirements[payerParty].marginBuffer - settlementAmount;
            marginCalls[payerParty] = 0;

            burn(irs.fixedRatePayer, 10**principalDecimal);
            burn(irs.floatingRatePayer, 10**principalDecimal);
            _updateIRSReceipt(settlementAmount);
            performSettlement(int256(settlementAmount), tradeID);

            emit ContractSettled(tradeID, payerParty, receiverParty, settlementAmount, fixedRatePayment, floatingRatePayment);
        } else {
            settlementAmount = floatingRatePayment - fixedRatePayment;
            payerParty = irs.floatingRatePayer;
            receiverParty = irs.fixedRatePayer;

            marginRequirements[payerParty].marginBuffer = marginRequirements[payerParty].marginBuffer - settlementAmount;
            marginCalls[payerParty] = 0;

            burn(irs.fixedRatePayer, 10**principalDecimal);
            burn(irs.floatingRatePayer, 10**principalDecimal);
            _updateIRSReceipt(settlementAmount);
            performSettlement(int256(settlementAmount), tradeID);

            emit ContractSettled(tradeID, payerParty, receiverParty, settlementAmount, fixedRatePayment, floatingRatePayment);
        }
    }

    /**
    * @notice Trabsfers the collateral to the smart contract after receiving a margin call
    */
    function postCollateral() external onlyCounterparty onlyWhenTradeConfirmed onlyBeforeMaturity {
        IParticipantRegistry(identityCheckAddress).checkUserVerification(msg.sender);

        uint256 currentMargin = marginCalls[msg.sender];
        uint256 buffer = marginRequirements[msg.sender].marginBuffer;

        marginCalls[msg.sender] = 0;
        marginRequirements[msg.sender].marginBuffer = buffer + currentMargin;
        
        require(
            IERC20(irs.settlementCurrency).transferFrom(msg.sender, address(this), currentMargin),
            "Failed to transfer the collateral"
        );

        emit CollateralUpdated(tradeID, msg.sender, marginRequirements[msg.sender].marginBuffer);
    }

    function setCollateralAdjustementForwarderAddress(address _address) external onlyCounterparty {
        collateralAdjustementForwarderAddress = _address;

        emit CollateralAdjustementForwaderSet(tradeID, msg.sender, _address);
    }

    function setsettlementForwarderAddress(address _address) external onlyCounterparty {
        settlementForwarderAddress = _address;

        emit SettlementForwderSet(tradeID, msg.sender, _address);
    }

    /**
    * @notice Withdraws the initial margin and the termination fee after the trade has matured
    *         The margin buffer and the initial fees are reset to 0 after the withdrawal
    */
    function withdrawInitialMarginAndTerminationFees() external onlyCounterparty onlyAfterMaturity {
        IParticipantRegistry(identityCheckAddress).checkUserVerification(msg.sender);

        uint256 amount = marginRequirements[msg.sender].marginBuffer + marginRequirements[msg.sender].terminationFee;
        
        require(
            IERC20(irs.settlementCurrency).transfer(msg.sender, amount),
            "Failed to transfer the initial margin and the termination fee"
        );

        emit MarginAndFeesWithdrawn(tradeID, msg.sender, marginRequirements[msg.sender].marginBuffer, marginRequirements[msg.sender].terminationFee);

        marginRequirements[msg.sender].marginBuffer = 0;
        marginRequirements[msg.sender].terminationFee = 0;
    }

    /**
     * @notice Allow withdraw of Link tokens from the contract
     * !!!!!   SECURE THIS FUNCTION FROM BEING CALLED BY NOT ALLOWED USERS !!!!!
     */
    function withdrawLink() public onlyAfterMaturity {
        LinkTokenInterface link = LinkTokenInterface(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );

        emit LinkWithdrawn(tradeID, msg.sender, link.balanceOf(address(this)));
    }

    function getContractLINKBalance() external view returns(uint256) {
        LinkTokenInterface link = LinkTokenInterface(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        return link.balanceOf(address(this));
    }

    /**---------------------- Internal Private and other view functions ----------------------*/
    function _updateIRSReceipt(uint256 _settlementAmount) private {
        irsReceipts.push(
            Types.IRSReceipt({
                from: payerParty,
                to: receiverParty,
                netAmount: _settlementAmount,
                timestamp: block.timestamp,
                fixedRatePayment: fixedRatePayment,
                floatingRatePayment: floatingRatePayment
            })
        );
    }

    function _updateMargin(address _payer, address _receiver) private {
        marginRequirements[_payer].marginBuffer = 0;
        marginRequirements[_payer].terminationFee = 0;
        marginRequirements[_receiver].marginBuffer = 0;
        marginRequirements[_receiver].terminationFee = 0;
    }

    function getTradeState() external view returns(TradeState) {
        return tradeState;
    }

    function getTradeID() external view returns(string memory) {
        return tradeID;
    }

    function getTradeHash() external view returns(string memory) {
        return tradeHash;
    }

    function getInceptingTime() external view returns(uint256) {
        return inceptingTime;
    }

    function getConfirmationTime() external view returns(uint256) {
        return confirmationTime;
    }

    function getInitialMargin() external view returns(uint256) {
        return initialMarginBuffer;
    }

    function getInitialTerminationFee() external view returns(uint256) {
        return initialTerminationFee;
    }

    function getMarginCall(address _account) external view returns(uint256) {
        return marginCalls[_account];
    }

    function getMarginRequirement(address _account) external view returns(Types.MarginRequirement memory) {
        return marginRequirements[_account];
    }

    function otherParty() internal view returns(address) {
        return msg.sender == irs.fixedRatePayer ? irs.floatingRatePayer : irs.fixedRatePayer;
    }

    function otherParty(address _account) internal view returns(address) {
        return _account == irs.fixedRatePayer ? irs.floatingRatePayer : irs.fixedRatePayer;
    }

    function getIRSReceipts() external view returns(Types.IRSReceipt[] memory) {
        return irsReceipts;
    }
}