// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

//import "../interfaces/IERC20.sol";
import "../Compliance/interfaces/IToken.sol";
import "../Types.sol";

/**
* @notice This token contract allows tokenize Interest Rate Swap cashflows.
*         Approval and Transfer of tokens are allowed only before the IRS contract reaches maturity.
*         This feature prevents tokens to be traded after the contract has matured.
*         When tokens are transferred to an account, the ownership (fixedRatePayer or floatingRatePayer) is also transferred.
*         The contract doesn't support partial transfer of tokens. All the balance must be transferred for the transaction to be successful.
*/
abstract contract IRSToken is IToken {
    Types.IRS internal irs;

    modifier onlyBeforeMaturity() {
        require(
            block.timestamp <= irs.maturityDate,
            "IRS contract has reached the Maturity Date"
        );
        _;
    }

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;
    uint256 internal _maxSupply;
    uint256 private _burnedSupply;

    string private _name;
    string private _symbol;

    error supplyExceededMaxSupply(uint256 totalSupply_, uint256 maxSupply_);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function maxSupply() public view returns(uint256) {
        return _maxSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual onlyBeforeMaturity {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance == amount, "ERC20: you must transfer all your balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        if(from == irs.fixedRatePayer) {
            irs.fixedRatePayer = to;
        } else if(from == irs.floatingRatePayer) {
            irs.floatingRatePayer = to;
        } else {
            revert("invalid from address");
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function mint(address account, uint256 amount) public virtual override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        if (_totalSupply + _burnedSupply > _maxSupply) revert supplyExceededMaxSupply(_totalSupply, _maxSupply);

        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
            _burnedSupply += amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual onlyBeforeMaturity {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function setName(string calldata name_) external {}
    function setSymbol(string calldata symbol_) external {}
    function setOnchainID(address _onchainID) external {}
    function pause() external {}
    function unpause() external {}
    function setAddressFrozen(address _userAddress, bool _freeze) external {}
    function freezePartialTokens(address _userAddress, uint256 _amount) external {}
    function unfreezePartialTokens(address _userAddress, uint256 _amount) external {}
    function setIdentityRegistry(address _identityRegistry) external {}
    function setCompliance(address _compliance) external {}
    function forcedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool) {}
    function recoveryAddress(
        address _lostWallet,
        address _newWallet,
        address _investorOnchainID
    ) external returns (bool) {}
    function batchTransfer(address[] calldata _toList, uint256[] calldata _amounts) external {}
    function batchForcedTransfer(
        address[] calldata _fromList,
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external {}
    function batchMint(address[] calldata _toList, uint256[] calldata _amounts) external {}
    function batchBurn(address[] calldata _userAddresses, uint256[] calldata _amounts) external {}
    function batchSetAddressFrozen(address[] calldata _userAddresses, bool[] calldata _freeze) external {}
    function batchFreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external {}
    function batchUnfreezePartialTokens(address[] calldata _userAddresses, uint256[] calldata _amounts) external {}
    function onchainID() external view returns (address) {}
    function version() external view returns (string memory) {}
    function identityRegistry() external view returns (IIdentityRegistry) {}
    function compliance() external view returns (IModularCompliance) {}
    function paused() external view returns (bool) {}
    function isFrozen(address _userAddress) external view returns (bool) {}
    function getFrozenTokens(address _userAddress) external view returns (uint256) {}
}