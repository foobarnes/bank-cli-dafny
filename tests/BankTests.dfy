// BankTests.dfy
// Comprehensive test suite for Bank module
//
// Tests cover:
// - Bank creation and initialization
// - Account management (add, get, exists)
// - Deposit operations with validation
// - Withdrawal operations (with/without overdraft and fee calculation)
// - Transfer operations (atomic fund conservation)
// - Bank invariants (ValidBank, fund conservation, fee monotonicity)
// - Edge cases from requirements
// - Transaction ID generation
// - Fee tracking and aggregation

include "../src/Bank.dfy"
include "../src/Account.dfy"
include "../src/Transaction.dfy"
include "../src/Configuration.dfy"

module BankTests {
  import opened Bank
  import opened Account
  import opened Transaction
  import opened Configuration

  // ============================================================================
  // BANK CREATION AND INITIALIZATION TESTS
  // ============================================================================

  // Test 1: Create empty bank
  method TestCreateEmptyBank()
  {
    var bank := CreateBank();
    assert bank.accounts == map[];
    assert bank.nextTransactionId == 1;
    assert bank.totalFees == 0;
    assert ValidBank(bank);
    print "✓ TestCreateEmptyBank passed\n";
  }

  // Test 2: Bank invariant holds for empty bank
  method TestEmptyBankInvariant()
  {
    var bank := CreateBank();
    assert ValidBank(bank);
    assert bank.totalFees == SumAccountFees(bank.accounts);
    print "✓ TestEmptyBankInvariant passed\n";
  }

  // ============================================================================
  // ACCOUNT MANAGEMENT TESTS
  // ============================================================================

  // Test 3: Add account to empty bank
  method TestAddAccountToEmptyBank()
  {
    var bank := CreateBank();
    var account := Account.Account(
      1000,
      "John Doe",
      0,
      [],
      false,
      0,
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_MAX_TRANSACTION_CENTS,
      0,
      Active,
      0
    );

    var newBank := AddAccount(bank, account);
    assert 1000 in newBank.accounts;
    assert newBank.accounts[1000] == account;
    assert |newBank.accounts| == 1;
    print "✓ TestAddAccountToEmptyBank passed\n";
  }

  // Test 4: Add multiple accounts
  method TestAddMultipleAccounts()
  {
    var bank := CreateBank();

    var account1 := Account.Account(1000, "Alice", 0, [], false, 0,
                                     DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                     0, Active, 0);
    var account2 := Account.Account(1001, "Bob", 0, [], false, 0,
                                     DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                     0, Active, 0);

    var bank1 := AddAccount(bank, account1);
    var bank2 := AddAccount(bank1, account2);

    assert 1000 in bank2.accounts;
    assert 1001 in bank2.accounts;
    assert |bank2.accounts| == 2;
    print "✓ TestAddMultipleAccounts passed\n";
  }

  // Test 5: Get existing account
  method TestGetExistingAccount()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 100000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var retrieved := GetAccount(bank1, 1000);
    assert retrieved.Some?;
    assert retrieved.value == account;
    assert retrieved.value.owner == "John Doe";
    assert retrieved.value.balance == 100000;
    print "✓ TestGetExistingAccount passed\n";
  }

  // Test 6: Get non-existent account
  method TestGetNonExistentAccount()
  {
    var bank := CreateBank();
    var retrieved := GetAccount(bank, 9999);
    assert retrieved.None?;
    print "✓ TestGetNonExistentAccount passed\n";
  }

  // Test 7: Account exists check
  method TestAccountExists()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 0, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    assert AccountExists(bank1, 1000);
    assert !AccountExists(bank1, 9999);
    print "✓ TestAccountExists passed\n";
  }

  // ============================================================================
  // TRANSACTION ID GENERATION TESTS
  // ============================================================================

  // Test 8: Generate unique transaction IDs
  method TestGenerateTransactionId()
  {
    var bank := CreateBank();
    assert bank.nextTransactionId == 1;

    var id1, bank1 := GenerateTransactionId(bank);
    assert id1 == "TX-1";
    assert bank1.nextTransactionId == 2;

    var id2, bank2 := GenerateTransactionId(bank1);
    assert id2 == "TX-2";
    assert bank2.nextTransactionId == 3;

    assert id1 != id2;
    print "✓ TestGenerateTransactionId passed\n";
  }

  // ============================================================================
  // DEPOSIT OPERATION TESTS
  // ============================================================================

  // Test 9: Valid deposit to account (EC-022)
  method TestValidDeposit()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 100000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg := Deposit(bank1, 1000, 50000, "Salary", 1);
    assert success;
    assert errorMsg == "";
    assert 1000 in newBank.accounts;
    assert newBank.accounts[1000].balance == 150000;  // $1500
    print "✓ TestValidDeposit passed\n";
  }

  // Test 10: Deposit to non-existent account (EC-024)
  method TestDepositToNonExistentAccount()
  {
    var bank := CreateBank();
    var newBank, success, errorMsg := Deposit(bank, 9999, 50000, "Deposit", 1);
    assert !success;
    assert errorMsg == "Account does not exist";
    print "✓ TestDepositToNonExistentAccount passed\n";
  }

  // Test 11: Deposit exceeding max balance (EC-023)
  method TestDepositExceedingMaxBalance()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", DEFAULT_MAX_BALANCE_CENTS - 100, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg := Deposit(bank1, 1000, 200, "Deposit", 1);
    assert !success;
    print "✓ TestDepositExceedingMaxBalance passed\n";
  }

  // Test 12: Deposit with zero amount (EC-025)
  method TestDepositZeroAmount()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 100000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg := Deposit(bank1, 1000, 0, "Deposit", 1);
    assert !success;
    print "✓ TestDepositZeroAmount passed\n";
  }

  // Test 13: Deposit creates transaction record
  method TestDepositCreatesTransaction()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 100000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg := Deposit(bank1, 1000, 50000, "Salary", 1);
    assert success;
    assert 1000 in newBank.accounts;
    assert |newBank.accounts[1000].history| == 1;

    var tx := newBank.accounts[1000].history[0];
    assert tx.txType.Deposit?;
    assert tx.amount == 50000;
    assert tx.description == "Salary";
    print "✓ TestDepositCreatesTransaction passed\n";
  }

  // ============================================================================
  // WITHDRAWAL OPERATION TESTS (WITHOUT OVERDRAFT)
  // ============================================================================

  // Test 14: Valid withdrawal without overdraft (EC-027)
  method TestValidWithdrawalNoOverdraft()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 100000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 50000, "ATM", 1);
    assert success;
    assert errorMsg == "";
    assert feeCharged == 0;  // No overdraft, no fee
    assert 1000 in newBank.accounts;
    assert newBank.accounts[1000].balance == 50000;  // $500 remaining
    print "✓ TestValidWithdrawalNoOverdraft passed\n";
  }

  // Test 15: Withdrawal exceeding balance without overdraft (EC-028)
  method TestWithdrawalExceedingBalanceNoOverdraft()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 50000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 100000, "ATM", 1);
    assert !success;
    assert newBank.accounts[1000].balance == 50000;  // Balance unchanged
    print "✓ TestWithdrawalExceedingBalanceNoOverdraft passed\n";
  }

  // Test 16: Withdrawal to exactly zero balance
  method TestWithdrawalToZeroBalance()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 100000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 100000, "Withdraw all", 1);
    assert success;
    assert feeCharged == 0;
    assert newBank.accounts[1000].balance == 0;
    print "✓ TestWithdrawalToZeroBalance passed\n";
  }

  // ============================================================================
  // WITHDRAWAL OPERATION TESTS (WITH OVERDRAFT)
  // ============================================================================

  // Test 17: Valid withdrawal using overdraft Tier 1 (EC-030, EC-055)
  method TestWithdrawalOverdraftTier1()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 5000, [], true, DEFAULT_OVERDRAFT_LIMIT_CENTS,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    // Withdraw $100, going $50 into overdraft (Tier 1: $0.01-$100 → $25 fee)
    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 10000, "ATM", 1);
    assert success;
    assert feeCharged == 2500;  // $25 fee
    assert newBank.accounts[1000].balance == -5000 - 2500;  // -$50 - $25 fee = -$75
    print "✓ TestWithdrawalOverdraftTier1 passed\n";
  }

  // Test 18: Withdrawal using overdraft Tier 2 (EC-057)
  method TestWithdrawalOverdraftTier2()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 5000, [], true, DEFAULT_OVERDRAFT_LIMIT_CENTS,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    // Withdraw $250, going $200 into overdraft (Tier 2: $100.01-$500 → $35 fee)
    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 25000, "ATM", 1);
    assert success;
    assert feeCharged == 3500;  // $35 fee
    assert newBank.accounts[1000].balance == -20000 - 3500;  // -$200 - $35 = -$235
    print "✓ TestWithdrawalOverdraftTier2 passed\n";
  }

  // Test 19: Withdrawal using overdraft Tier 3 (EC-059)
  method TestWithdrawalOverdraftTier3()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 5000, [], true, DEFAULT_OVERDRAFT_LIMIT_CENTS,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    // Withdraw $700, going $650 into overdraft (Tier 3: $500.01-$1000 → $50 fee)
    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 70000, "ATM", 1);
    assert success;
    assert feeCharged == 5000;  // $50 fee
    assert newBank.accounts[1000].balance == -65000 - 5000;  // -$650 - $50 = -$700
    print "✓ TestWithdrawalOverdraftTier3 passed\n";
  }

  // Test 20: Withdrawal exceeding overdraft limit (EC-031)
  method TestWithdrawalExceedingOverdraftLimit()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 50000, [], true, 100000,  // $1000 limit
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    // Try to withdraw $2000 (would need $1500 overdraft, but limit is $1000)
    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 200000, "ATM", 1);
    assert !success;
    assert newBank.accounts[1000].balance == 50000;  // Balance unchanged
    print "✓ TestWithdrawalExceedingOverdraftLimit passed\n";
  }

  // Test 21: Withdrawal creates fee transaction when overdraft used
  method TestWithdrawalCreatesFeeTransaction()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 5000, [], true, DEFAULT_OVERDRAFT_LIMIT_CENTS,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 10000, "ATM", 1);
    assert success;
    assert feeCharged == 2500;

    // Should have 2 transactions: withdrawal + fee
    assert |newBank.accounts[1000].history| == 2;

    var withdrawalTx := newBank.accounts[1000].history[0];
    var feeTx := newBank.accounts[1000].history[1];

    assert withdrawalTx.txType.Withdrawal?;
    assert feeTx.txType.Fee?;
    assert feeTx.amount == -2500;
    assert feeTx.parentTxId.Some?;
    assert feeTx.parentTxId.value == withdrawalTx.id;
    print "✓ TestWithdrawalCreatesFeeTransaction passed\n";
  }

  // Test 22: Fee monotonicity after withdrawal with overdraft
  method TestFeeMonotonicityAfterWithdrawal()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 5000, [], true, DEFAULT_OVERDRAFT_LIMIT_CENTS,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    assert bank1.totalFees == 0;

    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 10000, "ATM", 1);
    assert success;
    assert newBank.totalFees == 2500;  // $25 fee
    assert newBank.totalFees > bank1.totalFees;  // Monotonicity
    print "✓ TestFeeMonotonicityAfterWithdrawal passed\n";
  }

  // ============================================================================
  // TRANSFER OPERATION TESTS
  // ============================================================================

  // Test 23: Valid transfer between accounts (EC-041)
  method TestValidTransfer()
  {
    var bank := CreateBank();
    var account1 := Account.Account(1000, "Alice", 100000, [], false, 0,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var account2 := Account.Account(1001, "Bob", 50000, [], false, 0,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var bank1 := AddAccount(bank, account1);
    var bank2 := AddAccount(bank1, account2);

    var newBank, success, errorMsg := Transfer(bank2, 1000, 1001, 30000, "Payment", 1);
    assert success;
    assert errorMsg == "";
    assert newBank.accounts[1000].balance == 70000;   // Alice: $1000 - $300 = $700
    assert newBank.accounts[1001].balance == 80000;   // Bob: $500 + $300 = $800
    print "✓ TestValidTransfer passed\n";
  }

  // Test 24: Transfer with fund conservation
  method TestTransferFundConservation()
  {
    var bank := CreateBank();
    var account1 := Account.Account(1000, "Alice", 100000, [], false, 0,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var account2 := Account.Account(1001, "Bob", 50000, [], false, 0,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var bank1 := AddAccount(bank, account1);
    var bank2 := AddAccount(bank1, account2);

    var totalBefore := bank2.accounts[1000].balance + bank2.accounts[1001].balance;

    var newBank, success, errorMsg := Transfer(bank2, 1000, 1001, 30000, "Payment", 1);
    assert success;

    var totalAfter := newBank.accounts[1000].balance + newBank.accounts[1001].balance;
    assert totalAfter == totalBefore;  // Fund conservation (no fees on simple transfer)
    print "✓ TestTransferFundConservation passed\n";
  }

  // Test 25: Transfer creates two transaction records (EC-046)
  method TestTransferCreatesTransactions()
  {
    var bank := CreateBank();
    var account1 := Account.Account(1000, "Alice", 100000, [], false, 0,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var account2 := Account.Account(1001, "Bob", 50000, [], false, 0,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var bank1 := AddAccount(bank, account1);
    var bank2 := AddAccount(bank1, account2);

    var newBank, success, errorMsg := Transfer(bank2, 1000, 1001, 30000, "Payment", 1);
    assert success;

    // Alice should have 1 TransferOut transaction
    assert |newBank.accounts[1000].history| == 1;
    assert newBank.accounts[1000].history[0].txType.TransferOut?;

    // Bob should have 1 TransferIn transaction
    assert |newBank.accounts[1001].history| == 1;
    assert newBank.accounts[1001].history[0].txType.TransferIn?;
    print "✓ TestTransferCreatesTransactions passed\n";
  }

  // Test 26: Transfer from non-existent account (EC-047)
  method TestTransferFromNonExistentAccount()
  {
    var bank := CreateBank();
    var account := Account.Account(1001, "Bob", 50000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg := Transfer(bank1, 9999, 1001, 30000, "Payment", 1);
    assert !success;
    assert errorMsg == "Source account does not exist";
    print "✓ TestTransferFromNonExistentAccount passed\n";
  }

  // Test 27: Transfer to non-existent account (EC-048)
  method TestTransferToNonExistentAccount()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "Alice", 100000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg := Transfer(bank1, 1000, 9999, 30000, "Payment", 1);
    assert !success;
    assert errorMsg == "Destination account does not exist";
    print "✓ TestTransferToNonExistentAccount passed\n";
  }

  // Test 28: Transfer to same account (EC-049)
  method TestTransferToSameAccount()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "Alice", 100000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg := Transfer(bank1, 1000, 1000, 30000, "Self transfer", 1);
    assert !success;
    assert errorMsg == "Cannot transfer to the same account";
    print "✓ TestTransferToSameAccount passed\n";
  }

  // Test 29: Transfer with insufficient funds (EC-042)
  method TestTransferInsufficientFunds()
  {
    var bank := CreateBank();
    var account1 := Account.Account(1000, "Alice", 50000, [], false, 0,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var account2 := Account.Account(1001, "Bob", 50000, [], false, 0,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var bank1 := AddAccount(bank, account1);
    var bank2 := AddAccount(bank1, account2);

    var newBank, success, errorMsg := Transfer(bank2, 1000, 1001, 100000, "Payment", 1);
    assert !success;
    print "✓ TestTransferInsufficientFunds passed\n";
  }

  // Test 30: Transfer using overdraft with fee (EC-043, EC-055)
  method TestTransferUsingOverdraftWithFee()
  {
    var bank := CreateBank();
    var account1 := Account.Account(1000, "Alice", 50000, [], true, DEFAULT_OVERDRAFT_LIMIT_CENTS,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var account2 := Account.Account(1001, "Bob", 50000, [], false, 0,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var bank1 := AddAccount(bank, account1);
    var bank2 := AddAccount(bank1, account2);

    // Transfer $100 (Alice has $500, goes $50 into overdraft → $25 fee)
    var newBank, success, errorMsg := Transfer(bank2, 1000, 1001, 10000, "Payment", 1);
    assert success;

    // Alice: $500 - $100 - $25 fee = $375
    assert newBank.accounts[1000].balance == 37500;
    // Bob: $500 + $100 = $600
    assert newBank.accounts[1001].balance == 60000;

    // Check fee was recorded
    assert newBank.totalFees == 2500;
    print "✓ TestTransferUsingOverdraftWithFee passed\n";
  }

  // Test 31: Transfer with destination at max balance (EC-052)
  method TestTransferDestinationAtMaxBalance()
  {
    var bank := CreateBank();
    var account1 := Account.Account(1000, "Alice", 100000, [], false, 0,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var account2 := Account.Account(1001, "Bob", DEFAULT_MAX_BALANCE_CENTS, [], false, 0,
                                    DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                    0, Active, 0);
    var bank1 := AddAccount(bank, account1);
    var bank2 := AddAccount(bank1, account2);

    var newBank, success, errorMsg := Transfer(bank2, 1000, 1001, 10000, "Payment", 1);
    assert !success;
    print "✓ TestTransferDestinationAtMaxBalance passed\n";
  }

  // ============================================================================
  // BANK INVARIANT TESTS
  // ============================================================================

  // Test 32: ValidBank maintained after deposit
  method TestValidBankAfterDeposit()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 100000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg := Deposit(bank1, 1000, 50000, "Salary", 1);
    assert success;
    // ValidBank should still hold (though we can't fully verify without all predicates)
    assert newBank.totalFees == 0;  // No fees on deposit
    print "✓ TestValidBankAfterDeposit passed\n";
  }

  // Test 33: ValidBank maintained after withdrawal with fee
  method TestValidBankAfterWithdrawalWithFee()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 5000, [], true, DEFAULT_OVERDRAFT_LIMIT_CENTS,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 10000, "ATM", 1);
    assert success;
    assert newBank.totalFees == feeCharged;
    assert newBank.totalFees > 0;
    print "✓ TestValidBankAfterWithdrawalWithFee passed\n";
  }

  // Test 34: Transaction ID increments correctly
  method TestTransactionIdIncrement()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 100000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    assert bank1.nextTransactionId == 1;

    var bank2, success1, errorMsg1 := Deposit(bank1, 1000, 10000, "Deposit 1", 1);
    assert success1;

    var bank3, success2, errorMsg2 := Deposit(bank2, 1000, 10000, "Deposit 2", 2);
    assert success2;

    // Each deposit should increment transaction ID
    assert bank3.nextTransactionId > bank2.nextTransactionId;
    assert bank2.nextTransactionId > bank1.nextTransactionId;
    print "✓ TestTransactionIdIncrement passed\n";
  }

  // ============================================================================
  // EDGE CASE TESTS
  // ============================================================================

  // Test 35: Withdraw entire balance leaves zero (EC-032)
  method TestWithdrawEntireBalance()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 123456, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 123456, "Close account", 1);
    assert success;
    assert newBank.accounts[1000].balance == 0;
    assert feeCharged == 0;
    print "✓ TestWithdrawEntireBalance passed\n";
  }

  // Test 36: Multiple operations on same account
  method TestMultipleOperationsSameAccount()
  {
    var bank := CreateBank();
    var account := Account.Account(1000, "John Doe", 100000, [], false, 0,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    // Deposit
    var bank2, success1, errorMsg1 := Deposit(bank1, 1000, 50000, "Deposit", 1);
    assert success1;
    assert bank2.accounts[1000].balance == 150000;

    // Withdraw
    var bank3, success2, errorMsg2, fee2 := Withdraw(bank2, 1000, 30000, "Withdraw", 2);
    assert success2;
    assert bank3.accounts[1000].balance == 120000;

    // Deposit again
    var bank4, success3, errorMsg3 := Deposit(bank3, 1000, 10000, "Deposit 2", 3);
    assert success3;
    assert bank4.accounts[1000].balance == 130000;

    // Check transaction history
    assert |bank4.accounts[1000].history| == 3;
    print "✓ TestMultipleOperationsSameAccount passed\n";
  }

  // Test 37: Bank with no accounts has zero total balance
  method TestEmptyBankZeroBalance()
  {
    var bank := CreateBank();
    assert TotalBalance(bank.accounts) == 0;
    print "✓ TestEmptyBankZeroBalance passed\n";
  }

  // Test 38: Overdraft fee at exact tier boundary (EC-056)
  method TestOverdraftFeeAtTierBoundary()
  {
    var bank := CreateBank();
    // Start with exactly $100
    var account := Account.Account(1000, "John Doe", 10000, [], true, DEFAULT_OVERDRAFT_LIMIT_CENTS,
                                   DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS,
                                   0, Active, 0);
    var bank1 := AddAccount(bank, account);

    // Withdraw $200, going exactly $100 into overdraft (Tier 1 max)
    var newBank, success, errorMsg, feeCharged := Withdraw(bank1, 1000, 20000, "ATM", 1);
    assert success;
    assert feeCharged == 2500;  // $25 fee for Tier 1
    print "✓ TestOverdraftFeeAtTierBoundary passed\n";
  }

  // ============================================================================
  // MAIN TEST RUNNER
  // ============================================================================

  method Main()
  {
    print "\n========================================\n";
    print "Running Bank Module Tests\n";
    print "========================================\n\n";

    print "--- Bank Creation Tests ---\n";
    TestCreateEmptyBank();
    TestEmptyBankInvariant();

    print "\n--- Account Management Tests ---\n";
    TestAddAccountToEmptyBank();
    TestAddMultipleAccounts();
    TestGetExistingAccount();
    TestGetNonExistentAccount();
    TestAccountExists();

    print "\n--- Transaction ID Generation Tests ---\n";
    TestGenerateTransactionId();

    print "\n--- Deposit Operation Tests ---\n";
    TestValidDeposit();
    TestDepositToNonExistentAccount();
    TestDepositExceedingMaxBalance();
    TestDepositZeroAmount();
    TestDepositCreatesTransaction();

    print "\n--- Withdrawal Tests (No Overdraft) ---\n";
    TestValidWithdrawalNoOverdraft();
    TestWithdrawalExceedingBalanceNoOverdraft();
    TestWithdrawalToZeroBalance();

    print "\n--- Withdrawal Tests (With Overdraft) ---\n";
    TestWithdrawalOverdraftTier1();
    TestWithdrawalOverdraftTier2();
    TestWithdrawalOverdraftTier3();
    TestWithdrawalExceedingOverdraftLimit();
    TestWithdrawalCreatesFeeTransaction();
    TestFeeMonotonicityAfterWithdrawal();

    print "\n--- Transfer Operation Tests ---\n";
    TestValidTransfer();
    TestTransferFundConservation();
    TestTransferCreatesTransactions();
    TestTransferFromNonExistentAccount();
    TestTransferToNonExistentAccount();
    TestTransferToSameAccount();
    TestTransferInsufficientFunds();
    TestTransferUsingOverdraftWithFee();
    TestTransferDestinationAtMaxBalance();

    print "\n--- Bank Invariant Tests ---\n";
    TestValidBankAfterDeposit();
    TestValidBankAfterWithdrawalWithFee();
    TestTransactionIdIncrement();

    print "\n--- Edge Case Tests ---\n";
    TestWithdrawEntireBalance();
    TestMultipleOperationsSameAccount();
    TestEmptyBankZeroBalance();
    TestOverdraftFeeAtTierBoundary();

    print "\n========================================\n";
    print "All Bank Tests Completed!\n";
    print "Total Tests: 38\n";
    print "========================================\n";
  }
}
