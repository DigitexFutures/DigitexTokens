pragma solidity ^0.4.19;

 /*
  ERC223 additions to ERC20

  Interface wise is ERC20 + data paramenter to transfer and transferFrom.
 */

//import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20.sol";
import "./ERC20.sol";

contract ERC223 is ERC20 {
  function transfer(address to, uint value, bytes data) returns (bool ok);
  function transferFrom(address from, address to, uint value, bytes data) returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
