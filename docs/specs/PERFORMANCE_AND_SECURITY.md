# Bank CLI Performance and Security

## Introduction

This document details the performance requirements and security considerations for the Bank CLI application. Performance and security are intrinsically linked in financial applications: efficient operations reduce attack surfaces by minimizing exposure windows, while security measures must be implemented without degrading user experience. Together, these specifications ensure the Bank CLI is both responsive and trustworthy.

This specification is extracted from the main system specification and provides detailed guidance for implementing performance-critical and security-sensitive features.

---

## Performance Requirements

### Operation Latency

**Target Latencies (95th percentile):**
- Account creation: < 100ms (excluding animation delays)
- Deposit/Withdrawal: < 50ms
- Transfer: < 100ms
- Balance query: < 10ms
- History query (50 txs): < 50ms
- Save to file: < 200ms
- Load from file: < 500ms

**Measurement:**
- Log operation start/end times
- Report in system status display
- Include in session summary

**Implementation Guidance:**
- Operations must complete within their target latencies under normal conditions
- Animation delays (UI feedback) are separate from business logic latency
- Latency measurements should exclude user input time
- Consider the 95th percentile target, allowing for occasional slower operations
- Balance queries are the most frequent operation and must be highly optimized

### Scalability Limits

**Design Targets:**
- Accounts: Up to 10,000
- Transactions per account: Up to 100,000
- Total transactions: Up to 1,000,000
- Data file size: Up to 100 MB
- Backup files: Keep last 10
- Load time: < 5 seconds for 100 MB file

**Constraints:**
- In-memory state (entire bank loaded)
- Sequential operations (no parallelism)
- Single data file

**Future Optimizations:**
- Lazy loading of transaction history
- Database backend for large datasets
- Transaction history pagination
- Archive old transactions

**Implementation Guidance:**
- Design all data structures to scale to the target limits
- Test with datasets approaching maximum size
- Monitor memory usage during development
- Consider degradation characteristics beyond stated limits
- The single data file constraint simplifies consistency but limits horizontal scaling
- Backup rotation (keeping last 10) balances recoverability with disk usage

### Memory Usage

**Target:**
- Base memory: < 50 MB
- Per account: < 5 KB
- Per transaction: < 1 KB
- Total for 1,000 accounts with 10,000 txs: < 500 MB

**Monitoring:**
- Track memory usage in logs
- Report in system status

**Implementation Guidance:**
- Memory targets are conservative to allow headroom for future features
- Base memory includes runtime overhead (Dafny runtime, C# CLR, FFI layer)
- Per-account overhead includes metadata and empty history list
- Per-transaction overhead includes all fields and linkage information
- Test with large datasets to verify memory characteristics
- Consider memory fragmentation over long-running sessions
- Report memory usage in system status for operational awareness

---

## Security Considerations

### Input Sanitization

**Requirements:**
- Trim whitespace from all string inputs
- Limit string lengths (owner: 100, description: 200, path: 1000)
- Remove null bytes and control characters
- Validate numeric inputs within bounds
- Prevent path traversal in file operations

**Implementation:** See `ffi/IO.cs` `SanitizeInput()` method

**Threat Model:**
- Malicious input causing buffer overflows (mitigated by length limits)
- Path traversal attacks accessing unauthorized files (mitigated by path validation)
- Control character injection affecting terminal output (mitigated by sanitization)
- Null byte injection bypassing string validation (mitigated by null removal)

**Best Practices:**
- Sanitize at the FFI boundary before data enters Dafny
- Validate again in Dafny validation layer (defense in depth)
- Whitelist acceptable characters rather than blacklisting dangerous ones
- Log sanitization events for security monitoring
- Reject rather than silently fix invalid input when possible

### Data Integrity

**Mechanisms:**
- Atomic file writes (write to temp, then move)
- Backup before overwrite
- Validation after load
- Checksum verification (future)
- Invariant checks before save

**Atomicity Guarantees:**
- Write to temporary file: `bank.json.tmp`
- Validate written data
- Move temporary file to final location (atomic operation)
- On failure, original file remains unchanged

**Backup Strategy:**
- Create timestamped backup before any save operation
- Keep last 10 backups (configurable via `MAX_BACKUPS`)
- Backup filename format: `bank_backup_YYYYMMDD_HHMMSS.json`
- Store backups in separate directory: `./data/backups/`

**Validation:**
- Verify JSON structure after load
- Check all invariants hold for loaded data
- Validate relationships (transaction linkage, balance consistency)
- Reject and rollback if validation fails

**Future Enhancements:**
- CRC32 or SHA-256 checksums for corruption detection
- Cryptographic signatures for tamper detection
- Incremental backups for large datasets

### Access Control

**Current (v1):**
- No authentication (single-user CLI)
- File system permissions determine access
- No network exposure

**Security Model:**
- Trust the local file system's access control
- Data file owned by user running the CLI
- Standard file permissions (user read/write, no group/other access)
- No password protection on data file (relies on OS-level authentication)

**Assumptions:**
- User has physical or secure remote access to the machine
- Operating system enforces user isolation
- No untrusted users have access to the file system
- User is responsible for securing their account on the OS

**Future Considerations:**
- User authentication within the CLI
- Account ownership verification (multi-user mode)
- Audit logging of all operations
- Encryption at rest (symmetric encryption of data file)
- Role-based access control for administrative operations
- Integration with OS keychain/credential manager

**Multi-User Future Design:**
- User authentication before accessing the CLI
- Each account tied to specific user(s)
- Audit log recording user, timestamp, operation, outcome
- Separation between user accounts (account isolation)

### Error Information Disclosure

**Requirements:**
- Don't expose file system paths in user-facing errors
- Don't expose sensitive data in logs (balance amounts in ERROR only)
- Sanitize error messages from exceptions
- Use error codes instead of stack traces

**Information Leakage Prevention:**

**File System Paths:**
```
BAD:  "Error: Cannot open /home/alice/.bank/bank.json"
GOOD: "Error: Cannot access data file (ERR_FILE_NOT_FOUND)"
```

**Balance Information:**
```
BAD:  [INFO] Account 42 balance: $50,000
GOOD: [INFO] Account 42 balance query completed
```
- Only log balance amounts at ERROR level when diagnosing issues
- Use INFO level for operation success without sensitive data

**Exception Details:**
```
BAD:  "NullReferenceException at Bank.cs:142 in ProcessWithdrawal()"
GOOD: "Internal error during withdrawal (ERR_UNEXPECTED)"
```

**Error Code Strategy:**
- All user-facing errors use error codes (see Appendix C in SPEC.md)
- Error codes are stable across versions
- Detailed error information goes to logs, not user output
- Stack traces only in debug/development mode

**Logging Levels:**
- `DEBUG`: Full details, including sensitive data (never in production)
- `INFO`: Operation type, timestamp, success/failure (no sensitive data)
- `WARN`: Recoverable errors, validation failures (minimal data)
- `ERROR`: Unrecoverable errors, invariant violations (necessary data only)

**User-Facing Messages:**
- Clear, actionable error messages
- Explain what went wrong in user terms
- Suggest remediation steps when possible
- Include error code for support reference
- Never expose implementation details

**Example Error Message:**
```
Transaction failed: Insufficient funds in account #42

Your current balance is insufficient for this withdrawal.
Please check your balance and try again with a smaller amount.

Error Code: ERR_INSUFFICIENT_FUNDS
```

---

## Performance-Security Tradeoffs

Understanding the balance between performance and security is critical:

### Input Validation
- **Performance Impact**: Each input validation adds latency
- **Security Benefit**: Prevents invalid data from entering the system
- **Tradeoff**: Validate once at FFI boundary (performance) vs. multiple layers (security)
- **Decision**: Two-layer validation (FFI + Dafny) for critical inputs

### Backup Strategy
- **Performance Impact**: Creating backups adds ~50-100ms per save
- **Security Benefit**: Recovery from corruption or accidental overwrites
- **Tradeoff**: Backup every save vs. periodic backups
- **Decision**: Backup every save (security priority)

### Logging Verbosity
- **Performance Impact**: Excessive logging slows operations
- **Security Benefit**: Audit trail for forensics
- **Tradeoff**: Minimal logging (performance) vs. comprehensive logging (security)
- **Decision**: Structured logging with appropriate levels

### Memory Constraints
- **Performance Impact**: In-memory operations are fast but memory-limited
- **Security Benefit**: Smaller attack surface than database
- **Tradeoff**: Performance via in-memory vs. scalability via database
- **Decision**: In-memory for v1, plan migration path for larger datasets

---

## Testing Requirements

### Performance Testing
- [ ] Measure operation latencies under various dataset sizes
- [ ] Test with maximum account count (10,000)
- [ ] Test with maximum transactions per account (100,000)
- [ ] Load test with 100 MB data file
- [ ] Profile memory usage during typical operations
- [ ] Benchmark save/load times
- [ ] Test concurrent backup creation (if future parallelism added)

### Security Testing
- [ ] Fuzzing input validation with malformed inputs
- [ ] Test path traversal attempts in file operations
- [ ] Verify error messages don't leak sensitive data
- [ ] Test atomic write failure scenarios
- [ ] Verify backup restoration works correctly
- [ ] Test invariant violations are caught on load
- [ ] Verify file permissions are set correctly
- [ ] Test with corrupted JSON files
- [ ] Verify null byte and control character removal

### Integration Testing
- [ ] Load large dataset and verify performance targets met
- [ ] Simulate disk full during save operation
- [ ] Test recovery from interrupted save
- [ ] Verify backup rotation (11th backup deletes oldest)
- [ ] Test file locking scenarios
- [ ] Measure end-to-end transaction latency
- [ ] Verify all error codes are handled correctly

---

## Monitoring and Observability

### Performance Metrics
- Operation latency (per operation type)
- Memory usage (current, peak, per account/transaction)
- File I/O times (save, load, backup)
- Data file size
- Backup count and total size
- Session duration and operation count

### Security Metrics
- Input validation rejections (count, type)
- File access errors (count, type)
- Invariant violations detected (count, severity)
- Backup failures (count, reason)
- Error code frequency (histogram)
- Sanitization events (count, type)

### System Health Indicators
- Average operation latency trend
- Memory growth rate
- File size growth rate
- Error rate trend
- Backup success rate
- Validation failure rate

---

## Configuration Constants

Relevant performance and security constants from SPEC.md:

```dafny
// Performance Limits
const DEFAULT_MAX_BALANCE: int := 100_000_000;      // $1,000,000
const DEFAULT_MAX_TRANSACTION: int := 10_000_000;   // $100,000
const DEFAULT_OVERDRAFT_LIMIT: int := 100_000;      // $1,000

// Scalability Limits
const MAX_BACKUPS: int := 10;
const MAX_HISTORY_DISPLAY: int := 1000;

// Security Limits
const MAX_OWNER_NAME_LENGTH: int := 100;
const MAX_DESCRIPTION_LENGTH: int := 200;

// File Paths (for path validation)
const DATA_FILE: string := "./data/bank.json";
const BACKUP_DIR: string := "./data/backups";
const LOG_DIR: string := "./logs";
const ERROR_LOG: string := "./logs/errors.log";

// UI Delays (ms) - separate from business logic latency
const DELAY_VALIDATION: int := 150;
const DELAY_COMPUTATION: int := 250;
const DELAY_PERSISTENCE: int := 400;
```

---

## Implementation Checklist

### Performance Implementation
- [ ] Implement operation timing measurement
- [ ] Add memory usage tracking
- [ ] Optimize balance queries (most frequent operation)
- [ ] Test with maximum dataset sizes
- [ ] Add performance metrics to system status
- [ ] Profile and optimize hot paths
- [ ] Document performance characteristics

### Security Implementation
- [ ] Implement input sanitization at FFI boundary
- [ ] Add length validation for all string inputs
- [ ] Implement atomic file writes
- [ ] Add backup-before-save mechanism
- [ ] Implement invariant validation on load
- [ ] Sanitize all error messages
- [ ] Add error code system
- [ ] Set appropriate file permissions
- [ ] Implement path traversal prevention
- [ ] Add logging with appropriate levels

---

## Related Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture and component design considerations, including performance implications of design decisions
- **[ERROR_HANDLING.md](./ERROR_HANDLING.md)** - Comprehensive error handling specification with security-conscious error reporting
- **[FUNCTIONAL_REQUIREMENTS.md](./FUNCTIONAL_REQUIREMENTS.md)** - Functional requirements including performance-critical operations and their specifications
- **[../SPEC.md](../../SPEC.md)** - Complete system specification (this document extracts Sections 9 and 10)
- **[../../CLAUDE.md](../../CLAUDE.md)** - Development guide with Dafny verification patterns
- **[../REQUIREMENTS_AND_EDGE_CASES.md](../REQUIREMENTS_AND_EDGE_CASES.md)** - Edge case catalog including performance and security edge cases

---

## Appendix: Performance Optimization Patterns

### Dafny-Specific Optimizations

**1. Avoid Redundant Sequence Operations:**
```dafny
// BAD: Multiple passes
var total := 0;
for i := 0 to |transactions| {
  total := total + transactions[i].amount;
}
var validated := [];
for i := 0 to |transactions| {
  if transactions[i].status == "Completed" {
    validated := validated + [transactions[i]];
  }
}

// GOOD: Single pass
var total := 0;
var validated := [];
for i := 0 to |transactions| {
  var tx := transactions[i];
  total := total + tx.amount;
  if tx.status == "Completed" {
    validated := validated + [tx];
  }
}
```

**2. Use Assertions to Guide Verifier:**
```dafny
method ProcessAccount(account: Account)
  requires ValidAccount(account)
{
  assert account.balance == ComputeBalance(account.history);
  // Verifier now knows balance is correct, avoiding recomputation
  // ... rest of method
}
```

**3. Lemmas for Expensive Proofs:**
```dafny
// Prove once, reuse many times
lemma BalanceNeverExceedsMax(account: Account)
  requires ValidAccount(account)
  ensures account.balance <= account.maxBalance
{
  // Proof here
}

method Deposit(account: Account, amount: int)
  requires ValidAccount(account)
{
  BalanceNeverExceedsMax(account); // Use proven property
  // ... deposit logic
}
```

---

## Appendix: Security Checklist

### Pre-Release Security Audit
- [ ] All inputs sanitized at FFI boundary
- [ ] No hardcoded credentials or secrets
- [ ] File permissions set to user-only (0600)
- [ ] Error messages don't leak paths or sensitive data
- [ ] Logging levels appropriate for production
- [ ] Backup mechanism tested and verified
- [ ] Atomic writes implemented correctly
- [ ] All invariants checked on load
- [ ] Path traversal prevention tested
- [ ] Input length limits enforced
- [ ] Null byte handling verified
- [ ] Control character sanitization verified
- [ ] Error code system complete
- [ ] Documentation updated with security guidance

### Ongoing Security Practices
- [ ] Regular dependency updates
- [ ] Security-focused code reviews
- [ ] Penetration testing (as appropriate)
- [ ] User security guidance in README
- [ ] Incident response plan
- [ ] Security vulnerability disclosure process

---

*This document is maintained as part of the Bank CLI specification suite. Last updated: 2025-10-30*
