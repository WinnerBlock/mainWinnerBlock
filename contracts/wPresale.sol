/**
 *Submitted for verification at BscScan.com on 2022-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



interface IToken {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}

contract wPresale is Ownable {
    using SafeMath for uint256;
    
    //@dev BEP20 token infos
    address public tokenAddress = 0xB1D3e4346616Ba13f5d21fa07588f3bdF18abf47;
    uint256 public tokenDecimals = 9;
    uint256 public tokensPerBNB = 357142857;
    uint256 public tokensPerBNBDecimals = 2;
    
    //@dev Presale infos & parameters
    bool public isPresaleOpen = true;
    mapping(address => uint256) public userInvests;
    uint256 public minBNBLimit = 150000000000000000;
    uint256 public maxBNBLimit = 700000000000000000000;
    address public recipient = 0x70b0ba11D020408d651FcA0156BA16370fF3e93C;
    uint256 public tokensSold = 0;
    uint256 public totalBNBAmount = 0;    

    address deadWallet = 0x000000000000000000000000000000000000dEaD;
    
    //@dev Tokens locker parameters
    address public tokensLockerAddress;
    uint256[] public investRange = [25, 63, 125, 250];
    uint256[] public lockupTime = [90, 180, 270, 360];

    //@dev Whitelist parameters
    mapping(address => bool) public whitelisted;
    bool public isOnlyWhitelisted = true;
    

    //@dev BEP20 token funtions
    function setTokenAddress(address token) external onlyOwner {
        require(token != address(0), "Token address must be different than 0");
        tokenAddress = token;
    }

    function setTokenDecimals(uint256 decimals) external onlyOwner {
        tokenDecimals = decimals;
    }
    

    //@dev Tokens locker functions
    function setInvestRange(uint256[] memory _investRange) external onlyOwner {
        investRange = _investRange;
    }

    function setLockupTime(uint256[] memory _lockupTime) external onlyOwner {
        lockupTime = _lockupTime;
    }
    
    function setTokensLockerAddress(address _tokensLockerAddress) external onlyOwner {
	    require(_tokensLockerAddress != address(0), "Tokens Locker address must be different than 0");
        tokensLockerAddress = _tokensLockerAddress;
    }
    
    function addWalletToTokenLocker(address _userAddress, uint256 tokenAmount, uint256 duration) private {
        TokensLocker ITokensLocker = TokensLocker(tokensLockerAddress);
        ITokensLocker.addWallet(_userAddress, tokenAmount, duration);
        require(IToken(tokenAddress).transfer(tokensLockerAddress, tokenAmount), "Not enough tokens in presale contract!");
    }
    
    function getLockupTime(uint256 amount) public view returns (uint256 range) {
        uint256 duration = 0;

        if(amount <= investRange[0]*10**18){
            duration = 0;
        }
        else if(amount <= investRange[1]*10**18){
            duration = lockupTime[0] * 1 days;
        }
        else if(amount <= investRange[2]*10**18){
            duration = lockupTime[1] * 1 days;
        }
        else if(amount <= investRange[3]*10**18){
            duration = lockupTime[2] * 1 days;
        }
        else {
            duration = lockupTime[3] * 1 days;
        }
        return duration;
    }

    //@dev Whitelist functions
    function setWhitelistStatus(bool status) external onlyOwner {
        isOnlyWhitelisted = status;
    }
    
    function addToWhitelist(address _beneficiary) external onlyOwner {
    	whitelisted[_beneficiary] = true;
    }
    
    function addManyToWhitelist(address[] memory _beneficiaries) external onlyOwner {
    	for (uint256 i = 0; i < _beneficiaries.length; i++) {
      		whitelisted[_beneficiaries[i]] = true;
    	}
    }
    
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
    	whitelisted[_beneficiary] = false;
    }


    //@dev Presale functions
    function openPresale() external onlyOwner {
        require(!isPresaleOpen, "Presale is open");
        isPresaleOpen = true;
    }

    function closePresale() external onlyOwner {
        require(isPresaleOpen, "Presale is not opened yet");
        isPresaleOpen = false;
    }
    
    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setMinBNBLimit(uint256 amount) external onlyOwner {
        minBNBLimit = amount.div(100);
    }

    function setMaxBNBLimit(uint256 amount) external onlyOwner {
        maxBNBLimit = amount;
    }

    function setTokensPerBNB(uint256 _tokensPerBNB) external onlyOwner {
        tokensPerBNB = _tokensPerBNB;
    }

    function setTokensPerBNBDecimals(uint256 decimals) external onlyOwner {
        tokensPerBNBDecimals = decimals;
    }
    
    function getTokensPerBNB(uint256 amount) internal view returns (uint256) {
        return amount.mul(tokensPerBNB).div(10**(uint256(18).sub(tokenDecimals).add(tokensPerBNBDecimals)));
    }
    
    receive() external payable {
        buyToken();
    }

    function buyToken() public payable {
    
        require(isPresaleOpen, "Presale is not open");
        
        //@dev Check 24h early whitelist
        if (isOnlyWhitelisted) {
             require(whitelisted[msg.sender], "You are not whitelisted !");
        }
       
        //@dev Check users investments
        require(userInvests[msg.sender].add(msg.value) <= maxBNBLimit && userInvests[msg.sender].add(msg.value) >= minBNBLimit, "Investment too high or too low");
        
        //@dev Get tokens amount per BNB
        uint256 tokenAmount = getTokensPerBNB(msg.value);  
        
        //@dev Check lockup time and transfer or lock tokens
        uint256 lockupDuration = getLockupTime(msg.value);
        if (lockupDuration == 0) {
            require(IToken(tokenAddress).transfer(msg.sender, tokenAmount), "Not enough tokens in presale contract");
        } else {
            addWalletToTokenLocker(_msgSender(), tokenAmount, lockupDuration);
        }
        
        //@dev Infos update
        tokensSold += tokenAmount;
        totalBNBAmount = totalBNBAmount + msg.value;
        userInvests[msg.sender] = userInvests[msg.sender].add(msg.value);

	    //@dev Transfer BNB to recipient
        payable(recipient).transfer(msg.value);
    }

    function burnUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "Burn tokens is forbidden until the presale is closed");
        IToken(tokenAddress).transfer(deadWallet, IToken(tokenAddress).balanceOf(address(this)));
    }

    function getUnsoldTokens(address to) external onlyOwner {
        require(!isPresaleOpen, "Get unsold tokens is forbidden until the presale is closed");        
        IToken(tokenAddress).transfer(to, IToken(tokenAddress).balanceOf(address(this)));
    }
}