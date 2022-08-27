// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenTransfer {
    using SafeERC20 for IERC20;
    IERC20 _token;

    constructor(address token) {
        _token = IERC20(token);
    }

    event SettleInfoEvent(string settle);

    function depositTokens(address _to, uint _amount, string memory _settle) public {
        _token.safeTransferFrom(msg.sender, _to, _amount);
        emit SettleInfoEvent(_settle);
    }
}

