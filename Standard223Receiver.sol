pragma solidity ^0.4.19;

 /* ERC223 additions to ERC20 */

import "./ERC223Receiver.sol";

contract Standard223Receiver is ERC223Receiver {
  Tkn tkn;

  struct Tkn {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
  }

   function tokenFallback(address _from, uint _value, bytes _data){
      Tkn memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
      
      /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
    }
  }