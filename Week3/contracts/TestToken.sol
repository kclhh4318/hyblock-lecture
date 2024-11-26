// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;  // 버전을 0.8.20으로 변경

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";  // 상대 경로 대신 직접 import

contract TestToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("TestToken", "TST") {
        _mint(msg.sender, initialSupply);
    }
}