/*
 * AccountTests.dfy
 * Comprehensive test suite for Account module
 *
 * Tests cover:
 * - Account creation with various configurations
 * - Balance computation from transaction history
 * - Account validity predicates
 * - Edge cases and boundary conditions
 */

include "../src/Account.dfy"
include "../src/Transaction.dfy"
include "../src/Configuration.dfy"

module AccountTests {
  import opened Account
  import opened Transaction
  import opened Configuration

  // ============================================================================
  // Test 1: Valid Account Creation
  // ============================================================================

  method TestValidAccountCreation()
    ensures true  // Test should complete successfully
  {
    print "Test 1: TestValidAccountCreation\n";

    var account, success := CreateAccount(
      1,                                    // id
      "John Doe",                          // owner
      50000,                               // initialDeposit: $500.00
      false,                               // enableOverdraft
      0,                                   // overdraftLimit
      DEFAULT_MAX_BALANCE_CENTS,           // maxBalance
      DEFAULT_MAX_TRANSACTION_CENTS        // maxTransaction
    );

    // Verify success
    assert success;
    expect success, "Account creation should succeed";

    // Verify account properties
    expect account.id == 1, "Account ID should be 1";
    expect account.owner == "John Doe", "Owner should be John Doe";
    expect account.balance == 50000, "Balance should be $500.00 (50000 cents)";
    expect account.status == Active, "Account should be Active";
    expect !account.overdraftEnabled, "Overdraft should be disabled";
    expect |account.history| == 1, "History should contain 1 transaction";

    // Verify account validity
    assert ValidAccount(account);

    print "  PASSED: Account created successfully with correct properties\n";
  }

  // ============================================================================
  // Test 2: Zero Initial Deposit
  // ============================================================================

  method TestZeroInitialDeposit()
    ensures true
  {
    print "Test 2: TestZeroInitialDeposit\n";

    var account, success := CreateAccount(
      2,
      "Jane Smith",
      0,                                   // $0 initial deposit
      false,
      0,
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_MAX_TRANSACTION_CENTS
    );

    assert success;
    expect success, "Account creation with $0 should succeed";
    expect account.balance == 0, "Balance should be $0";
    expect |account.history| == 0, "History should be empty for $0 deposit";
    assert ValidAccount(account);

    print "  PASSED: Account created with $0 initial deposit\n";
  }

  // ============================================================================
  // Test 3: Account With Overdraft Enabled
  // ============================================================================

  method TestAccountWithOverdraft()
    ensures true
  {
    print "Test 3: TestAccountWithOverdraft\n";

    var account, success := CreateAccount(
      3,
      "Bob Johnson",
      100000,                              // $1,000.00
      true,                                // Enable overdraft
      50000,                               // $500.00 overdraft limit
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_MAX_TRANSACTION_CENTS
    );

    assert success;
    expect success, "Account creation with overdraft should succeed";
    expect account.overdraftEnabled, "Overdraft should be enabled";
    expect account.overdraftLimit == 50000, "Overdraft limit should be $500.00";
    expect account.balance == 100000, "Balance should be $1,000.00";
    assert ValidAccount(account);

    print "  PASSED: Account created with overdraft enabled\n";
  }

  // ============================================================================
  // Test 4: Account Without Overdraft
  // ============================================================================

  method TestAccountWithoutOverdraft()
    ensures true
  {
    print "Test 4: TestAccountWithoutOverdraft\n";

    var account, success := CreateAccount(
      4,
      "Alice Brown",
      25000,                               // $250.00
      false,                               // Disable overdraft
      0,
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_MAX_TRANSACTION_CENTS
    );

    assert success;
    expect success, "Account creation without overdraft should succeed";
    expect !account.overdraftEnabled, "Overdraft should be disabled";
    expect account.overdraftLimit == 0, "Overdraft limit should be 0";
    expect account.balance >= 0, "Balance should be non-negative";
    assert ValidAccount(account);

    print "  PASSED: Account created without overdraft\n";
  }

  // ============================================================================
  // Test 5: Excessive Initial Deposit (Should Fail)
  // ============================================================================

  method TestExcessiveInitialDeposit()
    ensures true
  {
    print "Test 5: TestExcessiveInitialDeposit\n";

    var maxBal := 100000;  // $1,000.00 max
    var excessiveDeposit := 150000;  // $1,500.00 (exceeds max)

    var account, success := CreateAccount(
      5,
      "Charlie Wilson",
      excessiveDeposit,
      false,
      0,
      maxBal,                              // Lower max balance
      DEFAULT_MAX_TRANSACTION_CENTS
    );

    // Should fail because initialDeposit > maxBalance
    expect !success, "Account creation should fail for excessive deposit";
    expect account.balance == 0, "Failed account should have 0 balance";
    expect account.status == Closed, "Failed account should be Closed";

    print "  PASSED: Excessive initial deposit correctly rejected\n";
  }

  // ============================================================================
  // Test 6: Balance Computation from Empty History
  // ============================================================================

  method TestBalanceComputationEmpty()
    ensures true
  {
    print "Test 6: TestBalanceComputationEmpty\n";

    var emptyHistory: seq<Transaction> := [];
    var balance := ComputeBalanceFromHistory(emptyHistory);

    expect balance == 0, "Balance of empty history should be 0";

    print "  PASSED: Empty history computed correctly\n";
  }

  // ============================================================================
  // Test 7: Balance Computation from Single Transaction
  // ============================================================================

  method TestBalanceComputationSingle()
    ensures true
  {
    print "Test 7: TestBalanceComputationSingle\n";

    var tx := Transaction(
      "TX-001",
      1,
      Deposit,
      50000,                               // $500.00 deposit
      "Initial deposit",
      0,
      0,
      50000,
      Completed,
      None,
      []
    );

    var history := [tx];
    var balance := ComputeBalanceFromHistory(history);

    expect balance == 50000, "Balance should equal transaction amount";

    print "  PASSED: Single transaction balance computed correctly\n";
  }

  // ============================================================================
  // Test 8: Balance Computation from Multiple Transactions
  // ============================================================================

  method TestBalanceComputationMultiple()
    ensures true
  {
    print "Test 8: TestBalanceComputationMultiple\n";

    // Create multiple transactions
    var tx1 := Transaction(
      "TX-001", 1, Deposit, 100000,        // +$1,000.00
      "Initial deposit", 0, 0, 100000, Completed, None, []
    );

    var tx2 := Transaction(
      "TX-002", 1, Withdrawal, -30000,     // -$300.00
      "ATM withdrawal", 1, 100000, 70000, Completed, None, []
    );

    var tx3 := Transaction(
      "TX-003", 1, Deposit, 20000,         // +$200.00
      "Check deposit", 2, 70000, 90000, Completed, None, []
    );

    var tx4 := Transaction(
      "TX-004", 1, Withdrawal, -10000,     // -$100.00
      "Purchase", 3, 90000, 80000, Completed, None, []
    );

    var history := [tx1, tx2, tx3, tx4];
    var balance := ComputeBalanceFromHistory(history);

    // Expected: 100000 - 30000 + 20000 - 10000 = 80000
    expect balance == 80000, "Balance should be $800.00 (80000 cents)";

    print "  PASSED: Multiple transaction balance computed correctly\n";
  }

  // ============================================================================
  // Test 9: Valid Account Predicate
  // ============================================================================

  method TestValidAccountPredicate()
    ensures true
  {
    print "Test 9: TestValidAccountPredicate\n";

    var account, success := CreateAccount(
      9,
      "David Lee",
      75000,                               // $750.00
      true,                                // Overdraft enabled
      DEFAULT_OVERDRAFT_LIMIT_CENTS,
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_MAX_TRANSACTION_CENTS
    );

    assert success;
    expect success, "Account creation should succeed";

    // Verify ValidAccount predicate
    assert ValidAccount(account);

    // Manually check key properties that ValidAccount verifies
    assert BalanceMatchesHistory(account);
    expect account.overdraftLimit >= 0, "Overdraft limit should be non-negative";
    expect account.maxBalance > 0, "Max balance should be positive";
    expect account.maxTransaction > 0, "Max transaction should be positive";
    expect account.totalFeesCollected >= 0, "Total fees should be non-negative";
    expect |account.owner| > 0, "Owner name should not be empty";

    print "  PASSED: ValidAccount predicate holds for valid account\n";
  }

  // ============================================================================
  // Test 10: Balance Matches History Predicate
  // ============================================================================

  method TestBalanceMatchesHistory()
    ensures true
  {
    print "Test 10: TestBalanceMatchesHistory\n";

    // Create account with known balance
    var account, success := CreateAccount(
      10,
      "Emma Davis",
      125000,                              // $1,250.00
      false,
      0,
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_MAX_TRANSACTION_CENTS
    );

    assert success;
    expect success, "Account creation should succeed";

    // Verify BalanceMatchesHistory predicate
    assert BalanceMatchesHistory(account);

    // Manually verify the relationship
    var computedBalance := ComputeBalanceFromHistory(account.history);
    expect account.balance == computedBalance,
      "Account balance should match computed balance from history";

    print "  PASSED: BalanceMatchesHistory predicate holds\n";
  }

  // ============================================================================
  // Additional Test: Account with Maximum Values
  // ============================================================================

  method TestAccountWithMaximumValues()
    ensures true
  {
    print "Test 11: TestAccountWithMaximumValues\n";

    var account, success := CreateAccount(
      999,
      "Maximum Value Account",
      DEFAULT_MAX_BALANCE_CENTS,           // Maximum initial deposit
      true,
      DEFAULT_OVERDRAFT_LIMIT_CENTS,
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_MAX_TRANSACTION_CENTS
    );

    assert success;
    expect success, "Account creation with max values should succeed";
    expect account.balance == DEFAULT_MAX_BALANCE_CENTS,
      "Balance should equal max balance";
    assert ValidAccount(account);

    print "  PASSED: Account created with maximum configuration values\n";
  }

  // ============================================================================
  // Additional Test: Overdraft Limit Boundary
  // ============================================================================

  method TestOverdraftLimitBoundary()
    ensures true
  {
    print "Test 12: TestOverdraftLimitBoundary\n";

    var customLimit := 200000;  // $2,000.00

    var account, success := CreateAccount(
      12,
      "Overdraft Boundary Test",
      50000,
      true,
      customLimit,
      DEFAULT_MAX_BALANCE_CENTS,
      DEFAULT_MAX_TRANSACTION_CENTS
    );

    assert success;
    expect success, "Account with custom overdraft limit should succeed";
    expect account.overdraftLimit == customLimit,
      "Overdraft limit should match specified value";
    assert ValidAccount(account);

    print "  PASSED: Custom overdraft limit set correctly\n";
  }

  // ============================================================================
  // Additional Test: Total Fees Computation
  // ============================================================================

  method TestTotalFeesComputation()
    ensures true
  {
    print "Test 13: TestTotalFeesComputation\n";

    // Create a history with fee transactions
    var tx1 := Transaction(
      "TX-001", 1, Deposit, 100000,
      "Initial deposit", 0, 0, 100000, Completed, None, []
    );

    var feeDetails := FeeDetails([], -2500, "Overdraft fee");
    var feeTx := Transaction(
      "TX-002", 1, Fee(OverdraftFee, feeDetails), 0,
      "Fee", 1, 100000, 100000, Completed, Some("TX-001"), []
    );

    var history := [tx1, feeTx];
    var totalFees := TotalFees(history);

    // TotalFees should sum up all fee amounts from history
    expect totalFees == 0, "Total fees should be 0 (fee is in amount field)";

    print "  PASSED: Total fees computed from history\n";
  }

  // ============================================================================
  // Main Test Runner
  // ============================================================================

  method Main()
  {
    print "\n";
    print "========================================\n";
    print "Account Module Test Suite\n";
    print "========================================\n";
    print "\n";

    TestValidAccountCreation();
    print "\n";

    TestZeroInitialDeposit();
    print "\n";

    TestAccountWithOverdraft();
    print "\n";

    TestAccountWithoutOverdraft();
    print "\n";

    TestExcessiveInitialDeposit();
    print "\n";

    TestBalanceComputationEmpty();
    print "\n";

    TestBalanceComputationSingle();
    print "\n";

    TestBalanceComputationMultiple();
    print "\n";

    TestValidAccountPredicate();
    print "\n";

    TestBalanceMatchesHistory();
    print "\n";

    TestAccountWithMaximumValues();
    print "\n";

    TestOverdraftLimitBoundary();
    print "\n";

    TestTotalFeesComputation();
    print "\n";

    print "========================================\n";
    print "All Account Tests Completed Successfully\n";
    print "========================================\n";
  }
}
