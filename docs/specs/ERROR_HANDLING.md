# Bank CLI Error Handling

## Introduction

The Bank CLI application implements a comprehensive, structured error handling system designed to provide clarity, safety, and recoverability. This specification defines four categories of errors, each with specific handling strategies that preserve system integrity and guide users toward resolution.

**Error Handling Philosophy:**

1. **Fail-Safe**: All operations are atomic. Errors leave the system in a consistent state.
2. **User-Friendly**: Every error provides actionable guidance for resolution.
3. **Transparent**: Error codes and messages clearly identify the problem category and cause.
4. **Recoverable**: Persistence errors fall back to backups; business rule errors suggest alternatives.
5. **Verified**: Dafny's formal verification ensures error handling paths preserve invariants.

This document is extracted from Section 5 of the complete [SPEC.md](../../SPEC.md) and serves as the authoritative reference for error handling in the Bank CLI system.

---

## 5.1 Error Categories

The Bank CLI system categorizes all errors into four distinct types:

1. **Validation Errors (VE)**: Input format and constraint violations
2. **Business Rule Errors (BR)**: Valid inputs that violate domain rules
3. **Persistence Errors (PE)**: File I/O and data storage failures
4. **System Errors (SE)**: Unexpected runtime failures

### 5.1.1 Validation Errors (VE)

Validation errors occur when user input fails to meet format or constraint requirements. These errors are caught early before any business logic executes.

#### VE-1: Invalid Amount

- **Condition**: amount ≤ 0 for deposit/withdrawal/transfer
- **Error Code**: ERR_INVALID_AMOUNT
- **Message**: "Amount must be positive. Received: ${amount}"
- **Suggestion**: "Please enter an amount greater than zero."

#### VE-2: Account Not Found

- **Condition**: accountId not in bank.accounts.Keys
- **Error Code**: ERR_ACCOUNT_NOT_FOUND
- **Message**: "Account ID ${accountId} does not exist."
- **Suggestion**: "Use 'List Accounts' to see available accounts."

#### VE-3: Invalid Account ID Format

- **Condition**: User input cannot parse to nat
- **Error Code**: ERR_INVALID_ACCOUNT_ID
- **Message**: "Account ID must be a non-negative integer. Received: '${input}'"
- **Suggestion**: "Please enter a valid account number (e.g., 1, 2, 3)."

#### VE-4: Empty Owner Name

- **Condition**: owner is empty or whitespace-only
- **Error Code**: ERR_EMPTY_OWNER
- **Message**: "Account owner name cannot be empty."
- **Suggestion**: "Please enter a valid owner name (1-100 characters)."

#### VE-5: Owner Name Too Long

- **Condition**: |owner| > 100
- **Error Code**: ERR_OWNER_TOO_LONG
- **Message**: "Owner name exceeds maximum length of 100 characters."
- **Suggestion**: "Please shorten the name to 100 characters or less."

#### VE-6: Negative Initial Deposit

- **Condition**: initialDeposit < 0
- **Error Code**: ERR_NEGATIVE_INITIAL_DEPOSIT
- **Message**: "Initial deposit cannot be negative. Received: ${amount}"
- **Suggestion**: "Please enter a non-negative amount (minimum $0.00)."

#### VE-7: Invalid Overdraft Configuration

- **Condition**: overdraftEnabled = true but overdraftLimit ≤ 0
- **Error Code**: ERR_INVALID_OVERDRAFT_CONFIG
- **Message**: "Overdraft limit must be positive when overdraft is enabled."
- **Suggestion**: "Please specify a limit greater than $0.00, or disable overdraft."

#### VE-8: Description Too Long

- **Condition**: |description| > 200
- **Error Code**: ERR_DESCRIPTION_TOO_LONG
- **Message**: "Description exceeds maximum length of 200 characters."
- **Suggestion**: "Please shorten the description to 200 characters or less."

### 5.1.2 Business Rule Errors (BR)

Business rule errors occur when valid inputs violate domain-specific constraints or policies. The system state remains UNCHANGED for all business rule errors.

#### BR-1: Insufficient Funds

- **Condition**: balance - amount < 0 and !overdraftEnabled
- **Error Code**: ERR_INSUFFICIENT_FUNDS
- **Message**: "Insufficient funds. Balance: ${balance}, Required: ${amount}"
- **Suggestion**: "Enable overdraft protection, or deposit additional funds."
- **System State**: UNCHANGED

#### BR-2: Overdraft Limit Exceeded

- **Condition**: balance - amount < -overdraftLimit
- **Error Code**: ERR_OVERDRAFT_LIMIT_EXCEEDED
- **Message**: "Withdrawal would exceed overdraft limit. Balance: ${balance}, Limit: ${limit}, Requested: ${amount}"
- **Suggestion**: "Maximum withdrawal: ${maxWithdrawal}"
- **System State**: UNCHANGED

#### BR-3: Balance Exceeds Maximum

- **Condition**: balance + amount > maxBalance
- **Error Code**: ERR_MAX_BALANCE_EXCEEDED
- **Message**: "Deposit would exceed maximum balance of ${maxBalance}."
- **Suggestion**: "Maximum deposit: ${maxDeposit}"
- **System State**: UNCHANGED

#### BR-4: Transaction Exceeds Limit

- **Condition**: amount > maxTransaction
- **Error Code**: ERR_TRANSACTION_LIMIT_EXCEEDED
- **Message**: "Transaction amount ${amount} exceeds limit of ${maxTransaction}."
- **Suggestion**: "Please split into multiple transactions."
- **System State**: UNCHANGED

#### BR-5: Transfer to Same Account

- **Condition**: fromId == toId
- **Error Code**: ERR_TRANSFER_SAME_ACCOUNT
- **Message**: "Cannot transfer funds to the same account."
- **Suggestion**: "Please select a different destination account."
- **System State**: UNCHANGED

#### BR-6: Account Suspended

- **Condition**: account.status == Suspended
- **Error Code**: ERR_ACCOUNT_SUSPENDED
- **Message**: "Account ${accountId} is suspended. No transactions allowed."
- **Suggestion**: "Contact support to reactivate the account."
- **System State**: UNCHANGED

#### BR-7: Account Closed

- **Condition**: account.status == Closed
- **Error Code**: ERR_ACCOUNT_CLOSED
- **Message**: "Account ${accountId} is closed."
- **Suggestion**: "Create a new account to perform transactions."
- **System State**: UNCHANGED

#### BR-8: Cannot Disable Overdraft While Overdrawn

- **Condition**: Attempting to disable overdraft when balance < 0
- **Error Code**: ERR_OVERDRAWN_CANNOT_DISABLE
- **Message**: "Cannot disable overdraft while account is overdrawn. Current balance: ${balance}"
- **Suggestion**: "Deposit funds to bring balance to $0.00 or higher first."
- **System State**: UNCHANGED

#### BR-9: Cannot Close Account With Non-Zero Balance

- **Condition**: Attempting to close account when balance != 0
- **Error Code**: ERR_CANNOT_CLOSE_NONZERO
- **Message**: "Cannot close account with non-zero balance: ${balance}"
- **Suggestion**: "Withdraw or transfer all funds before closing."
- **System State**: UNCHANGED

#### BR-10: Duplicate Account ID

- **Condition**: Attempting to create account with existing ID (internal error)
- **Error Code**: ERR_DUPLICATE_ACCOUNT_ID
- **Message**: "Account ID ${accountId} already exists. This is a system error."
- **Suggestion**: "Please contact support."
- **System State**: UNCHANGED

### 5.1.3 Persistence Errors (PE)

Persistence errors occur during file I/O operations. The system implements sophisticated recovery strategies including backup loading and graceful degradation.

#### PE-1: File Not Found

- **Condition**: Data file doesn't exist at startup
- **Error Code**: ERR_FILE_NOT_FOUND
- **Message**: "Data file not found: ${filepath}"
- **Handling**: Create new empty bank, log info message
- **System State**: New empty bank initialized

#### PE-2: Permission Denied

- **Condition**: Cannot read/write data file due to permissions
- **Error Code**: ERR_PERMISSION_DENIED
- **Message**: "Permission denied accessing file: ${filepath}"
- **Suggestion**: "Check file permissions and user access rights."
- **System State**: Operation aborted, use in-memory state

#### PE-3: Disk Full

- **Condition**: Cannot write to disk (out of space)
- **Error Code**: ERR_DISK_FULL
- **Message**: "Cannot save data: disk is full."
- **Suggestion**: "Free up disk space and try again."
- **System State**: In-memory state preserved, save retried on next operation

#### PE-4: File Locked

- **Condition**: Another process has file open exclusively
- **Error Code**: ERR_FILE_LOCKED
- **Message**: "Data file is locked by another process."
- **Suggestion**: "Close other instances of the application."
- **System State**: Operation retried with exponential backoff

#### PE-5: Corrupted Data File

- **Condition**: JSON parsing fails or data validation fails
- **Error Code**: ERR_CORRUPTED_DATA
- **Message**: "Data file is corrupted: ${details}"
- **Handling**:
  1. Attempt to load most recent backup
  2. If backup also corrupted, load second-most recent
  3. If all backups fail, create new empty bank
- **System State**: Best available state loaded, user notified

#### PE-6: Malformed JSON

- **Condition**: JSON syntax error
- **Error Code**: ERR_MALFORMED_JSON
- **Message**: "Invalid JSON syntax in data file: ${parseError}"
- **Handling**: Same as PE-5
- **System State**: Fallback to backup

#### PE-7: Invalid Timestamp

- **Condition**: Timestamp in future or before epoch
- **Error Code**: ERR_INVALID_TIMESTAMP
- **Message**: "Invalid timestamp in transaction ${txId}: ${timestamp}"
- **Handling**: Skip transaction, log warning, continue loading
- **System State**: Partial load, flagged for review

#### PE-8: Missing Required Field

- **Condition**: Required JSON field absent
- **Error Code**: ERR_MISSING_FIELD
- **Message**: "Missing required field '${fieldName}' in ${context}"
- **Handling**: Same as PE-5
- **System State**: Fallback to backup

#### PE-9: Backup Creation Failed

- **Condition**: Cannot create backup file
- **Error Code**: ERR_BACKUP_FAILED
- **Message**: "Warning: Could not create backup: ${reason}"
- **Handling**: Log warning, continue with save
- **System State**: Operation continues

#### PE-10: Data Inconsistency Detected

- **Condition**: Loaded data violates invariants
- **Error Code**: ERR_DATA_INCONSISTENCY
- **Message**: "Data inconsistency detected: ${details}"
- **Handling**:
  1. Attempt to repair (e.g., recalculate balances)
  2. If repair fails, load backup
  3. If backup also inconsistent, create new bank
- **System State**: Repaired or fallback state

### 5.1.4 System Errors (SE)

System errors represent unexpected runtime failures, typically at the FFI boundary or in platform services.

#### SE-1: Unexpected Exception

- **Condition**: Uncaught exception in C# FFI
- **Error Code**: ERR_UNEXPECTED
- **Message**: "An unexpected error occurred: ${exception}"
- **Handling**: Log full stack trace, return Failure to Dafny
- **System State**: UNCHANGED (transaction rolled back)

#### SE-2: Timestamp Generation Failed

- **Condition**: System clock unavailable
- **Error Code**: ERR_TIMESTAMP_FAILED
- **Message**: "Could not generate timestamp."
- **Handling**: Use fallback timestamp (last known + 1)
- **System State**: Operation continues with fallback

#### SE-3: UUID Generation Failed

- **Condition**: UUID library fails
- **Error Code**: ERR_UUID_FAILED
- **Message**: "Could not generate transaction ID."
- **Handling**: Use sequential ID fallback
- **System State**: Operation continues with fallback

---

## 5.2 Error Response Format

All errors follow a consistent format to provide clarity and actionability:

```
┌─────────────────────────────────────────┐
│ ERROR: [ERR_CODE]                       │
├─────────────────────────────────────────┤
│ Message: [Detailed error message]      │
│                                         │
│ Suggestion: [Actionable advice]        │
│                                         │
│ System State: [UNCHANGED/Modified]     │
└─────────────────────────────────────────┘
```

### Example Error Display

```
┌─────────────────────────────────────────────────────────┐
│ ERROR: ERR_INSUFFICIENT_FUNDS                           │
├─────────────────────────────────────────────────────────┤
│ Message: Insufficient funds.                            │
│   Balance: $150.00                                      │
│   Required: $200.00                                     │
│                                                         │
│ Suggestion: Enable overdraft protection, or deposit    │
│   an additional $50.00 to complete this transaction.   │
│                                                         │
│ System State: UNCHANGED                                 │
└─────────────────────────────────────────────────────────┘
```

**Format Components:**

1. **Error Code**: Unique identifier (ERR_*) for programmatic handling and documentation lookup
2. **Message**: Detailed description including relevant context (balances, limits, inputs)
3. **Suggestion**: Actionable guidance for the user to resolve the error
4. **System State**: Explicit indication whether the operation modified state or left it unchanged

---

## 5.3 Error Recovery

### Recovery Strategies

The Bank CLI implements category-specific recovery strategies to maintain system integrity and user experience:

#### 1. Validation Errors
**Strategy**: Prompt user for corrected input

- Display error with specific constraint violation
- Re-prompt for input with example of valid format
- Preserve partial progress where applicable
- No system state modification occurs

#### 2. Business Rule Errors
**Strategy**: Suggest alternative actions

- Explain why the operation was rejected
- Calculate and display maximum allowed values
- Suggest enabling features (e.g., overdraft protection)
- Offer alternative operations (e.g., transfer instead of withdraw)
- System state remains UNCHANGED

#### 3. Persistence Errors
**Strategy**: Fallback to backups, continue in-memory

- **File not found**: Initialize new empty bank
- **Read errors**: Attempt backup loading (most recent → older → new bank)
- **Write errors**: Continue with in-memory state, retry on next operation
- **Corruption**: Repair if possible, otherwise load backup
- User notified of fallback state loaded

#### 4. System Errors
**Strategy**: Log, report, graceful degradation

- Log full error details including stack traces
- Return Failure to Dafny (preserves invariants)
- Use fallback mechanisms (e.g., sequential IDs instead of UUIDs)
- Notify user of degraded functionality
- Transaction rolled back if in progress

### Logging Requirements

All errors must be logged to support debugging, auditing, and system monitoring.

**Log File Location**: `/logs/errors.log`

**Log Entry Format**:
```
[TIMESTAMP] [LEVEL] [ERROR_CODE] [CONTEXT] Message
```

**Log Levels**:

- **ERROR**: Critical failures requiring immediate attention (BR, PE, SE errors)
- **WARNING**: Non-critical issues with successful recovery (PE-9, fallback usage)
- **INFO**: Informational messages (PE-1 with new bank creation)

**Context Information**:

- Account ID (when applicable)
- Operation type (Deposit, Withdrawal, Transfer, etc.)
- User input (sanitized)
- Timestamp of operation attempt

**Sensitive Data Handling**:

- Balance amounts: **ERROR level only** (not WARNING/INFO)
- Transaction amounts: **ERROR level only**
- Account IDs: All levels (not considered sensitive)
- Owner names: **ERROR level only**
- Full stack traces: **ERROR level only**

**Example Log Entries**:

```
[2025-10-30T14:23:45Z] [ERROR] [ERR_INSUFFICIENT_FUNDS] [Account:1234, Operation:Withdraw] Insufficient funds. Balance: $150.00, Required: $200.00
[2025-10-30T14:25:12Z] [WARNING] [ERR_BACKUP_FAILED] [Operation:Save] Could not create backup: disk full
[2025-10-30T14:30:00Z] [INFO] [ERR_FILE_NOT_FOUND] [Operation:Load] Data file not found, initialized new empty bank
```

---

## Related Documentation

For comprehensive understanding of the Bank CLI error handling system, refer to these related documents:

- **[FUNCTIONAL_REQUIREMENTS.md](./FUNCTIONAL_REQUIREMENTS.md)**: Detailed specifications of operations that can produce errors, including preconditions and postconditions for deposits, withdrawals, transfers, and account management.

- **[REFERENCE.md](./REFERENCE.md)**: Complete error code reference with quick lookup table, categorization matrix, and cross-references to handling code locations.

- **[REQUIREMENTS_AND_EDGE_CASES.md](../guides/REQUIREMENTS_AND_EDGE_CASES.md)**: Catalog of edge cases and error scenarios with test cases, including boundary conditions, race conditions, and recovery testing.

- **[SPEC.md](../../SPEC.md)**: Complete technical specification including data models, business logic, and formal verification requirements that ensure error handling preserves system invariants.

- **[AI_ASSISTED_GUIDE.md](../AI_ASSISTED_GUIDE.md)**: Guidelines for implementing new error handling with AI assistance, including verification patterns for error paths.

---

**Document Version**: 1.0
**Last Updated**: 2025-10-30
**Extracted From**: SPEC.md Section 5
