# Bank CLI Functional Requirements

**Version:** 1.0
**Last Updated:** 2025-10-30
**Status:** Final Specification
**Document Type:** Functional Requirements Specification

---

## Overview

This document defines the complete functional requirements for the Verified Bank CLI system. It specifies all user-facing operations, business rules, input/output specifications, and invariants that must be maintained by the system. These requirements form the contract between the system's behavior and its formal verification specifications.

The Bank CLI provides a complete banking experience with:
- Account management (create, list, query)
- Transaction operations (deposit, withdrawal, transfer)
- Balance and history queries with filtering
- Configuration operations (overdraft, account status)

Each requirement includes detailed specifications for inputs, outputs, business rules, and mathematical invariants that must be proven correct through Dafny's verification system.

---

## 2. Functional Requirements

### 2.1 Account Management

#### FR-1: Create Account
**Description**: Create a new bank account with unique identifier and initial deposit.

**Inputs:**
- `owner`: string (1-100 characters, non-empty)
- `initialDeposit`: int (≥ 0, in cents)
- `enableOverdraft`: bool
- `overdraftLimit`: int (≥ 0, in cents, required if overdraft enabled)

**Outputs:**
- Success: Account ID (unique natural number)
- Failure: Error message with specific reason

**Business Rules:**
- Account ID must be unique (auto-generated sequential)
- Owner name cannot be empty or whitespace-only
- Initial deposit must be non-negative
- If overdraft enabled, limit must be specified and > 0
- Default limits applied: maxBalance = $1,000,000, maxTransaction = $100,000

**Invariants Maintained:**
- New account balance equals initial deposit
- History contains exactly one transaction (initial deposit)
- Account ID is unique across all accounts
- Total fees collected initialized to 0

#### FR-2: List Accounts
**Description**: Display all accounts with summary information.

**Inputs:** None

**Outputs:**
- List of accounts with:
  - Account ID
  - Owner name
  - Current balance (formatted as USD)
  - Overdraft status (enabled/disabled)
  - Account status (active/suspended/closed)
  - Number of transactions

**Business Rules:**
- Accounts sorted by ID ascending
- Balance displayed with proper formatting ($X,XXX.XX)
- Empty list if no accounts exist

#### FR-3: Query Account Details
**Description**: Display detailed information about a specific account.

**Inputs:**
- `accountId`: nat

**Outputs:**
- Success: Complete account details including:
  - Account ID, Owner, Balance
  - Overdraft settings (enabled, limit, current usage)
  - Account limits (maxBalance, maxTransaction)
  - Total fees collected
  - Transaction count
  - Account status
- Failure: "Account not found" error

### 2.2 Transaction Operations

#### FR-4: Deposit
**Description**: Add funds to an account.

**Inputs:**
- `accountId`: nat
- `amount`: int (> 0, in cents)
- `description`: string (optional, max 200 characters)

**Outputs:**
- Success: Transaction confirmation with:
  - Transaction ID
  - New balance
  - Balance change visualization
  - Timestamp
- Failure: Error message with reason

**Business Rules:**
- Amount must be positive (> 0)
- Resulting balance must not exceed maxBalance
- Account must not be suspended or closed
- Transaction recorded in history with:
  - Unique transaction ID (UUID or sequential)
  - Type: Deposit
  - Timestamp (Unix epoch seconds)
  - Balance before/after snapshots
  - Status: Completed

**Invariants Maintained:**
- Balance increases by exactly `amount`
- Transaction history grows by one entry
- Fund conservation (total system funds increase)

#### FR-5: Withdrawal
**Description**: Remove funds from an account with overdraft protection.

**Inputs:**
- `accountId`: nat
- `amount`: int (> 0, in cents)
- `description`: string (optional, max 200 characters)

**Outputs:**
- Success: Transaction confirmation with:
  - Transaction ID
  - New balance (may be negative if overdraft used)
  - Overdraft fee if applicable (separate transaction)
  - Fee tier breakdown
  - Balance change visualization
- Failure: Error message with reason

**Business Rules:**
- Amount must be positive (> 0)
- Amount must not exceed maxTransaction limit
- Account must not be suspended or closed
- If overdraft disabled: balance - amount must be ≥ 0
- If overdraft enabled: balance - amount must be ≥ -overdraftLimit
- Overdraft fee applied AFTER withdrawal if balance becomes negative
- Fee is a separate transaction with proper linking

**Overdraft Fee Calculation:**
1. Determine overdraft amount: abs(balance after withdrawal) if negative
2. Apply tiered fee structure:
   - Tier 1: $0.01 - $100.00 → $25.00 fee
   - Tier 2: $100.01 - $500.00 → $35.00 fee
   - Tier 3: $500.01 - $1000.00 → $50.00 fee
   - Tier 4: $1000.01+ → $75.00 fee
3. Create fee transaction linked to withdrawal
4. Update totalFeesCollected

**Invariants Maintained:**
- Balance decreases by exactly `amount` + `fee`
- Transaction history grows by 1 (withdrawal) or 2 (withdrawal + fee)
- Fee transaction has parentTxId = withdrawal transaction ID
- Withdrawal transaction has fee ID in childTxIds
- totalFeesCollected increases by fee amount (monotonic)

#### FR-6: Transfer
**Description**: Move funds from one account to another atomically.

**Inputs:**
- `fromAccountId`: nat
- `toAccountId`: nat
- `amount`: int (> 0, in cents)
- `description`: string (optional, max 200 characters)

**Outputs:**
- Success: Transfer confirmation with:
  - Transfer ID (parent transaction)
  - TransferOut transaction ID (from account)
  - TransferIn transaction ID (to account)
  - New balances for both accounts
  - Overdraft fee if applicable (separate transaction)
- Failure: Error message with reason, system state unchanged

**Business Rules:**
- Amount must be positive (> 0)
- From and to accounts must be different
- Both accounts must exist
- Both accounts must be active (not suspended/closed)
- From account must have sufficient funds (considering overdraft)
- Amount must not exceed fromAccount.maxTransaction
- Resulting toAccount balance must not exceed maxBalance
- Operation is atomic: both succeed or both fail
- If fromAccount goes negative, overdraft fee applies

**Transfer Structure:**
1. Create TransferOut transaction in fromAccount
2. Create TransferIn transaction in toAccount
3. Link transactions via parentTxId/childTxIds
4. If overdraft triggered, create fee transaction in fromAccount
5. All transactions share same timestamp

**Invariants Maintained:**
- Fund conservation: fromAccount.balance decrease = toAccount.balance increase + fees
- Both accounts' history grow (by 1 or 2 entries each)
- Transaction linkage preserved
- Atomicity: all-or-nothing execution

### 2.3 Balance and History

#### FR-7: Check Balance
**Description**: Display current balance with detailed breakdown.

**Inputs:**
- `accountId`: nat

**Outputs:**
- Success: Balance report with:
  - Current balance (formatted)
  - Available balance (considering overdraft)
  - Overdraft usage (if applicable)
  - Total fees collected (lifetime)
  - Balance status (positive, overdraft, near limit)
- Failure: "Account not found" error

**Business Rules:**
- Balance calculated from transaction history (verified against stored balance)
- Available balance = balance + overdraftLimit (if enabled)
- Overdraft usage = abs(balance) if balance < 0

#### FR-8: Transaction History
**Description**: Display filtered transaction history with details.

**Inputs:**
- `accountId`: nat
- `filter`: TransactionFilter (optional)
  - `txType`: TransactionType (optional)
  - `startDate`: nat (optional, Unix timestamp)
  - `endDate`: nat (optional, Unix timestamp)
  - `minAmount`: int (optional)
  - `maxAmount`: int (optional)
- `limit`: nat (optional, default 50, max 1000)
- `offset`: nat (optional, default 0)

**Outputs:**
- Success: Transaction list with:
  - Transaction ID
  - Type (Deposit, Withdrawal, TransferIn, TransferOut, Fee, etc.)
  - Amount (formatted)
  - Description
  - Timestamp (formatted as datetime)
  - Balance before/after
  - Status
  - Fee details (if type is Fee)
  - Linked transactions (parent/children)
- Failure: "Account not found" error

**Business Rules:**
- Transactions displayed in reverse chronological order (newest first)
- Filters applied inclusively (AND logic)
- Fee transactions displayed separately with full breakdown
- Balance snapshots shown for each transaction
- Pagination supported via limit/offset

**Fee Transaction Display:**
```
Transaction #12345
Type: Fee (Overdraft - Tier 2)
Amount: -$35.00
Triggered by: Transaction #12344 (Withdrawal: -$450.00)
Details:
  - Overdraft amount: $375.50
  - Tier: 2 ($100.01 - $500.00)
  - Fee: $35.00
Balance: $-410.50 → $-445.50
```

### 2.4 Configuration

#### FR-9: Configure Overdraft
**Description**: Enable/disable overdraft protection and set limits.

**Inputs:**
- `accountId`: nat
- `enable`: bool
- `limit`: int (required if enabling, ≥ 0, in cents)

**Outputs:**
- Success: Confirmation with new overdraft settings
- Failure: Error message with reason

**Business Rules:**
- Can enable overdraft only if limit > 0 specified
- Can disable overdraft only if current balance ≥ 0
- Cannot disable overdraft while account is overdrawn
- Limit can be changed while overdraft is enabled
- New limit must accommodate current balance (if negative)

**Invariants Maintained:**
- Account balance invariant preserved
- Configuration change logged in transaction history (Adjustment type)

#### FR-10: Account Status Management
**Description**: Change account status (active, suspended, closed).

**Inputs:**
- `accountId`: nat
- `newStatus`: AccountStatus
- `reason`: string

**Outputs:**
- Success: Status change confirmation
- Failure: Error message with reason

**Business Rules:**
- Suspended accounts: no transactions allowed, can view only
- Closed accounts: no transactions, no status changes
- Can close account only if balance = 0
- Status change logged in transaction history

---

## Requirement Categories

### Critical Requirements (Security & Correctness)
- FR-1: Account creation with unique IDs
- FR-4, FR-5, FR-6: Transaction operations with atomicity
- FR-9: Overdraft configuration with balance validation
- FR-10: Account status management with state validation

### High Priority (Core Functionality)
- FR-2, FR-3: Account queries
- FR-7: Balance checking with verification
- FR-8: Transaction history with filtering

### Medium Priority (User Experience)
- Transaction descriptions
- Balance formatting and visualization
- Fee breakdowns and explanations

---

## Verification Priorities

Each functional requirement must be accompanied by formal verification that proves:

1. **Type Safety**: All inputs validated before processing
2. **Preconditions**: Required conditions checked before execution
3. **Postconditions**: Expected results achieved after execution
4. **Invariant Preservation**: Critical system invariants maintained
5. **Atomicity**: Operations complete fully or not at all
6. **Fund Conservation**: Total system funds tracked correctly

### Key Invariants Across All Requirements

**Balance Integrity:**
```dafny
invariant account.balance == ComputeBalanceFromHistory(account.history)
```

**Fee Monotonicity:**
```dafny
invariant account.totalFeesCollected >= old(account.totalFeesCollected)
```

**Fund Conservation:**
```dafny
invariant TotalSystemFunds(bank) == Sum(deposits) - Sum(withdrawals) - Sum(fees)
```

**Overdraft Bounds:**
```dafny
invariant account.overdraftEnabled ==>
  account.balance >= -account.overdraftLimit
```

---

## Requirement Traceability

| Requirement | Implementation Module | Verification Module | Test Coverage |
|-------------|----------------------|---------------------|---------------|
| FR-1 | Bank.dfy | BankInvariants.dfy | AccountTests.dfy |
| FR-2 | Bank.dfy | - | AccountTests.dfy |
| FR-3 | Bank.dfy | - | AccountTests.dfy |
| FR-4 | Bank.dfy | TransactionInvariants.dfy | TransactionTests.dfy |
| FR-5 | Bank.dfy, OverdraftPolicy.dfy | OverdraftVerification.dfy | OverdraftTests.dfy |
| FR-6 | Bank.dfy | TransferInvariants.dfy | TransferTests.dfy |
| FR-7 | Bank.dfy | BalanceInvariants.dfy | BalanceTests.dfy |
| FR-8 | Bank.dfy, Transaction.dfy | - | HistoryTests.dfy |
| FR-9 | Bank.dfy | ConfigurationInvariants.dfy | ConfigTests.dfy |
| FR-10 | Bank.dfy | StatusInvariants.dfy | StatusTests.dfy |

---

## Compliance & Validation

### Input Validation Requirements

All functional requirements must validate:
- **Type constraints**: Natural numbers, positive amounts, valid strings
- **Range constraints**: Maximum lengths, minimum values, balance limits
- **Business rules**: Account existence, status checks, sufficient funds
- **State consistency**: No duplicate IDs, valid transitions, preserved invariants

### Output Consistency Requirements

All functional requirements must provide:
- **Success indicators**: Clear confirmation of completed operations
- **Error messages**: Specific, actionable failure reasons
- **State visibility**: Current balances, transaction IDs, timestamps
- **Audit trail**: Complete transaction history with linkage

---

## Related Documentation

This document should be read in conjunction with:

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Implementation architecture and module structure
- **[DATA_MODELS.md](DATA_MODELS.md)** - Complete datatype specifications and field constraints
- **[UI_SPECIFICATION.md](UI_SPECIFICATION.md)** - User interface flows and interaction patterns
- **[ERROR_HANDLING.md](ERROR_HANDLING.md)** - Error codes, messages, and recovery strategies
- **[../../guides/REQUIREMENTS_AND_EDGE_CASES.md](../../guides/REQUIREMENTS_AND_EDGE_CASES.md)** - Detailed edge case catalog and test scenarios
- **[../SPEC.md](../../SPEC.md)** - Complete system specification (master document)

### Quick Reference

- For **implementation details**: See ARCHITECTURE.md
- For **data structure definitions**: See DATA_MODELS.md
- For **user interaction flows**: See UI_SPECIFICATION.md
- For **error handling**: See ERROR_HANDLING.md
- For **edge case testing**: See guides/REQUIREMENTS_AND_EDGE_CASES.md
- For **verification specifications**: See SPEC.md Section 4

---

## Document Control

**Approval:**
- Technical Lead: [Required]
- Verification Engineer: [Required]
- Product Owner: [Required]

**Change History:**
| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-30 | Documentation Engineer | Initial extraction from SPEC.md |

**Review Schedule:** Quarterly or upon significant system changes

---

*This document is part of the Verified Bank CLI formal specification suite. All requirements must be implemented with corresponding Dafny verification proofs.*
