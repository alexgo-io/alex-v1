// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Ownable {    
  address private _owner;
  
  constructor()
  {
    _owner = msg.sender;
  }
  
  function owner() public view returns(address) 
  {
    return _owner;
  }
  
  modifier only_owner() 
  {
    require(check_is_owner(),
    "Error: Unauthorized access");
    _;
  }
  
  function check_is_owner() public view returns(bool) 
  {
    return msg.sender == _owner;
  }
}

contract TokenTransfer is Ownable {
    using SafeERC20 for IERC20;
    IERC20 _token;

    mapping(address => bool) private _approved_recipients;

    constructor(address token) {
        _token = IERC20(token);
    }

    event SettleInfoEvent(string settle);

    function set_approved_recipient (address recipient, bool approved) only_owner public {
        _approved_recipients[recipient] = approved;
    }

    function depositTokens(address _to, uint _amount, string memory _settle) public {
        require(_approved_recipients[_to] == true, "Error: Unapproved recipient");
        
        _token.safeTransferFrom(msg.sender, _to, _amount);
        emit SettleInfoEvent(_settle);
    }
}

