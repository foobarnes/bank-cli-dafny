// Configuration.dfy
// Single source of truth for all system configuration values
//
// This module centralizes all configurable parameters including:
// - Overdraft fee tiers and amounts
// - Account limits and defaults
// - Transaction limits
// - System-wide settings
//
// Developers: Modify values here to adjust system behavior
// Users: View current configuration via CLI command "View System Configuration"

module Configuration {

  // ============================================================================
  // OVERDRAFT FEE CONFIGURATION
  // ============================================================================

  // Tier 1: Overdraft amount from $0.01 to $100.00
  const OVERDRAFT_TIER1_MAX_CENTS: int := 10000        // $100.00
  const OVERDRAFT_TIER1_FEE_CENTS: int := 2500         // $25.00

  // Tier 2: Overdraft amount from $100.01 to $500.00
  const OVERDRAFT_TIER2_MAX_CENTS: int := 50000        // $500.00
  const OVERDRAFT_TIER2_FEE_CENTS: int := 3500         // $35.00

  // Tier 3: Overdraft amount from $500.01 to $1,000.00
  const OVERDRAFT_TIER3_MAX_CENTS: int := 100000       // $1,000.00
  const OVERDRAFT_TIER3_FEE_CENTS: int := 5000         // $50.00

  // Tier 4: Overdraft amount over $1,000.00
  const OVERDRAFT_TIER4_FEE_CENTS: int := 7500         // $75.00

  // ============================================================================
  // ACCOUNT LIMIT DEFAULTS
  // ============================================================================

  // Default maximum balance per account (can be overridden per account)
  const DEFAULT_MAX_BALANCE_CENTS: int := 100000000    // $1,000,000.00

  // Default maximum single transaction amount (can be overridden per account)
  const DEFAULT_MAX_TRANSACTION_CENTS: int := 1000000  // $10,000.00

  // Default maximum overdraft limit when enabled (can be overridden per account)
  const DEFAULT_OVERDRAFT_LIMIT_CENTS: int := 100000   // $1,000.00

  // Minimum account balance without overdraft
  const MIN_BALANCE_NO_OVERDRAFT_CENTS: int := 0       // $0.00

  // ============================================================================
  // ACCOUNT CREATION DEFAULTS
  // ============================================================================

  // Default overdraft setting for new accounts
  const DEFAULT_OVERDRAFT_ENABLED: bool := false

  // Minimum owner name length
  const MIN_OWNER_NAME_LENGTH: nat := 1

  // Maximum owner name length
  const MAX_OWNER_NAME_LENGTH: nat := 255

  // Minimum initial deposit (can be zero)
  const MIN_INITIAL_DEPOSIT_CENTS: int := 0            // $0.00

  // ============================================================================
  // TRANSACTION LIMITS
  // ============================================================================

  // Minimum transaction amount (must be positive)
  const MIN_TRANSACTION_AMOUNT_CENTS: int := 1         // $0.01

  // Maximum transaction history size per account (for performance)
  const MAX_TRANSACTION_HISTORY_SIZE: nat := 100000

  // ============================================================================
  // SYSTEM-WIDE LIMITS
  // ============================================================================

  // Maximum number of accounts in the system
  const MAX_SYSTEM_ACCOUNTS: nat := 10000

  // Maximum attempts for file operations before failure
  const MAX_FILE_OPERATION_RETRIES: nat := 3

  // Backup retention days
  const BACKUP_RETENTION_DAYS: nat := 30

  // ============================================================================
  // FEE CONFIGURATION (OTHER TYPES)
  // ============================================================================

  // Maintenance fee (if implemented)
  const MAINTENANCE_FEE_CENTS: int := 1000             // $10.00

  // Transfer fee (if implemented)
  const TRANSFER_FEE_CENTS: int := 500                 // $5.00

  // ATM fee (if implemented)
  const ATM_FEE_CENTS: int := 300                      // $3.00

  // Insufficient funds fee (if implemented)
  const INSUFFICIENT_FUNDS_FEE_CENTS: int := 3500      // $35.00

  // ============================================================================
  // VALIDATION PREDICATES
  // ============================================================================

  // Verify configuration values are internally consistent
  ghost predicate ValidConfiguration()
  {
    // Overdraft tier boundaries are ordered correctly
    OVERDRAFT_TIER1_MAX_CENTS < OVERDRAFT_TIER2_MAX_CENTS &&
    OVERDRAFT_TIER2_MAX_CENTS < OVERDRAFT_TIER3_MAX_CENTS &&
    // Fees are non-negative
    OVERDRAFT_TIER1_FEE_CENTS >= 0 &&
    OVERDRAFT_TIER2_FEE_CENTS >= 0 &&
    OVERDRAFT_TIER3_FEE_CENTS >= 0 &&
    OVERDRAFT_TIER4_FEE_CENTS >= 0 &&
    // Fee monotonicity: higher tiers should have higher fees
    OVERDRAFT_TIER1_FEE_CENTS <= OVERDRAFT_TIER2_FEE_CENTS &&
    OVERDRAFT_TIER2_FEE_CENTS <= OVERDRAFT_TIER3_FEE_CENTS &&
    OVERDRAFT_TIER3_FEE_CENTS <= OVERDRAFT_TIER4_FEE_CENTS &&
    // Default limits are positive
    DEFAULT_MAX_BALANCE_CENTS > 0 &&
    DEFAULT_MAX_TRANSACTION_CENTS > 0 &&
    DEFAULT_OVERDRAFT_LIMIT_CENTS >= 0 &&
    // Name length constraints are valid
    MIN_OWNER_NAME_LENGTH > 0 &&
    MIN_OWNER_NAME_LENGTH <= MAX_OWNER_NAME_LENGTH &&
    // System limits are reasonable
    MAX_SYSTEM_ACCOUNTS > 0 &&
    MAX_TRANSACTION_HISTORY_SIZE > 0
  }

  // Lemma: Configuration is valid
  lemma ConfigurationIsValid()
    ensures ValidConfiguration()
  {
    // Proof by computation - all constants satisfy the predicate
  }

  // ============================================================================
  // HELPER FUNCTIONS FOR CONFIGURATION DISPLAY
  // ============================================================================

  // Convert cents to dollar string representation (requires FFI implementation)
  // Example: 2500 cents -> "$25.00"
  method {:extern} FormatCentsToDollars(cents: int) returns (formatted: string)

  // Get configuration as human-readable description
  method GetConfigurationSummary() returns (summary: string)
  {
    summary := "Bank CLI Configuration\n" +
               "======================\n\n" +
               "OVERDRAFT FEE TIERS:\n" +
               "  Tier 1 ($0.01 - $100.00):     $25.00\n" +
               "  Tier 2 ($100.01 - $500.00):   $35.00\n" +
               "  Tier 3 ($500.01 - $1,000.00): $50.00\n" +
               "  Tier 4 ($1,000.01+):          $75.00\n\n" +
               "ACCOUNT DEFAULTS:\n" +
               "  Max Balance:        $1,000,000.00\n" +
               "  Max Transaction:    $10,000.00\n" +
               "  Overdraft Limit:    $1,000.00\n" +
               "  Overdraft Enabled:  false\n\n" +
               "SYSTEM LIMITS:\n" +
               "  Max Accounts:       10,000\n" +
               "  Max History/Account: 100,000 transactions\n";
  }
}
