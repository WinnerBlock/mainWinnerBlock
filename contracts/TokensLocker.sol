/**
 *Submitted for verification at BscScan.com on 2022-04-19
*/

// SPDX-License-Identifier: MIT
// @dev Telegram: @retropico

pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract TokensLocker is Context, Ownable {

    address public tokenContract = 0xB1D3e4346616Ba13f5d21fa07588f3bdF18abf47;
    address public presaleWallet = 0x70b0ba11D020408d651FcA0156BA16370fF3e93C;
    address public presaleContract;

    //@dev Users locked tokens infos
    address[] public wallets;
    mapping(address => uint256) public tokensAmount;
    mapping(address => uint256) public timeLocked;
    mapping(address => uint256) public unlockDate;

    event walletAdded(address wallet, uint256 tokensAmount, uint256 unlockDate);
    event claimedTokens(address tokenContract, address to, uint256 amount);
    event getRefundedTokens(address tokenContract, address to, uint256 amount);

    //@dev Called by presaleContract with tokensAmount transfered into tokens locker
    function addWallet(address wallet, uint256 amount, uint256 _timeLocked) external {   
    	require(msg.sender == owner() || msg.sender == presaleWallet || msg.sender == presaleContract, "Not the owner or presale actor");
    	wallets.push(wallet);
    	tokensAmount[wallet] = tokensAmount[wallet] + amount;
        
        //@dev Add new time lock to remaining time if already locked
        if (unlockDate[wallet] >= block.timestamp) {
            uint256 remainingTime = unlockDate[wallet] - block.timestamp;
            timeLocked[wallet] = remainingTime + _timeLocked;
            unlockDate[wallet] = unlockDate[wallet] + timeLocked[wallet];
        }
        else {
            unlockDate[wallet] = block.timestamp + _timeLocked;
            timeLocked[wallet] = _timeLocked;
        }
    }

    //@dev Reset Locked Wallet in case of refund (primos only)
    function resetWalletForRefund(address wallet) external onlyOwner {
        IBEP20 token = IBEP20(tokenContract);
        token.transfer(presaleWallet, tokensAmount[wallet]);
        emit getRefundedTokens(tokenContract, presaleWallet, tokensAmount[wallet]);
        tokensAmount[wallet] = 0;
        timeLocked[wallet] = 0;
        unlockDate[wallet] = 0;
    }

    //@dev Claim locked tokens
    function claimTokens(address wallet) public {
       require(block.timestamp >= unlockDate[wallet], "You can't release your tokens yet !");
       require(msg.sender == wallet || msg.sender == owner() || msg.sender == presaleWallet, "You have no locked tokens !");
       
       IBEP20 token = IBEP20(tokenContract);
       token.transfer(wallet, tokensAmount[wallet]);
       emit claimedTokens(tokenContract, wallet, tokensAmount[wallet]);
       tokensAmount[wallet] = 0;
       timeLocked[wallet] = 0;
       unlockDate[wallet] = 0;
    }

    //@dev Get infos about tokens locked linked to wallet
    function infos(address wallet) public view returns(address, uint256, uint256, uint256) {
        return (wallet, tokensAmount[wallet], timeLocked[wallet], unlockDate[wallet]);
    }
        
    function setPresaleWallet(address wallet) external onlyOwner {
        presaleWallet = wallet;
    }
    
    function setPresaleContract(address _presaleContract) external onlyOwner {
        presaleContract = _presaleContract;
    }
    
    function setTokenContract(address _tokenContract) external onlyOwner {
        tokenContract = _tokenContract;
    }  
}