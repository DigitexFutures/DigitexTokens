pragma solidity ^0.4.19;

//import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";
import "./oraclizeAPI.sol";

//import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./SafeMath.sol";


//import "github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Ownable.sol";

//import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/BurnableToken.sol";
import "./BurnableToken.sol";

import "./Standard223Token.sol";
import './RefundVault.sol';


contract DGTX is usingOraclize, Ownable, RefundVault, BurnableToken, Standard223Token
{
    string public constant name = "DigitexFutures";
    string public constant symbol = "DGTX";
    uint8 public constant decimals = 18;
    uint public constant DECIMALS_MULTIPLIER = 10**uint(decimals);
    
    uint public ICOstarttime = 1516024800;           //2018.1.15  January 15, 2018 2:00:00 PM GMT 1516024800
    uint public ICOendtime = 1518757200;             //2018.2.15 February 16, 2018 5:00:00 AM GMT 1518757200
    
    uint public minimumInvestmentInWei = DECIMALS_MULTIPLIER / 100;
    uint public maximumInvestmentInWei = 1000 * 1 ether;
    address saleWalletAddress;

    uint256 public constant softcapInTokens = 25000000 * DECIMALS_MULTIPLIER; //25000000 * DECIMALS_MULTIPLIER;
    uint256 public constant hardcapInTokens = 650000000 * DECIMALS_MULTIPLIER;
    
    uint256 public totaltokensold = 0;
    
    uint public USDETH = 1205;
    uint NumberOfTokensIn1USD = 100;
    
    //RefundVault public vault;
    bool public isFinalized = false;
    event Finalized();
    
    event newOraclizeQuery(string description);
    event newETHUSDPrice(string price);
    
    function increaseSupply(uint value, address to) public onlyOwner returns (bool) {
        totalSupply = totalSupply.add(value);
        balances[to] = balances[to].add(value);
        Transfer(0, to, value);
        return true;
    }
    
    /*function decreaseSupply(uint value, address from) public onlyOwner returns (bool) {
        balances[from] = balances[from].sub(value);
        totalSupply = totalSupply.sub(value);
        Transfer(from, 0, value);
        return true;
    }*/

    
    
    function burn(uint256 _value) public {
        require(0 != _value);
        
        super.burn(_value);
        Transfer(msg.sender, 0, _value);
    }
    
    /*function StartNextCampain(uint _ICOstarttime, uint _ICOendtime, uint _minimumInvestment, uint _maximumInvestment, uint _NumberOfTokensIn1USD) public onlyOwner {
        require(!ICOactive());
        require(State.Released == vault_state);
        
        ICOstarttime = _ICOstarttime;
        ICOendtime = _ICOendtime;
        minimumInvestmentInWei = _minimumInvestment;
        maximumInvestmentInWei = _maximumInvestment;
        NumberOfTokensIn1USD = _NumberOfTokensIn1USD;
        UpdateUSDETHPriceAfter(0);
    }*/

    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        uint256 localOwnerBalance = balances[owner];
        balances[newOwner] = balances[newOwner].add(localOwnerBalance);
        balances[owner] = 0;
        vault_wallet = newOwner;
        Transfer(owner, newOwner, localOwnerBalance);
        super.transferOwnership(newOwner);
    }
    
    function finalize() public {
        require(!isFinalized);
        require(ICOendtime < now);
        finalization();
        Finalized();
        isFinalized = true;
    }
  
    function depositFunds() internal {
        vault_deposit(msg.sender, msg.value * 96 / 100);
    }
    
    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());
        
        uint256 refundedTokens = balances[msg.sender];
        balances[owner] = balances[owner].add(refundedTokens);
        totaltokensold = totaltokensold.sub(refundedTokens);
        balances[msg.sender] = 0;
        
        Transfer(msg.sender, owner, refundedTokens);
        
        vault_refund(msg.sender);
    }
    
    // vault finalization task, called when owner calls finalize()
    function finalization() internal {
        if (goalReached()) {
            vault_releaseDeposit();
        } else {
            vault_enableRefunds();
            
        }
    }
    
    function releaseUnclaimedFunds() onlyOwner public {
        require(vault_state == State.Refunding && now >= refundDeadline);
        vault_releaseDeposit();
    }

    function goalReached() public view returns (bool) {
        return totaltokensold >= softcapInTokens;
    }    
    
    function __callback(bytes32 myid, string result) {
        require (msg.sender == oraclize_cbAddress());

        newETHUSDPrice(result);

        USDETH = parseInt(result, 0);
        if ((now < ICOendtime) && (totaltokensold < hardcapInTokens))
        {
            UpdateUSDETHPriceAfter(day); //update every 24 hours
        }
        
    }
    

  function UpdateUSDETHPriceAfter (uint delay) private {
      
    newOraclizeQuery("Update of USD/ETH price requested");
    oraclize_query(delay, "URL", "json(https://api.etherscan.io/api?module=stats&action=ethprice&apikey=YourApiKeyToken).result.ethusd");
       
  }


  

  function DGTX() public payable {
      totalSupply = 1000000000 * DECIMALS_MULTIPLIER;
      balances[owner] = totalSupply;
      vault_wallet = owner;
      Transfer(0x0, owner, totalSupply);
      initializeSaleWalletAddress();
      UpdateUSDETHPriceAfter(0);
  }
  
  function initializeSaleWalletAddress() private {
      saleWalletAddress = 0xd8A56FB51B86e668B5665E83E0a31E3696578333;
      
  }
  

  /*function  SendEther ( uint _amount) onlyOwner public {
      require(this.balance > _amount);
      owner.transfer(_amount);
  } */

  

  function () payable {
       if (msg.sender != owner) {
          buy();
       }
  }
  
  function ICOactive() public view returns (bool success) {
      if (ICOstarttime < now && now < ICOendtime && totaltokensold < hardcapInTokens) {
          return true;
      }
      
      return false;
  }

  function buy() payable {

      

      require (msg.value >= minimumInvestmentInWei && msg.value <= maximumInvestmentInWei);

      require (ICOactive());
      
      uint256 NumberOfTokensToGive = msg.value.mul(USDETH).mul(NumberOfTokensIn1USD);
     

      
      if(now <= ICOstarttime + week) {
          
          NumberOfTokensToGive = NumberOfTokensToGive.mul(120).div(100);
          
      } else if(now <= ICOstarttime + 2*week){
          
          NumberOfTokensToGive = NumberOfTokensToGive.mul(115).div(100);
          
      } else if(now <= ICOstarttime + 3*week){
          
          NumberOfTokensToGive = NumberOfTokensToGive.mul(110).div(100);
          
      } else{
          NumberOfTokensToGive = NumberOfTokensToGive.mul(105).div(100);
      }
      
      uint256 localTotaltokensold = totaltokensold;
      require(localTotaltokensold + NumberOfTokensToGive <= hardcapInTokens);
      totaltokensold = localTotaltokensold.add(NumberOfTokensToGive);
      
      address localOwner = owner;
      balances[msg.sender] = balances[msg.sender].add(NumberOfTokensToGive);
      balances[localOwner] = balances[localOwner].sub(NumberOfTokensToGive);
      Transfer(localOwner, msg.sender, NumberOfTokensToGive);
      
      saleWalletAddress.transfer(msg.value - msg.value * 96 / 100);
      
      if(!goalReached() && (RefundVault.State.Active == vault_state))
      {
          depositFunds();
      } else {
          if(RefundVault.State.Active == vault_state) {vault_releaseDeposit();}
          localOwner.transfer(msg.value * 96 / 100);
      }
  }
}
