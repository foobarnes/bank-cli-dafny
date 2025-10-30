# Requirements and Edge Cases - Verified Bank CLI

**Project:** Verified Bank CLI in Dafny
**Version:** 1.0
**Last Updated:** 2025-10-30

## Table of Contents

1. [Functional Requirements](#functional-requirements)
2. [Non-Functional Requirements](#non-functional-requirements)
3. [Edge Cases Catalog](#edge-cases-catalog)
4. [Boundary Conditions](#boundary-conditions)
5. [Invalid Input Cases](#invalid-input-cases)
6. [Error Recovery Scenarios](#error-recovery-scenarios)
7. [Requirements Traceability](#requirements-traceability)

---

## 1. Functional Requirements

### Account Management (FR-001 to FR-008)
- **FR-001**: System shall support creation of bank accounts with unique IDs
- **FR-002**: System shall store account owner name
- **FR-003**: System shall maintain current balance for each account
- **FR-004**: System shall support initial deposit during account creation
- **FR-005**: System shall prevent duplicate account IDs
- **FR-006**: System shall track account creation timestamp
- **FR-007**: System shall support configurable account limits (max balance, max transaction)
- **FR-008**: System shall support account status (active/suspended)

### Transaction Operations (FR-009 to FR-019)
- **FR-009**: System shall support deposit operations (positive amounts only)
- **FR-010**: System shall update balance immediately upon successful deposit
- **FR-011**: System shall support withdrawal operations
- **FR-012**: System shall verify sufficient funds before withdrawal
- **FR-013**: System shall support overdraft protection when enabled
- **FR-014**: System shall support transfer operations between different accounts
- **FR-015**: System shall ensure atomicity of transfers (all-or-nothing)
- **FR-016**: System shall record timestamp for each transaction
- **FR-017**: System shall assign unique transaction ID to each operation
- **FR-018**: System shall record balance before and after each transaction
- **FR-019**: System shall record transaction description/memo

### Transaction History (FR-020 to FR-028)
- **FR-020**: System shall maintain complete transaction history per account
- **FR-021**: System shall record transaction type (Deposit/Withdrawal/Transfer/Fee)
- **FR-022**: System shall record transaction amount and resulting balance
- **FR-023**: System shall record transaction metadata (ID, status, parent/child links)
- **FR-024**: System shall support querying transaction history by account
- **FR-025**: System shall support limiting number of returned transactions
- **FR-026**: System shall return transactions in chronological order
- **FR-027**: System shall preserve transaction history across restarts
- **FR-028**: System shall support filtering transactions by type

### Overdraft Management (FR-029 to FR-038)
- **FR-029**: System shall support enabling/disabling overdraft per account
- **FR-030**: System shall enforce configurable overdraft limit
- **FR-031**: System shall calculate fees using 4-tier structure:
  - Tier 1: $0.01 - $100.00 → $25.00 fee
  - Tier 2: $100.01 - $500.00 → $35.00 fee
  - Tier 3: $500.01 - $1,000.00 → $50.00 fee
  - Tier 4: $1,000.01+ → $75.00 fee
- **FR-032**: System shall create separate transaction entries for fees
- **FR-033**: System shall link fee transactions to triggering transaction
- **FR-034**: System shall record tier breakdown for overdraft fees
- **FR-035**: System shall automatically deduct fees from account balance
- **FR-036**: System shall prevent withdrawals exceeding overdraft limit
- **FR-037**: System shall show fee calculation before applying
- **FR-038**: System shall track total lifetime fees per account

### Data Persistence (FR-039 to FR-046)
- **FR-039**: System shall persist all account data to JSON files
- **FR-040**: System shall persist all transaction history
- **FR-041**: System shall load existing data on startup
- **FR-042**: System shall save data after each successful transaction
- **FR-043**: System shall create automatic backups
- **FR-044**: System shall handle missing data files gracefully
- **FR-045**: System shall validate loaded data for integrity
- **FR-046**: System shall support rollback on persistence failure

### User Interface (FR-047 to FR-060)
- **FR-047**: System shall provide interactive CLI with 10 menu options
- **FR-048**: System shall validate all user inputs
- **FR-049**: System shall display multi-step progress indicators
- **FR-050**: System shall show loading animations (100-500ms delays)
- **FR-051**: System shall display confirmation for successful operations
- **FR-052**: System shall display clear error messages with suggestions
- **FR-053**: System shall support graceful exit with final verification
- **FR-054**: System shall show verification status after operations
- **FR-055**: System shall handle invalid menu selections
- **FR-056**: System shall support repeating operations without restart
- **FR-057**: System shall display balance with fee breakdown
- **FR-058**: System shall show transaction history with filtering
- **FR-059**: System shall use FFI (Foreign Function Interface) for input
- **FR-060**: System shall display system status and statistics

---

## 2. Non-Functional Requirements

### Verification and Correctness (NFR-001 to NFR-008)
- **NFR-001**: All core operations must be formally verified in Dafny
- **NFR-002**: System must prove balance calculations are correct
- **NFR-003**: System must prove fund conservation (no money creation/destruction)
- **NFR-004**: System must prove fee monotonicity (fees never decrease over time)
- **NFR-005**: System must prove transaction atomicity
- **NFR-006**: All preconditions must be explicitly stated and verified
- **NFR-007**: All postconditions must be explicitly stated and verified
- **NFR-008**: System must prove account invariants are maintained

### Data Integrity (NFR-009 to NFR-014)
- **NFR-009**: System must maintain referential integrity for all operations
- **NFR-010**: System must prevent data corruption during failures
- **NFR-011**: System must ensure account balances are always accurate
- **NFR-012**: System must maintain transaction history consistency
- **NFR-013**: System must validate all data before persistence
- **NFR-014**: System must document concurrent access limitations

### Reliability (NFR-015 to NFR-020)
- **NFR-015**: System must handle all error conditions gracefully
- **NFR-016**: System must not crash on invalid inputs
- **NFR-017**: System must provide rollback capability for failed operations
- **NFR-018**: System must recover from file system errors
- **NFR-019**: System must maintain operation even if persistence fails
- **NFR-020**: System must preserve data integrity across crashes

### Usability (NFR-021 to NFR-025)
- **NFR-021**: All user prompts must be clear and unambiguous
- **NFR-022**: Error messages must be informative and actionable
- **NFR-023**: System must provide feedback for all operations
- **NFR-024**: User interface must be consistent across operations
- **NFR-025**: System must handle user errors without data loss

---

## 3. Edge Cases Catalog

### Account Creation Edge Cases

**Account ID Edge Cases:**
- EC-001: Duplicate account ID (already exists) - MUST REJECT
- EC-002: Account ID = 0 (minimum valid ID) - MUST ACCEPT
- EC-003: Very large account ID (near max int) - MUST ACCEPT
- EC-004: First account in empty system - MUST ACCEPT
- EC-005: Creating account after max accounts reached - MUST REJECT

**Owner Name Edge Cases:**
- EC-006: Empty owner name ("") - MUST REJECT
- EC-007: Very long owner name (1000+ chars) - MUST HANDLE OR REJECT
- EC-008: Owner name with special characters - MUST ACCEPT
- EC-009: Owner name with only whitespace - MUST REJECT
- EC-010: Multiple accounts with identical owner names - MUST ACCEPT

**Initial Deposit Edge Cases:**
- EC-011: Zero initial deposit - DESIGN DECISION (accept or reject)
- EC-012: Negative initial deposit - MUST REJECT
- EC-013: Initial deposit = $0.01 (minimum positive) - MUST ACCEPT
- EC-014: Initial deposit exceeding max balance - MUST REJECT
- EC-015: Initial deposit with fractional cents - MUST HANDLE ROUNDING

### Deposit Edge Cases

**Deposit Amount Edge Cases:**
- EC-016: Depositing $0.00 - MUST REJECT (must be positive)
- EC-017: Depositing $0.01 (minimum positive) - MUST ACCEPT
- EC-018: Negative deposit - MUST REJECT
- EC-019: Deposit would exceed max balance - MUST REJECT
- EC-020: Deposit exactly to max balance - MUST ACCEPT
- EC-021: Deposit exceeding single transaction limit - MUST REJECT

**Deposit Account State Edge Cases:**
- EC-022: Depositing to non-existent account - MUST REJECT
- EC-023: Depositing to suspended account - MUST REJECT
- EC-024: Depositing to account with negative balance - MUST ACCEPT
- EC-025: Depositing to account with zero balance - MUST ACCEPT
- EC-026: Multiple consecutive deposits - MUST ACCEPT ALL

### Withdrawal Edge Cases

**Withdrawal Amount Edge Cases:**
- EC-027: Withdrawing $0.00 - MUST REJECT
- EC-028: Withdrawing $0.01 (minimum positive) - MUST ACCEPT
- EC-029: Negative withdrawal - MUST REJECT
- EC-030: Withdrawing entire balance (balance becomes zero) - MUST ACCEPT
- EC-031: Withdrawing more than balance (no overdraft) - MUST REJECT
- EC-032: Withdrawing amount exceeding transaction limit - MUST REJECT

**Withdrawal with Overdraft Edge Cases:**
- EC-033: Withdrawing exactly to overdraft limit - MUST ACCEPT
- EC-034: Withdrawing one cent over overdraft limit - MUST REJECT
- EC-035: Withdrawing causing exactly $100.00 overdraft (tier boundary) - MUST ACCEPT, FEE = $25
- EC-036: Withdrawing causing exactly $500.00 overdraft (tier boundary) - MUST ACCEPT, FEE = $35
- EC-037: Withdrawing causing exactly $1000.00 overdraft (tier boundary) - MUST ACCEPT, FEE = $50
- EC-038: Withdrawing amount spanning multiple fee tiers - MUST CALCULATE CORRECTLY
- EC-039: Withdrawing when already at max overdraft - MUST REJECT
- EC-040: Overdraft fee itself would cause additional tier charges - MUST HANDLE

### Transfer Edge Cases

**Transfer Participant Edge Cases:**
- EC-041: Transferring from account to itself - MUST REJECT
- EC-042: Transferring from non-existent source - MUST REJECT
- EC-043: Transferring to non-existent destination - MUST REJECT
- EC-044: Transferring when both accounts don't exist - MUST REJECT

**Transfer Amount Edge Cases:**
- EC-045: Transferring $0.00 - MUST REJECT
- EC-046: Transferring $0.01 (minimum positive) - MUST ACCEPT
- EC-047: Transferring entire source balance - MUST ACCEPT
- EC-048: Transferring more than source balance (no overdraft) - MUST REJECT
- EC-049: Transferring would exceed destination max balance - MUST REJECT
- EC-050: Transferring exactly to destination max balance - MUST ACCEPT

**Transfer Atomicity Edge Cases:**
- EC-051: System crash during transfer (before dest credit) - MUST ROLLBACK
- EC-052: System crash after source debit, before dest credit - MUST ROLLBACK
- EC-053: File system full during transfer save - MUST ROLLBACK
- EC-054: Transfer rollback due to persistence failure - MUST RESTORE SOURCE

### Overdraft Fee Calculation Edge Cases

**Tier Boundary Edge Cases:**
- EC-055: Overdraft $0.01 (Tier 1 minimum) - FEE = $25.00
- EC-056: Overdraft $100.00 (Tier 1 maximum) - FEE = $25.00
- EC-057: Overdraft $100.01 (Tier 2 minimum) - FEE = $35.00
- EC-058: Overdraft $500.00 (Tier 2 maximum) - FEE = $35.00
- EC-059: Overdraft $500.01 (Tier 3 minimum) - FEE = $50.00
- EC-060: Overdraft $1000.00 (Tier 3 maximum) - FEE = $50.00
- EC-061: Overdraft $1000.01 (Tier 4 minimum) - FEE = $75.00
- EC-062: Overdraft at max overdraft limit - FEE = APPROPRIATE TIER

**Fee Application Edge Cases:**
- EC-063: Fee application causing balance to go more negative - MUST ACCEPT
- EC-064: Fee application pushing into next tier - COMPLEX CASE, DESIGN DECISION
- EC-065: Zero overdraft amount - NO FEE
- EC-066: Enabling overdraft on account with negative balance - DESIGN DECISION
- EC-067: Disabling overdraft on account with negative balance - MUST REJECT OR ALLOW WITH WARNING

### Transaction History Edge Cases

**History Query Edge Cases:**
- EC-068: Querying history of account with no transactions - RETURN EMPTY
- EC-069: Querying history of non-existent account - MUST REJECT
- EC-070: Requesting more transactions than exist - RETURN ALL AVAILABLE
- EC-071: Requesting zero transactions - RETURN EMPTY
- EC-072: Requesting negative number - MUST REJECT
- EC-073: Querying very large history (10,000+ transactions) - MUST HANDLE EFFICIENTLY

**History Content Edge Cases:**
- EC-074: History containing only deposits - MUST DISPLAY
- EC-075: History containing only withdrawals - MUST DISPLAY
- EC-076: History with transactions at identical timestamps - MUST PRESERVE ORDER
- EC-077: History containing fees from multiple tiers - MUST SHOW BREAKDOWN

### Persistence Edge Cases

**File System Edge Cases:**
- EC-078: Data file doesn't exist on first load - CREATE NEW
- EC-079: Data file is empty - TREAT AS EMPTY SYSTEM
- EC-080: Data file contains malformed JSON - MUST REJECT, OFFER RECOVERY
- EC-081: Data file corrupted - MUST REJECT, ATTEMPT BACKUP RESTORE
- EC-082: Permission denied on read - MUST FAIL GRACEFULLY
- EC-083: Permission denied on write - MUST FAIL GRACEFULLY, KEEP IN-MEMORY
- EC-084: Disk full during save - MUST ROLLBACK, NOTIFY USER
- EC-085: File locked by another process - MUST RETRY OR FAIL GRACEFULLY

**Data Validation Edge Cases:**
- EC-086: Loaded account has negative balance beyond overdraft - MUST REJECT OR WARN
- EC-087: Loaded transaction history inconsistent with balance - MUST REJECT
- EC-088: Loaded data contains duplicate account IDs - MUST REJECT
- EC-089: Loaded account balances violate fund conservation - MUST WARN

### Balance Calculation Edge Cases

**Arithmetic Edge Cases:**
- EC-090: Balance exactly at max balance limit - MUST ACCEPT
- EC-091: Balance calculation resulting in exactly zero - MUST ACCEPT
- EC-092: Balance with maximum precision ($9,999,999.99) - MUST HANDLE
- EC-093: Balance after millions of small transactions - MUST REMAIN ACCURATE
- EC-094: Total system balance after only deposits - MUST EQUAL SUM
- EC-095: Total system balance after only withdrawals (with fees) - MUST ACCOUNT FOR FEES

### User Interface Edge Cases

**Input Validation Edge Cases:**
- EC-096: User enters empty string - MUST REJECT, RE-PROMPT
- EC-097: User enters whitespace only - MUST REJECT, RE-PROMPT
- EC-098: User enters non-numeric for amount - MUST REJECT, RE-PROMPT
- EC-099: User enters non-numeric for account ID - MUST REJECT, RE-PROMPT
- EC-100: User enters amount with dollar sign ($) - STRIP OR REJECT
- EC-101: User enters amount with commas (1,000.00) - STRIP OR REJECT
- EC-102: User enters very large number (overflow) - MUST REJECT
- EC-103: User enters special characters - MUST HANDLE SAFELY

**Menu Navigation Edge Cases:**
- EC-104: User selects invalid menu option - MUST RE-PROMPT
- EC-105: User enters letter instead of number - MUST RE-PROMPT
- EC-106: User presses Enter without input - MUST RE-PROMPT
- EC-107: User interrupts operation (Ctrl+C) - MUST HANDLE GRACEFULLY

---

## 4. Boundary Conditions

### Numeric Boundaries

**Account ID:**
- Minimum: 0
- Maximum: 2^31 - 1 (or system-defined)

**Balance:**
- Minimum (with overdraft): -$1,000.00 (configurable)
- Maximum: $10,000,000.00 (configurable)
- Zero: $0.00

**Transaction Amount:**
- Minimum positive: $0.01
- Maximum: $1,000,000.00 (configurable transaction limit)

**Overdraft Tier Boundaries:**
- Tier 1/2 boundary: $100.00
- Tier 2/3 boundary: $500.00
- Tier 3/4 boundary: $1,000.00

**Fees:**
- Tier 1: $25.00
- Tier 2: $35.00
- Tier 3: $50.00
- Tier 4: $75.00

### String Boundaries

**Owner Name:**
- Minimum length: 1 character (or reject empty)
- Maximum length: 255 characters (configurable)

**Description:**
- Minimum: 0 characters (empty allowed)
- Maximum: 500 characters (configurable)

### Collection Boundaries

**Accounts:**
- Minimum: 0 (empty system)
- Maximum: 10,000 (configurable)

**Transaction History:**
- Minimum: 0 (new account)
- Maximum per account: 100,000 (configurable)

---

## 5. Invalid Input Cases

### Account Creation
- II-001: Account ID as negative number
- II-002: Owner name as null/undefined
- II-003: Initial deposit as string
- II-004: Initial deposit as negative

### Deposit/Withdrawal
- II-005: Account ID doesn't exist
- II-006: Amount as non-numeric string
- II-007: Amount as boolean
- II-008: Amount with more than 2 decimal places
- II-009: Missing required parameters

### Transfer
- II-010: Source and destination IDs identical
- II-011: Source account doesn't exist
- II-012: Destination account doesn't exist
- II-013: Transfer amount negative or zero

### Menu Selection
- II-014: Menu option as string
- II-015: Menu option out of valid range (not 0-9)
- II-016: Empty input

---

## 6. Error Recovery Scenarios

### Transaction Failure Recovery
- ER-001: Rollback after failed deposit due to validation
- ER-002: Rollback after failed withdrawal (insufficient funds)
- ER-003: Rollback after failed transfer (atomicity violation)
- ER-004: Restore account state after rejected operation

### Persistence Failure Recovery
- ER-005: Recovery from file write failure (disk full)
- ER-006: Recovery from permission denied
- ER-007: Recovery from corrupted data file
- ER-008: Restore from backup after data corruption
- ER-009: Continue in-memory when persistence unavailable

### Data Integrity Recovery
- ER-010: Detect and correct balance calculation errors
- ER-011: Recalculate balances from transaction history
- ER-012: Verify and restore fund conservation
- ER-013: Rebuild transaction history from partial data

### System Recovery
- ER-014: Recovery from unexpected system crash
- ER-015: Recovery from power loss
- ER-016: Restore to last known good state

---

## 7. Requirements Traceability

### Account Management
| Requirement | Module | Implementation | Invariant |
|------------|--------|----------------|-----------|
| FR-001 | Account.dfy | Account datatype | UniqueAccountIDs |
| FR-002 | Account.dfy | owner field | - |
| FR-003 | Account.dfy | balance field | BalanceValid |
| FR-005 | Bank.dfy | AccountExists check | UniqueAccountIDs |

### Transactions
| Requirement | Module | Implementation | Invariant |
|------------|--------|----------------|-----------|
| FR-009 | Account.dfy | Deposit method | BalanceIncreases |
| FR-011 | Account.dfy | Withdraw method | SufficientFunds |
| FR-014 | Bank.dfy | Transfer method | FundConservation |
| FR-015 | Bank.dfy | Transfer atomicity | AllOrNothing |

### Overdraft
| Requirement | Module | Implementation | Invariant |
|------------|--------|----------------|-----------|
| FR-031 | OverdraftPolicy.dfy | CalculateFee | FeeMonotonicity |
| FR-032 | Transaction.dfy | Fee transaction type | FeeLinkedToParent |
| FR-036 | Account.dfy | Withdraw precondition | WithinOverdraftLimit |

### Persistence
| Requirement | Module | Implementation | Error Handling |
|------------|--------|----------------|----------------|
| FR-039 | Persistence.dfy | SaveAccounts | FileWriteError |
| FR-041 | Persistence.dfy | LoadData | DataValidation |
| FR-043 | Persistence.dfy | CreateBackup | BackupFailure |

---

## Appendix: Edge Case Priority

### Critical (Must Handle)
- All balance calculation edge cases
- All fund conservation edge cases
- All overdraft limit violations
- All persistence failures
- All data corruption scenarios
- All atomicity violations

### High (Should Handle)
- Boundary conditions for all operations
- Invalid input cases
- User interface edge cases
- Error recovery scenarios

### Medium (Good to Handle)
- Display formatting edge cases
- Performance edge cases
- Unusual state combinations

---

**Document Maintenance:**
- Review quarterly
- Update when requirements change
- Add edge cases as discovered
- Track coverage in test suite

**Last Review:** 2025-10-30
**Next Review:** 2026-01-30
