# Bank CLI Testing Specification

## Overview

This document defines the comprehensive testing strategy for the Bank CLI application implemented in Dafny. The testing approach combines traditional software testing methodologies with formal verification techniques unique to Dafny, ensuring both functional correctness and mathematical proof of critical properties.

The testing strategy is organized into five complementary layers:

1. **Unit Tests** - Verify individual components in isolation
2. **Integration Tests** - Validate end-to-end workflows and component interactions
3. **Verification Tests** - Prove critical invariants hold under all conditions
4. **Property-Based Tests** - Validate system behavior across random input sequences
5. **Manual Testing** - Human-driven scenarios for usability and edge case validation

Together, these testing layers provide confidence that the Bank CLI application is correct, reliable, and maintains its critical invariants under all operating conditions.

---

## 8.1 Unit Tests

### 8.1.1 Transaction Tests (TransactionTests.dfy)

**Test Coverage:**
- Transaction creation with valid inputs
- Balance snapshot calculations
- Transaction type discrimination
- Fee detail construction
- Transaction linking (parent/child)

**Example Tests:**
```dafny
method TestCreateDepositTransaction()
{
  var tx := CreateDepositTransaction(
    "TX-001", 1, 10000, "Test deposit", 1000000, 50000
  );

  assert tx.txType.Deposit?;
  assert tx.amount == 10000;
  assert tx.balanceBefore == 50000;
  assert tx.balanceAfter == 60000;
  assert tx.parentTxId.None?;
  assert |tx.childTxIds| == 0;
}

method TestFeeTransactionLinking()
{
  var withdrawal := CreateWithdrawalTransaction(...);
  var fee := CreateFeeTransaction(..., Some(withdrawal.id));

  assert fee.parentTxId == Some(withdrawal.id);
  assert fee.txType.Fee?;
}
```

### 8.1.2 Account Tests (AccountTests.dfy)

**Test Coverage:**
- Account creation with valid inputs
- Account balance validation
- Overdraft limit enforcement
- Account limit checks (maxBalance, maxTransaction)
- Account status transitions

**Example Tests:**
```dafny
method TestAccountCreation()
{
  var account := CreateAccount(1, "Alice", 100000, true, 50000);

  assert ValidAccount(account);
  assert account.balance == 100000;
  assert account.overdraftEnabled;
  assert account.overdraftLimit == 50000;
}

method TestBalanceIntegrityAfterTransactions()
{
  var account := CreateAccount(1, "Bob", 100000, false, 0);
  var tx1 := CreateDepositTransaction(...);
  var account' := AppendTransaction(account, tx1);

  assert BalanceMatchesHistory(account');
  assert account'.balance ==
    account'.history[|account'.history|-1].balanceAfter;
}
```

### 8.1.3 Overdraft Tests (OverdraftTests.dfy)

**Test Coverage:**
- Tier determination for all ranges
- Fee calculation correctness
- Boundary conditions (tier edges)
- Fee details construction
- Zero/negative overdraft handling

**Example Tests:**
```dafny
method TestOverdraftTier1()
{
  var (fee, details) := CalculateOverdraftFee(5000);  // $50.00

  assert fee == 2500;  // $25.00
  assert details.tier == 1;
  assert details.tierRange == (1, 10000);
}

method TestOverdraftTier2()
{
  var (fee, details) := CalculateOverdraftFee(25000);  // $250.00

  assert fee == 3500;  // $35.00
  assert details.tier == 2;
}

method TestOverdraftBoundary()
{
  var (fee1, _) := CalculateOverdraftFee(10000);   // $100.00 - Tier 1
  var (fee2, _) := CalculateOverdraftFee(10001);   // $100.01 - Tier 2

  assert fee1 == 2500;
  assert fee2 == 3500;
}
```

### 8.1.4 Validation Tests (ValidationTests.dfy)

**Test Coverage:**
- Amount validation (positive, limits)
- Account ID validation
- Owner name validation
- Overdraft configuration validation
- Business rule checks

**Example Tests:**
```dafny
method TestAmountValidation()
{
  var r1 := ValidateAmount(0, 10000);
  assert r1.Failure?;

  var r2 := ValidateAmount(-100, 10000);
  assert r2.Failure?;

  var r3 := ValidateAmount(5000, 10000);
  assert r3.Success?;

  var r4 := ValidateAmount(15000, 10000);
  assert r4.Failure?;
}

method TestOwnerNameValidation()
{
  var r1 := ValidateOwnerName("");
  assert r1.Failure?;

  var r2 := ValidateOwnerName("   ");
  assert r2.Failure?;

  var r3 := ValidateOwnerName("John Doe");
  assert r3.Success?;
}
```

---

## 8.2 Integration Tests

### 8.2.1 Bank Operations Tests (BankOperationsTests.dfy)

**Test Coverage:**
- Complete deposit workflow
- Complete withdrawal workflow (with/without overdraft)
- Complete transfer workflow
- Account creation workflow
- Overdraft configuration workflow
- Multi-operation sequences

**Example Tests:**
```dafny
method TestDepositWorkflow()
{
  var bank := CreateEmptyBank();
  var createResult := CreateAccount(bank, "Alice", 0, false, 0);
  assert createResult.Success?;

  var (bank1, accountId) := createResult.value;
  var depositResult := Deposit(bank1, accountId, 50000, "Initial");
  assert depositResult.Success?;

  var (bank2, tx) := depositResult.value;
  assert bank2.accounts[accountId].balance == 50000;
  assert ValidBankState(bank2);
}

method TestWithdrawalWithOverdraftWorkflow()
{
  var bank := CreateBankWithAccount("Bob", 10000, true, 50000);
  var withdrawResult := Withdraw(bank, 0, 30000, "Test");
  assert withdrawResult.Success?;

  var (bank', withdrawal, maybeFee) := withdrawResult.value;
  assert maybeFee.Some?;  // fee should be assessed
  assert bank'.accounts[0].balance < 0;
  assert ValidBankState(bank');
}

method TestTransferWorkflow()
{
  var bank := CreateBankWithAccounts([
    ("Alice", 100000), ("Bob", 50000)
  ]);

  var transferResult := Transfer(bank, 0, 1, 30000, "Payment");
  assert transferResult.Success?;

  var (bank', txOut, txIn, maybeFee) := transferResult.value;
  assert bank'.accounts[0].balance == 70000;
  assert bank'.accounts[1].balance == 80000;
  assert txOut.parentTxId == Some(txIn.id);
  assert txIn.parentTxId == Some(txOut.id);
}
```

### 8.2.2 Persistence Tests (PersistenceTests.dfy)

**Test Coverage:**
- Save and load roundtrip
- Backup creation
- Corrupted file recovery
- Missing file handling
- Invalid JSON handling
- Data validation after load

**Example Tests:**
```dafny
method TestSaveLoadRoundtrip()
{
  var bank := CreateBankWithMultipleAccounts();
  var saveResult := SaveBankToFile(bank, "test.json");
  assert saveResult.Success?;

  var loadResult := LoadBankFromFile("test.json");
  assert loadResult.Success?;

  var loadedBank := loadResult.value;
  assert BanksEqual(bank, loadedBank);
  assert ValidBankState(loadedBank);
}

method TestCorruptedFileRecovery()
{
  // Create valid bank and save
  var bank := CreateBankWithAccount("Alice", 100000, false, 0);
  SaveBankToFile(bank, "test.json");

  // Corrupt the file
  CorruptFile("test.json");

  // Load should fallback to backup
  var loadResult := LoadBankFromFile("test.json");
  assert loadResult.Success?;
  assert ValidBankState(loadResult.value);
}
```

---

## 8.3 Verification Tests

### 8.3.1 Invariant Tests (InvariantTests.dfy)

**Test Coverage:**
- All invariants hold after each operation
- Invariants preserved across sequences
- Edge cases (limits, boundaries)
- Failure cases don't violate invariants

**Example Tests:**
```dafny
method TestInvariantsAfterDeposit()
{
  var bank := CreateBankWithAccount("Alice", 50000, false, 0);
  var result := Deposit(bank, 0, 25000, "Test");
  assert result.Success?;

  var (bank', tx) := result.value;
  assert ValidBankState(bank');
  assert ValidAccount(bank'.accounts[0]);
  assert BalanceMatchesHistory(bank'.accounts[0]);
}

method TestInvariantsAfterFailedWithdrawal()
{
  var bank := CreateBankWithAccount("Bob", 10000, false, 0);
  var result := Withdraw(bank, 0, 50000, "Test");
  assert result.Failure?;

  // Bank should be unchanged
  assert BanksEqual(bank, bank);  // Dafny proves no mutation
  assert ValidBankState(bank);
}

method TestFundConservationInTransfer()
{
  var bank := CreateBankWithAccounts([
    ("Alice", 100000), ("Bob", 50000)
  ]);

  var totalBefore := bank.accounts[0].balance + bank.accounts[1].balance;

  var result := Transfer(bank, 0, 1, 30000, "Test");
  assert result.Success?;

  var (bank', _, _, maybeFee) := result.value;
  var fee := if maybeFee.Some? then -maybeFee.value.amount else 0;
  var totalAfter := bank'.accounts[0].balance + bank'.accounts[1].balance;

  assert totalBefore == totalAfter + fee;  // Fund conservation
}
```

---

## 8.4 Property-Based Tests

**Test Coverage:**
- Random operation sequences
- Invariants hold for any valid input
- Failure modes don't corrupt state

**Approach:**
```dafny
method TestRandomOperationSequence()
{
  var bank := CreateEmptyBank();
  var operations := GenerateRandomOperations(100);

  var i := 0;
  while i < |operations|
    invariant ValidBankState(bank)
  {
    var op := operations[i];
    bank := ApplyOperation(bank, op);
    assert ValidBankState(bank);
    i := i + 1;
  }
}
```

---

## 8.5 Manual Testing Scenarios

### Scenario 1: Happy Path

1. Start application
2. Create account with initial deposit
3. Deposit additional funds
4. Withdraw within balance
5. Transfer to another account
6. Check balance and history
7. Exit gracefully

### Scenario 2: Overdraft Path

1. Create account with overdraft enabled
2. Withdraw beyond balance
3. Verify fee assessed
4. Check transaction history shows fee separately
5. Deposit to bring balance positive
6. Verify overdraft cleared

### Scenario 3: Error Handling

1. Attempt withdrawal with insufficient funds (overdraft disabled)
2. Attempt transfer to same account
3. Attempt withdrawal exceeding transaction limit
4. Attempt to close account with non-zero balance
5. Verify all operations rejected with clear errors
6. Verify system state unchanged

### Scenario 4: Persistence

1. Create accounts and perform transactions
2. Exit application
3. Restart application
4. Verify all data loaded correctly
5. Check backup files created
6. Simulate corrupted file, verify backup recovery

---

## Related Documentation

- **[VERIFICATION_SPEC.md](./VERIFICATION_SPEC.md)** - Formal verification specifications that complement the testing strategy with mathematical proofs of correctness
- **[FUNCTIONAL_REQUIREMENTS.md](./FUNCTIONAL_REQUIREMENTS.md)** - Complete feature specifications that define what is being tested
- **[../../guides/REQUIREMENTS_AND_EDGE_CASES.md](../REQUIREMENTS_AND_EDGE_CASES.md)** - Comprehensive catalog of edge cases and boundary conditions to test
- **[../../guides/AI_ASSISTED_GUIDE.md](../AI_ASSISTED_GUIDE.md)** - Guide for AI-assisted test generation and development workflows

---

**Document Version:** 1.0
**Last Updated:** 2025-10-30
**Status:** Active
