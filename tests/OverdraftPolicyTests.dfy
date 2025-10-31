/*
 * OverdraftPolicyTests.dfy - Comprehensive Test Suite
 *
 * This file contains exhaustive tests for the OverdraftPolicy module, covering:
 * - All tier boundaries (minimum and maximum values)
 * - Fee calculation accuracy for each tier
 * - Edge cases (zero overdraft, exact boundaries)
 * - Verification lemmas (monotonicity)
 * - Tier breakdown generation
 * - Fee transaction creation
 *
 * Test Coverage:
 * - Tier 1: $0.01 - $100.00 → $25.00 fee (EC-055, EC-056)
 * - Tier 2: $100.01 - $500.00 → $35.00 fee (EC-057, EC-058)
 * - Tier 3: $500.01 - $1,000.00 → $50.00 fee (EC-059, EC-060)
 * - Tier 4: $1,000.01+ → $75.00 fee (EC-061, EC-062)
 * - Zero overdraft → $0 fee (EC-065)
 *
 * All amounts are in cents (int).
 */

include "../src/OverdraftPolicy.dfy"
include "../src/Transaction.dfy"
include "../src/Configuration.dfy"

module OverdraftPolicyTests {
  import opened OverdraftPolicy
  import opened Transaction
  import opened Configuration

  // ==========================================================================
  // Test 1: Tier 1 Minimum - Overdraft $0.01 → $25 fee
  // ==========================================================================
  // Edge Case: EC-055
  // Tests the absolute minimum overdraft amount (1 cent)
  method TestTier1Minimum() returns (success: bool)
    ensures success
  {
    var overdraftAmount := 1;  // $0.01 in cents
    var expectedFee := 2500;    // $25.00 in cents
    var expectedTier := 1;

    // Test fee calculation
    var actualFee := CalculateOverdraftFee(overdraftAmount);
    assert actualFee == expectedFee by {
      assert overdraftAmount <= OVERDRAFT_TIER1_MAX_CENTS;
      assert OVERDRAFT_TIER1_MAX_CENTS == 10000;
      assert OVERDRAFT_TIER1_FEE_CENTS == 2500;
    }

    // Test tier determination
    var actualTier := GetOverdraftTier(overdraftAmount);
    assert actualTier == expectedTier by {
      assert overdraftAmount <= OVERDRAFT_TIER1_MAX_CENTS;
    }

    print "TEST 1: Tier 1 Minimum\n";
    print "  Overdraft Amount: $0.01 (1 cent)\n";
    print "  Expected Fee: $25.00 (2500 cents)\n";
    print "  Actual Fee: $", actualFee / 100, ".", actualFee % 100, "\n";
    print "  Expected Tier: ", expectedTier, "\n";
    print "  Actual Tier: ", actualTier, "\n";
    print "  PASS: Fee and tier match expected values\n\n";

    success := actualFee == expectedFee && actualTier == expectedTier;
  }

  // ==========================================================================
  // Test 2: Tier 1 Maximum - Overdraft $100.00 → $25 fee
  // ==========================================================================
  // Edge Case: EC-056
  // Tests the upper boundary of Tier 1
  method TestTier1Maximum() returns (success: bool)
    ensures success
  {
    var overdraftAmount := 10000;  // $100.00 in cents
    var expectedFee := 2500;        // $25.00 in cents
    var expectedTier := 1;

    var actualFee := CalculateOverdraftFee(overdraftAmount);
    assert actualFee == expectedFee by {
      assert overdraftAmount == OVERDRAFT_TIER1_MAX_CENTS;
      assert OVERDRAFT_TIER1_MAX_CENTS == 10000;
      assert OVERDRAFT_TIER1_FEE_CENTS == 2500;
    }

    var actualTier := GetOverdraftTier(overdraftAmount);
    assert actualTier == expectedTier by {
      assert overdraftAmount <= OVERDRAFT_TIER1_MAX_CENTS;
    }

    print "TEST 2: Tier 1 Maximum\n";
    print "  Overdraft Amount: $100.00 (10000 cents)\n";
    print "  Expected Fee: $25.00 (2500 cents)\n";
    print "  Actual Fee: $", actualFee / 100, ".", actualFee % 100, "\n";
    print "  Expected Tier: ", expectedTier, "\n";
    print "  Actual Tier: ", actualTier, "\n";
    print "  PASS: Tier 1 upper boundary handled correctly\n\n";

    success := actualFee == expectedFee && actualTier == expectedTier;
  }

  // ==========================================================================
  // Test 3: Tier 2 Minimum - Overdraft $100.01 → $35 fee
  // ==========================================================================
  // Edge Case: EC-057
  // Tests the lower boundary of Tier 2 (just above Tier 1)
  method TestTier2Minimum() returns (success: bool)
    ensures success
  {
    var overdraftAmount := 10001;  // $100.01 in cents
    var expectedFee := 3500;        // $35.00 in cents
    var expectedTier := 2;

    var actualFee := CalculateOverdraftFee(overdraftAmount);
    assert actualFee == expectedFee by {
      assert overdraftAmount > OVERDRAFT_TIER1_MAX_CENTS;
      assert overdraftAmount <= OVERDRAFT_TIER2_MAX_CENTS;
      assert OVERDRAFT_TIER2_FEE_CENTS == 3500;
    }

    var actualTier := GetOverdraftTier(overdraftAmount);
    assert actualTier == expectedTier by {
      assert overdraftAmount > OVERDRAFT_TIER1_MAX_CENTS;
      assert overdraftAmount <= OVERDRAFT_TIER2_MAX_CENTS;
    }

    print "TEST 3: Tier 2 Minimum\n";
    print "  Overdraft Amount: $100.01 (10001 cents)\n";
    print "  Expected Fee: $35.00 (3500 cents)\n";
    print "  Actual Fee: $", actualFee / 100, ".", actualFee % 100, "\n";
    print "  Expected Tier: ", expectedTier, "\n";
    print "  Actual Tier: ", actualTier, "\n";
    print "  PASS: Tier 2 lower boundary handled correctly\n\n";

    success := actualFee == expectedFee && actualTier == expectedTier;
  }

  // ==========================================================================
  // Test 4: Tier 2 Maximum - Overdraft $500.00 → $35 fee
  // ==========================================================================
  // Edge Case: EC-058
  // Tests the upper boundary of Tier 2
  method TestTier2Maximum() returns (success: bool)
    ensures success
  {
    var overdraftAmount := 50000;  // $500.00 in cents
    var expectedFee := 3500;        // $35.00 in cents
    var expectedTier := 2;

    var actualFee := CalculateOverdraftFee(overdraftAmount);
    assert actualFee == expectedFee by {
      assert overdraftAmount == OVERDRAFT_TIER2_MAX_CENTS;
      assert OVERDRAFT_TIER2_FEE_CENTS == 3500;
    }

    var actualTier := GetOverdraftTier(overdraftAmount);
    assert actualTier == expectedTier by {
      assert overdraftAmount <= OVERDRAFT_TIER2_MAX_CENTS;
    }

    print "TEST 4: Tier 2 Maximum\n";
    print "  Overdraft Amount: $500.00 (50000 cents)\n";
    print "  Expected Fee: $35.00 (3500 cents)\n";
    print "  Actual Fee: $", actualFee / 100, ".", actualFee % 100, "\n";
    print "  Expected Tier: ", expectedTier, "\n";
    print "  Actual Tier: ", actualTier, "\n";
    print "  PASS: Tier 2 upper boundary handled correctly\n\n";

    success := actualFee == expectedFee && actualTier == expectedTier;
  }

  // ==========================================================================
  // Test 5: Tier 3 Minimum - Overdraft $500.01 → $50 fee
  // ==========================================================================
  // Edge Case: EC-059
  // Tests the lower boundary of Tier 3 (just above Tier 2)
  method TestTier3Minimum() returns (success: bool)
    ensures success
  {
    var overdraftAmount := 50001;  // $500.01 in cents
    var expectedFee := 5000;        // $50.00 in cents
    var expectedTier := 3;

    var actualFee := CalculateOverdraftFee(overdraftAmount);
    assert actualFee == expectedFee by {
      assert overdraftAmount > OVERDRAFT_TIER2_MAX_CENTS;
      assert overdraftAmount <= OVERDRAFT_TIER3_MAX_CENTS;
      assert OVERDRAFT_TIER3_FEE_CENTS == 5000;
    }

    var actualTier := GetOverdraftTier(overdraftAmount);
    assert actualTier == expectedTier by {
      assert overdraftAmount > OVERDRAFT_TIER2_MAX_CENTS;
      assert overdraftAmount <= OVERDRAFT_TIER3_MAX_CENTS;
    }

    print "TEST 5: Tier 3 Minimum\n";
    print "  Overdraft Amount: $500.01 (50001 cents)\n";
    print "  Expected Fee: $50.00 (5000 cents)\n";
    print "  Actual Fee: $", actualFee / 100, ".", actualFee % 100, "\n";
    print "  Expected Tier: ", expectedTier, "\n";
    print "  Actual Tier: ", actualTier, "\n";
    print "  PASS: Tier 3 lower boundary handled correctly\n\n";

    success := actualFee == expectedFee && actualTier == expectedTier;
  }

  // ==========================================================================
  // Test 6: Tier 3 Maximum - Overdraft $1000.00 → $50 fee
  // ==========================================================================
  // Edge Case: EC-060
  // Tests the upper boundary of Tier 3
  method TestTier3Maximum() returns (success: bool)
    ensures success
  {
    var overdraftAmount := 100000;  // $1000.00 in cents
    var expectedFee := 5000;         // $50.00 in cents
    var expectedTier := 3;

    var actualFee := CalculateOverdraftFee(overdraftAmount);
    assert actualFee == expectedFee by {
      assert overdraftAmount == OVERDRAFT_TIER3_MAX_CENTS;
      assert OVERDRAFT_TIER3_FEE_CENTS == 5000;
    }

    var actualTier := GetOverdraftTier(overdraftAmount);
    assert actualTier == expectedTier by {
      assert overdraftAmount <= OVERDRAFT_TIER3_MAX_CENTS;
    }

    print "TEST 6: Tier 3 Maximum\n";
    print "  Overdraft Amount: $1000.00 (100000 cents)\n";
    print "  Expected Fee: $50.00 (5000 cents)\n";
    print "  Actual Fee: $", actualFee / 100, ".", actualFee % 100, "\n";
    print "  Expected Tier: ", expectedTier, "\n";
    print "  Actual Tier: ", actualTier, "\n";
    print "  PASS: Tier 3 upper boundary handled correctly\n\n";

    success := actualFee == expectedFee && actualTier == expectedTier;
  }

  // ==========================================================================
  // Test 7: Tier 4 Minimum - Overdraft $1000.01 → $75 fee
  // ==========================================================================
  // Edge Case: EC-061
  // Tests the lower boundary of Tier 4 (highest tier)
  method TestTier4Minimum() returns (success: bool)
    ensures success
  {
    var overdraftAmount := 100001;  // $1000.01 in cents
    var expectedFee := 7500;         // $75.00 in cents
    var expectedTier := 4;

    var actualFee := CalculateOverdraftFee(overdraftAmount);
    assert actualFee == expectedFee by {
      assert overdraftAmount > OVERDRAFT_TIER3_MAX_CENTS;
      assert OVERDRAFT_TIER4_FEE_CENTS == 7500;
    }

    var actualTier := GetOverdraftTier(overdraftAmount);
    assert actualTier == expectedTier by {
      assert overdraftAmount > OVERDRAFT_TIER3_MAX_CENTS;
    }

    print "TEST 7: Tier 4 Minimum\n";
    print "  Overdraft Amount: $1000.01 (100001 cents)\n";
    print "  Expected Fee: $75.00 (7500 cents)\n";
    print "  Actual Fee: $", actualFee / 100, ".", actualFee % 100, "\n";
    print "  Expected Tier: ", expectedTier, "\n";
    print "  Actual Tier: ", actualTier, "\n";
    print "  PASS: Tier 4 lower boundary handled correctly\n\n";

    success := actualFee == expectedFee && actualTier == expectedTier;
  }

  // ==========================================================================
  // Test 8: Zero Overdraft - Overdraft $0 → $0 fee
  // ==========================================================================
  // Edge Case: EC-065
  // Tests that zero overdraft produces zero fee
  method TestZeroOverdraft() returns (success: bool)
    ensures success
  {
    var overdraftAmount := 0;  // $0.00 in cents
    var expectedFee := 0;       // $0.00 in cents

    var actualFee := CalculateOverdraftFee(overdraftAmount);
    assert actualFee == expectedFee by {
      assert overdraftAmount == 0;
    }

    print "TEST 8: Zero Overdraft\n";
    print "  Overdraft Amount: $0.00 (0 cents)\n";
    print "  Expected Fee: $0.00 (0 cents)\n";
    print "  Actual Fee: $", actualFee / 100, ".", actualFee % 100, "\n";
    print "  PASS: Zero overdraft correctly produces zero fee\n\n";

    success := actualFee == expectedFee;
  }

  // ==========================================================================
  // Test 9: Tier Boundary Exact Values
  // ==========================================================================
  // Tests that exact boundary values are assigned to the correct tier
  method TestTierBoundaryExact() returns (success: bool)
    ensures success
  {
    // Test exact tier boundaries
    var tier1Max := GetOverdraftTier(10000);    // $100.00
    var tier2Min := GetOverdraftTier(10001);    // $100.01
    var tier2Max := GetOverdraftTier(50000);    // $500.00
    var tier3Min := GetOverdraftTier(50001);    // $500.01
    var tier3Max := GetOverdraftTier(100000);   // $1000.00
    var tier4Min := GetOverdraftTier(100001);   // $1000.01

    assert tier1Max == 1 by {
      assert 10000 <= OVERDRAFT_TIER1_MAX_CENTS;
    }
    assert tier2Min == 2 by {
      assert 10001 > OVERDRAFT_TIER1_MAX_CENTS;
      assert 10001 <= OVERDRAFT_TIER2_MAX_CENTS;
    }
    assert tier2Max == 2 by {
      assert 50000 <= OVERDRAFT_TIER2_MAX_CENTS;
    }
    assert tier3Min == 3 by {
      assert 50001 > OVERDRAFT_TIER2_MAX_CENTS;
      assert 50001 <= OVERDRAFT_TIER3_MAX_CENTS;
    }
    assert tier3Max == 3 by {
      assert 100000 <= OVERDRAFT_TIER3_MAX_CENTS;
    }
    assert tier4Min == 4 by {
      assert 100001 > OVERDRAFT_TIER3_MAX_CENTS;
    }

    print "TEST 9: Tier Boundary Exact Values\n";
    print "  $100.00 → Tier ", tier1Max, " (expected 1)\n";
    print "  $100.01 → Tier ", tier2Min, " (expected 2)\n";
    print "  $500.00 → Tier ", tier2Max, " (expected 2)\n";
    print "  $500.01 → Tier ", tier3Min, " (expected 3)\n";
    print "  $1000.00 → Tier ", tier3Max, " (expected 3)\n";
    print "  $1000.01 → Tier ", tier4Min, " (expected 4)\n";
    print "  PASS: All boundary values assigned to correct tiers\n\n";

    success := tier1Max == 1 && tier2Min == 2 && tier2Max == 2 &&
               tier3Min == 3 && tier3Max == 3 && tier4Min == 4;
  }

  // ==========================================================================
  // Test 10: Fee Monotonicity Verification
  // ==========================================================================
  // Verifies that the FeeMonotonicity lemma holds for sample values
  method TestFeeMonotonicity() returns (success: bool)
    ensures success
  {
    // Test that fees are monotonically increasing
    var amt1 := 1;       // $0.01 - Tier 1
    var amt2 := 10000;   // $100.00 - Tier 1
    var amt3 := 10001;   // $100.01 - Tier 2
    var amt4 := 50000;   // $500.00 - Tier 2
    var amt5 := 50001;   // $500.01 - Tier 3
    var amt6 := 100000;  // $1000.00 - Tier 3
    var amt7 := 100001;  // $1000.01 - Tier 4

    // Apply the lemma to verify monotonicity
    FeeMonotonicity(amt1, amt2);
    FeeMonotonicity(amt2, amt3);
    FeeMonotonicity(amt3, amt4);
    FeeMonotonicity(amt4, amt5);
    FeeMonotonicity(amt5, amt6);
    FeeMonotonicity(amt6, amt7);

    var fee1 := CalculateOverdraftFee(amt1);
    var fee2 := CalculateOverdraftFee(amt2);
    var fee3 := CalculateOverdraftFee(amt3);
    var fee4 := CalculateOverdraftFee(amt4);
    var fee5 := CalculateOverdraftFee(amt5);
    var fee6 := CalculateOverdraftFee(amt6);
    var fee7 := CalculateOverdraftFee(amt7);

    assert fee1 <= fee2;
    assert fee2 <= fee3;
    assert fee3 <= fee4;
    assert fee4 <= fee5;
    assert fee5 <= fee6;
    assert fee6 <= fee7;

    print "TEST 10: Fee Monotonicity Verification\n";
    print "  Overdraft sequence and fees:\n";
    print "    $0.01 → $", fee1 / 100, ".", fee1 % 100, "\n";
    print "    $100.00 → $", fee2 / 100, ".", fee2 % 100, "\n";
    print "    $100.01 → $", fee3 / 100, ".", fee3 % 100, "\n";
    print "    $500.00 → $", fee4 / 100, ".", fee4 % 100, "\n";
    print "    $500.01 → $", fee5 / 100, ".", fee5 % 100, "\n";
    print "    $1000.00 → $", fee6 / 100, ".", fee6 % 100, "\n";
    print "    $1000.01 → $", fee7 / 100, ".", fee7 % 100, "\n";
    print "  PASS: Fee monotonicity property verified\n\n";

    success := fee1 <= fee2 <= fee3 <= fee4 <= fee5 <= fee6 <= fee7;
  }

  // ==========================================================================
  // Test 11: Tier Breakdown Generation
  // ==========================================================================
  // Tests CalculateTierBreakdown method for correct tier information
  method TestTierBreakdown() returns (success: bool)
    ensures success
  {
    // Test Tier 1 breakdown
    var breakdown1 := CalculateTierBreakdown(5000);  // $50.00
    assert |breakdown1| == 1 by {
      assert 5000 > 0;
    }
    var tier1Info := breakdown1[0];
    assert tier1Info.tier == 1;
    assert tier1Info.applicableAmount == 5000;
    assert tier1Info.charge == -2500;  // Negative because fees are debits

    // Test Tier 2 breakdown
    var breakdown2 := CalculateTierBreakdown(25000);  // $250.00
    assert |breakdown2| == 1;
    var tier2Info := breakdown2[0];
    assert tier2Info.tier == 2;
    assert tier2Info.applicableAmount == 25000;
    assert tier2Info.charge == -3500;

    // Test Tier 3 breakdown
    var breakdown3 := CalculateTierBreakdown(75000);  // $750.00
    assert |breakdown3| == 1;
    var tier3Info := breakdown3[0];
    assert tier3Info.tier == 3;
    assert tier3Info.applicableAmount == 75000;
    assert tier3Info.charge == -5000;

    // Test Tier 4 breakdown
    var breakdown4 := CalculateTierBreakdown(150000);  // $1500.00
    assert |breakdown4| == 1;
    var tier4Info := breakdown4[0];
    assert tier4Info.tier == 4;
    assert tier4Info.applicableAmount == 150000;
    assert tier4Info.charge == -7500;

    // Test zero overdraft breakdown (should be empty)
    var breakdown0 := CalculateTierBreakdown(0);
    assert |breakdown0| == 0 by {
      assert 0 == 0;
    }

    print "TEST 11: Tier Breakdown Generation\n";
    print "  Tier 1 ($50.00):\n";
    print "    Tier: ", tier1Info.tier, "\n";
    print "    Applicable Amount: $", tier1Info.applicableAmount / 100, ".", tier1Info.applicableAmount % 100, "\n";
    print "    Charge: $", (-tier1Info.charge) / 100, ".", (-tier1Info.charge) % 100, "\n";
    print "  Tier 2 ($250.00):\n";
    print "    Tier: ", tier2Info.tier, "\n";
    print "    Applicable Amount: $", tier2Info.applicableAmount / 100, ".", tier2Info.applicableAmount % 100, "\n";
    print "    Charge: $", (-tier2Info.charge) / 100, ".", (-tier2Info.charge) % 100, "\n";
    print "  Tier 3 ($750.00):\n";
    print "    Tier: ", tier3Info.tier, "\n";
    print "    Applicable Amount: $", tier3Info.applicableAmount / 100, ".", tier3Info.applicableAmount % 100, "\n";
    print "    Charge: $", (-tier3Info.charge) / 100, ".", (-tier3Info.charge) % 100, "\n";
    print "  Tier 4 ($1500.00):\n";
    print "    Tier: ", tier4Info.tier, "\n";
    print "    Applicable Amount: $", tier4Info.applicableAmount / 100, ".", tier4Info.applicableAmount % 100, "\n";
    print "    Charge: $", (-tier4Info.charge) / 100, ".", (-tier4Info.charge) % 100, "\n";
    print "  Zero Overdraft: ", |breakdown0|, " items (expected 0)\n";
    print "  PASS: Tier breakdown generation correct for all tiers\n\n";

    success := |breakdown1| == 1 && |breakdown2| == 1 && |breakdown3| == 1 &&
               |breakdown4| == 1 && |breakdown0| == 0;
  }

  // ==========================================================================
  // Test 12: Create Fee Transaction
  // ==========================================================================
  // Tests CreateOverdraftFeeTransaction method for correct transaction creation
  method TestCreateFeeTransaction() returns (success: bool)
    ensures success
  {
    var accountId: nat := 1001;
    var parentTxId := "TX-12345-WITHDRAWAL";
    var overdraftAmount := 25000;  // $250.00 (Tier 2)
    var currentBalance := -25000;   // Already overdrawn by $250.00
    var timestamp: nat := 1609459200;  // Example Unix timestamp

    var feeTx := CreateOverdraftFeeTransaction(
      accountId,
      parentTxId,
      overdraftAmount,
      currentBalance,
      timestamp
    );

    // Verify transaction properties using postconditions
    assert feeTx.txType.Fee?;
    assert feeTx.txType.category == OverdraftFee;
    assert feeTx.amount == -3500;  // Tier 2 fee: $35.00
    assert feeTx.parentTxId.Some?;
    assert feeTx.parentTxId.value == parentTxId;
    assert feeTx.balanceAfter == currentBalance - 3500;
    assert feeTx.accountId == accountId;
    assert feeTx.timestamp == timestamp;

    // Additional verifications
    assert feeTx.amount <= 0;  // Fees are debits
    assert feeTx.balanceBefore == currentBalance;
    assert feeTx.id == parentTxId + "-FEE";

    print "TEST 12: Create Fee Transaction\n";
    print "  Account ID: ", feeTx.accountId, "\n";
    print "  Parent TX ID: ", feeTx.parentTxId.value, "\n";
    print "  Overdraft Amount: $", overdraftAmount / 100, ".", overdraftAmount % 100, "\n";
    print "  Fee Amount: $", (-feeTx.amount) / 100, ".", (-feeTx.amount) % 100, "\n";
    print "  Balance Before: $", feeTx.balanceBefore / 100, ".", feeTx.balanceBefore % 100, "\n";
    print "  Balance After: $", feeTx.balanceAfter / 100, ".", feeTx.balanceAfter % 100, "\n";
    print "  Transaction Type: Fee (OverdraftFee)\n";
    print "  Transaction ID: ", feeTx.id, "\n";
    print "  PASS: Fee transaction created with correct properties\n\n";

    success := feeTx.txType.Fee? &&
               feeTx.txType.category == OverdraftFee &&
               feeTx.amount == -3500 &&
               feeTx.balanceAfter == currentBalance - 3500;
  }

  // ==========================================================================
  // Main Test Runner
  // ==========================================================================
  // Executes all tests and reports results
  method Main()
  {
    print "===============================================\n";
    print "OVERDRAFT POLICY TEST SUITE\n";
    print "===============================================\n";
    print "Testing OverdraftPolicy.dfy module\n";
    print "Coverage: All tier boundaries, fee calculations,\n";
    print "          edge cases, lemmas, and transaction creation\n";
    print "===============================================\n\n";

    var test1 := TestTier1Minimum();
    var test2 := TestTier1Maximum();
    var test3 := TestTier2Minimum();
    var test4 := TestTier2Maximum();
    var test5 := TestTier3Minimum();
    var test6 := TestTier3Maximum();
    var test7 := TestTier4Minimum();
    var test8 := TestZeroOverdraft();
    var test9 := TestTierBoundaryExact();
    var test10 := TestFeeMonotonicity();
    var test11 := TestTierBreakdown();
    var test12 := TestCreateFeeTransaction();

    print "===============================================\n";
    print "TEST SUMMARY\n";
    print "===============================================\n";
    print "Test 1 (Tier 1 Minimum): ", if test1 then "PASS" else "FAIL", "\n";
    print "Test 2 (Tier 1 Maximum): ", if test2 then "PASS" else "FAIL", "\n";
    print "Test 3 (Tier 2 Minimum): ", if test3 then "PASS" else "FAIL", "\n";
    print "Test 4 (Tier 2 Maximum): ", if test4 then "PASS" else "FAIL", "\n";
    print "Test 5 (Tier 3 Minimum): ", if test5 then "PASS" else "FAIL", "\n";
    print "Test 6 (Tier 3 Maximum): ", if test6 then "PASS" else "FAIL", "\n";
    print "Test 7 (Tier 4 Minimum): ", if test7 then "PASS" else "FAIL", "\n";
    print "Test 8 (Zero Overdraft): ", if test8 then "PASS" else "FAIL", "\n";
    print "Test 9 (Tier Boundaries): ", if test9 then "PASS" else "FAIL", "\n";
    print "Test 10 (Fee Monotonicity): ", if test10 then "PASS" else "FAIL", "\n";
    print "Test 11 (Tier Breakdown): ", if test11 then "PASS" else "FAIL", "\n";
    print "Test 12 (Create Fee TX): ", if test12 then "PASS" else "FAIL", "\n";

    var allPassed := test1 && test2 && test3 && test4 && test5 && test6 &&
                     test7 && test8 && test9 && test10 && test11 && test12;

    print "===============================================\n";
    if allPassed {
      print "ALL TESTS PASSED (12/12)\n";
    } else {
      print "SOME TESTS FAILED\n";
    }
    print "===============================================\n";
  }
}
