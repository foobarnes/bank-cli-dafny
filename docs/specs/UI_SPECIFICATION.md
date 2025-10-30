# Bank CLI User Interface Specification

## Introduction

This document specifies the user interface design for the Verified Bank CLI application. The CLI is designed with a focus on clarity, user feedback, and educational transparency about the formal verification process. The interface provides progressive disclosure through interactive menus, detailed operation flows with loading indicators, and comprehensive feedback at each step.

The UI design emphasizes:
- **Clarity**: Clear prompts, validation feedback, and result displays
- **Transparency**: Visible verification steps to build trust in the formal methods
- **Feedback**: Real-time progress indicators and detailed operation results
- **Safety**: Confirmation of all state changes with invariant verification
- **Education**: Exposure of verification concepts through the interface

All UI operations are backed by formally verified Dafny code, ensuring that every displayed state transition is mathematically proven correct.

---

## Table of Contents

1. [CLI Architecture](#1-cli-architecture)
2. [Main Menu](#2-main-menu)
3. [Operation Flows](#3-operation-flows)
   - 3.1 [Create Account Flow](#31-create-account-flow)
   - 3.2 [Withdrawal Flow (with Overdraft)](#32-withdrawal-flow-with-overdraft)
   - 3.3 [Transfer Flow](#33-transfer-flow)
   - 3.4 [Transaction History Flow](#34-transaction-history-flow)
4. [Loading Animations](#4-loading-animations)
5. [System Status Display](#5-system-status-display)
6. [Startup Sequence](#6-startup-sequence)
7. [Shutdown Sequence](#7-shutdown-sequence)
8. [Related Documentation](#8-related-documentation)

---

## 1. CLI Architecture

### Execution Model
Interactive menu-driven interface with Foreign Function Interface (FFI) for input/output operations.

### Application Flow

The CLI follows a continuous loop pattern:

1. **System startup and health checks** - Verify all data and invariants on load
2. **Display main menu** - Present all available operations
3. **Accept user choice** - Validate input and route to operation
4. **Execute operation with progress feedback** - Show verification steps in real-time
5. **Display result with confirmation** - Present detailed results and state changes
6. **Return to menu** - Allow user to continue or exit
7. **Repeat until exit** - Continue operation loop

### Key Design Principles

- **Atomic Operations**: Every operation is all-or-nothing with rollback on failure
- **Progressive Disclosure**: Complex operations broken into clear steps
- **Verification Visibility**: Show the formal verification process to users
- **Error Recovery**: Clear error messages with actionable guidance
- **State Consistency**: Always return to a verified, consistent state

---

## 2. Main Menu

The main menu is the central hub of the application, providing access to all banking operations.

```
╔════════════════════════════════════════════════════════╗
║          VERIFIED BANK CLI - MAIN MENU                 ║
║                                                        ║
║  All operations are formally verified for correctness  ║
╚════════════════════════════════════════════════════════╝

Available Operations:

  1. Create New Account
  2. List All Accounts
  3. Deposit Funds
  4. Withdraw Funds
  5. Transfer Between Accounts
  6. Check Account Balance
  7. View Transaction History
  8. Configure Overdraft Protection
  9. System Status & Health Check
  0. Exit

Enter your choice (0-9): _
```

### Menu Features

- **Box Drawing Characters**: Use Unicode box drawing for visual hierarchy
- **Operation Numbering**: Single-digit choices (0-9) for quick access
- **Verification Badge**: Remind users of formal verification guarantee
- **Input Prompt**: Clear cursor position indicator
- **Invalid Input Handling**: Re-prompt on invalid choice with error message

---

## 3. Operation Flows

### 3.1 Create Account Flow

The account creation flow demonstrates multi-step input collection, validation, and verification feedback.

```
┌─ Create New Account ─────────────────────────────────┐
│                                                       │
│ Enter account owner name: John Doe                    │
│ ✓ Valid name (8 characters)                          │
│                                                       │
│ Enter initial deposit ($): 1000.00                    │
│ ✓ Valid amount ($1,000.00)                           │
│                                                       │
│ Enable overdraft protection? (y/n): y                │
│ Enter overdraft limit ($): 500.00                     │
│ ✓ Valid limit ($500.00)                              │
│                                                       │
├─ Creating Account ───────────────────────────────────┤
│                                                       │
│ ⟳ Step 1/7: Validating input...                      │
│ ✓ Step 2/7: Generating account ID...                 │
│ ✓ Step 3/7: Creating account structure...            │
│ ✓ Step 4/7: Recording initial deposit...             │
│ ✓ Step 5/7: Verifying balance integrity...           │
│ ✓ Step 6/7: Persisting to storage...                 │
│ ✓ Step 7/7: Creating backup...                       │
│                                                       │
├─ SUCCESS ────────────────────────────────────────────┤
│                                                       │
│ Account Created Successfully!                         │
│                                                       │
│   Account ID: 42                                      │
│   Owner: John Doe                                     │
│   Initial Balance: $1,000.00                          │
│   Overdraft: Enabled (Limit: $500.00)                │
│   Available Balance: $1,500.00                        │
│                                                       │
│   ✓ All invariants verified                          │
│   ✓ Transaction recorded (TX-00001)                  │
│   ✓ Data persisted and backed up                     │
│                                                       │
└───────────────────────────────────────────────────────┘

Press Enter to continue...
```

#### Flow Characteristics

- **Incremental Validation**: Each input is validated immediately with visual feedback
- **Conditional Inputs**: Overdraft limit only requested if protection is enabled
- **Progress Steps**: Show all 7 verification steps during account creation
- **Comprehensive Summary**: Display all account details and verification status
- **Transaction Receipt**: Provide transaction ID for record-keeping

---

### 3.2 Withdrawal Flow (with Overdraft)

This flow demonstrates overdraft detection, fee calculation, and multi-transaction processing.

```
┌─ Withdraw Funds ─────────────────────────────────────┐
│                                                       │
│ Enter account ID: 42                                  │
│ ✓ Account found: John Doe                            │
│   Current Balance: $150.00                           │
│   Available: $650.00 (includes $500.00 overdraft)    │
│                                                       │
│ Enter withdrawal amount ($): 400.00                   │
│ ✓ Valid amount ($400.00)                             │
│                                                       │
│ Description (optional): ATM withdrawal                │
│                                                       │
├─ Processing Withdrawal ──────────────────────────────┤
│                                                       │
│ ⟳ Step 1/9: Validating transaction...                │
│ ⚠ Step 2/9: Checking funds...                        │
│   └─ Overdraft required: $250.00                     │
│ ✓ Step 3/9: Calculating overdraft fee...             │
│   └─ Tier 2 fee: $35.00                              │
│ ✓ Step 4/9: Processing withdrawal...                 │
│ ✓ Step 5/9: Assessing overdraft fee...               │
│ ✓ Step 6/9: Updating balance...                      │
│ ✓ Step 7/9: Verifying invariants...                  │
│ ✓ Step 8/9: Recording transactions...                │
│ ✓ Step 9/9: Persisting changes...                    │
│                                                       │
├─ SUCCESS ────────────────────────────────────────────┤
│                                                       │
│ Withdrawal Completed                                  │
│                                                       │
│   Withdrawal Amount: -$400.00                         │
│   Overdraft Fee: -$35.00 (Tier 2)                    │
│   ──────────────────────────────                      │
│   Total Debited: -$435.00                             │
│                                                       │
│   Balance: $150.00 → -$285.00                         │
│   Overdraft Usage: $285.00 / $500.00 (57%)           │
│                                                       │
│   Transactions:                                       │
│     • TX-00042: Withdrawal                            │
│     • TX-00043: Overdraft Fee (linked)                │
│                                                       │
│   ✓ All invariants verified                          │
│   ✓ Data persisted and backed up                     │
│                                                       │
│ ⚠ NOTE: Account is now overdrawn. Deposit funds to   │
│   avoid additional fees.                              │
│                                                       │
└───────────────────────────────────────────────────────┘

Press Enter to continue...
```

#### Flow Characteristics

- **Context Display**: Show current balance and available funds before withdrawal
- **Warning Indicators**: Use ⚠ symbol to highlight overdraft conditions
- **Fee Transparency**: Display fee calculation details (tier and amount)
- **Transaction Linking**: Show relationship between withdrawal and fee transactions
- **Balance Visualization**: Use arrow notation (→) to show state transitions
- **Usage Metrics**: Display overdraft usage as percentage of limit
- **Actionable Warning**: Provide clear guidance to avoid future fees

---

### 3.3 Transfer Flow

The transfer flow demonstrates atomic multi-account operations with fund conservation verification.

```
┌─ Transfer Between Accounts ──────────────────────────┐
│                                                       │
│ Enter source account ID: 42                           │
│ ✓ Account found: John Doe                            │
│   Balance: $1,500.00                                  │
│                                                       │
│ Enter destination account ID: 17                      │
│ ✓ Account found: Jane Smith                          │
│   Balance: $250.00                                    │
│                                                       │
│ Enter transfer amount ($): 800.00                     │
│ ✓ Valid amount ($800.00)                             │
│                                                       │
│ Description (optional): Rent payment                  │
│                                                       │
├─ Processing Transfer ────────────────────────────────┤
│                                                       │
│ ⟳ Step 1/8: Validating transaction...                │
│ ✓ Step 2/8: Checking source funds...                 │
│ ✓ Step 3/8: Checking destination limits...           │
│ ✓ Step 4/8: Creating linked transactions...          │
│ ✓ Step 5/8: Updating balances atomically...          │
│ ✓ Step 6/8: Verifying fund conservation...           │
│ ✓ Step 7/8: Recording in both accounts...            │
│ ✓ Step 8/8: Persisting changes...                    │
│                                                       │
├─ SUCCESS ────────────────────────────────────────────┤
│                                                       │
│ Transfer Completed Successfully                       │
│                                                       │
│   Amount Transferred: $800.00                         │
│   Description: Rent payment                           │
│                                                       │
│   From Account #42 (John Doe):                       │
│     Balance: $1,500.00 → $700.00                     │
│     Transaction: TX-00055 (Transfer Out)              │
│                                                       │
│   To Account #17 (Jane Smith):                       │
│     Balance: $250.00 → $1,050.00                     │
│     Transaction: TX-00056 (Transfer In)               │
│                                                       │
│   ✓ Transactions linked (TX-00055 ↔ TX-00056)       │
│   ✓ Funds conserved (verified)                       │
│   ✓ All invariants verified                          │
│   ✓ Data persisted and backed up                     │
│                                                       │
└───────────────────────────────────────────────────────┘

Press Enter to continue...
```

#### Flow Characteristics

- **Dual Account Display**: Show both source and destination account information
- **Atomic Operation**: Emphasize both accounts are updated together
- **Fund Conservation**: Explicitly verify that total funds are preserved
- **Transaction Linkage**: Display bidirectional link symbol (↔) between transactions
- **Parallel State Changes**: Show before/after for both accounts simultaneously
- **Mathematical Guarantee**: Highlight that fund conservation is formally verified

---

### 3.4 Transaction History Flow

The history view demonstrates filtering, pagination, and detailed transaction display.

```
┌─ Transaction History ────────────────────────────────┐
│                                                       │
│ Enter account ID: 42                                  │
│ ✓ Account found: John Doe                            │
│                                                       │
│ Filter by type? (y/n): y                              │
│   1. Deposit                                          │
│   2. Withdrawal                                       │
│   3. Transfer In                                      │
│   4. Transfer Out                                     │
│   5. Fee                                              │
│   6. All types                                        │
│ Select type (1-6): 6                                  │
│                                                       │
│ Filter by date range? (y/n): n                        │
│                                                       │
│ Number of transactions to show (max 1000): 10        │
│                                                       │
├─ Loading History ────────────────────────────────────┤
│ ⟳ Retrieving transactions...                         │
│ ✓ Found 47 transactions, showing most recent 10      │
│                                                       │
├─ TRANSACTION HISTORY ───────────────────────────────┤
│                                                       │
│ Account #42: John Doe                                 │
│ Current Balance: $700.00                              │
│ Total Transactions: 47                                │
│ Total Fees Collected: $105.00                         │
│                                                       │
├──────────────────────────────────────────────────────┤
│                                                       │
│ [10] 2025-10-30 14:32:15                             │
│   Transfer Out → Account #17                          │
│   Amount: -$800.00                                    │
│   Description: Rent payment                           │
│   Balance: $1,500.00 → $700.00                       │
│   TX-00055 ↔ TX-00056                                │
│   ✓ Verified                                          │
│                                                       │
│ [9] 2025-10-30 10:15:42                              │
│   Deposit                                             │
│   Amount: +$500.00                                    │
│   Description: Paycheck deposit                       │
│   Balance: $1,000.00 → $1,500.00                     │
│   TX-00054                                            │
│   ✓ Verified                                          │
│                                                       │
│ [8] 2025-10-29 16:20:33                              │
│   Fee (Overdraft - Tier 2)                           │
│   Amount: -$35.00                                     │
│   Triggered by: TX-00042 (Withdrawal)                │
│   Details:                                            │
│     • Overdraft: $250.00                             │
│     • Tier: 2 ($100.01 - $500.00)                    │
│     • Fee: $35.00                                     │
│   Balance: -$250.00 → -$285.00                       │
│   TX-00043 (parent: TX-00042)                        │
│   ✓ Verified                                          │
│                                                       │
│ [7] 2025-10-29 16:20:33                              │
│   Withdrawal                                          │
│   Amount: -$400.00                                    │
│   Description: ATM withdrawal                         │
│   Balance: $150.00 → -$250.00                        │
│   TX-00042 → TX-00043 (fee)                          │
│   ⚠ Triggered overdraft                              │
│   ✓ Verified                                          │
│                                                       │
│ [showing 4 of 10, press 'n' for next, 'q' to quit]   │
│                                                       │
└───────────────────────────────────────────────────────┘
```

#### Flow Characteristics

- **Progressive Filtering**: Allow optional filters for type and date range
- **Transaction Metadata**: Display comprehensive account summary at top
- **Reverse Chronological Order**: Most recent transactions first
- **Rich Transaction Details**: Include timestamps, amounts, descriptions, and linkage
- **Fee Detail Expansion**: Show complete fee calculation for fee transactions
- **Visual Indicators**: Use → for transfers, ↔ for linked transactions
- **Pagination Controls**: Support navigation through large transaction sets
- **Verification Badge**: Confirm each transaction is formally verified

---

## 4. Loading Animations

Loading animations provide user feedback during multi-step operations and emphasize the thoroughness of the verification process.

### Animation Symbols

| Symbol | Meaning | Usage |
|--------|---------|-------|
| `⟳` | Processing/Rotating | Operation currently in progress |
| `✓` | Success/Checkmark | Step completed successfully |
| `⚠` | Warning/Attention | Step completed but requires attention |
| `✗` | Error/Cross | Step failed (operation will rollback) |

### Timing Guidelines

| Operation Type | Duration | Purpose |
|----------------|----------|---------|
| Validation steps | 100-200ms | Input checking and business rule validation |
| Computation steps | 200-300ms | Balance calculations, fee computations |
| Persistence steps | 300-500ms | File I/O and backup operations |
| Minimum display | 100ms | Ensure user can see instant operations |

### Design Principles

1. **User Feedback**: Prevent perception of system hang during operations
2. **Educational Value**: Expose the verification process to build trust
3. **Progressive Disclosure**: Show steps sequentially rather than all at once
4. **Psychological Pacing**: Create sense of thoroughness and care
5. **Verification Visibility**: Make the formal verification process tangible

### Example Animation Sequence

```
⟳ Step 1/5: Validating input...
✓ Step 1/5: Validating input...
⟳ Step 2/5: Processing transaction...
✓ Step 2/5: Processing transaction...
⟳ Step 3/5: Verifying invariants...
✓ Step 3/5: Verifying invariants...
⟳ Step 4/5: Persisting changes...
✓ Step 4/5: Persisting changes...
⟳ Step 5/5: Creating backup...
✓ Step 5/5: Creating backup...
```

---

## 5. System Status Display

The system status display provides comprehensive health information and verification status.

```
╔════════════════════════════════════════════════════════╗
║              SYSTEM STATUS & HEALTH CHECK              ║
╚════════════════════════════════════════════════════════╝

Bank State:
  ✓ Total Accounts: 42
  ✓ Total Balance: $125,450.75
  ✓ Active Accounts: 39
  ✓ Suspended Accounts: 2
  ✓ Closed Accounts: 1

Verification Status:
  ✓ All account balances valid
  ✓ All transaction histories consistent
  ✓ All account limits within bounds
  ✓ All transaction links valid
  ✓ Fund conservation verified

Persistence:
  ✓ Data file: /data/bank.json (125 KB)
  ✓ Last saved: 2025-10-30 14:32:17
  ✓ Backup count: 10
  ✓ Latest backup: /data/backups/bank_20251030_143217.json

Performance:
  ✓ Average operation time: 0.15s
  ✓ Total transactions: 1,247
  ✓ Total fees collected: $2,840.00

Invariants:
  ✓ INV-1: Balance Integrity
  ✓ INV-2: Balance Computation Consistency
  ✓ INV-3: Fee Monotonicity
  ✓ INV-4: Transaction Linkage
  ✓ INV-5: Fund Conservation
  ✓ INV-6: Account Limits
  ✓ INV-7: History Ordering
  ✓ INV-8: Bank State Consistency

System Status: HEALTHY ✓

Press Enter to continue...
```

### Status Categories

1. **Bank State**: High-level metrics about accounts and balances
2. **Verification Status**: Confirmation that all data integrity checks pass
3. **Persistence**: File system and backup information
4. **Performance**: Operation metrics and statistics
5. **Invariants**: Explicit listing of all verified formal properties

### Use Cases

- **System Diagnostics**: Identify potential issues before they cause problems
- **Audit Trail**: Document that system maintains correctness
- **Educational**: Expose the invariants being verified
- **Performance Monitoring**: Track operation efficiency over time

---

## 6. Startup Sequence

The startup sequence demonstrates data loading, validation, and verification on system initialization.

```
╔════════════════════════════════════════════════════════╗
║         VERIFIED BANK CLI v1.0                         ║
║    Formal Verification Powered by Dafny                ║
╚════════════════════════════════════════════════════════╝

Initializing...

⟳ Loading data file...
✓ Data file loaded: /data/bank.json

⟳ Parsing JSON...
✓ JSON parsed successfully

⟳ Validating account data...
✓ All 42 accounts valid

⟳ Verifying balances...
✓ All balances consistent with history

⟳ Checking transaction links...
✓ All transaction links valid

⟳ Verifying invariants...
✓ All invariants hold

⟳ Preparing user interface...
✓ CLI ready

╔════════════════════════════════════════════════════════╗
║              STARTUP COMPLETE                          ║
║                                                        ║
║  All data verified and ready for use.                  ║
║  System is in a provably correct state.                ║
╚════════════════════════════════════════════════════════╝

Press Enter to continue to main menu...
```

### Startup Steps

1. **Load Data File**: Read JSON from file system
2. **Parse JSON**: Deserialize into Dafny datatypes
3. **Validate Account Data**: Check all accounts meet structural requirements
4. **Verify Balances**: Confirm balance equals computed value from history
5. **Check Transaction Links**: Validate all transaction relationships
6. **Verify Invariants**: Prove all critical properties hold
7. **Prepare UI**: Initialize CLI components

### Error Handling

If any startup step fails, the system:
1. Displays the failure with details
2. Attempts to load from most recent backup
3. If backup also fails, starts with empty state
4. Logs all errors for investigation

---

## 7. Shutdown Sequence

The shutdown sequence ensures data persistence, backup creation, and session reporting.

```
╔════════════════════════════════════════════════════════╗
║              SHUTTING DOWN                             ║
╚════════════════════════════════════════════════════════╝

⟳ Verifying final state...
✓ All invariants hold

⟳ Saving data...
✓ Data saved to /data/bank.json

⟳ Creating backup...
✓ Backup created: /data/backups/bank_20251030_150000.json

⟳ Generating session report...
✓ Report saved to /logs/session_20251030_150000.log

╔════════════════════════════════════════════════════════╗
║              SESSION SUMMARY                           ║
║                                                        ║
║  Session Duration: 25 minutes                          ║
║  Operations Performed: 7                               ║
║    • Created accounts: 2                               ║
║    • Deposits: 3                                       ║
║    • Withdrawals: 1                                    ║
║    • Transfers: 1                                      ║
║                                                        ║
║  Verification:                                         ║
║    ✓ All operations verified                          ║
║    ✓ No invariant violations                          ║
║    ✓ Data persisted successfully                      ║
║                                                        ║
║  Thank you for using Verified Bank CLI!                ║
╚════════════════════════════════════════════════════════╝
```

### Shutdown Steps

1. **Verify Final State**: Confirm all invariants before saving
2. **Save Data**: Write current state to primary data file
3. **Create Backup**: Generate timestamped backup copy
4. **Generate Session Report**: Log all operations performed during session

### Session Summary Contents

- **Session Duration**: Total time system was active
- **Operation Counts**: Breakdown of operations by type
- **Verification Status**: Confirmation of correctness throughout session
- **Persistence Status**: Confirmation data is safely stored

### Safety Guarantees

- Data is never written unless all invariants hold
- Backup is always created before exit
- Session log provides complete audit trail
- Graceful degradation if shutdown steps fail

---

## 8. Related Documentation

This UI Specification is part of a comprehensive documentation suite for the Verified Bank CLI. For complete understanding of the system, please refer to these related documents:

### Core Specifications

- **[SPEC.md](/Users/chandler/Workspace/playground/bank-cli-dafny/SPEC.md)** - Complete technical specification for the entire system, including all sections referenced in this document

### Related Specification Documents

- **FUNCTIONAL_REQUIREMENTS.md** - Detailed functional requirements for all features exposed through this UI (Section 2 of SPEC.md)
- **ERROR_HANDLING.md** - Error handling specifications including all error messages displayed in the UI (Section 5 of SPEC.md)
- **ARCHITECTURE.md** - Implementation architecture including CLI module design and FFI boundaries (Section 7 of SPEC.md)

### Development Guides

- **[REQUIREMENTS_AND_EDGE_CASES.md](/Users/chandler/Workspace/playground/bank-cli-dafny/docs/REQUIREMENTS_AND_EDGE_CASES.md)** - Catalog of edge cases that affect UI flows
- **[AI_ASSISTED_GUIDE.md](/Users/chandler/Workspace/playground/bank-cli-dafny/docs/AI_ASSISTED_GUIDE.md)** - Guide for AI-assisted development of UI components
- **[CLAUDE.md](/Users/chandler/Workspace/playground/bank-cli-dafny/CLAUDE.md)** - Development workflow guide including UI testing procedures

### Implementation Files

- **src/CLI.dfy** - CLI module implementation of this specification
- **ffi/IO.cs** - C# FFI for ReadLine/WriteLine operations
- **ffi/LoadingAnimations.cs** - Loading animation implementation

---

## Document Metadata

- **Version**: 1.0
- **Last Updated**: 2025-10-30
- **Source**: Extracted from SPEC.md Section 6
- **Maintained By**: Documentation Engineering
- **Status**: Living Document

---

*This specification is part of a formally verified banking system. All UI operations are backed by mathematical proofs of correctness implemented in Dafny.*
