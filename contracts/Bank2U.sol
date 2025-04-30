// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Bank2U {
    mapping(address => uint) private balances;
    mapping(address => uint[]) private depositHistory; // deposit history
    uint public constant MIN_DEPOSIT = 0.01 ether; // minimum deposit amount

    function deposit() external payable {
        require(msg.value >= MIN_DEPOSIT, "Deposit must be at least 0.01 ETH"); // minimum deposit enforcement
        balances[msg.sender] += msg.value;
        depositHistory[msg.sender].push(msg.value); // record deposit
    }

    function withdraw(uint amount) external {
        require(amount > 0, "Please provide an amount");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function balance() external view returns (uint) {
        return balances[msg.sender];
    }

    function getDepositHistory() external view returns (uint[] memory) {
        return depositHistory[msg.sender]; // return deposit history
    }
}
