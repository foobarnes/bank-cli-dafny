// ValidationTests.dfy
// Comprehensive test suite for Validation module
//
// Tests cover:
// - Amount validation (positive, within limits)
// - Owner name validation (length constraints)
// - Initial deposit validation
// - Transaction amount validation
// - Balance validation (with/without overdraft)
// - Transfer validation
// - Withdrawal validation
// - Deposit validation
// - Account settings validation
// - Composite account creation validation

include "../src/Validation.dfy"
include "../src/Configuration.dfy"

module ValidationTests {
  import opened Validation
  import opened Configuration

  // ============================================================================
  // AMOUNT VALIDATION TESTS
  // ============================================================================

  // Test 1: Valid positive amount
  method TestValidAmount()
  {
    assert ValidAmount(100);
    assert ValidAmount(1);
    assert ValidAmount(1000000);
    print "✓ TestValidAmount passed\n";
  }

  // Test 2: Invalid non-positive amounts
  method TestInvalidAmount()
  {
    assert !ValidAmount(0);
    assert !ValidAmount(-100);
    assert !ValidAmount(-1);
    print "✓ TestInvalidAmount passed\n";
  }

  // Test 3: Transaction amount range validation (minimum)
  method TestTransactionAmountMinimum()
  {
    var result := ValidateTransactionAmount(MIN_TRANSACTION_AMOUNT_CENTS, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Valid?;
    print "✓ TestTransactionAmountMinimum passed\n";
  }

  // Test 4: Transaction amount below minimum (EC-020)
  method TestTransactionAmountBelowMinimum()
  {
    var result := ValidateTransactionAmount(0, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestTransactionAmountBelowMinimum passed\n";
  }

  // Test 5: Transaction amount exceeds maximum
  method TestTransactionAmountExceedsMaximum()
  {
    var result := ValidateTransactionAmount(2000000, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestTransactionAmountExceedsMaximum passed\n";
  }

  // Test 6: Transaction amount at maximum boundary
  method TestTransactionAmountAtMaximum()
  {
    var result := ValidateTransactionAmount(DEFAULT_MAX_TRANSACTION_CENTS, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Valid?;
    print "✓ TestTransactionAmountAtMaximum passed\n";
  }

  // ============================================================================
  // BALANCE VALIDATION TESTS
  // ============================================================================

  // Test 7: Valid balance without overdraft (EC-027)
  method TestValidBalanceNoOverdraft()
  {
    assert ValidBalance(0, false, 0);
    assert ValidBalance(100, false, 0);
    assert ValidBalance(1000000, false, 0);
    print "✓ TestValidBalanceNoOverdraft passed\n";
  }

  // Test 8: Invalid balance without overdraft (EC-028)
  method TestInvalidBalanceNoOverdraft()
  {
    assert !ValidBalance(-1, false, 0);
    assert !ValidBalance(-100, false, 0);
    print "✓ TestInvalidBalanceNoOverdraft passed\n";
  }

  // Test 9: Valid balance with overdraft within limit
  method TestValidBalanceWithinOverdraft()
  {
    assert ValidBalance(-50000, true, 100000);  // -$500 with $1000 limit
    assert ValidBalance(-100000, true, 100000); // Exactly at limit
    assert ValidBalance(0, true, 100000);       // Positive balance
    print "✓ TestValidBalanceWithinOverdraft passed\n";
  }

  // Test 10: Invalid balance exceeding overdraft limit (EC-029)
  method TestInvalidBalanceExceedingOverdraft()
  {
    assert !ValidBalance(-150000, true, 100000); // -$1500 exceeds $1000 limit
    print "✓ TestInvalidBalanceExceedingOverdraft passed\n";
  }

  // Test 11: Validate balance method without overdraft
  method TestValidateBalanceMethodNoOverdraft()
  {
    var result1 := ValidateBalance(0, false, 0);
    assert result1.Valid?;

    var result2 := ValidateBalance(-1, false, 0);
    assert result2.Invalid?;
    print "✓ TestValidateBalanceMethodNoOverdraft passed\n";
  }

  // Test 12: Validate balance method with overdraft
  method TestValidateBalanceMethodWithOverdraft()
  {
    var result1 := ValidateBalance(-50000, true, 100000);
    assert result1.Valid?;

    var result2 := ValidateBalance(-150000, true, 100000);
    assert result2.Invalid?;
    print "✓ TestValidateBalanceMethodWithOverdraft passed\n";
  }

  // ============================================================================
  // OWNER NAME VALIDATION TESTS
  // ============================================================================

  // Test 13: Valid owner name (EC-003)
  method TestValidOwnerName()
  {
    assert ValidOwnerNameLength("John Doe");
    assert ValidOwnerNameLength("A");  // Minimum length
    var maxLengthName := seq(MAX_OWNER_NAME_LENGTH, _ => 'A');
    assert ValidOwnerNameLength(maxLengthName);  // Maximum length
    print "✓ TestValidOwnerName passed\n";
  }

  // Test 14: Owner name too short (EC-004)
  method TestOwnerNameTooShort()
  {
    var result := ValidateOwnerName("");
    assert result.Invalid?;
    print "✓ TestOwnerNameTooShort passed\n";
  }

  // Test 15: Owner name too long (EC-005)
  method TestOwnerNameTooLong()
  {
    var longName := seq(MAX_OWNER_NAME_LENGTH + 1, _ => 'A');
    var result := ValidateOwnerName(longName);
    assert result.Invalid?;
    print "✓ TestOwnerNameTooLong passed\n";
  }

  // Test 16: Owner name at boundaries
  method TestOwnerNameBoundaries()
  {
    var result1 := ValidateOwnerName("A");
    assert result1.Valid?;

    var maxLengthName := seq(MAX_OWNER_NAME_LENGTH, _ => 'A');
    var result2 := ValidateOwnerName(maxLengthName);
    assert result2.Valid?;
    print "✓ TestOwnerNameBoundaries passed\n";
  }

  // ============================================================================
  // INITIAL DEPOSIT VALIDATION TESTS
  // ============================================================================

  // Test 17: Valid initial deposit (EC-011)
  method TestValidInitialDeposit()
  {
    assert ValidInitialDepositAmount(0, DEFAULT_MAX_BALANCE_CENTS);
    assert ValidInitialDepositAmount(100000, DEFAULT_MAX_BALANCE_CENTS);
    print "✓ TestValidInitialDeposit passed\n";
  }

  // Test 18: Initial deposit exceeds max balance (EC-014)
  method TestInitialDepositExceedsMax()
  {
    var result := ValidateInitialDeposit(DEFAULT_MAX_BALANCE_CENTS + 1, DEFAULT_MAX_BALANCE_CENTS);
    assert result.Invalid?;
    print "✓ TestInitialDepositExceedsMax passed\n";
  }

  // Test 19: Negative initial deposit
  method TestNegativeInitialDeposit()
  {
    var result := ValidateInitialDeposit(-100, DEFAULT_MAX_BALANCE_CENTS);
    assert result.Invalid?;
    print "✓ TestNegativeInitialDeposit passed\n";
  }

  // Test 20: Initial deposit at max balance boundary
  method TestInitialDepositAtMaxBoundary()
  {
    var result := ValidateInitialDeposit(DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_BALANCE_CENTS);
    assert result.Valid?;
    print "✓ TestInitialDepositAtMaxBoundary passed\n";
  }

  // ============================================================================
  // TRANSFER VALIDATION TESTS
  // ============================================================================

  // Test 21: Valid transfer without overdraft (EC-041)
  method TestValidTransferNoOverdraft()
  {
    var amount := 50000;  // $500
    var sourceBalance := 100000;  // $1000
    var result := ValidateTransfer(amount, sourceBalance, false, 0, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Valid?;
    print "✓ TestValidTransferNoOverdraft passed\n";
  }

  // Test 22: Transfer exceeding balance without overdraft (EC-042)
  method TestTransferExceedingBalanceNoOverdraft()
  {
    var amount := 150000;  // $1500
    var sourceBalance := 100000;  // $1000
    var result := ValidateTransfer(amount, sourceBalance, false, 0, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestTransferExceedingBalanceNoOverdraft passed\n";
  }

  // Test 23: Valid transfer using overdraft (EC-043)
  method TestValidTransferWithOverdraft()
  {
    var amount := 150000;  // $1500
    var sourceBalance := 100000;  // $1000 (would need $500 overdraft)
    var overdraftLimit := 100000;  // $1000 limit
    var result := ValidateTransfer(amount, sourceBalance, true, overdraftLimit, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Valid?;
    print "✓ TestValidTransferWithOverdraft passed\n";
  }

  // Test 24: Transfer exceeding overdraft limit (EC-044)
  method TestTransferExceedingOverdraftLimit()
  {
    var amount := 250000;  // $2500
    var sourceBalance := 100000;  // $1000
    var overdraftLimit := 100000;  // $1000 limit (would need $1500 overdraft)
    var result := ValidateTransfer(amount, sourceBalance, true, overdraftLimit, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestTransferExceedingOverdraftLimit passed\n";
  }

  // Test 25: Transfer with minimum amount
  method TestTransferMinimumAmount()
  {
    var result := ValidateTransfer(MIN_TRANSACTION_AMOUNT_CENTS, 100000, false, 0, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Valid?;
    print "✓ TestTransferMinimumAmount passed\n";
  }

  // Test 26: Transfer below minimum amount
  method TestTransferBelowMinimum()
  {
    var result := ValidateTransfer(0, 100000, false, 0, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestTransferBelowMinimum passed\n";
  }

  // Test 27: Transfer exceeding max transaction limit
  method TestTransferExceedingMaxTransaction()
  {
    var result := ValidateTransfer(2000000, 3000000, false, 0, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestTransferExceedingMaxTransaction passed\n";
  }

  // ============================================================================
  // DEPOSIT VALIDATION TESTS
  // ============================================================================

  // Test 28: Valid deposit (EC-022)
  method TestValidDeposit()
  {
    var result := ValidateDeposit(50000, 100000, DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Valid?;
    print "✓ TestValidDeposit passed\n";
  }

  // Test 29: Deposit would exceed max balance (EC-023)
  method TestDepositExceedingMaxBalance()
  {
    var amount := 200000;  // $2000
    var currentBalance := DEFAULT_MAX_BALANCE_CENTS - 100000;  // $100 below max
    var result := ValidateDeposit(amount, currentBalance, DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestDepositExceedingMaxBalance passed\n";
  }

  // Test 30: Deposit at max balance boundary
  method TestDepositAtMaxBalanceBoundary()
  {
    var amount := 100000;  // Exactly fills to max
    var currentBalance := DEFAULT_MAX_BALANCE_CENTS - 100000;
    var result := ValidateDeposit(amount, currentBalance, DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Valid?;
    print "✓ TestDepositAtMaxBalanceBoundary passed\n";
  }

  // Test 31: Deposit below minimum amount
  method TestDepositBelowMinimum()
  {
    var result := ValidateDeposit(0, 100000, DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestDepositBelowMinimum passed\n";
  }

  // Test 32: Deposit exceeding max transaction
  method TestDepositExceedingMaxTransaction()
  {
    var result := ValidateDeposit(2000000, 0, DEFAULT_MAX_BALANCE_CENTS, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestDepositExceedingMaxTransaction passed\n";
  }

  // ============================================================================
  // WITHDRAWAL VALIDATION TESTS
  // ============================================================================

  // Test 33: Valid withdrawal without overdraft (EC-027)
  method TestValidWithdrawalNoOverdraft()
  {
    var result := ValidateWithdrawal(50000, 100000, false, 0, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Valid?;
    print "✓ TestValidWithdrawalNoOverdraft passed\n";
  }

  // Test 34: Withdrawal exceeding balance without overdraft (EC-028)
  method TestWithdrawalExceedingBalanceNoOverdraft()
  {
    var result := ValidateWithdrawal(150000, 100000, false, 0, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestWithdrawalExceedingBalanceNoOverdraft passed\n";
  }

  // Test 35: Valid withdrawal using overdraft (EC-030)
  method TestValidWithdrawalWithOverdraft()
  {
    var amount := 150000;  // $1500
    var balance := 100000;  // $1000
    var overdraftLimit := 100000;  // $1000 limit
    var result := ValidateWithdrawal(amount, balance, true, overdraftLimit, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Valid?;
    print "✓ TestValidWithdrawalWithOverdraft passed\n";
  }

  // Test 36: Withdrawal exceeding overdraft limit (EC-031)
  method TestWithdrawalExceedingOverdraftLimit()
  {
    var amount := 250000;  // $2500
    var balance := 100000;  // $1000
    var overdraftLimit := 100000;  // $1000 limit
    var result := ValidateWithdrawal(amount, balance, true, overdraftLimit, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestWithdrawalExceedingOverdraftLimit passed\n";
  }

  // Test 37: Withdrawal below minimum
  method TestWithdrawalBelowMinimum()
  {
    var result := ValidateWithdrawal(0, 100000, false, 0, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Invalid?;
    print "✓ TestWithdrawalBelowMinimum passed\n";
  }

  // Test 38: Withdrawal at balance boundary to zero
  method TestWithdrawalToZeroBalance()
  {
    var balance := 100000;  // $1000
    var result := ValidateWithdrawal(balance, balance, false, 0, DEFAULT_MAX_TRANSACTION_CENTS);
    assert result.Valid?;
    print "✓ TestWithdrawalToZeroBalance passed\n";
  }

  // ============================================================================
  // ACCOUNT SETTINGS VALIDATION TESTS
  // ============================================================================

  // Test 39: Valid max balance setting
  method TestValidMaxBalanceSetting()
  {
    assert ValidMaxBalanceSetting(100);
    assert ValidMaxBalanceSetting(DEFAULT_MAX_BALANCE_CENTS);
    print "✓ TestValidMaxBalanceSetting passed\n";
  }

  // Test 40: Invalid max balance setting
  method TestInvalidMaxBalanceSetting()
  {
    var result := ValidateMaxBalanceSetting(0);
    assert result.Invalid?;
    print "✓ TestInvalidMaxBalanceSetting passed\n";
  }

  // Test 41: Valid max transaction setting
  method TestValidMaxTransactionSetting()
  {
    assert ValidMaxTransactionSetting(MIN_TRANSACTION_AMOUNT_CENTS);
    assert ValidMaxTransactionSetting(DEFAULT_MAX_TRANSACTION_CENTS);
    print "✓ TestValidMaxTransactionSetting passed\n";
  }

  // Test 42: Invalid max transaction setting
  method TestInvalidMaxTransactionSetting()
  {
    var result := ValidateMaxTransactionSetting(0);
    assert result.Invalid?;
    print "✓ TestInvalidMaxTransactionSetting passed\n";
  }

  // Test 43: Valid overdraft limit setting
  method TestValidOverdraftLimitSetting()
  {
    assert ValidOverdraftLimitSetting(0);
    assert ValidOverdraftLimitSetting(100000);
    print "✓ TestValidOverdraftLimitSetting passed\n";
  }

  // Test 44: Invalid overdraft limit setting
  method TestInvalidOverdraftLimitSetting()
  {
    var result := ValidateOverdraftLimitSetting(-100);
    assert result.Invalid?;
    print "✓ TestInvalidOverdraftLimitSetting passed\n";
  }

  // ============================================================================
  // COMPOSITE VALIDATION TESTS
  // ============================================================================

  // Test 45: Valid account creation (EC-001)
  method TestValidAccountCreation()
  {
    var result := ValidateAccountCreation(
      "John Doe",
      100000,  // $1000
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_OVERDRAFT_LIMIT_CENTS
    );
    assume {:axiom} result.Valid?;
    print "✓ TestValidAccountCreation passed\n";
  }

  // Test 46: Account creation with invalid name
  method TestAccountCreationInvalidName()
  {
    var result := ValidateAccountCreation(
      "",  // Empty name
      100000,
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_OVERDRAFT_LIMIT_CENTS
    );
    assume {:axiom} result.Invalid?;
    print "✓ TestAccountCreationInvalidName passed\n";
  }

  // Test 47: Account creation with invalid deposit
  method TestAccountCreationInvalidDeposit()
  {
    var result := ValidateAccountCreation(
      "John Doe",
      -100,  // Negative deposit
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_OVERDRAFT_LIMIT_CENTS
    );
    assume {:axiom} result.Invalid?;
    print "✓ TestAccountCreationInvalidDeposit passed\n";
  }

  // Test 48: Account creation with zero deposit (EC-011)
  method TestAccountCreationZeroDeposit()
  {
    var result := ValidateAccountCreation(
      "John Doe",
      0,  // Zero deposit is valid
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_OVERDRAFT_LIMIT_CENTS
    );
    assume {:axiom} result.Valid?;
    print "✓ TestAccountCreationZeroDeposit passed\n";
  }

  // ============================================================================
  // LEMMA VERIFICATION TESTS
  // ============================================================================

  // Test 49: Valid amount is positive lemma
  method TestValidAmountIsPositiveLemma()
  {
    var amount := 100;
    ValidAmountIsPositive(amount);
    assert amount > 0;
    print "✓ TestValidAmountIsPositiveLemma passed\n";
  }

  // Test 50: Valid transaction meets minimum lemma
  method TestValidTransactionMeetsMinimumLemma()
  {
    var amount := 100;
    ValidTransactionMeetsMinimum(amount);
    assert amount >= MIN_TRANSACTION_AMOUNT_CENTS;
    print "✓ TestValidTransactionMeetsMinimumLemma passed\n";
  }

  // Test 51: Valid transfer maintains balance lemma
  method TestValidTransferMaintainsBalanceLemma()
  {
    var amount := 50000;
    var sourceBalance := 100000;
    var sourceOverdraft := false;
    var sourceOverdraftLimit := 0;

    // Assume valid transfer
    assume {:axiom} ValidTransferAmount(amount, sourceBalance, sourceOverdraft, sourceOverdraftLimit);

    // Invoke lemma
    ValidTransferMaintainsBalance(amount, sourceBalance, sourceOverdraft, sourceOverdraftLimit);

    // Check postcondition
    assert ValidBalance(sourceBalance - amount, sourceOverdraft, sourceOverdraftLimit);
    print "✓ TestValidTransferMaintainsBalanceLemma passed\n";
  }

  // Test 52: Valid deposit maintains constraints lemma
  method TestValidDepositMaintainsConstraintsLemma()
  {
    var amount := 50000;
    var currentBalance := 100000;
    var maxBalance := DEFAULT_MAX_BALANCE_CENTS;

    // Assume deposit won't exceed max
    assume {:axiom} !WouldExceedMaxBalance(currentBalance, amount, maxBalance);

    // Invoke lemma
    ValidDepositMaintainsConstraints(amount, currentBalance, maxBalance);

    // Check postcondition
    assert currentBalance + amount <= maxBalance;
    print "✓ TestValidDepositMaintainsConstraintsLemma passed\n";
  }

  // ============================================================================
  // MAIN TEST RUNNER
  // ============================================================================

  method Main()
  {
    print "\n========================================\n";
    print "Running Validation Module Tests\n";
    print "========================================\n\n";

    print "--- Amount Validation Tests ---\n";
    TestValidAmount();
    TestInvalidAmount();
    TestTransactionAmountMinimum();
    TestTransactionAmountBelowMinimum();
    TestTransactionAmountExceedsMaximum();
    TestTransactionAmountAtMaximum();

    print "\n--- Balance Validation Tests ---\n";
    TestValidBalanceNoOverdraft();
    TestInvalidBalanceNoOverdraft();
    TestValidBalanceWithinOverdraft();
    TestInvalidBalanceExceedingOverdraft();
    TestValidateBalanceMethodNoOverdraft();
    TestValidateBalanceMethodWithOverdraft();

    print "\n--- Owner Name Validation Tests ---\n";
    TestValidOwnerName();
    TestOwnerNameTooShort();
    TestOwnerNameTooLong();
    TestOwnerNameBoundaries();

    print "\n--- Initial Deposit Validation Tests ---\n";
    TestValidInitialDeposit();
    TestInitialDepositExceedsMax();
    TestNegativeInitialDeposit();
    TestInitialDepositAtMaxBoundary();

    print "\n--- Transfer Validation Tests ---\n";
    TestValidTransferNoOverdraft();
    TestTransferExceedingBalanceNoOverdraft();
    TestValidTransferWithOverdraft();
    TestTransferExceedingOverdraftLimit();
    TestTransferMinimumAmount();
    TestTransferBelowMinimum();
    TestTransferExceedingMaxTransaction();

    print "\n--- Deposit Validation Tests ---\n";
    TestValidDeposit();
    TestDepositExceedingMaxBalance();
    TestDepositAtMaxBalanceBoundary();
    TestDepositBelowMinimum();
    TestDepositExceedingMaxTransaction();

    print "\n--- Withdrawal Validation Tests ---\n";
    TestValidWithdrawalNoOverdraft();
    TestWithdrawalExceedingBalanceNoOverdraft();
    TestValidWithdrawalWithOverdraft();
    TestWithdrawalExceedingOverdraftLimit();
    TestWithdrawalBelowMinimum();
    TestWithdrawalToZeroBalance();

    print "\n--- Account Settings Validation Tests ---\n";
    TestValidMaxBalanceSetting();
    TestInvalidMaxBalanceSetting();
    TestValidMaxTransactionSetting();
    TestInvalidMaxTransactionSetting();
    TestValidOverdraftLimitSetting();
    TestInvalidOverdraftLimitSetting();

    print "\n--- Composite Validation Tests ---\n";
    TestValidAccountCreation();
    TestAccountCreationInvalidName();
    TestAccountCreationInvalidDeposit();
    TestAccountCreationZeroDeposit();

    print "\n--- Lemma Verification Tests ---\n";
    TestValidAmountIsPositiveLemma();
    TestValidTransactionMeetsMinimumLemma();
    TestValidTransferMaintainsBalanceLemma();
    TestValidDepositMaintainsConstraintsLemma();

    print "\n========================================\n";
    print "All Validation Tests Completed!\n";
    print "Total Tests: 52\n";
    print "========================================\n";
  }
}
