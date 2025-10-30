# Bank CLI Verification Specifications

## Overview

This document specifies the formal verification requirements for the Bank CLI application implemented in Dafny. Formal verification is a critical component of this system, providing mathematical proofs that ensure correctness properties such as balance integrity, fund conservation, and transaction atomicity are always maintained.

Unlike traditional testing which validates specific scenarios, formal verification proves that these properties hold for all possible execution paths. Dafny's verification-aware type system, combined with Z3 theorem prover, enables us to detect and prevent entire classes of errors at compile time rather than runtime.

**Key Benefits of Formal Verification:**
- **Balance Integrity**: Mathematically proven that balances always match transaction history
- **Fund Conservation**: Guaranteed that transfers never create or destroy money
- **Atomicity**: Proven that operations either complete fully or have no effect
- **Fee Correctness**: Verified that overdraft fees are calculated accurately across all tiers
- **No Runtime Surprises**: Entire classes of bugs eliminated before code execution

## 4.1 Core Invariants

The following eight core invariants must hold at all times during system execution. Each invariant is expressed as a Dafny predicate and is checked at specific verification points throughout the codebase.

### INV-1: Balance Integrity

**Invariant:**
```dafny
predicate ValidAccountBalance(a: Account)
{
  if a.overdraftEnabled then
    a.balance >= -a.overdraftLimit
  else
    a.balance >= 0
}
```

**Description:**
Account balances must always respect overdraft settings. Non-overdraft accounts cannot have negative balances, and overdraft-enabled accounts cannot exceed their configured overdraft limit.

**Verification Points:**
- After every deposit
- After every withdrawal
- After every transfer
- After fee assessment
- After account creation

**Proof Obligations:**
- All operations maintain this invariant
- Overdraft limit changes preserve invariant

---

### INV-2: Balance Computation Consistency

**Invariant:**
```dafny
predicate BalanceMatchesHistory(a: Account)
{
  a.balance == ComputeBalanceFromHistory(a.history)
}

function ComputeBalanceFromHistory(history: seq<Transaction>): int
{
  if |history| == 0 then 0
  else history[|history|-1].balanceAfter
}
```

**Description:**
The current account balance must always equal the balance computed from the complete transaction history. This ensures that the transaction history is the single source of truth for account balances and prevents inconsistencies.

**Verification Points:**
- After every transaction
- After loading from persistence
- During account validation

**Proof Obligations:**
- Transaction history is append-only
- Balance snapshots are accurate
- No gaps or inconsistencies in history

---

### INV-3: Fee Monotonicity

**Invariant:**
```dafny
predicate FeesNeverDecrease(a: Account)
{
  a.totalFeesCollected >= 0 &&
  forall i, j :: 0 <= i < j < |a.history| &&
    a.history[i].txType.Fee? && a.history[j].txType.Fee? ==>
    GetTotalFeesAtIndex(a.history, j) >= GetTotalFeesAtIndex(a.history, i)
}
```

**Description:**
The total fees collected on an account can only increase over time, never decrease. This ensures fee transactions are irreversible and that the system maintains accurate fee accounting.

**Verification Points:**
- After fee assessment
- After account modification

**Proof Obligations:**
- totalFeesCollected only increases
- Fee transactions always have negative amounts
- Fee amounts match tier calculation

---

### INV-4: Transaction Linkage

**Invariant:**
```dafny
predicate ValidTransactionLinks(a: Account)
{
  forall tx :: tx in a.history ==>
    (tx.parentTxId.Some? ==>
      exists parent :: parent in a.history && parent.id == tx.parentTxId.value &&
                       tx.id in parent.childTxIds) &&
    (|tx.childTxIds| > 0 ==>
      forall childId :: childId in tx.childTxIds ==>
        exists child :: child in a.history && child.id == childId &&
                       child.parentTxId == Some(tx.id))
}
```

**Description:**
Parent-child relationships between transactions (e.g., withdrawal and its associated fee) must be bidirectional and consistent. Every parent reference must have a corresponding child reference and vice versa.

**Verification Points:**
- After creating linked transactions (transfers, fees)
- During transaction validation

**Proof Obligations:**
- Parent-child relationships are bidirectional
- No orphaned transactions
- No circular references

---

### INV-5: Fund Conservation (Transfers)

**Invariant:**
```dafny
predicate TransferConservesFunds(
  fromAccount: Account,
  toAccount: Account,
  fromAccountOld: Account,
  toAccountOld: Account,
  amount: int,
  fee: int
)
{
  fromAccount.balance == fromAccountOld.balance - amount - fee &&
  toAccount.balance == toAccountOld.balance + amount
}
```

**Description:**
Transfer operations must conserve funds across the system. The sum of balances before and after a transfer (excluding fees) must remain constant, ensuring money is neither created nor destroyed.

**Verification Points:**
- After every transfer operation

**Proof Obligations:**
- Total funds in system unchanged (excluding fees)
- Both accounts updated atomically
- Fee only assessed on from account

---

### INV-6: Account Limits

**Invariant:**
```dafny
predicate AccountWithinLimits(a: Account)
{
  a.balance <= a.maxBalance &&
  a.overdraftLimit >= 0 &&
  a.maxBalance > 0 &&
  a.maxTransaction > 0 &&
  a.maxTransaction <= a.maxBalance
}
```

**Description:**
All account limits must be valid and respected. Balances cannot exceed maximum balance limits, and transaction amounts cannot exceed configured transaction limits.

**Verification Points:**
- After account creation
- After limit changes
- After every transaction

**Proof Obligations:**
- Deposits don't exceed maxBalance
- Withdrawals/transfers respect maxTransaction
- Limit configuration is valid

---

### INV-7: Transaction History Ordering

**Invariant:**
```dafny
predicate HistoryProperlyOrdered(a: Account)
{
  forall i, j :: 0 <= i < j < |a.history| ==>
    a.history[i].timestamp <= a.history[j].timestamp
}
```

**Description:**
Transaction history must be ordered chronologically by timestamp. This ensures that history replays produce consistent results and that audit trails are meaningful.

**Verification Points:**
- After appending transactions
- After loading from file

**Proof Obligations:**
- Timestamps monotonically increasing
- Concurrent transactions (same timestamp) preserve order

---

### INV-8: Bank Account Map Consistency

**Invariant:**
```dafny
predicate ValidBankState(b: Bank)
{
  (forall id :: id in b.accounts.Keys ==> id < b.nextAccountId) &&
  (forall a :: a in b.accounts.Values ==> ValidAccountBalance(a) &&
                                          BalanceMatchesHistory(a))
}
```

**Description:**
The bank's global state must be consistent. All account IDs must be less than the next account ID counter, and all accounts in the system must individually satisfy their invariants.

**Verification Points:**
- After every bank operation
- After loading from file

**Proof Obligations:**
- No account ID >= nextAccountId
- All accounts valid
- nextAccountId never decreases

---

## 4.2 Preconditions and Postconditions

Each banking operation has formally specified preconditions that must be satisfied before execution and postconditions that are guaranteed to hold after successful execution.

### 4.2.1 Deposit

**Preconditions:**
```dafny
method Deposit(accountId: nat, amount: int, description: string)
  returns (r: Result<Transaction>)
  requires amount > 0
  requires accountId in bank.accounts.Keys
  requires bank.accounts[accountId].status == Active
  requires bank.accounts[accountId].balance + amount <=
           bank.accounts[accountId].maxBalance
```

**Postconditions:**
```dafny
  ensures r.Success? ==>
    var newAccount := bank'.accounts[accountId];
    newAccount.balance == old(bank.accounts[accountId].balance) + amount &&
    |newAccount.history| == |old(bank.accounts[accountId].history)| + 1 &&
    ValidAccountBalance(newAccount) &&
    BalanceMatchesHistory(newAccount)
```

**Specification Summary:**
- **Input Requirements**: Amount must be positive, account must exist and be active, resulting balance must not exceed maximum
- **Guarantees**: Balance increases by exact amount, exactly one transaction added to history, all invariants maintained

---

### 4.2.2 Withdrawal

**Preconditions:**
```dafny
method Withdraw(accountId: nat, amount: int, description: string)
  returns (r: Result<(Transaction, Option<Transaction>)>)
  requires amount > 0
  requires amount <= bank.accounts[accountId].maxTransaction
  requires accountId in bank.accounts.Keys
  requires bank.accounts[accountId].status == Active
  requires var a := bank.accounts[accountId];
    if a.overdraftEnabled then
      a.balance - amount >= -a.overdraftLimit
    else
      a.balance - amount >= 0
```

**Postconditions:**
```dafny
  ensures r.Success? ==>
    var newAccount := bank'.accounts[accountId];
    var (withdrawal, maybeFee) := r.value;
    var totalDebit := amount + (if maybeFee.Some? then -maybeFee.value.amount else 0);
    newAccount.balance == old(bank.accounts[accountId].balance) - totalDebit &&
    ValidAccountBalance(newAccount) &&
    BalanceMatchesHistory(newAccount) &&
    (maybeFee.Some? ==>
      maybeFee.value.parentTxId == Some(withdrawal.id) &&
      withdrawal.id in newAccount.history[|newAccount.history|-2].childTxIds)
```

**Specification Summary:**
- **Input Requirements**: Amount must be positive and within transaction limit, sufficient balance or overdraft available
- **Guarantees**: Balance decreases by amount plus any fees, fee transaction properly linked to withdrawal, all invariants maintained

---

### 4.2.3 Transfer

**Preconditions:**
```dafny
method Transfer(fromId: nat, toId: nat, amount: int, description: string)
  returns (r: Result<(Transaction, Transaction, Option<Transaction>)>)
  requires amount > 0
  requires fromId != toId
  requires fromId in bank.accounts.Keys
  requires toId in bank.accounts.Keys
  requires bank.accounts[fromId].status == Active
  requires bank.accounts[toId].status == Active
  requires amount <= bank.accounts[fromId].maxTransaction
  requires bank.accounts[toId].balance + amount <= bank.accounts[toId].maxBalance
  requires var a := bank.accounts[fromId];
    if a.overdraftEnabled then
      a.balance - amount >= -a.overdraftLimit
    else
      a.balance - amount >= 0
```

**Postconditions:**
```dafny
  ensures r.Success? ==>
    var (txOut, txIn, maybeFee) := r.value;
    var newFrom := bank'.accounts[fromId];
    var newTo := bank'.accounts[toId];
    var fee := if maybeFee.Some? then -maybeFee.value.amount else 0;
    TransferConservesFunds(newFrom, newTo,
                          old(bank.accounts[fromId]),
                          old(bank.accounts[toId]),
                          amount, fee) &&
    ValidAccountBalance(newFrom) &&
    ValidAccountBalance(newTo) &&
    txOut.parentTxId == Some(txIn.id) &&
    txIn.parentTxId == Some(txOut.id)
```

**Specification Summary:**
- **Input Requirements**: Amount positive, accounts different and both active, sufficient balance in source, room in destination
- **Guarantees**: Funds conserved across accounts, transactions properly linked, all invariants maintained for both accounts

---

## 4.3 Termination

**Requirement:** All methods must provably terminate.

Dafny requires proof that all methods and loops terminate. This prevents infinite loops and ensures that operations complete in finite time.

**Strategies:**
- Use bounded loops with explicit decreases clauses
- Avoid recursion where possible (use iteration)
- Sequence operations on bounded sequences
- File I/O through FFI (trusted, no proof obligation)

**Example:**
```dafny
method ComputeTotalFees(history: seq<Transaction>) returns (total: int)
  ensures total >= 0
  decreases |history|
{
  total := 0;
  var i := 0;
  while i < |history|
    invariant 0 <= i <= |history|
    invariant total >= 0
    decreases |history| - i
  {
    if history[i].txType.Fee? {
      total := total + (-history[i].amount);  // fees are negative
    }
    i := i + 1;
  }
}
```

**Termination Proof Elements:**
- **decreases clause**: Specifies a metric that decreases with each iteration
- **Loop invariants**: Properties that hold before and after each iteration
- **Bounds checking**: Ensures indices stay within valid ranges

---

## 4.4 Proof Strategies

### 4.4.1 Balance Integrity

**Strategy:** Induction on transaction history

**Base Case:** New account with initial deposit
- Balance = initial deposit >= 0
- If overdraft enabled, limit > 0, so balance >= -limit

**Inductive Step:** Given valid account, after transaction
- Deposit: balance increases, stays valid
- Withdrawal: precondition ensures post-withdrawal balance >= minimum
- Fee: already overdrawn, fee doesn't violate limit (proven separately)

**Proof Technique:**
This proof uses mathematical induction over the sequence of transactions. By proving the base case (account creation) and the inductive step (each operation preserves the invariant), we prove that the invariant holds for all possible transaction histories.

---

### 4.4.2 Fee Calculation Correctness

**Theorem:**
```dafny
lemma FeeCalculationCorrect(overdraftAmount: int)
  requires overdraftAmount > 0
  ensures var fee := CalculateOverdraftFee(overdraftAmount);
    fee == GetTierFee(GetTier(overdraftAmount))
```

**Proof Approach:**
- Case analysis on overdraftAmount ranges
- Show tier determination is exhaustive and exclusive
- Verify fee lookup matches tier

**Proof Technique:**
This uses case-by-case analysis to verify that the tiered fee structure is correct. For each tier range ($0.01-$100, $100.01-$500, etc.), we prove that the correct fee is applied and that the ranges are exhaustive (cover all positive amounts) and mutually exclusive (no overlap).

---

### 4.4.3 Atomicity

**Strategy:** Result type with ghost state

**Approach:**
- All operations return Result<T>
- On Failure, ghost state shows bank unchanged
- On Success, ghost state shows valid state transition

**Example:**
```dafny
method TransferAtomic(fromId: nat, toId: nat, amount: int)
  returns (r: Result<...>)
  ensures r.Failure? ==> bank' == old(bank)
  ensures r.Success? ==> ValidBankState(bank')
```

**Proof Technique:**
The Result type pattern combined with ghost state tracking enables proofs of atomicity. Ghost variables track the old state, and postconditions prove that either the operation completes fully (Success) with all invariants preserved, or the state remains unchanged (Failure). This eliminates partial updates and inconsistent states.

---

## Verification Workflow

### Step 1: Write Specifications
Before implementing a feature, write the formal specifications:
- Define preconditions (requires clauses)
- Define postconditions (ensures clauses)
- Identify relevant invariants

### Step 2: Implement with Verification
Write the implementation with verification in mind:
- Add loop invariants for all loops
- Use decreases clauses for termination
- Structure code to help the verifier

### Step 3: Verify
Run Dafny verification:
```bash
dafny verify src/Account.dfy
dafny verify src/Bank.dfy
dafny verify src/OverdraftPolicy.dfy
```

### Step 4: Debug Verification Failures
When verification fails:
- Read the error message carefully
- Add assert statements to check intermediate properties
- Use calc blocks to show step-by-step reasoning
- Simplify the implementation if necessary

### Step 5: Document Proofs
Add comments explaining:
- Why invariants hold
- How termination is proven
- Key lemmas and their purpose

---

## Verification Tools and Techniques

### Ghost Code
Ghost code exists only for verification and is erased at runtime:
```dafny
ghost var oldBalance := account.balance;
// ... operation ...
assert account.balance == oldBalance + amount;
```

### Lemmas
Lemmas are proven theorems that can be used in other proofs:
```dafny
lemma BalanceNonNegativeAfterDeposit(account: Account, amount: int)
  requires ValidAccountBalance(account)
  requires amount > 0
  ensures account.balance + amount >= 0
{
  // Proof by arithmetic
}
```

### Assertions
Assertions check that properties hold at specific points:
```dafny
assert account.balance >= 0;
assert |account.history| > 0;
```

### Calc Blocks
Calc blocks show step-by-step equality/inequality chains:
```dafny
calc {
  newBalance;
  == oldBalance + deposit - withdrawal;
  >= oldBalance;  // if deposit >= withdrawal
}
```

---

## Common Verification Patterns

### Pattern 1: Bounded Iteration
```dafny
var i := 0;
while i < |accounts|
  invariant 0 <= i <= |accounts|
  invariant forall j :: 0 <= j < i ==> ValidAccount(accounts[j])
  decreases |accounts| - i
{
  // process accounts[i]
  i := i + 1;
}
```

### Pattern 2: Result Type for Atomicity
```dafny
method Operation() returns (r: Result<T>)
  ensures r.Failure? ==> state' == old(state)
  ensures r.Success? ==> ValidState(state')
{
  if !precondition {
    return Failure("Error");
  }
  // ... perform operation ...
  return Success(value);
}
```

### Pattern 3: Immutable Update
```dafny
method UpdateAccount(account: Account, newBalance: int)
  returns (newAccount: Account)
  ensures newAccount.balance == newBalance
  ensures newAccount.history == account.history
{
  newAccount := account.(balance := newBalance);
}
```

---

## Verification Status

To check the verification status of the entire system:

```bash
# Verify all modules
dafny verify src/*.dfy

# Verify specific module
dafny verify src/Bank.dfy

# Show verification statistics
dafny verify src/Bank.dfy --show-snippets:false --show-stats
```

**Expected Output:**
```
Dafny program verifier finished with X verified, 0 errors
```

---

## Related Documentation

### Internal Specifications
- **[DATA_MODELS.md](DATA_MODELS.md)** - Datatype definitions and structure specifications
- **[FUNCTIONAL_REQUIREMENTS.md](FUNCTIONAL_REQUIREMENTS.md)** - Operations being verified
- **[TESTING_SPEC.md](TESTING_SPEC.md)** - How verification complements testing

### Development Guides
- **[AI_ASSISTED_GUIDE.md](../../guides/AI_ASSISTED_GUIDE.md)** - AI-assisted verification workflows
- **[CLAUDE.md](../../CLAUDE.md)** - Development environment setup for verification

### Reference Documentation
- **[SPEC.md](../../SPEC.md)** - Complete technical specification
- **[REQUIREMENTS_AND_EDGE_CASES.md](../REQUIREMENTS_AND_EDGE_CASES.md)** - Edge cases catalog

---

## Verification Best Practices

1. **Start Simple**: Begin with basic invariants before adding complex ones
2. **Incremental Verification**: Verify each method as you write it, don't wait until the end
3. **Use Helper Lemmas**: Break complex proofs into smaller, reusable lemmas
4. **Add Assertions**: Use assertions to help the verifier understand your reasoning
5. **Simplify When Stuck**: If verification is difficult, consider simplifying the implementation
6. **Document Assumptions**: Clearly document why preconditions are sufficient
7. **Test Edge Cases**: Verification proves correctness, but test edge cases for confidence
8. **Review Verification Errors**: Verification failures often reveal real bugs

---

**Document Version:** 1.0.0
**Last Updated:** 2025-10-30
**Verification Tool:** Dafny 4.11.0+ with Z3 Theorem Prover
**Verification Status:** All 8 core invariants specified and checkable
