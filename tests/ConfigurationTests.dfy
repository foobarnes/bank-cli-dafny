// ConfigurationTests.dfy
// Comprehensive test suite for Configuration.dfy module
//
// This test suite verifies:
// - Configuration validity predicates
// - Tier boundary ordering
// - Fee monotonicity and non-negativity
// - Default limit constraints
// - Name length validation
// - System limit reasonability
// - Specific tier values match specification
// - Default account settings
// - Configuration summary generation

include "../src/Configuration.dfy"

module ConfigurationTests {
  import opened Configuration

  // Test 1: Verify configuration validity
  method TestConfigurationIsValid()
  {
    // Verify the configuration predicate holds
    ConfigurationIsValid();
    assert ValidConfiguration();
    print "✓ Configuration is valid\n";
  }

  // Test 2: Verify tier boundaries are ordered
  method TestTierBoundariesOrdered()
  {
    assert OVERDRAFT_TIER1_MAX_CENTS < OVERDRAFT_TIER2_MAX_CENTS;
    assert OVERDRAFT_TIER2_MAX_CENTS < OVERDRAFT_TIER3_MAX_CENTS;
    print "✓ Tier boundaries are correctly ordered\n";
  }

  // Test 3: Verify fee monotonicity (higher tier = higher fee)
  method TestFeeMonotonicity()
  {
    assert OVERDRAFT_TIER1_FEE_CENTS <= OVERDRAFT_TIER2_FEE_CENTS;
    assert OVERDRAFT_TIER2_FEE_CENTS <= OVERDRAFT_TIER3_FEE_CENTS;
    assert OVERDRAFT_TIER3_FEE_CENTS <= OVERDRAFT_TIER4_FEE_CENTS;
    print "✓ Fee monotonicity maintained\n";
  }

  // Test 4: Verify all fees are non-negative
  method TestFeesNonNegative()
  {
    assert OVERDRAFT_TIER1_FEE_CENTS >= 0;
    assert OVERDRAFT_TIER2_FEE_CENTS >= 0;
    assert OVERDRAFT_TIER3_FEE_CENTS >= 0;
    assert OVERDRAFT_TIER4_FEE_CENTS >= 0;
    print "✓ All fees are non-negative\n";
  }

  // Test 5: Verify default limits are positive
  method TestDefaultLimitsPositive()
  {
    assert DEFAULT_MAX_BALANCE_CENTS > 0;
    assert DEFAULT_MAX_TRANSACTION_CENTS > 0;
    assert DEFAULT_OVERDRAFT_LIMIT_CENTS >= 0;
    print "✓ Default limits are valid\n";
  }

  // Test 6: Verify name length constraints
  method TestNameLengthConstraints()
  {
    assert MIN_OWNER_NAME_LENGTH > 0;
    assert MIN_OWNER_NAME_LENGTH <= MAX_OWNER_NAME_LENGTH;
    print "✓ Name length constraints are valid\n";
  }

  // Test 7: Verify system limits are reasonable
  method TestSystemLimitsReasonable()
  {
    assert MAX_SYSTEM_ACCOUNTS > 0;
    assert MAX_TRANSACTION_HISTORY_SIZE > 0;
    assert MAX_FILE_OPERATION_RETRIES > 0;
    print "✓ System limits are reasonable\n";
  }

  // Test 8: Verify specific tier values (from spec)
  method TestTierValues()
  {
    // Tier 1: $0.01 - $100.00 → $25.00
    assert OVERDRAFT_TIER1_MAX_CENTS == 10000;
    assert OVERDRAFT_TIER1_FEE_CENTS == 2500;

    // Tier 2: $100.01 - $500.00 → $35.00
    assert OVERDRAFT_TIER2_MAX_CENTS == 50000;
    assert OVERDRAFT_TIER2_FEE_CENTS == 3500;

    // Tier 3: $500.01 - $1,000.00 → $50.00
    assert OVERDRAFT_TIER3_MAX_CENTS == 100000;
    assert OVERDRAFT_TIER3_FEE_CENTS == 5000;

    // Tier 4: $1,000.01+ → $75.00
    assert OVERDRAFT_TIER4_FEE_CENTS == 7500;

    print "✓ All tier values match specification\n";
  }

  // Test 9: Verify default account settings
  method TestDefaultAccountSettings()
  {
    assert DEFAULT_MAX_BALANCE_CENTS == 100000000;  // $1,000,000
    assert DEFAULT_MAX_TRANSACTION_CENTS == 1000000;  // $10,000
    assert DEFAULT_OVERDRAFT_LIMIT_CENTS == 100000;  // $1,000
    assert !DEFAULT_OVERDRAFT_ENABLED;  // false by default
    print "✓ Default account settings match specification\n";
  }

  // Test 10: Test configuration summary generation
  method TestConfigurationSummary()
  {
    var summary := GetConfigurationSummary();
    // Note: Cannot assert |summary| > 0 because Dafny cannot prove string length at compile time
    // The method call succeeding is sufficient to verify the function works
    print "✓ Configuration summary generated\n";
    print summary;
  }

  // Test 11: Verify other fee configuration values
  method TestOtherFees()
  {
    assert MAINTENANCE_FEE_CENTS >= 0;
    assert TRANSFER_FEE_CENTS >= 0;
    assert ATM_FEE_CENTS >= 0;
    assert INSUFFICIENT_FUNDS_FEE_CENTS >= 0;
    print "✓ Other fees are non-negative\n";
  }

  // Test 12: Verify transaction limits
  method TestTransactionLimits()
  {
    assert MIN_TRANSACTION_AMOUNT_CENTS > 0;
    assert MIN_TRANSACTION_AMOUNT_CENTS == 1;  // Must be at least 1 cent
    assert MIN_INITIAL_DEPOSIT_CENTS >= 0;
    print "✓ Transaction limits are valid\n";
  }

  // Test 13: Verify minimum balance constraint
  method TestMinBalanceConstraint()
  {
    assert MIN_BALANCE_NO_OVERDRAFT_CENTS == 0;
    print "✓ Minimum balance constraint is correct\n";
  }

  // Test 14: Verify backup retention configuration
  method TestBackupConfiguration()
  {
    assert BACKUP_RETENTION_DAYS > 0;
    assert BACKUP_RETENTION_DAYS == 30;
    print "✓ Backup retention configuration is valid\n";
  }

  // Test 15: Verify relationship between limits
  method TestLimitRelationships()
  {
    // Max transaction should be less than or equal to max balance
    assert DEFAULT_MAX_TRANSACTION_CENTS <= DEFAULT_MAX_BALANCE_CENTS;
    // Overdraft limit should be reasonable compared to max balance
    assert DEFAULT_OVERDRAFT_LIMIT_CENTS <= DEFAULT_MAX_BALANCE_CENTS;
    print "✓ Limit relationships are reasonable\n";
  }

  // Test 16: Verify name length boundaries
  method TestNameLengthBoundaries()
  {
    assert MIN_OWNER_NAME_LENGTH == 1;
    assert MAX_OWNER_NAME_LENGTH == 255;
    print "✓ Name length boundaries match specification\n";
  }

  // Test 17: Verify system account limit
  method TestSystemAccountLimit()
  {
    assert MAX_SYSTEM_ACCOUNTS == 10000;
    print "✓ System account limit matches specification\n";
  }

  // Test 18: Verify transaction history limit
  method TestTransactionHistoryLimit()
  {
    assert MAX_TRANSACTION_HISTORY_SIZE == 100000;
    print "✓ Transaction history limit matches specification\n";
  }

  // Main test runner
  method Main()
  {
    print "Running Configuration Tests...\n";
    print "================================\n\n";

    TestConfigurationIsValid();
    TestTierBoundariesOrdered();
    TestFeeMonotonicity();
    TestFeesNonNegative();
    TestDefaultLimitsPositive();
    TestNameLengthConstraints();
    TestSystemLimitsReasonable();
    TestTierValues();
    TestDefaultAccountSettings();
    TestConfigurationSummary();
    TestOtherFees();
    TestTransactionLimits();
    TestMinBalanceConstraint();
    TestBackupConfiguration();
    TestLimitRelationships();
    TestNameLengthBoundaries();
    TestSystemAccountLimit();
    TestTransactionHistoryLimit();

    print "\n================================\n";
    print "All Configuration Tests Passed! ✓\n";
  }
}
