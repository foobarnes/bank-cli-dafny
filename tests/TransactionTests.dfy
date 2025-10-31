/*
 * Comprehensive Test Suite for Transaction Module
 *
 * This test suite validates all transaction types, fee calculations,
 * parent-child linking, and verification predicates defined in Transaction.dfy.
 *
 * Test Coverage:
 * - All transaction types (Deposit, Withdrawal, TransferIn, TransferOut, Fee, Interest, Adjustment)
 * - Option type operations (Some/None)
 * - TotalFees calculation (empty history, single transaction, multiple transactions)
 * - FeeMonotonicity predicate validation
 * - Balance consistency checks
 * - Fee transaction parent-child linking
 * - FeeLinksValid predicate validation
 * - TierBreakdown calculations
 * - TransactionHistoryValid compound predicate
 */

include "../src/Transaction.dfy"

module TransactionTests {
  import opened Transaction

  // ============================================================================
  // Test 1: Create Transaction of Each Type
  // ============================================================================

  method TestCreateDepositTransaction() returns (success: bool)
  {
    var tx := Transaction(
      "tx001",
      1,
      Deposit,
      1000,
      "Initial deposit",
      1000000,
      0,
      1000,
      Completed,
      None,
      []
    );

    success := tx.txType.Deposit? &&
               tx.amount == 1000 &&
               tx.balanceAfter == 1000 &&
               tx.parentTxId.None?;

    print "Test: CreateDepositTransaction - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestCreateWithdrawalTransaction() returns (success: bool)
  {
    var tx := Transaction(
      "tx002",
      1,
      Withdrawal,
      -500,
      "ATM withdrawal",
      1000100,
      1000,
      500,
      Completed,
      None,
      []
    );

    success := tx.txType.Withdrawal? &&
               tx.amount == -500 &&
               tx.balanceBefore == 1000 &&
               tx.balanceAfter == 500;

    print "Test: CreateWithdrawalTransaction - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestCreateTransferInTransaction() returns (success: bool)
  {
    var tx := Transaction(
      "tx003",
      1,
      TransferIn,
      2000,
      "Transfer from account 2",
      1000200,
      500,
      2500,
      Completed,
      None,
      []
    );

    success := tx.txType.TransferIn? &&
               tx.amount == 2000 &&
               tx.balanceAfter == 2500;

    print "Test: CreateTransferInTransaction - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestCreateTransferOutTransaction() returns (success: bool)
  {
    var tx := Transaction(
      "tx004",
      1,
      TransferOut,
      -1500,
      "Transfer to account 3",
      1000300,
      2500,
      1000,
      Completed,
      None,
      ["fee001"]  // Has child fee
    );

    success := tx.txType.TransferOut? &&
               tx.amount == -1500 &&
               tx.balanceAfter == 1000 &&
               |tx.childTxIds| == 1;

    print "Test: CreateTransferOutTransaction - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestCreateFeeTransaction() returns (success: bool)
  {
    var tierCharge := TierCharge(0, 0, 1000, 1000, 250, -25);
    var feeDetails := FeeDetails([tierCharge], -25, "Transfer fee: $25");
    var tx := Transaction(
      "fee001",
      1,
      Fee(TransferFee, feeDetails),
      -25,
      "Transfer fee",
      1000301,
      1000,
      975,
      Completed,
      Some("tx004"),  // Parent is the transfer out
      []
    );

    success := tx.txType.Fee? &&
               tx.amount == -25 &&
               tx.parentTxId.Some? &&
               tx.parentTxId.value == "tx004" &&
               tx.txType.category == TransferFee;

    print "Test: CreateFeeTransaction - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestCreateInterestTransaction() returns (success: bool)
  {
    var tx := Transaction(
      "tx005",
      1,
      Interest,
      15,
      "Monthly interest",
      1000400,
      975,
      990,
      Completed,
      None,
      []
    );

    success := tx.txType.Interest? &&
               tx.amount == 15 &&
               tx.balanceAfter == 990;

    print "Test: CreateInterestTransaction - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestCreateAdjustmentTransaction() returns (success: bool)
  {
    var tx := Transaction(
      "tx006",
      1,
      Adjustment,
      100,
      "Correction for processing error",
      1000500,
      990,
      1090,
      Completed,
      None,
      []
    );

    success := tx.txType.Adjustment? &&
               tx.amount == 100 &&
               tx.balanceAfter == 1090;

    print "Test: CreateAdjustmentTransaction - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Test 2: Option Type Operations
  // ============================================================================

  method TestOptionTypeSome() returns (success: bool)
  {
    var parentId: Option<string> := Some("parent123");

    success := parentId.Some? &&
               parentId.value == "parent123";

    print "Test: OptionTypeSome - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestOptionTypeNone() returns (success: bool)
  {
    var parentId: Option<string> := None;

    success := parentId.None? &&
               !parentId.Some?;

    print "Test: OptionTypeNone - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestOptionTypeComparison() returns (success: bool)
  {
    var some1: Option<string> := Some("abc");
    var some2: Option<string> := Some("abc");
    var none1: Option<string> := None;

    success := some1 == some2 &&
               some1 != none1 &&
               !(some1 == none1);

    print "Test: OptionTypeComparison - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Test 3: TotalFees with Empty History
  // ============================================================================

  method TestTotalFeesEmptyHistory() returns (success: bool)
  {
    var history: seq<Transaction> := [];
    var total := TotalFees(history);

    success := total == 0;

    print "Test: TotalFeesEmptyHistory - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Test 4: TotalFees with Multiple Transactions
  // ============================================================================

  method TestTotalFeesMultipleTransactions() returns (success: bool)
  {
    // Create a deposit (no fee)
    var deposit := Transaction(
      "tx001", 1, Deposit, 1000, "Deposit", 1000000, 0, 1000, Completed, None, []
    );

    // Create a withdrawal with fee
    var withdrawal := Transaction(
      "tx002", 1, Withdrawal, -500, "Withdrawal", 1000100, 1000, 500, Completed, None, ["fee001"]
    );

    // Create an ATM fee
    var tierCharge1 := TierCharge(0, 0, 500, 500, 600, -30);
    var feeDetails1 := FeeDetails([tierCharge1], -30, "ATM fee: $30");
    var atmFee := Transaction(
      "fee001", 1, Fee(ATMFee, feeDetails1), -30, "ATM fee", 1000101, 500, 470, Completed, Some("tx002"), []
    );

    // Create a transfer with fee
    var transfer := Transaction(
      "tx003", 1, TransferOut, -200, "Transfer", 1000200, 470, 270, Completed, None, ["fee002"]
    );

    // Create a transfer fee
    var tierCharge2 := TierCharge(0, 0, 200, 200, 250, -5);
    var feeDetails2 := FeeDetails([tierCharge2], -5, "Transfer fee: $5");
    var transferFee := Transaction(
      "fee002", 1, Fee(TransferFee, feeDetails2), -5, "Transfer fee", 1000201, 270, 265, Completed, Some("tx003"), []
    );

    // Create history
    var history := [deposit, withdrawal, atmFee, transfer, transferFee];
    var total := TotalFees(history);

    // Total fees should be 30 + 5 = 35 (fees are negated when summing)
    success := total == 35;

    print "Test: TotalFeesMultipleTransactions - ", if success then "PASSED" else "FAILED", "\n";
    print "  Expected total fees: 35, Actual: ", total, "\n";
    return success;
  }

  method TestTotalFeesSingleFee() returns (success: bool)
  {
    var tierCharge := TierCharge(0, 0, 1000, 1000, 250, -25);
    var feeDetails := FeeDetails([tierCharge], -25, "Single fee");
    var fee := Transaction(
      "fee001", 1, Fee(OverdraftFee, feeDetails), -25, "Overdraft fee", 1000000, 100, 75, Completed, Some("parent"), []
    );

    var history := [fee];
    var total := TotalFees(history);

    success := total == 25;  // Fee amount is -25, negated to 25

    print "Test: TotalFeesSingleFee - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Test 5: FeeMonotonicity with Increasing Fees
  // ============================================================================

  method TestFeeMonotonicityValid() returns (success: bool)
  {
    // Create transactions with monotonically increasing fees
    var deposit := Transaction(
      "tx001", 1, Deposit, 1000, "Deposit", 1000000, 0, 1000, Completed, None, []
    );

    var tierCharge1 := TierCharge(0, 0, 100, 100, 1000, -10);
    var feeDetails1 := FeeDetails([tierCharge1], -10, "Fee 1");
    var fee1 := Transaction(
      "fee001", 1, Fee(MaintenanceFee, feeDetails1), -10, "Fee 1", 1000100, 1000, 990, Completed, Some("tx001"), []
    );

    var tierCharge2 := TierCharge(0, 0, 100, 100, 2000, -20);
    var feeDetails2 := FeeDetails([tierCharge2], -20, "Fee 2");
    var fee2 := Transaction(
      "fee002", 1, Fee(MaintenanceFee, feeDetails2), -20, "Fee 2", 1000200, 990, 970, Completed, Some("tx001"), []
    );

    var history := [deposit, fee1, fee2];

    // Verify monotonicity: fees at each point should be non-decreasing
    var fees0 := TotalFees(history[..0]);  // 0 fees
    var fees1 := TotalFees(history[..1]);  // 0 fees (deposit only)
    var fees2 := TotalFees(history[..2]);  // 10 fees
    var fees3 := TotalFees(history[..3]);  // 30 fees

    success := fees0 <= fees1 && fees1 <= fees2 && fees2 <= fees3 &&
               FeeMonotonicity(history);

    print "Test: FeeMonotonicityValid - ", if success then "PASSED" else "FAILED", "\n";
    print "  Fees progression: ", fees0, " -> ", fees1, " -> ", fees2, " -> ", fees3, "\n";
    return success;
  }

  method TestFeeMonotonicityEmptyHistory() returns (success: bool)
  {
    var history: seq<Transaction> := [];
    var isMonotonic := FeeMonotonicity(history);

    success := isMonotonic;  // Empty history is trivially monotonic

    print "Test: FeeMonotonicityEmptyHistory - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Test 6: Balance Consistency Checks
  // ============================================================================

  method TestBalanceConsistencyValid() returns (success: bool)
  {
    var tx := Transaction(
      "tx001", 1, Deposit, 500, "Deposit", 1000000, 1000, 1500, Completed, None, []
    );

    var isConsistent := BalanceConsistency(tx);

    success := isConsistent &&
               tx.balanceAfter == tx.balanceBefore + tx.amount;

    print "Test: BalanceConsistencyValid - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestBalanceConsistencyNegativeAmount() returns (success: bool)
  {
    var tx := Transaction(
      "tx002", 1, Withdrawal, -300, "Withdrawal", 1000100, 1500, 1200, Completed, None, []
    );

    var isConsistent := BalanceConsistency(tx);

    success := isConsistent &&
               tx.balanceAfter == 1200 &&
               1200 == 1500 + (-300);

    print "Test: BalanceConsistencyNegativeAmount - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestBalanceConsistencyZeroAmount() returns (success: bool)
  {
    var tx := Transaction(
      "tx003", 1, Adjustment, 0, "No-op adjustment", 1000200, 1200, 1200, Completed, None, []
    );

    var isConsistent := BalanceConsistency(tx);

    success := isConsistent &&
               tx.balanceAfter == tx.balanceBefore;

    print "Test: BalanceConsistencyZeroAmount - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Test 7: Fee Transaction Parent-Child Linking
  // ============================================================================

  method TestFeeLinksValidSimple() returns (success: bool)
  {
    // Create parent transaction
    var parent := Transaction(
      "tx001", 1, Withdrawal, -500, "Withdrawal", 1000000, 1000, 500, Completed, None, ["fee001"]
    );

    // Create fee transaction with proper parent link
    var tierCharge := TierCharge(0, 0, 500, 500, 500, -25);
    var feeDetails := FeeDetails([tierCharge], -25, "Withdrawal fee");
    var fee := Transaction(
      "fee001", 1, Fee(ATMFee, feeDetails), -25, "ATM fee", 1000001, 500, 475, Completed, Some("tx001"), []
    );

    var history := [parent, fee];
    var linksValid := FeeLinksValid(history);

    success := linksValid &&
               fee.parentTxId.Some? &&
               fee.parentTxId.value == parent.id &&
               fee.id in parent.childTxIds;

    print "Test: FeeLinksValidSimple - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestFeeLinksValidMultipleFees() returns (success: bool)
  {
    // Create parent transaction with multiple child fees
    var parent := Transaction(
      "tx001", 1, TransferOut, -1000, "Transfer", 1000000, 2000, 1000, Completed, None, ["fee001", "fee002"]
    );

    // Create first fee
    var tierCharge1 := TierCharge(0, 0, 1000, 1000, 250, -25);
    var feeDetails1 := FeeDetails([tierCharge1], -25, "Transfer fee");
    var fee1 := Transaction(
      "fee001", 1, Fee(TransferFee, feeDetails1), -25, "Transfer fee", 1000001, 1000, 975, Completed, Some("tx001"), []
    );

    // Create second fee
    var tierCharge2 := TierCharge(0, 0, 1000, 1000, 150, -15);
    var feeDetails2 := FeeDetails([tierCharge2], -15, "Processing fee");
    var fee2 := Transaction(
      "fee002", 1, Fee(MaintenanceFee, feeDetails2), -15, "Processing fee", 1000002, 975, 960, Completed, Some("tx001"), []
    );

    var history := [parent, fee1, fee2];
    var linksValid := FeeLinksValid(history);

    success := linksValid &&
               fee1.parentTxId.Some? &&
               fee2.parentTxId.Some? &&
               fee1.id in parent.childTxIds &&
               fee2.id in parent.childTxIds;

    print "Test: FeeLinksValidMultipleFees - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestFeeLinksNoFeesInHistory() returns (success: bool)
  {
    // History with no fee transactions
    var deposit := Transaction(
      "tx001", 1, Deposit, 1000, "Deposit", 1000000, 0, 1000, Completed, None, []
    );

    var withdrawal := Transaction(
      "tx002", 1, Withdrawal, -500, "Withdrawal", 1000100, 1000, 500, Completed, None, []
    );

    var history := [deposit, withdrawal];
    var linksValid := FeeLinksValid(history);

    success := linksValid;  // Vacuously true - no fees to validate

    print "Test: FeeLinksNoFeesInHistory - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Test 8: TierBreakdown Calculations
  // ============================================================================

  method TestTierBreakdownSingleTier() returns (success: bool)
  {
    var tierCharge := TierCharge(0, 0, 1000, 1000, 250, -25);
    var feeDetails := FeeDetails([tierCharge], -25, "Single tier fee");

    var isValid := TierBreakdownValid(feeDetails);
    var sum := SumTierCharges(feeDetails.tierBreakdown);

    success := isValid &&
               sum == -25 &&
               sum == feeDetails.baseAmount;

    print "Test: TierBreakdownSingleTier - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  method TestTierBreakdownMultipleTiers() returns (success: bool)
  {
    // Three-tier fee structure
    var tier0 := TierCharge(0, 0, 1000, 1000, 100, -10);      // First $1000 at 1%
    var tier1 := TierCharge(1, 1000, 5000, 4000, 200, -80);   // Next $4000 at 2%
    var tier2 := TierCharge(2, 5000, 10000, 3000, 300, -90);  // Remaining $3000 at 3%

    var feeDetails := FeeDetails([tier0, tier1, tier2], -180, "Tiered fee: $180");

    var isValid := TierBreakdownValid(feeDetails);
    var sum := SumTierCharges(feeDetails.tierBreakdown);

    success := isValid &&
               sum == -180 &&
               sum == feeDetails.baseAmount &&
               sum == (-10 + -80 + -90);

    print "Test: TierBreakdownMultipleTiers - ", if success then "PASSED" else "FAILED", "\n";
    print "  Tier 0 charge: -10, Tier 1 charge: -80, Tier 2 charge: -90, Total: ", sum, "\n";
    return success;
  }

  method TestSumTierChargesEmpty() returns (success: bool)
  {
    var emptyTiers: seq<TierCharge> := [];
    var sum := SumTierCharges(emptyTiers);

    success := sum == 0;

    print "Test: SumTierChargesEmpty - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Test 9: FeeAmountMatchesDetails Predicate
  // ============================================================================

  method TestFeeAmountMatchesDetailsValid() returns (success: bool)
  {
    var tierCharge := TierCharge(0, 0, 500, 500, 400, -20);
    var feeDetails := FeeDetails([tierCharge], -20, "Fee details");
    var fee := Transaction(
      "fee001", 1, Fee(OverdraftFee, feeDetails), -20, "Overdraft fee", 1000000, 1000, 980, Completed, Some("parent"), []
    );

    var matches := FeeAmountMatchesDetails(fee);

    success := matches &&
               fee.amount == -20 &&
               fee.txType.details.baseAmount == -20;

    print "Test: FeeAmountMatchesDetailsValid - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Test 10: TransactionHistoryValid Compound Predicate
  // ============================================================================

  method TestTransactionHistoryValidComplete() returns (success: bool)
  {
    // Build a complete valid transaction history
    var tx1 := Transaction(
      "tx001", 1, Deposit, 1000, "Initial deposit", 1000000, 0, 1000, Completed, None, []
    );

    var tx2 := Transaction(
      "tx002", 1, Withdrawal, -500, "Withdrawal", 1000100, 1000, 500, Completed, None, ["fee001"]
    );

    var tierCharge := TierCharge(0, 0, 500, 500, 600, -30);
    var feeDetails := FeeDetails([tierCharge], -30, "ATM fee");
    var fee1 := Transaction(
      "fee001", 1, Fee(ATMFee, feeDetails), -30, "ATM fee", 1000101, 500, 470, Completed, Some("tx002"), []
    );

    var tx3 := Transaction(
      "tx003", 1, Interest, 5, "Monthly interest", 1000200, 470, 475, Completed, None, []
    );

    var history := [tx1, tx2, fee1, tx3];
    var historyValid := TransactionHistoryValid(history);

    // Verify all individual predicates
    var feeMonotonic := FeeMonotonicity(history);
    var linksValid := FeeLinksValid(history);
    var allBalancesConsistent :=
      BalanceConsistency(history[0]) &&
      BalanceConsistency(history[1]) &&
      BalanceConsistency(history[2]) &&
      BalanceConsistency(history[3]);
    var sequentialBalances :=
      history[0].balanceAfter == history[1].balanceBefore &&
      history[1].balanceAfter == history[2].balanceBefore &&
      history[2].balanceAfter == history[3].balanceBefore;

    success := historyValid &&
               feeMonotonic &&
               linksValid &&
               allBalancesConsistent &&
               sequentialBalances;

    print "Test: TransactionHistoryValidComplete - ", if success then "PASSED" else "FAILED", "\n";
    print "  FeeMonotonicity: ", feeMonotonic, "\n";
    print "  FeeLinksValid: ", linksValid, "\n";
    print "  BalanceConsistency: ", allBalancesConsistent, "\n";
    print "  SequentialBalances: ", sequentialBalances, "\n";
    return success;
  }

  method TestTransactionHistoryValidEmpty() returns (success: bool)
  {
    var history: seq<Transaction> := [];
    var historyValid := TransactionHistoryValid(history);

    success := historyValid;  // Empty history is trivially valid

    print "Test: TransactionHistoryValidEmpty - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Test 11: Fee Category Coverage
  // ============================================================================

  method TestAllFeeCategories() returns (success: bool)
  {
    var tierCharge := TierCharge(0, 0, 100, 100, 1000, -10);

    var overdraftDetails := FeeDetails([tierCharge], -10, "Overdraft");
    var overdraftFee := Fee(OverdraftFee, overdraftDetails);

    var maintenanceDetails := FeeDetails([tierCharge], -10, "Maintenance");
    var maintenanceFee := Fee(MaintenanceFee, maintenanceDetails);

    var transferDetails := FeeDetails([tierCharge], -10, "Transfer");
    var transferFee := Fee(TransferFee, transferDetails);

    var atmDetails := FeeDetails([tierCharge], -10, "ATM");
    var atmFee := Fee(ATMFee, atmDetails);

    var insufficientDetails := FeeDetails([tierCharge], -10, "Insufficient Funds");
    var insufficientFee := Fee(InsufficientFundsFee, insufficientDetails);

    success := overdraftFee.Fee? &&
               maintenanceFee.Fee? &&
               transferFee.Fee? &&
               atmFee.Fee? &&
               insufficientFee.Fee? &&
               overdraftFee.category == OverdraftFee &&
               maintenanceFee.category == MaintenanceFee &&
               transferFee.category == TransferFee &&
               atmFee.category == ATMFee &&
               insufficientFee.category == InsufficientFundsFee;

    print "Test: AllFeeCategories - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Test 12: Transaction Status Coverage
  // ============================================================================

  method TestAllTransactionStatuses() returns (success: bool)
  {
    var pending := Transaction(
      "tx001", 1, Deposit, 1000, "Pending deposit", 1000000, 0, 1000, Pending, None, []
    );

    var completed := Transaction(
      "tx002", 1, Deposit, 1000, "Completed deposit", 1000100, 0, 1000, Completed, None, []
    );

    var failed := Transaction(
      "tx003", 1, Withdrawal, -5000, "Failed withdrawal", 1000200, 1000, 1000, Failed, None, []
    );

    var rolledBack := Transaction(
      "tx004", 1, TransferOut, -500, "Rolled back transfer", 1000300, 1000, 1000, RolledBack, None, []
    );

    success := pending.status.Pending? &&
               completed.status.Completed? &&
               failed.status.Failed? &&
               rolledBack.status.RolledBack? &&
               failed.balanceBefore == failed.balanceAfter;  // Failed tx doesn't change balance

    print "Test: AllTransactionStatuses - ", if success then "PASSED" else "FAILED", "\n";
    return success;
  }

  // ============================================================================
  // Main Test Runner
  // ============================================================================

  method Main()
  {
    print "\n";
    print "========================================\n";
    print "Transaction Module Test Suite\n";
    print "========================================\n\n";

    var passCount := 0;
    var totalTests := 0;

    // Test 1: Transaction type creation
    print "--- Test Suite 1: Transaction Type Creation ---\n";
    var t1 := TestCreateDepositTransaction();
    passCount := passCount + (if t1 then 1 else 0);
    totalTests := totalTests + 1;

    var t2 := TestCreateWithdrawalTransaction();
    passCount := passCount + (if t2 then 1 else 0);
    totalTests := totalTests + 1;

    var t3 := TestCreateTransferInTransaction();
    passCount := passCount + (if t3 then 1 else 0);
    totalTests := totalTests + 1;

    var t4 := TestCreateTransferOutTransaction();
    passCount := passCount + (if t4 then 1 else 0);
    totalTests := totalTests + 1;

    var t5 := TestCreateFeeTransaction();
    passCount := passCount + (if t5 then 1 else 0);
    totalTests := totalTests + 1;

    var t6 := TestCreateInterestTransaction();
    passCount := passCount + (if t6 then 1 else 0);
    totalTests := totalTests + 1;

    var t7 := TestCreateAdjustmentTransaction();
    passCount := passCount + (if t7 then 1 else 0);
    totalTests := totalTests + 1;

    // Test 2: Option type
    print "\n--- Test Suite 2: Option Type Operations ---\n";
    var t8 := TestOptionTypeSome();
    passCount := passCount + (if t8 then 1 else 0);
    totalTests := totalTests + 1;

    var t9 := TestOptionTypeNone();
    passCount := passCount + (if t9 then 1 else 0);
    totalTests := totalTests + 1;

    var t10 := TestOptionTypeComparison();
    passCount := passCount + (if t10 then 1 else 0);
    totalTests := totalTests + 1;

    // Test 3: TotalFees calculations
    print "\n--- Test Suite 3: TotalFees Calculations ---\n";
    var t11 := TestTotalFeesEmptyHistory();
    passCount := passCount + (if t11 then 1 else 0);
    totalTests := totalTests + 1;

    var t12 := TestTotalFeesSingleFee();
    passCount := passCount + (if t12 then 1 else 0);
    totalTests := totalTests + 1;

    var t13 := TestTotalFeesMultipleTransactions();
    passCount := passCount + (if t13 then 1 else 0);
    totalTests := totalTests + 1;

    // Test 4: FeeMonotonicity
    print "\n--- Test Suite 4: FeeMonotonicity ---\n";
    var t14 := TestFeeMonotonicityValid();
    passCount := passCount + (if t14 then 1 else 0);
    totalTests := totalTests + 1;

    var t15 := TestFeeMonotonicityEmptyHistory();
    passCount := passCount + (if t15 then 1 else 0);
    totalTests := totalTests + 1;

    // Test 5: Balance consistency
    print "\n--- Test Suite 5: Balance Consistency ---\n";
    var t16 := TestBalanceConsistencyValid();
    passCount := passCount + (if t16 then 1 else 0);
    totalTests := totalTests + 1;

    var t17 := TestBalanceConsistencyNegativeAmount();
    passCount := passCount + (if t17 then 1 else 0);
    totalTests := totalTests + 1;

    var t18 := TestBalanceConsistencyZeroAmount();
    passCount := passCount + (if t18 then 1 else 0);
    totalTests := totalTests + 1;

    // Test 6: Fee parent-child linking
    print "\n--- Test Suite 6: Fee Parent-Child Linking ---\n";
    var t19 := TestFeeLinksValidSimple();
    passCount := passCount + (if t19 then 1 else 0);
    totalTests := totalTests + 1;

    var t20 := TestFeeLinksValidMultipleFees();
    passCount := passCount + (if t20 then 1 else 0);
    totalTests := totalTests + 1;

    var t21 := TestFeeLinksNoFeesInHistory();
    passCount := passCount + (if t21 then 1 else 0);
    totalTests := totalTests + 1;

    // Test 7: Tier breakdown
    print "\n--- Test Suite 7: Tier Breakdown Calculations ---\n";
    var t22 := TestTierBreakdownSingleTier();
    passCount := passCount + (if t22 then 1 else 0);
    totalTests := totalTests + 1;

    var t23 := TestTierBreakdownMultipleTiers();
    passCount := passCount + (if t23 then 1 else 0);
    totalTests := totalTests + 1;

    var t24 := TestSumTierChargesEmpty();
    passCount := passCount + (if t24 then 1 else 0);
    totalTests := totalTests + 1;

    // Test 8: Fee amount matches details
    print "\n--- Test Suite 8: Fee Amount Validation ---\n";
    var t25 := TestFeeAmountMatchesDetailsValid();
    passCount := passCount + (if t25 then 1 else 0);
    totalTests := totalTests + 1;

    // Test 9: TransactionHistoryValid
    print "\n--- Test Suite 9: Transaction History Validation ---\n";
    var t26 := TestTransactionHistoryValidComplete();
    passCount := passCount + (if t26 then 1 else 0);
    totalTests := totalTests + 1;

    var t27 := TestTransactionHistoryValidEmpty();
    passCount := passCount + (if t27 then 1 else 0);
    totalTests := totalTests + 1;

    // Test 10: Fee categories
    print "\n--- Test Suite 10: Fee Categories ---\n";
    var t28 := TestAllFeeCategories();
    passCount := passCount + (if t28 then 1 else 0);
    totalTests := totalTests + 1;

    // Test 11: Transaction statuses
    print "\n--- Test Suite 11: Transaction Statuses ---\n";
    var t29 := TestAllTransactionStatuses();
    passCount := passCount + (if t29 then 1 else 0);
    totalTests := totalTests + 1;

    // Summary
    print "\n========================================\n";
    print "Test Summary\n";
    print "========================================\n";
    print "Total tests: ", totalTests, "\n";
    print "Passed: ", passCount, "\n";
    print "Failed: ", totalTests - passCount, "\n";

    if passCount == totalTests {
      print "\nALL TESTS PASSED!\n";
    } else {
      print "\nSOME TESTS FAILED!\n";
    }
    print "========================================\n\n";
  }
}
