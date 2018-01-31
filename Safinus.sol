pragma solidity ^0.4.11;

import './MintableToken.sol';

contract Safinus is Ownable {
  using SafeMath for uint256;

  MintableToken public token;

  uint256 public PreICOStartTime;
  uint256 public PreICOEndTime;
  uint256 public ICOStartTime;
  uint256 public ICOEndTime;

  address public wallet;

  uint256 public rate;
  uint256 public weiRaised;

   event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   
   function Safinus(uint256 _rate, address _wallet) public {
     require(_rate > 0);
     require(_wallet != address(0));

     token = createTokenContract();
    
     rate = _rate;
     wallet = _wallet;
   }
   function startPreICO() onlyOwner public {
     require(PreICOStartTime == 0);
     PreICOStartTime = now;
     PreICOEndTime = PreICOStartTime + 21 days;
   }
   function stopPreICO() onlyOwner public {
     require(PreICOEndTime > now);
     PreICOEndTime = now;
   }
   function startICO() onlyOwner public {
     require(ICOStartTime == 0);
     ICOStartTime = now;
     ICOEndTime = ICOStartTime + 29 days;
   }
   function stopICO() onlyOwner public {
     require(ICOEndTime > now);
     ICOEndTime = now;
   }
   function setUsdRate(uint256 _rate) onlyOwner public {
     require(_rate > 0);
     rate = _rate;
   }

   function createTokenContract() internal returns (MintableToken) {
     return new MintableToken();
   }

   function () payable public {
     buyTokens(msg.sender);
   }
  
   function getUSDPrice() public constant returns (uint256 cents_by_token) {
     if (ICOStartTime > 0 && now >= ICOStartTime)    
     {
       if (now <= ICOStartTime + 7 days)
         return 90;
       else if (now <= ICOStartTime + 29 days)
         return 100;
     }
     else
     {
       if (now <= PreICOStartTime + 1 days)
         return 50;
       else if (now <= PreICOStartTime + 7 days)
         return 60;
       else if (now <= PreICOStartTime + 14 days)
         return 70;
       else if (now <= PreICOStartTime + 21 days)
         return 80;
     }
     return 100;
   }

   function buyTokens(address beneficiary) public payable {
     require(beneficiary != address(0));
     require(validPurchase());
     
     uint256 weiAmount = msg.value;
     uint256 _convert_rate = rate;
     
     _convert_rate = _convert_rate * getUSDPrice() / 100; 

 
     uint256 tokens = weiAmount.div(_convert_rate);
     require(tokens > 0); 


     weiRaised = weiRaised.add(weiAmount);

     token.mint(beneficiary, tokens);
     TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

     forwardFunds();
   }

  

   function sendTokens(address _to, uint256 _amount) onlyOwner public {
     token.mint(_to, _amount);
   }

   function transferTokenOwnership(address _newOwner) onlyOwner public {
     token.transferOwnership(_newOwner);
   }

   function forwardFunds() internal {
     wallet.transfer(msg.value);
   }

   function validPurchase() internal constant returns (bool) {
     bool withinPreICOPeriod = now >= PreICOStartTime && now <= PreICOEndTime;
     bool withinICOPeriod = now >= ICOStartTime && now <= ICOEndTime;
     bool nonZeroPurchase = msg.value != 0;
     return (withinPreICOPeriod || withinICOPeriod) && nonZeroPurchase;
   }
}