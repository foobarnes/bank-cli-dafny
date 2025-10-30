# AI-Assisted Development Guide for Verified Bank CLI

**Purpose:** Guide developers in leveraging AI tools to develop, verify, and maintain this formally verified banking system in Dafny.

**Last Updated:** 2025-10-30

---

## Table of Contents

1. [Specification Refinement](#1-specification-refinement)
2. [Invariant Generation](#2-invariant-generation)
3. [Proof Assistance](#3-proof-assistance)
4. [Code Generation](#4-code-generation)
5. [Verification Error Interpretation](#5-verification-error-interpretation)
6. [Refactoring with Verification](#6-refactoring-with-verification)
7. [Testing Strategy](#7-testing-strategy)
8. [Documentation Generation](#8-documentation-generation)
9. [Best Practices](#9-best-practices)
10. [Example Workflows](#10-example-workflows)

---

## 1. Specification Refinement

### How AI Can Help

AI tools excel at:
- Identifying missing requirements in specifications
- Suggesting edge cases you haven't considered
- Clarifying ambiguous requirements
- Generating formal property statements from informal descriptions
- Reviewing specification completeness

### Example Prompts

**Identify Missing Requirements:**
```
Review this banking specification for completeness:
- Account creation with unique IDs
- Deposits and withdrawals
- Overdraft protection

What requirements might be missing?
```

**Expected AI Response:**
- Missing: Transaction history tracking
- Missing: Balance inquiry functionality
- Missing: Transfer between accounts
- Missing: Fee structure definition
- Missing: Persistence requirements
- Missing: Error handling specifications

**Suggest Edge Cases:**
```
I'm implementing account transfers. What edge cases should I consider?
```

**Expected AI Response:**
- Transfer to the same account
- Insufficient funds in source account
- Non-existent source or destination
- Overdraft limits
- Maximum balance constraints
- Atomic failure scenarios
- Concurrent transfers (if applicable)

**Formalize Requirements:**
```
Help me formalize this requirement in Dafny:
"The account balance should never be negative unless overdraft is enabled"
```

**Expected AI Response:**
```dafny
ghost predicate ValidBalance(account: Account)
  reads account
{
  (account.overdraftEnabled ==> account.balance >= -account.overdraftLimit) &&
  (!account.overdraftEnabled ==> account.balance >= 0)
}
```

---

## 2. Invariant Generation

### How AI Can Help

- Suggest appropriate invariants for data structures
- Generate loop invariants for iterative algorithms
- Identify missing preconditions and postconditions
- Propose ghost predicates for verification

### Example Prompts

**Data Structure Invariants:**
```
What invariants should I add to this Account datatype?

datatype Account = Account(
  id: nat,
  balance: int,
  history: seq<Transaction>,
  overdraftEnabled: bool,
  overdraftLimit: int
)
```

**Expected AI Response:**
```dafny
ghost predicate ValidAccount(account: Account)
{
  // Balance matches transaction history
  account.balance == ComputeBalance(account.history) &&
  // Overdraft limit is non-negative
  account.overdraftLimit >= 0 &&
  // Balance respects overdraft setting
  (account.overdraftEnabled ==> account.balance >= -account.overdraftLimit) &&
  (!account.overdraftEnabled ==> account.balance >= 0) &&
  // Transaction history is non-empty for non-zero balance
  (account.balance != 0 ==> |account.history| > 0)
}
```

**Loop Invariants:**
```
Generate loop invariants for calculating total system balance:

method ComputeTotalBalance(accounts: seq<Account>) returns (total: int)
{
  total := 0;
  var i := 0;
  while i < |accounts|
    // Invariants needed here
  {
    total := total + accounts[i].balance;
    i := i + 1;
  }
}
```

**Expected AI Response:**
```dafny
while i < |accounts|
  invariant 0 <= i <= |accounts|
  invariant total == SumBalances(accounts[..i])
  decreases |accounts| - i
{
  total := total + accounts[i].balance;
  i := i + 1;
}
```

---

## 3. Proof Assistance

### How AI Can Help

- Suggest lemmas to prove complex properties
- Explain why verification fails
- Recommend proof strategies
- Debug failing proofs

### Example Prompts

**Why Verification Fails:**
```
Dafny fails to verify this postcondition. Why?

method Transfer(from: Account, to: Account, amount: int)
  returns (newFrom: Account, newTo: Account)
  requires amount > 0
  requires from.balance >= amount
  ensures newFrom.balance + newTo.balance == from.balance + to.balance
{
  newFrom := from.(balance := from.balance - amount);
  newTo := to.(balance := to.balance + amount);
}
```

**Expected AI Response:**
```
The postcondition fails because:
1. 'from' and 'to' in the ensures clause refer to the original parameters
2. You need to prove the relationship between old and new values

Fix:
ensures newFrom.balance + newTo.balance ==
        old(from.balance) + old(to.balance)

Or use explicit old() in postcondition for clarity.
```

**Suggest Lemmas:**
```
I need to prove fund conservation across all transfers.
What lemma would help?
```

**Expected AI Response:**
```dafny
lemma TransferPreservesFunds(
  from: Account, to: Account, amount: int,
  newFrom: Account, newTo: Account
)
  requires newFrom.balance == from.balance - amount
  requires newTo.balance == to.balance + amount
  ensures newFrom.balance + newTo.balance == from.balance + to.balance
{
  // Proof by arithmetic
}

// Use in Transfer method:
method Transfer(...)
  ...
  ensures newFrom.balance + newTo.balance == from.balance + to.balance
{
  newFrom := from.(balance := from.balance - amount);
  newTo := to.(balance := to.balance + amount);

  TransferPreservesFunds(from, to, amount, newFrom, newTo);
}
```

---

## 4. Code Generation

### How AI Can Help

- Generate boilerplate Dafny code
- Create test scenarios
- Implement verified methods from specifications
- Translate informal requirements to Dafny

### Example Prompts

**Generate Verified Method:**
```
Generate a Dafny method for withdrawing funds with these specs:
- Amount must be positive
- Account must have sufficient funds (including overdraft)
- Balance must be updated correctly
- Transaction must be recorded in history
```

**Expected AI Response:**
```dafny
method Withdraw(account: Account, amount: int, description: string)
  returns (newAccount: Account, success: bool)
  requires amount > 0
  requires ValidAccount(account)
  ensures ValidAccount(newAccount)
  ensures success ==> newAccount.balance == account.balance - amount
  ensures !success ==> newAccount == account
  ensures success ==> |newAccount.history| == |account.history| + 1
{
  if amount <= account.balance +
     (if account.overdraftEnabled then account.overdraftLimit else 0)
  {
    var txn := Transaction(amount, description, GetTimestamp());
    newAccount := account.(
      balance := account.balance - amount,
      history := account.history + [txn]
    );
    success := true;
  } else {
    newAccount := account;
    success := false;
  }
}
```

**Generate Test Cases:**
```
Create test cases for the Withdraw method covering:
- Normal withdrawal
- Withdrawal with overdraft
- Insufficient funds
- Boundary conditions
```

**Expected AI Response:**
```dafny
method TestWithdrawNormal()
{
  var account := Account(1, 1000, [], false, 0);
  var newAccount, success := Withdraw(account, 500, "Test");
  assert success;
  assert newAccount.balance == 500;
}

method TestWithdrawOverdraft()
{
  var account := Account(1, 100, [], true, 500);
  var newAccount, success := Withdraw(account, 200, "Overdraft test");
  assert success;
  assert newAccount.balance == -100;
}

method TestWithdrawInsufficientFunds()
{
  var account := Account(1, 100, [], false, 0);
  var newAccount, success := Withdraw(account, 200, "Too much");
  assert !success;
  assert newAccount == account;
}

method TestWithdrawExactBalance()
{
  var account := Account(1, 100, [], false, 0);
  var newAccount, success := Withdraw(account, 100, "Exact");
  assert success;
  assert newAccount.balance == 0;
}
```

---

## 5. Verification Error Interpretation

### How AI Can Help

- Decode complex Dafny error messages
- Identify root causes of verification failures
- Suggest fixes for common verification issues
- Explain Z3 timeout problems

### Example Prompts

**Interpret Error:**
```
Dafny error: "A postcondition might not hold on this return path"

Method:
method Deposit(account: Account, amount: int)
  returns (newAccount: Account)
  requires amount > 0
  ensures newAccount.balance == account.balance + amount
{
  newAccount := account;
  newAccount.balance := account.balance + amount;  // Error here
}
```

**Expected AI Response:**
```
Error Cause:
Dafny datatypes are immutable. You cannot modify fields directly.

Fix:
Use the update syntax:
newAccount := account.(balance := account.balance + amount);

This creates a new Account instance with the updated balance field.
```

**Z3 Timeout:**
```
Verification times out on this complex transfer method. How do I fix it?
```

**Expected AI Response:**
```
Strategies for Z3 timeouts:

1. Split complex methods into smaller pieces
2. Add intermediate assertions to guide the prover
3. Use lemmas to prove sub-properties
4. Increase timeout: {:timeLimit 30} attribute
5. Simplify complex expressions
6. Use calc statements for arithmetic proofs

Example:
method Transfer(...)
{
  // Add intermediate assertion
  assert from.balance >= amount;
  newFrom := from.(balance := from.balance - amount);
  assert newFrom.balance == from.balance - amount;  // Guide prover

  newTo := to.(balance := to.balance + amount);
  assert newTo.balance == to.balance + amount;

  // Now postcondition should verify
}
```

---

## 6. Refactoring with Verification

### How AI Can Help

- Suggest refactorings that preserve verification
- Identify verification-breaking changes
- Propose better abstractions
- Help maintain invariants during refactoring

### Example Prompts

**Safe Refactoring:**
```
How can I refactor this withdrawal method to separate
overdraft fee calculation while keeping verification?

method Withdraw(account: Account, amount: int)
  returns (newAccount: Account)
  // Complex overdraft fee logic inline
```

**Expected AI Response:**
```dafny
// Extract fee calculation into pure function
function CalculateOverdraftFee(overdraftAmount: int): int
  requires overdraftAmount >= 0
  ensures CalculateOverdraftFee(overdraftAmount) >= 0
{
  if overdraftAmount == 0 then 0
  else if overdraftAmount <= 100 then 25
  else if overdraftAmount <= 500 then 35
  else if overdraftAmount <= 1000 then 50
  else 75
}

// Refactored Withdraw using the function
method Withdraw(account: Account, amount: int)
  returns (newAccount: Account)
  requires amount > 0
  ensures newAccount.balance <= account.balance
{
  var overdraft := if amount > account.balance
                   then amount - account.balance
                   else 0;
  var fee := CalculateOverdraftFee(overdraft);

  newAccount := account.(balance := account.balance - amount - fee);
}
```

---

## 7. Testing Strategy

### How AI Can Help

- Generate comprehensive test cases
- Identify missing test coverage
- Create property-based tests
- Suggest edge cases to test

### Example Prompts

**Generate Test Coverage:**
```
What test cases should I add for the Transfer operation?
Current tests: normal transfer, insufficient funds
```

**Expected AI Response:**
```
Missing test cases:

1. Transfer to same account (should fail)
2. Transfer with zero amount (should fail)
3. Transfer with negative amount (should fail)
4. Transfer from non-existent account
5. Transfer to non-existent account
6. Transfer exact balance amount
7. Transfer causing source overdraft
8. Transfer exceeding destination max balance
9. Transfer at tier boundaries for fees
10. Multiple sequential transfers

Property-based tests:
- For all valid transfers, fund conservation holds
- For all valid transfers, both accounts are updated
- For all invalid transfers, no state changes occur
```

---

## 8. Documentation Generation

### How AI Can Help

- Generate API documentation from Dafny signatures
- Explain verification properties in plain English
- Create usage examples
- Write specification documents

### Example Prompts

**Document Method:**
```
Document this verified method with its guarantees:

method Transfer(from: Account, to: Account, amount: int)
  returns (newFrom: Account, newTo: Account, success: bool)
  requires amount > 0
  requires from.id != to.id
  requires ValidAccount(from) && ValidAccount(to)
  ensures success ==> newFrom.balance + newTo.balance ==
                      from.balance + to.balance
  ensures !success ==> newFrom == from && newTo == to
```

**Expected AI Response:**
```markdown
## Transfer

Transfers funds between two accounts atomically.

**Parameters:**
- `from`: Source account (must be valid)
- `to`: Destination account (must be valid, different from source)
- `amount`: Amount to transfer in cents (must be positive)

**Returns:**
- `newFrom`: Updated source account
- `newTo`: Updated destination account
- `success`: Whether transfer succeeded

**Preconditions:**
- Amount must be positive
- Source and destination must be different accounts
- Both accounts must satisfy their invariants

**Guarantees:**
- If successful, total funds are conserved (no money created or destroyed)
- If unsuccessful, neither account is modified
- Account invariants are maintained

**Example:**
```dafny
var alice := Account(1, 1000, ...);
var bob := Account(2, 500, ...);
var newAlice, newBob, ok := Transfer(alice, bob, 300);
assert ok ==> newAlice.balance == 700 && newBob.balance == 800;
```
```

---

## 9. Best Practices

### When to Use AI

✅ **Good Use Cases:**
- Generating boilerplate code
- Suggesting invariants and preconditions
- Interpreting error messages
- Brainstorming edge cases
- Generating test cases
- Creating documentation

❌ **Avoid AI For:**
- Blindly applying suggested fixes
- Complex proof strategies without understanding
- Final verification decisions
- Security-critical logic

### Validating AI Suggestions

Always:
1. **Verify**: Run Dafny verification on AI-generated code
2. **Understand**: Make sure you understand why the code works
3. **Test**: Create test cases for AI-generated implementations
4. **Review**: Check that suggestions align with project requirements
5. **Question**: Ask AI to explain its reasoning

### Iterative Refinement

Use this workflow:
1. Start with informal requirement
2. Ask AI to formalize it
3. Review and refine the formalization
4. Ask AI to generate implementation
5. Ask AI to suggest tests
6. Refine based on verification results
7. Iterate until verified

---

## 10. Example Workflows

### Workflow 1: Implementing a New Feature

**Task:** Add interest calculation for savings accounts

**Step 1: Refine Specification**
```
Prompt: "I want to add interest calculation to bank accounts.
What requirements should I consider?"

AI Response:
- Interest rate per account
- Compounding frequency (daily, monthly, annual)
- Interest accrual method
- When interest is applied
- Minimum balance requirements
- Interest calculation precision
- Transaction recording for interest
```

**Step 2: Generate Invariants**
```
Prompt: "What invariants do I need for interest calculation?"

AI Response:
ghost predicate ValidInterest(account: Account)
{
  account.interestRate >= 0.0 &&
  account.interestRate <= 0.20 &&  // Max 20%
  account.accruedInterest >= 0
}
```

**Step 3: Implement with Verification**
```
Prompt: "Generate a verified method to calculate daily interest"

AI Response:
method CalculateDailyInterest(account: Account)
  returns (newAccount: Account)
  requires ValidAccount(account)
  requires ValidInterest(account)
  ensures ValidAccount(newAccount)
  ensures newAccount.balance >= account.balance
{
  var interest := (account.balance * account.interestRate) / 365;
  newAccount := account.(
    balance := account.balance + interest,
    accruedInterest := account.accruedInterest + interest
  );
}
```

**Step 4: Generate Tests**
```
Prompt: "Create test cases for daily interest calculation"

AI Response: [Tests generated]
```

**Step 5: Debug Verification Errors**
```
If errors occur:
Prompt: "Why does this postcondition fail? [paste error]"

AI helps diagnose and fix.
```

### Workflow 2: Debugging Verification Failure

**Problem:** Dafny can't verify fund conservation in transfer

**Step 1: Explain the Issue**
```
Prompt: "Dafny can't verify this postcondition:
ensures newFrom.balance + newTo.balance == from.balance + to.balance

Why?"
```

**Step 2: Get Diagnosis**
```
AI Response: "The postcondition references 'from' and 'to'
which are the old values. Dafny needs explicit old() or
the values must be preserved."
```

**Step 3: Apply Fix**
```
ensures newFrom.balance + newTo.balance ==
        old(from).balance + old(to).balance
```

**Step 4: Add Lemma if Needed**
```
If still failing, prompt: "Should I add a lemma to prove this?"

AI suggests appropriate lemma.
```

---

## Recommended AI Tools

1. **Claude Code** - Excellent for Dafny-specific help with sequential thinking
2. **GitHub Copilot** - Good for code completion in Dafny files
3. **ChatGPT/Claude** - Great for brainstorming and specification refinement

---

## Conclusion

AI is a powerful assistant for developing verified code, but:
- **Always verify AI suggestions** with Dafny
- **Understand the proofs**, don't just apply fixes
- **Use AI iteratively** to refine your approach
- **Trust but verify** all AI-generated code

The combination of AI assistance and formal verification gives you the best of both worlds: rapid development with mathematical guarantees.

---

**Last Updated:** 2025-10-30
**Maintained By:** Development Team
**Questions?** Refer to SPEC.md and Dafny documentation
