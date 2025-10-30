# Configuration Specification

**Version:** 1.0
**Last Updated:** 2025-10-30
**Status:** Active

## Overview

This document specifies the centralized configuration system for the Verified Bank CLI. All configurable system parameters are maintained in a single source of truth: `src/Configuration.dfy`.

**Purpose:**
- Single source of truth for all system configuration
- Type-safe configuration with Dafny verification
- Runtime visibility via CLI
- Developer-friendly modification

**Location:** `src/Configuration.dfy`

---

## Table of Contents

1. [Configuration Architecture](#configuration-architecture)
2. [Overdraft Fee Configuration](#overdraft-fee-configuration)
3. [Account Defaults](#account-defaults)
4. [Transaction Limits](#transaction-limits)
5. [System-Wide Limits](#system-wide-limits)
6. [Other Fee Types](#other-fee-types)
7. [Validation and Invariants](#validation-and-invariants)
8. [Viewing Configuration](#viewing-configuration)
9. [Modifying Configuration](#modifying-configuration)
10. [Configuration Impact Analysis](#configuration-impact-analysis)

---

## Configuration Architecture

### Design Principles

1. **Single Source of Truth**: All configuration values defined in one module
2. **Type Safety**: Dafny constants ensure compile-time type checking
3. **Verification**: Configuration validity is formally verified
4. **Transparency**: Users can view all settings via CLI
5. **Maintainability**: One place to update system behavior

### Module Structure

```dafny
module Configuration {
  // All constants defined here
  // No mutable state
  // Pure configuration values
}
```

### Integration

All modules that need configuration import the Configuration module:

```dafny
include "Configuration.dfy"
import opened Configuration
```

**Modules using Configuration:**
- `OverdraftPolicy.dfy` - Uses overdraft tier and fee constants
- `Account.dfy` - Uses default account limits
- `Validation.dfy` - Uses validation constraints
- `CLI.dfy` - Displays configuration to users

---

## Overdraft Fee Configuration

### Fee Tier Structure

The system uses a **4-tier** overdraft fee structure with fixed fees per tier:

| Tier | Overdraft Range | Fee | Constant Name |
|------|----------------|-----|---------------|
| **1** | $0.01 - $100.00 | **$25.00** | `OVERDRAFT_TIER1_FEE_CENTS` |
| **2** | $100.01 - $500.00 | **$35.00** | `OVERDRAFT_TIER2_FEE_CENTS` |
| **3** | $500.01 - $1,000.00 | **$50.00** | `OVERDRAFT_TIER3_FEE_CENTS` |
| **4** | $1,000.01+ | **$75.00** | `OVERDRAFT_TIER4_FEE_CENTS` |

### Tier Boundary Constants

```dafny
const OVERDRAFT_TIER1_MAX_CENTS: int := 10000      // $100.00
const OVERDRAFT_TIER2_MAX_CENTS: int := 50000      // $500.00
const OVERDRAFT_TIER3_MAX_CENTS: int := 100000     // $1,000.00
// Tier 4 has no maximum (any amount over Tier 3)
```

### Fee Amount Constants

```dafny
const OVERDRAFT_TIER1_FEE_CENTS: int := 2500       // $25.00
const OVERDRAFT_TIER2_FEE_CENTS: int := 3500       // $35.00
const OVERDRAFT_TIER3_FEE_CENTS: int := 5000       // $50.00
const OVERDRAFT_TIER4_FEE_CENTS: int := 7500       // $75.00
```

### Design Rationale

**Why Fixed Fees?**
- Predictable costs for users
- Simpler verification (no percentage calculations)
- Industry standard for overdraft fees
- Monotonic fee structure (higher overdraft = higher fee)

**Why 4 Tiers?**
- Balance between granularity and simplicity
- Common tier structure in banking
- Provides escalation for large overdrafts
- Verifiable monotonicity property

### Modifying Overdraft Fees

To change fees or tier boundaries:

1. Edit `src/Configuration.dfy`
2. Update the relevant constants
3. Verify: `dafny verify src/Configuration.dfy`
4. Ensure `ValidConfiguration()` still holds
5. Recompile the system
6. Changes take effect immediately

**Example: Increasing Tier 1 fee to $30:**
```dafny
const OVERDRAFT_TIER1_FEE_CENTS: int := 3000  // Changed from 2500
```

---

## Account Defaults

### Default Limits

```dafny
const DEFAULT_MAX_BALANCE_CENTS: int := 100000000    // $1,000,000.00
const DEFAULT_MAX_TRANSACTION_CENTS: int := 1000000  // $10,000.00
const DEFAULT_OVERDRAFT_LIMIT_CENTS: int := 100000   // $1,000.00
```

**Purpose:**
- `DEFAULT_MAX_BALANCE_CENTS`: Maximum balance an account can hold
- `DEFAULT_MAX_TRANSACTION_CENTS`: Maximum amount for single transaction
- `DEFAULT_OVERDRAFT_LIMIT_CENTS`: Maximum negative balance when overdraft enabled

**Can be overridden:** Yes, per-account during creation

### Account Creation Defaults

```dafny
const DEFAULT_OVERDRAFT_ENABLED: bool := false
```

**Purpose:** New accounts are created with overdraft protection **disabled** by default for user safety.

### Name Constraints

```dafny
const MIN_OWNER_NAME_LENGTH: nat := 1
const MAX_OWNER_NAME_LENGTH: nat := 255
```

**Purpose:** Enforce reasonable owner name lengths (prevents empty names and excessive strings)

### Initial Deposit Constraints

```dafny
const MIN_INITIAL_DEPOSIT_CENTS: int := 0  // $0.00
```

**Purpose:** Accounts can be created with zero balance (no minimum deposit required)

---

## Transaction Limits

### Minimum Transaction

```dafny
const MIN_TRANSACTION_AMOUNT_CENTS: int := 1  // $0.01
```

**Purpose:** Prevent zero or negative transaction amounts (except fees which are separate)

**Applies to:**
- Deposits
- Withdrawals
- Transfers

### Maximum History Size

```dafny
const MAX_TRANSACTION_HISTORY_SIZE: nat := 100000
```

**Purpose:**
- Performance optimization
- Prevents unbounded memory growth
- 100,000 transactions is sufficient for typical account lifetime

**Behavior when reached:**
- Older transactions may be archived
- Core balance integrity maintained
- Current balance calculation unaffected

---

## System-Wide Limits

### Maximum Accounts

```dafny
const MAX_SYSTEM_ACCOUNTS: nat := 10000
```

**Purpose:**
- Prevent system resource exhaustion
- Reasonable limit for CLI application
- Can be increased for production systems

**Behavior when reached:**
- Account creation fails gracefully
- Existing accounts continue to function
- User receives clear error message

### File Operation Retries

```dafny
const MAX_FILE_OPERATION_RETRIES: nat := 3
```

**Purpose:**
- Handle transient file system errors
- Automatic retry for persistence operations
- Prevents data loss from temporary failures

**Retry Strategy:**
- Exponential backoff between retries
- After 3 failures, report error to user
- In-memory state preserved

### Backup Retention

```dafny
const BACKUP_RETENTION_DAYS: nat := 30
```

**Purpose:**
- Automatic backup file cleanup
- Prevent disk space exhaustion
- 30 days provides adequate recovery window

---

## Other Fee Types

### Fee Configuration (Future Implementation)

```dafny
const MAINTENANCE_FEE_CENTS: int := 1000             // $10.00
const TRANSFER_FEE_CENTS: int := 500                 // $5.00
const ATM_FEE_CENTS: int := 300                      // $3.00
const INSUFFICIENT_FUNDS_FEE_CENTS: int := 3500      // $35.00
```

**Status:** Defined but not currently implemented
**Purpose:** Placeholders for future fee types
**Usage:** Can be activated by implementing corresponding fee logic

---

## Validation and Invariants

### ValidConfiguration Predicate

```dafny
ghost predicate ValidConfiguration()
{
  // Overdraft tier boundaries are ordered
  OVERDRAFT_TIER1_MAX_CENTS < OVERDRAFT_TIER2_MAX_CENTS &&
  OVERDRAFT_TIER2_MAX_CENTS < OVERDRAFT_TIER3_MAX_CENTS &&

  // Fees are non-negative
  OVERDRAFT_TIER1_FEE_CENTS >= 0 &&
  OVERDRAFT_TIER2_FEE_CENTS >= 0 &&
  OVERDRAFT_TIER3_FEE_CENTS >= 0 &&
  OVERDRAFT_TIER4_FEE_CENTS >= 0 &&

  // Fee monotonicity (higher tier = higher fee)
  OVERDRAFT_TIER1_FEE_CENTS <= OVERDRAFT_TIER2_FEE_CENTS &&
  OVERDRAFT_TIER2_FEE_CENTS <= OVERDRAFT_TIER3_FEE_CENTS &&
  OVERDRAFT_TIER3_FEE_CENTS <= OVERDRAFT_TIER4_FEE_CENTS &&

  // Default limits are positive
  DEFAULT_MAX_BALANCE_CENTS > 0 &&
  DEFAULT_MAX_TRANSACTION_CENTS > 0 &&
  DEFAULT_OVERDRAFT_LIMIT_CENTS >= 0 &&

  // Name constraints are valid
  MIN_OWNER_NAME_LENGTH > 0 &&
  MIN_OWNER_NAME_LENGTH <= MAX_OWNER_NAME_LENGTH &&

  // System limits are reasonable
  MAX_SYSTEM_ACCOUNTS > 0 &&
  MAX_TRANSACTION_HISTORY_SIZE > 0
}
```

### Verification Lemma

```dafny
lemma ConfigurationIsValid()
  ensures ValidConfiguration()
{
  // Proof by computation
  // All constants satisfy the predicate
}
```

**Verification:** Dafny formally proves the configuration is valid at compile time.

### Configuration Constraints

| Constraint | Requirement | Rationale |
|------------|-------------|-----------|
| Tier boundaries ordered | T1 < T2 < T3 | Prevent tier overlap |
| Fees non-negative | All fees ≥ 0 | No negative fees allowed |
| Fee monotonicity | T1 ≤ T2 ≤ T3 ≤ T4 | Fairness: higher overdraft = higher fee |
| Positive limits | Max values > 0 | Prevent zero/negative limits |
| Name length valid | Min > 0, Min ≤ Max | Enforceable constraints |

---

## Viewing Configuration

### CLI Command

**Menu Option:** `10 - View System Configuration`

**Output Format:**
```
Bank CLI Configuration
======================

OVERDRAFT FEE TIERS:
  Tier 1 ($0.01 - $100.00):     $25.00
  Tier 2 ($100.01 - $500.00):   $35.00
  Tier 3 ($500.01 - $1,000.00): $50.00
  Tier 4 ($1,000.01+):          $75.00

ACCOUNT DEFAULTS:
  Max Balance:        $1,000,000.00
  Max Transaction:    $10,000.00
  Overdraft Limit:    $1,000.00
  Overdraft Enabled:  false

SYSTEM LIMITS:
  Max Accounts:       10,000
  Max History/Account: 100,000 transactions
```

### API Method

```dafny
method GetConfigurationSummary() returns (summary: string)
```

**Returns:** Formatted string with all configuration values
**Usage:** Called by CLI to display configuration
**Format:** Human-readable text with proper alignment

---

## Modifying Configuration

### Developer Workflow

**Step 1: Edit Configuration**
```bash
# Open configuration file
vim src/Configuration.dfy

# Modify desired constants
const OVERDRAFT_TIER1_FEE_CENTS: int := 3000  // Changed from 2500
```

**Step 2: Verify Changes**
```bash
dafny verify src/Configuration.dfy
```

Expected output:
```
Dafny program verifier finished with X verified, 0 errors
```

**Step 3: Verify Impact**
```bash
# Verify modules that use configuration
dafny verify src/OverdraftPolicy.dfy
dafny verify src/Account.dfy
```

**Step 4: Recompile**
```bash
dafny build src/Main.dfy --output:bank-cli
```

**Step 5: Test**
```bash
./bank-cli
# Use option 10 to view updated configuration
```

### Configuration Change Checklist

- [ ] Edit `src/Configuration.dfy`
- [ ] Verify `ValidConfiguration()` still holds
- [ ] Run `dafny verify src/Configuration.dfy`
- [ ] Verify dependent modules (OverdraftPolicy, Account)
- [ ] Update documentation if behavior changes
- [ ] Recompile application
- [ ] Test configuration display (CLI option 10)
- [ ] Test affected functionality
- [ ] Commit with clear message describing change

### Common Configuration Changes

**Change overdraft fees:**
```dafny
// In Configuration.dfy
const OVERDRAFT_TIER1_FEE_CENTS: int := 3000  // Was 2500
```
**Impact:** All withdrawals triggering Tier 1 overdraft

**Change tier boundaries:**
```dafny
const OVERDRAFT_TIER1_MAX_CENTS: int := 15000  // Was 10000
```
**Impact:** More overdrafts fall into Tier 1 (lower fees)

**Change account limits:**
```dafny
const DEFAULT_MAX_BALANCE_CENTS: int := 200000000  // Was 100000000
```
**Impact:** New accounts can hold more funds

**Enable overdraft by default:**
```dafny
const DEFAULT_OVERDRAFT_ENABLED: bool := true  // Was false
```
**Impact:** All new accounts created with overdraft enabled

---

## Configuration Impact Analysis

### Overdraft Fee Changes

**Increasing Fees:**
- ✅ Users see higher fees for overdrafts
- ✅ Revenue increases
- ⚠️ User dissatisfaction risk
- ⚠️ May violate regulatory limits

**Decreasing Fees:**
- ✅ User-friendly
- ✅ Competitive advantage
- ⚠️ Revenue decreases
- ✅ May improve customer retention

### Tier Boundary Changes

**Expanding Tier 1 (higher max):**
- ✅ More users pay lower fees
- ⚠️ Fewer users reach higher tiers
- Effect: Lower average fee revenue

**Contracting Tier 1 (lower max):**
- ⚠️ More users reach higher tiers
- Effect: Higher average fee revenue
- ⚠️ May seem punitive to users

### Account Limit Changes

**Increasing MAX_BALANCE:**
- ✅ Supports high-value accounts
- ⚠️ May require additional compliance
- Minimal system impact

**Increasing MAX_TRANSACTION:**
- ✅ Supports large transactions
- ⚠️ May enable fraud (consider carefully)
- ⚠️ Regulatory implications

**Changing OVERDRAFT_LIMIT:**
- Higher limit: More credit risk, more fee revenue
- Lower limit: Less credit risk, less fee revenue
- ⚠️ Balance risk vs revenue

### System Limit Changes

**Increasing MAX_SYSTEM_ACCOUNTS:**
- ✅ Supports growth
- ⚠️ May impact performance
- ⚠️ Increased memory/storage requirements

**Increasing MAX_TRANSACTION_HISTORY:**
- ✅ Better audit trail
- ⚠️ Memory and query performance impact
- ⚠️ Consider archiving strategy

---

## Best Practices

### Configuration Management

1. **Version Control**: Always commit configuration changes
2. **Documentation**: Update this document when behavior changes
3. **Testing**: Test all affected flows after changes
4. **Verification**: Ensure Dafny verification passes
5. **Rollback Plan**: Keep previous configuration values in git history

### Security Considerations

1. **Fee Limits**: Ensure fees don't exceed regulatory limits
2. **Balance Limits**: Consider fraud prevention
3. **Transaction Limits**: Balance convenience vs security
4. **Default Settings**: Conservative defaults for safety

### Performance Considerations

1. **History Size**: Larger MAX_TRANSACTION_HISTORY_SIZE impacts memory
2. **Account Limits**: Higher MAX_SYSTEM_ACCOUNTS impacts load times
3. **Retry Limits**: More retries impact failure response time

---

## References

**Related Documents:**
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture and module design
- [DATA_MODELS.md](DATA_MODELS.md) - Datatype definitions
- [FUNCTIONAL_REQUIREMENTS.md](FUNCTIONAL_REQUIREMENTS.md) - Feature requirements
- [ERROR_HANDLING.md](ERROR_HANDLING.md) - Error scenarios and handling

**Source Files:**
- `src/Configuration.dfy` - Configuration module source
- `src/OverdraftPolicy.dfy` - Uses overdraft configuration
- `src/Account.dfy` - Uses account defaults
- `src/CLI.dfy` - Displays configuration

---

**Version History:**
- v1.0 (2025-10-30): Initial configuration specification with centralized system

**Maintainers:** Development Team
**Review Schedule:** Quarterly or when configuration changes are proposed
