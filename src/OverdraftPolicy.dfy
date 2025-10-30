/*
 * OverdraftPolicy Module for Verified Bank CLI
 *
 * This module implements the tiered overdraft fee calculation system with
 * formal verification of fee correctness and monotonicity properties.
 *
 * Tier Structure:
 * - Tier 1: $0.01 - $100.00 → $25.00 fee
 * - Tier 2: $100.01 - $500.00 → $35.00 fee
 * - Tier 3: $500.01 - $1,000.00 → $50.00 fee
 * - Tier 4: $1,000.01+ → $75.00 fee
 *
 * All amounts are in cents (int).
 */

include "Transaction.dfy"
include "Configuration.dfy"

module OverdraftPolicy {
  import opened Transaction
  import opened Configuration

  // ============================================================================
  // Configuration Summary
  // ============================================================================
  //
  // This module uses centralized configuration from Configuration.dfy for all
  // overdraft fee tier boundaries and fee amounts. See Configuration.dfy for
  // the authoritative values and system-wide settings.

  // ============================================================================
  // Core Fee Calculation Functions
  // ============================================================================

  /*
   * GetOverdraftTier determines which tier an overdraft amount falls into.
   *
   * Returns:
   * - 1 for amounts $0.01 - $100.00
   * - 2 for amounts $100.01 - $500.00
   * - 3 for amounts $500.01 - $1,000.00
   * - 4 for amounts $1,000.01+
   */
  function GetOverdraftTier(overdraftAmount: int): nat
    requires overdraftAmount >= 0
    ensures 1 <= GetOverdraftTier(overdraftAmount) <= 4
  {
    if overdraftAmount <= OVERDRAFT_TIER1_MAX_CENTS then 1
    else if overdraftAmount <= OVERDRAFT_TIER2_MAX_CENTS then 2
    else if overdraftAmount <= OVERDRAFT_TIER3_MAX_CENTS then 3
    else 4
  }

  /*
   * CalculateOverdraftFee computes the fee for a given overdraft amount.
   *
   * The fee is based on the tier the overdraft amount falls into.
   * Zero overdraft results in zero fee.
   *
   * Returns: Fee amount in cents (positive value)
   */
  function CalculateOverdraftFee(overdraftAmount: int): int
    requires overdraftAmount >= 0
    ensures CalculateOverdraftFee(overdraftAmount) >= 0
    ensures overdraftAmount == 0 ==> CalculateOverdraftFee(overdraftAmount) == 0
  {
    if overdraftAmount == 0 then 0
    else if overdraftAmount <= OVERDRAFT_TIER1_MAX_CENTS then OVERDRAFT_TIER1_FEE_CENTS
    else if overdraftAmount <= OVERDRAFT_TIER2_MAX_CENTS then OVERDRAFT_TIER2_FEE_CENTS
    else if overdraftAmount <= OVERDRAFT_TIER3_MAX_CENTS then OVERDRAFT_TIER3_FEE_CENTS
    else OVERDRAFT_TIER4_FEE_CENTS
  }

  // ============================================================================
  // Verification Lemmas
  // ============================================================================

  /*
   * FeeMonotonicity proves that higher overdraft amounts never result in lower fees.
   *
   * This is a critical invariant: the fee structure is designed such that
   * as the overdraft amount increases, the fee either stays the same (within a tier)
   * or increases (when crossing into a higher tier).
   *
   * This property ensures fairness and prevents perverse incentives.
   */
  lemma FeeMonotonicity(amount1: int, amount2: int)
    requires amount1 >= 0
    requires amount2 >= 0
    requires amount1 <= amount2
    ensures CalculateOverdraftFee(amount1) <= CalculateOverdraftFee(amount2)
  {
    // Proof by case analysis on tier boundaries
    // The Dafny verifier can automatically prove this by examining all cases
    // where amounts cross tier boundaries
  }

  /*
   * TierDeterminism proves that the tier calculation is deterministic.
   * Same input always produces same output.
   */
  lemma TierDeterminism(amount: int)
    requires amount >= 0
    ensures GetOverdraftTier(amount) == GetOverdraftTier(amount)
  {
    // Trivial, but explicitly stated for completeness
  }

  /*
   * FeeBounds ensures all fees are within expected ranges.
   */
  lemma FeeBounds(overdraftAmount: int)
    requires overdraftAmount >= 0
    ensures var fee := CalculateOverdraftFee(overdraftAmount);
      0 <= fee <= OVERDRAFT_TIER4_FEE_CENTS
  {
    // Proof follows from the definition of CalculateOverdraftFee
  }

  // ============================================================================
  // Tier Breakdown Generation
  // ============================================================================

  /*
   * CalculateTierBreakdown generates detailed tier information for an overdraft.
   *
   * This provides transparency into fee calculation by showing:
   * - Which tier the overdraft falls into
   * - The tier's range boundaries
   * - The applicable amount
   * - The calculated fee
   *
   * Note: feeRate is set to 0 as we use fixed fees per tier rather than percentage rates.
   * The charge field contains the negative fee amount (as debits are negative).
   */
  method CalculateTierBreakdown(overdraftAmount: int)
    returns (breakdown: seq<TierCharge>)
    requires overdraftAmount >= 0
    ensures |breakdown| > 0 <==> overdraftAmount > 0
    ensures overdraftAmount == 0 ==> breakdown == []
    ensures overdraftAmount > 0 ==> |breakdown| == 1
  {
    if overdraftAmount == 0 {
      breakdown := [];
      return;
    }

    var tier := GetOverdraftTier(overdraftAmount);
    var fee := CalculateOverdraftFee(overdraftAmount);

    // Determine tier boundaries
    var rangeStart: int;
    var rangeEnd: int;

    if tier == 1 {
      rangeStart := 1;
      rangeEnd := OVERDRAFT_TIER1_MAX_CENTS;
    } else if tier == 2 {
      rangeStart := OVERDRAFT_TIER1_MAX_CENTS + 1;
      rangeEnd := OVERDRAFT_TIER2_MAX_CENTS;
    } else if tier == 3 {
      rangeStart := OVERDRAFT_TIER2_MAX_CENTS + 1;
      rangeEnd := OVERDRAFT_TIER3_MAX_CENTS;
    } else {  // tier == 4
      rangeStart := OVERDRAFT_TIER3_MAX_CENTS + 1;
      rangeEnd := overdraftAmount;  // No upper bound for tier 4
    }

    var charge := TierCharge(
      tier,
      rangeStart,
      rangeEnd,
      overdraftAmount,
      0,           // feeRate: 0 since we use fixed fees, not percentage
      -fee         // charge: negative because fees are debits
    );

    breakdown := [charge];
  }

  // ============================================================================
  // Fee Transaction Creation
  // ============================================================================

  /*
   * CreateOverdraftFeeTransaction creates a complete fee transaction record.
   *
   * This method:
   * 1. Calculates the overdraft fee based on the amount
   * 2. Generates a tier breakdown for transparency
   * 3. Constructs a FeeDetails record
   * 4. Creates a Transaction with all required fields
   *
   * The resulting transaction:
   * - Has a negative amount (fees are debits)
   * - Links to the parent transaction that caused the overdraft
   * - Includes detailed breakdown for verification
   * - Updates the account balance accordingly
   *
   * Note: String conversion functions like IntToString() would typically be
   * implemented via FFI (Foreign Function Interface) as Dafny doesn't have
   * built-in integer-to-string conversion. For verification purposes, we use
   * placeholder strings.
   */
  method CreateOverdraftFeeTransaction(
    accountId: nat,
    parentTxId: string,
    overdraftAmount: int,
    currentBalance: int,
    timestamp: nat
  ) returns (feeTx: Transaction)
    requires overdraftAmount >= 0
    ensures feeTx.txType.Fee?
    ensures feeTx.txType.category == OverdraftFee
    ensures feeTx.amount <= 0  // Fees are non-positive (debit)
    ensures feeTx.amount == -CalculateOverdraftFee(overdraftAmount)
    ensures feeTx.parentTxId.Some?
    ensures feeTx.parentTxId.value == parentTxId
    ensures feeTx.balanceAfter == currentBalance - CalculateOverdraftFee(overdraftAmount)
  {
    var fee := CalculateOverdraftFee(overdraftAmount);
    var breakdown := CalculateTierBreakdown(overdraftAmount);
    var tier := GetOverdraftTier(overdraftAmount);

    // Note: In a real implementation, IntToString would be provided via FFI
    // For now, we use placeholder descriptions based on Configuration constants
    var tierDescription: string;
    if tier == 1 {
      tierDescription := "Tier 1 ($0.01-$100.00): $25.00 fee";  // OVERDRAFT_TIER1_FEE_CENTS
    } else if tier == 2 {
      tierDescription := "Tier 2 ($100.01-$500.00): $35.00 fee";  // OVERDRAFT_TIER2_FEE_CENTS
    } else if tier == 3 {
      tierDescription := "Tier 3 ($500.01-$1,000.00): $50.00 fee";  // OVERDRAFT_TIER3_FEE_CENTS
    } else {
      tierDescription := "Tier 4 ($1,000.01+): $75.00 fee";  // OVERDRAFT_TIER4_FEE_CENTS
    }

    var feeDetails := FeeDetails(
      breakdown,
      -fee,  // baseAmount: negative for debit
      tierDescription
    );

    feeTx := Transaction(
      parentTxId + "-FEE",               // Unique ID derived from parent
      accountId,
      Fee(OverdraftFee, feeDetails),     // Transaction type with fee details
      -fee,                               // Amount: negative because it's a debit
      "Overdraft fee - " + tierDescription,
      timestamp,
      currentBalance,                     // Balance before fee
      currentBalance - fee,               // Balance after fee
      Completed,
      Some(parentTxId),                   // Link to parent transaction
      []                                  // No child transactions
    );
  }

  // ============================================================================
  // Validation Predicates
  // ============================================================================

  /*
   * ValidOverdraftFee verifies that a fee transaction is correctly constructed.
   *
   * Checks:
   * 1. Transaction type is Fee with OverdraftFee category
   * 2. Fee amount matches calculated fee for the overdraft amount
   * 3. Fee is non-positive (debit)
   * 4. Balance progression is correct
   * 5. Has parent transaction link
   */
  ghost predicate ValidOverdraftFee(tx: Transaction, overdraftAmount: int)
    requires overdraftAmount >= 0
  {
    tx.txType.Fee? &&
    tx.txType.category == OverdraftFee &&
    tx.amount == -CalculateOverdraftFee(overdraftAmount) &&
    tx.amount <= 0 &&
    tx.balanceAfter == tx.balanceBefore + tx.amount &&
    tx.parentTxId.Some?
  }

  // ============================================================================
  // Helper Methods for Testing and Integration
  // ============================================================================

  /*
   * GetFeeForAmount is a simple wrapper for external callers.
   * Returns the fee amount for a given overdraft.
   */
  method GetFeeForAmount(overdraftAmount: int) returns (fee: int)
    requires overdraftAmount >= 0
    ensures fee >= 0
    ensures fee == CalculateOverdraftFee(overdraftAmount)
  {
    fee := CalculateOverdraftFee(overdraftAmount);
  }

  /*
   * GetTierForAmount is a simple wrapper for external callers.
   * Returns the tier number for a given overdraft.
   */
  method GetTierForAmount(overdraftAmount: int) returns (tier: nat)
    requires overdraftAmount >= 0
    ensures 1 <= tier <= 4
    ensures tier == GetOverdraftTier(overdraftAmount)
  {
    tier := GetOverdraftTier(overdraftAmount);
  }
}
