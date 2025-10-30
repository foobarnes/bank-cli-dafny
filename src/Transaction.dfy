/*
 * Transaction Module for Verified Bank CLI
 *
 * This module defines the core transaction types and related structures for
 * modeling banking operations with formal verification support.
 *
 * Key Design Principles:
 * - Transactions use signed integers: positive for credits, negative for debits
 * - Fees are represented as negative amounts (debits to the account)
 * - Parent-child relationships link fees to their triggering transactions
 * - Ghost predicates enable verification of fee invariants
 */

module Transaction {

  // ============================================================================
  // Core Transaction Types
  // ============================================================================

  /*
   * TransactionType categorizes different banking operations.
   * Fee transactions include detailed breakdown information for verification.
   */
  datatype TransactionType =
    | Deposit
    | Withdrawal
    | TransferIn
    | TransferOut
    | Fee(category: FeeCategory, details: FeeDetails)
    | Interest
    | Adjustment

  /*
   * FeeCategory enumerates the different types of fees that can be charged.
   * Each category may have different calculation rules and tier structures.
   */
  datatype FeeCategory =
    | OverdraftFee
    | MaintenanceFee
    | TransferFee
    | ATMFee
    | InsufficientFundsFee

  /*
   * FeeDetails provides transparent breakdown of fee calculations.
   * This enables verification that fees are computed correctly according
   * to the tiered fee schedule.
   */
  datatype FeeDetails = FeeDetails(
    tierBreakdown: seq<TierCharge>,  // Sequence of tier-based charges
    baseAmount: int,                  // Total fee amount (should match transaction amount)
    calculationNote: string           // Human-readable explanation
  )

  /*
   * TierCharge represents a single tier in a tiered fee calculation.
   * For example, different fee rates may apply to different balance ranges.
   */
  datatype TierCharge = TierCharge(
    tier: nat,              // Tier number (0-indexed)
    rangeStart: int,        // Start of the balance/amount range for this tier
    rangeEnd: int,          // End of the balance/amount range for this tier
    applicableAmount: int,  // Amount of balance/transaction in this tier
    feeRate: int,           // Fee rate in basis points (e.g., 250 = 2.5%)
    charge: int             // Actual fee charged for this tier (negative value)
  )

  /*
   * TransactionStatus tracks the lifecycle state of a transaction.
   * - Pending: Transaction initiated but not yet finalized
   * - Completed: Successfully processed and posted
   * - Failed: Transaction could not be completed
   * - RolledBack: Transaction was reversed/cancelled
   */
  datatype TransactionStatus =
    | Pending
    | Completed
    | Failed
    | RolledBack

  /*
   * Option type for representing optional values.
   * Used for parent transaction IDs (only fees have parents).
   */
  datatype Option<T> = Some(value: T) | None

  // ============================================================================
  // Transaction Record
  // ============================================================================

  /*
   * Transaction represents a complete banking transaction with all metadata.
   *
   * Amount Convention:
   * - Positive values: Credits to the account (deposits, transfers in, interest)
   * - Negative values: Debits from the account (withdrawals, transfers out, fees)
   *
   * Parent-Child Relationships:
   * - A fee transaction has a parentTxId pointing to the transaction that caused it
   * - The parent transaction includes the fee's ID in its childTxIds sequence
   * - This bidirectional link enables verification of fee integrity
   */
  datatype Transaction = Transaction(
    id: string,                      // Unique transaction identifier
    accountId: nat,                  // Account this transaction belongs to
    txType: TransactionType,         // Type of transaction
    amount: int,                     // Signed amount (negative for debits/fees, positive for credits)
    description: string,             // Human-readable description
    timestamp: nat,                  // Unix timestamp or sequence number
    balanceBefore: int,              // Account balance before transaction
    balanceAfter: int,               // Account balance after transaction
    status: TransactionStatus,       // Current status of the transaction
    parentTxId: Option<string>,      // Links fee to triggering transaction
    childTxIds: seq<string>          // Links transaction to resulting fees
  )

  // ============================================================================
  // Helper Functions
  // ============================================================================

  /*
   * TotalFees computes the cumulative fees from a transaction history.
   *
   * Since fees are stored as negative amounts, we negate them when summing
   * to get a positive total fee value.
   *
   * Recursive definition enables formal verification of fee properties.
   */
  function TotalFees(history: seq<Transaction>): int
  {
    if |history| == 0 then 0
    else (if history[0].txType.Fee? then -history[0].amount else 0)
         + TotalFees(history[1..])
  }

  // ============================================================================
  // Ghost Predicates for Verification
  // ============================================================================

  /*
   * FeeMonotonicity verifies that total fees never decrease over time.
   *
   * This is a fundamental invariant: once a fee is charged, it remains
   * in the history. Total fees can only increase or stay the same.
   *
   * This predicate enables verification that the system never "loses"
   * fee transactions or incorrectly reduces fee totals.
   */
  ghost predicate FeeMonotonicity(history: seq<Transaction>)
  {
    forall i, j :: 0 <= i < j < |history| ==>
      TotalFees(history[..i]) <= TotalFees(history[..j])
  }

  /*
   * FeeLinksValid verifies the integrity of parent-child relationships
   * between fees and their triggering transactions.
   *
   * For every fee transaction:
   * 1. It must have a parent transaction ID (Some, not None)
   * 2. The parent transaction must exist in the history
   * 3. The parent must reference this fee in its childTxIds
   *
   * This bidirectional link prevents orphaned fees and ensures
   * complete audit trails for fee calculations.
   */
  ghost predicate FeeLinksValid(history: seq<Transaction>)
  {
    forall i :: 0 <= i < |history| && history[i].txType.Fee? ==>
      // Fee must have parent
      history[i].parentTxId.Some? &&
      // Parent must exist in history
      exists j :: 0 <= j < |history| &&
                  history[j].id == history[i].parentTxId.value &&
                  // Parent must reference this fee as child
                  history[i].id in history[j].childTxIds
  }

  // ============================================================================
  // Additional Helper Predicates
  // ============================================================================

  /*
   * BalanceConsistency verifies that balance transitions are correct.
   * Each transaction's balanceAfter must equal balanceBefore + amount.
   */
  ghost predicate BalanceConsistency(tx: Transaction)
  {
    tx.balanceAfter == tx.balanceBefore + tx.amount
  }

  /*
   * TransactionHistoryValid verifies multiple invariants on transaction history:
   * 1. Fee monotonicity holds
   * 2. Fee parent-child links are valid
   * 3. All individual transactions have consistent balances
   * 4. Sequential transactions have matching balance boundaries
   */
  ghost predicate TransactionHistoryValid(history: seq<Transaction>)
  {
    FeeMonotonicity(history) &&
    FeeLinksValid(history) &&
    (forall i :: 0 <= i < |history| ==> BalanceConsistency(history[i])) &&
    (forall i :: 0 <= i < |history| - 1 ==>
      history[i].balanceAfter == history[i + 1].balanceBefore)
  }

  /*
   * FeeAmountMatchesDetails verifies that fee transaction amounts match
   * the baseAmount in their FeeDetails structure.
   */
  ghost predicate FeeAmountMatchesDetails(tx: Transaction)
    requires tx.txType.Fee?
  {
    tx.amount == tx.txType.details.baseAmount
  }

  /*
   * TierBreakdownValid verifies that tier charges sum to the base amount.
   * This ensures fee calculations are transparent and verifiable.
   */
  ghost predicate TierBreakdownValid(details: FeeDetails)
  {
    details.baseAmount == SumTierCharges(details.tierBreakdown)
  }

  /*
   * SumTierCharges computes the total of all tier charges.
   * Used to verify that tier breakdowns sum correctly.
   */
  function SumTierCharges(tiers: seq<TierCharge>): int
  {
    if |tiers| == 0 then 0
    else tiers[0].charge + SumTierCharges(tiers[1..])
  }

}
