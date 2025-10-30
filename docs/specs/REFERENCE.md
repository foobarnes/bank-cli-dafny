# Bank CLI Reference

This document contains reference material and appendices extracted from the complete specification. It provides quick access to glossary terms, configuration constants, error codes, JSON schemas, and implementation phases.

For the complete technical specification, see [SPEC.md](/SPEC.md) in the project root.

---

## Appendix A: Glossary

- **Account**: A bank account with owner, balance, and transaction history
- **Transaction**: A record of funds movement (deposit, withdrawal, transfer, fee)
- **Overdraft**: Negative account balance, allowed if protection enabled
- **Overdraft Fee**: Charge assessed when account goes negative
- **Tier**: Range in overdraft fee structure determining fee amount
- **Balance Snapshot**: Balance value before/after a specific transaction
- **Transaction Linkage**: Parent-child relationship between related transactions
- **Fund Conservation**: Property that transfers don't create or destroy money
- **Invariant**: Property that must always hold true about system state
- **Atomic Operation**: Operation that succeeds completely or fails with no effect
- **FFI**: Foreign Function Interface - boundary between Dafny and C#
- **Immutable**: Data structure that cannot be modified after creation

---

## Appendix B: Configuration Constants

```dafny
// Limits
const DEFAULT_MAX_BALANCE: int := 100_000_000;      // $1,000,000
const DEFAULT_MAX_TRANSACTION: int := 10_000_000;   // $100,000
const DEFAULT_OVERDRAFT_LIMIT: int := 100_000;      // $1,000

// Overdraft Tiers (cents)
const TIER_1_MIN: int := 1;
const TIER_1_MAX: int := 10_000;        // $100.00
const TIER_1_FEE: int := 2_500;         // $25.00

const TIER_2_MIN: int := 10_001;
const TIER_2_MAX: int := 50_000;        // $500.00
const TIER_2_FEE: int := 3_500;         // $35.00

const TIER_3_MIN: int := 50_001;
const TIER_3_MAX: int := 100_000;       // $1,000.00
const TIER_3_FEE: int := 5_000;         // $50.00

const TIER_4_MIN: int := 100_001;
const TIER_4_FEE: int := 7_500;         // $75.00

// File Paths
const DATA_FILE: string := "./data/bank.json";
const BACKUP_DIR: string := "./data/backups";
const LOG_DIR: string := "./logs";
const ERROR_LOG: string := "./logs/errors.log";

// UI Delays (ms)
const DELAY_VALIDATION: int := 150;
const DELAY_COMPUTATION: int := 250;
const DELAY_PERSISTENCE: int := 400;

// Limits
const MAX_BACKUPS: int := 10;
const MAX_HISTORY_DISPLAY: int := 1000;
const MAX_OWNER_NAME_LENGTH: int := 100;
const MAX_DESCRIPTION_LENGTH: int := 200;
```

---

## Appendix C: Error Codes Reference

| Code | Category | Description |
|------|----------|-------------|
| ERR_INVALID_AMOUNT | Validation | Amount <= 0 or exceeds limit |
| ERR_ACCOUNT_NOT_FOUND | Validation | Account ID doesn't exist |
| ERR_INVALID_ACCOUNT_ID | Validation | Account ID format invalid |
| ERR_EMPTY_OWNER | Validation | Owner name empty/whitespace |
| ERR_OWNER_TOO_LONG | Validation | Owner name > 100 chars |
| ERR_NEGATIVE_INITIAL_DEPOSIT | Validation | Initial deposit < 0 |
| ERR_INVALID_OVERDRAFT_CONFIG | Validation | Overdraft limit invalid |
| ERR_DESCRIPTION_TOO_LONG | Validation | Description > 200 chars |
| ERR_INSUFFICIENT_FUNDS | Business Rule | Balance < amount, no overdraft |
| ERR_OVERDRAFT_LIMIT_EXCEEDED | Business Rule | Withdrawal exceeds overdraft |
| ERR_MAX_BALANCE_EXCEEDED | Business Rule | Deposit exceeds maxBalance |
| ERR_TRANSACTION_LIMIT_EXCEEDED | Business Rule | Amount > maxTransaction |
| ERR_TRANSFER_SAME_ACCOUNT | Business Rule | Transfer to self |
| ERR_ACCOUNT_SUSPENDED | Business Rule | Account not active |
| ERR_ACCOUNT_CLOSED | Business Rule | Account is closed |
| ERR_OVERDRAWN_CANNOT_DISABLE | Business Rule | Can't disable overdraft while negative |
| ERR_CANNOT_CLOSE_NONZERO | Business Rule | Can't close with balance != 0 |
| ERR_DUPLICATE_ACCOUNT_ID | Business Rule | Account ID already exists |
| ERR_FILE_NOT_FOUND | Persistence | Data file doesn't exist |
| ERR_PERMISSION_DENIED | Persistence | File access denied |
| ERR_DISK_FULL | Persistence | Out of disk space |
| ERR_FILE_LOCKED | Persistence | File locked by other process |
| ERR_CORRUPTED_DATA | Persistence | Data file corrupted |
| ERR_MALFORMED_JSON | Persistence | JSON syntax error |
| ERR_INVALID_TIMESTAMP | Persistence | Timestamp invalid |
| ERR_MISSING_FIELD | Persistence | Required JSON field missing |
| ERR_BACKUP_FAILED | Persistence | Backup creation failed |
| ERR_DATA_INCONSISTENCY | Persistence | Loaded data violates invariants |
| ERR_UNEXPECTED | System | Uncaught exception |
| ERR_TIMESTAMP_FAILED | System | Timestamp generation failed |
| ERR_UUID_FAILED | System | UUID generation failed |

---

## Appendix D: JSON Schema

### Bank JSON Structure

Complete structure for the bank data file:

```json
{
  "accounts": {
    "0": {
      "id": 0,
      "owner": "John Doe",
      "balance": 100000,
      "history": [
        {
          "id": "TX-00001",
          "accountId": 0,
          "txType": {
            "tag": "Deposit"
          },
          "amount": 100000,
          "description": "Initial deposit",
          "timestamp": 1730304000,
          "balanceBefore": 0,
          "balanceAfter": 100000,
          "status": "Completed",
          "parentTxId": null,
          "childTxIds": []
        }
      ],
      "overdraftEnabled": true,
      "overdraftLimit": 50000,
      "maxBalance": 100000000,
      "maxTransaction": 10000000,
      "totalFeesCollected": 0,
      "status": "Active"
    }
  },
  "nextAccountId": 1,
  "lastModified": 1730304000
}
```

### Fee Transaction Example

Example of a fee transaction with detailed overdraft information:

```json
{
  "id": "TX-00043",
  "accountId": 0,
  "txType": {
    "tag": "Fee",
    "category": "OverdraftFee",
    "details": {
      "overdraftAmount": 25000,
      "tier": 2,
      "tierRange": [10001, 50000],
      "calculatedFee": 3500,
      "explanation": "Overdraft of $250.00 falls in Tier 2 ($100.01-$500.00): $35.00 fee"
    }
  },
  "amount": -3500,
  "description": "Overdraft fee - Tier 2",
  "timestamp": 1730304100,
  "balanceBefore": -25000,
  "balanceAfter": -28500,
  "status": "Completed",
  "parentTxId": "TX-00042",
  "childTxIds": []
}
```

---

## Appendix E: Implementation Phases

This section outlines a 6-week implementation plan for the Bank CLI application.

### Phase 1: Core Datatypes (Week 1)
- [ ] Define Transaction, Account, Bank datatypes
- [ ] Implement basic predicates (ValidAccount, ValidBankState)
- [ ] Write unit tests for datatypes
- [ ] Verify compilation to C#

### Phase 2: Business Logic (Week 2)
- [ ] Implement overdraft fee calculation with proofs
- [ ] Implement account operations (deposit, withdraw)
- [ ] Implement transfer with atomicity
- [ ] Write integration tests
- [ ] Verify all invariants

### Phase 3: Validation & Error Handling (Week 3)
- [ ] Implement all validation functions
- [ ] Define all error codes and messages
- [ ] Add error handling to all operations
- [ ] Test error scenarios

### Phase 4: Persistence Layer (Week 4)
- [ ] Implement C# FileStorage with backup
- [ ] Implement JSON serialization
- [ ] Add data validation on load
- [ ] Test save/load roundtrip
- [ ] Test backup recovery

### Phase 5: CLI Interface (Week 5)
- [ ] Implement main menu and navigation
- [ ] Implement all operation flows
- [ ] Add loading animations
- [ ] Add formatted output
- [ ] Test user workflows

### Phase 6: Polish & Documentation (Week 6)
- [ ] Add system health checks
- [ ] Implement startup/shutdown sequences
- [ ] Write README and user guide
- [ ] Create AI_ASSISTED_GUIDE.md
- [ ] Final testing and refinement

---

## Related Documentation

This reference document is part of a comprehensive documentation suite. For additional context and detailed information, see:

- **[ERROR_HANDLING.md](/docs/specs/ERROR_HANDLING.md)** - Detailed error handling patterns and strategies. Provides context for the error codes listed in Appendix C.

- **[DATA_MODELS.md](/docs/specs/DATA_MODELS.md)** - Complete data model specifications and type definitions. Provides detailed context for the JSON schemas in Appendix D.

- **[ARCHITECTURE.md](/docs/specs/ARCHITECTURE.md)** - System architecture and design decisions. Provides context for the implementation phases in Appendix E and explains how components fit together.

- **[SPEC.md](/SPEC.md)** - Complete technical specification document. This is the source of all appendices and contains full context, requirements, and detailed explanations.

- **[REQUIREMENTS_AND_EDGE_CASES.md](/docs/REQUIREMENTS_AND_EDGE_CASES.md)** - Comprehensive catalog of edge cases and requirements that drive the configuration constants and error codes.

- **[AI_ASSISTED_GUIDE.md](/docs/AI_ASSISTED_GUIDE.md)** - Guide for AI-assisted development, useful when implementing the phases outlined in Appendix E.

---

**Document Version**: 1.0
**Last Updated**: 2025-10-30
**Status**: Reference Material
