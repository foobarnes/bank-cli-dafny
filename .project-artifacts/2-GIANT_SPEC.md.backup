# Verified Bank CLI System Specification

**Version:** 1.0
**Last Updated:** 2025-10-30
**Status:** Final Specification

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Functional Requirements](#2-functional-requirements)
3. [Data Models](#3-data-models)
4. [Verification Requirements](#4-verification-requirements)
5. [Error Handling Specifications](#5-error-handling-specifications)
6. [User Interface Specifications](#6-user-interface-specifications)
7. [Implementation Architecture](#7-implementation-architecture)
8. [Testing Strategy](#8-testing-strategy)
9. [Performance Requirements](#9-performance-requirements)
10. [Security Considerations](#10-security-considerations)

---

## 1. System Overview

### 1.1 Purpose

The Verified Bank CLI is an educational banking system implementation in Dafny that demonstrates formal verification techniques applied to a real-world user-friendly application. The system provides a complete banking experience with mathematical guarantees about correctness, safety, and consistency.

### 1.2 Goals

- **Educational Value**: Showcase formal verification in a practical, understandable context
- **Real-World Design**: Implement features users expect from modern banking systems
- **Mathematical Guarantees**: Prove critical invariants about account balances, transaction integrity, and fund conservation
- **User-Friendly Interface**: Provide an interactive CLI with helpful feedback and error messages

### 1.3 Technology Stack

- **Core Language**: Dafny 4.x
- **FFI Language**: C# (.NET 6.0+)
- **Data Format**: JSON
- **Runtime**: Dafny compiled to C#

### 1.4 Scope

**In Scope:**
- Single-user account management
- Basic banking operations (deposit, withdrawal, transfer)
- Overdraft protection with tiered fees
- Transaction history tracking
- File-based persistence with backup/recovery
- Interactive CLI with input validation

**Out of Scope:**
- Multi-user authentication/authorization
- Network/distributed transactions
- Multiple currency support (USD only)
- Interest calculation automation
- Scheduled/recurring transactions
- Credit card or loan accounts
- Regulatory compliance features

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

## 3. Data Models

### 3.1 Core Datatypes

#### 3.1.1 Transaction

```dafny
datatype Transaction = Transaction(
  id: string,
  accountId: nat,
  txType: TransactionType,
  amount: int,  // in cents, can be negative for debits/fees
  description: string,
  timestamp: nat,  // Unix epoch seconds
  balanceBefore: int,  // snapshot before transaction
  balanceAfter: int,   // snapshot after transaction
  status: TransactionStatus,
  parentTxId: Option<string>,      // for linked transactions (transfers, fees)
  childTxIds: seq<string>          // for parent transactions
)
```

**Field Specifications:**

- **id**: UUID v4 or sequential string ("TX-00001")
  - Must be unique across all transactions in all accounts
  - Immutable after creation

- **accountId**: Natural number
  - References owning account
  - Must exist in bank's account map

- **txType**: See TransactionType below
  - Determines how amount is interpreted
  - Affects balance calculation direction

- **amount**: Integer in cents
  - Positive for credits (deposits, transfers in)
  - Negative for debits (withdrawals, transfers out, fees)
  - Zero not allowed for user-initiated transactions

- **description**: String (max 200 characters)
  - User-provided or system-generated
  - Required for user transactions, auto-generated for fees

- **timestamp**: Natural number (Unix seconds)
  - Must be monotonically increasing within account history
  - Set at transaction creation time
  - Same timestamp for linked transactions (transfer pairs)

- **balanceBefore/balanceAfter**: Integer in cents
  - Snapshots for audit trail
  - Invariant: `balanceAfter = balanceBefore + amount`
  - Allows verification of balance computation

- **status**: See TransactionStatus below
  - Tracks transaction lifecycle
  - Immutable for completed/failed transactions

- **parentTxId**: Optional string
  - Set for fee transactions (points to triggering transaction)
  - Set for transfer components (points to other half)
  - None for standalone transactions

- **childTxIds**: Sequence of strings
  - Set for transactions that spawn fees
  - Set for transfer parent transactions
  - Empty for leaf transactions

#### 3.1.2 TransactionType

```dafny
datatype TransactionType =
  | Deposit
  | Withdrawal
  | TransferIn
  | TransferOut
  | Fee(category: FeeCategory, details: FeeDetails)
  | Interest
  | Adjustment  // for corrections, config changes
```

**Type Descriptions:**

- **Deposit**: Funds added to account
  - Amount always positive
  - Increases balance

- **Withdrawal**: Funds removed from account
  - Amount always negative
  - Decreases balance
  - May trigger overdraft fee

- **TransferIn**: Funds received from another account
  - Amount always positive
  - Has parentTxId pointing to TransferOut in source account

- **TransferOut**: Funds sent to another account
  - Amount always negative
  - Has parentTxId pointing to TransferIn in destination account
  - May trigger overdraft fee

- **Fee**: System-assessed charge
  - Amount always negative
  - Has category and details
  - Has parentTxId pointing to triggering transaction

- **Interest**: Interest credited to account
  - Amount always positive
  - For future use (not auto-calculated in v1)

- **Adjustment**: Manual correction or configuration change
  - Amount can be positive or negative
  - Requires description with reason

#### 3.1.3 FeeCategory

```dafny
datatype FeeCategory =
  | OverdraftFee
  | MaintenanceFee
  | TransferFee
  | ATMFee
  | InsufficientFundsFee
```

**Category Usage (v1):**

- **OverdraftFee**: Used when withdrawal/transfer causes negative balance
- **InsufficientFundsFee**: Reserved for failed transaction attempts
- Others reserved for future use

#### 3.1.4 FeeDetails

```dafny
datatype FeeDetails = FeeDetails(
  overdraftAmount: int,      // amount overdrawn (positive)
  tier: nat,                 // 1-4 for tiered fees
  tierRange: (int, int),     // (min, max) for tier
  calculatedFee: int,        // fee amount (positive)
  explanation: string        // human-readable breakdown
)
```

**Example:**
```dafny
FeeDetails(
  overdraftAmount := 37550,  // $375.50
  tier := 2,
  tierRange := (10001, 50000),  // $100.01 - $500.00
  calculatedFee := 3500,         // $35.00
  explanation := "Overdraft of $375.50 falls in Tier 2 ($100.01-$500.00): $35.00 fee"
)
```

#### 3.1.5 TransactionStatus

```dafny
datatype TransactionStatus =
  | Pending
  | Completed
  | Failed
  | Reversed
```

**Status Lifecycle:**

- **Pending**: Transaction initiated, not yet finalized (reserved for future async)
- **Completed**: Successfully executed and recorded
- **Failed**: Attempted but rejected (validation/business rule failure)
- **Reversed**: Previously completed, now undone (reserved for future)

#### 3.1.6 Account

```dafny
datatype Account = Account(
  id: nat,
  owner: string,
  balance: int,  // in cents, can be negative if overdraft enabled
  history: seq<Transaction>,
  overdraftEnabled: bool,
  overdraftLimit: int,  // in cents, must be >= 0
  maxBalance: int,      // in cents, must be > 0
  maxTransaction: int,  // in cents, must be > 0
  totalFeesCollected: int,  // lifetime fees, in cents, monotonic
  status: AccountStatus
)
```

**Field Specifications:**

- **id**: Natural number
  - Unique across all accounts
  - Auto-generated sequentially
  - Immutable

- **owner**: String (1-100 characters)
  - Non-empty, non-whitespace
  - Can contain letters, numbers, spaces, hyphens
  - Immutable (use Adjustment transaction for name changes)

- **balance**: Integer in cents
  - Can be negative if overdraftEnabled
  - Computed from history (cached for performance)
  - Invariant: `balance == ComputeBalanceFromHistory(history)`

- **history**: Sequence of transactions
  - Append-only (immutability)
  - Ordered by timestamp ascending
  - Contains complete audit trail

- **overdraftEnabled**: Boolean
  - True if overdraft protection active
  - Can be toggled (see FR-9)

- **overdraftLimit**: Integer in cents
  - Maximum allowed negative balance
  - Must be ≥ 0
  - Ignored if overdraftEnabled = false
  - Can be changed while overdraft enabled

- **maxBalance**: Integer in cents
  - Maximum allowed positive balance
  - Default: $1,000,000 (100,000,000 cents)
  - Prevents overflow issues

- **maxTransaction**: Integer in cents
  - Maximum single transaction amount
  - Default: $100,000 (10,000,000 cents)
  - Applied to withdrawals and transfers

- **totalFeesCollected**: Integer in cents
  - Running total of all fees assessed
  - Monotonically increasing
  - For reporting/statistics

- **status**: AccountStatus
  - Controls account availability

#### 3.1.7 AccountStatus

```dafny
datatype AccountStatus =
  | Active
  | Suspended
  | Closed
```

**Status Effects:**

- **Active**: All operations allowed
- **Suspended**: Read-only, no transactions
- **Closed**: No operations allowed, balance must be 0

#### 3.1.8 Bank

```dafny
datatype Bank = Bank(
  accounts: map<nat, Account>,
  nextAccountId: nat,
  lastModified: nat  // Unix timestamp
)
```

**Field Specifications:**

- **accounts**: Map from account ID to Account
  - Immutable map (functional updates)
  - All account IDs must be < nextAccountId

- **nextAccountId**: Natural number
  - Next ID to assign
  - Monotonically increasing
  - Ensures ID uniqueness

- **lastModified**: Unix timestamp
  - Updated on every bank operation
  - For optimistic locking (future)

### 3.2 Helper Datatypes

#### 3.2.1 Result<T>

```dafny
datatype Result<T> =
  | Success(value: T)
  | Failure(error: string)
```

**Usage**: All bank operations return Result<T> for error handling.

#### 3.2.2 Option<T>

```dafny
datatype Option<T> =
  | Some(value: T)
  | None
```

**Usage**: For optional fields (parentTxId, filters, etc.).

### 3.3 Overdraft Tier Configuration

```dafny
const OVERDRAFT_TIERS: seq<(int, int, int)> := [
  (1, 10000, 2500),        // Tier 1: $0.01-$100.00 → $25.00
  (10001, 50000, 3500),    // Tier 2: $100.01-$500.00 → $35.00
  (50001, 100000, 5000),   // Tier 3: $500.01-$1000.00 → $50.00
  (100001, INT_MAX, 7500)  // Tier 4: $1000.01+ → $75.00
]
```

**Tuple Format**: `(minCents, maxCents, feeCents)`

### 3.4 Default Limits

```dafny
const DEFAULT_MAX_BALANCE: int := 100_000_000;      // $1,000,000
const DEFAULT_MAX_TRANSACTION: int := 10_000_000;   // $100,000
const DEFAULT_OVERDRAFT_LIMIT: int := 100_000;      // $1,000
```

---

## 4. Verification Requirements

### 4.1 Core Invariants

#### INV-1: Balance Integrity

**Invariant:**
```dafny
predicate ValidAccountBalance(a: Account)
{
  if a.overdraftEnabled then
    a.balance >= -a.overdraftLimit
  else
    a.balance >= 0
}
```

**Verification Points:**
- After every deposit
- After every withdrawal
- After every transfer
- After fee assessment
- After account creation

**Proof Obligations:**
- All operations maintain this invariant
- Overdraft limit changes preserve invariant

#### INV-2: Balance Computation Consistency

**Invariant:**
```dafny
predicate BalanceMatchesHistory(a: Account)
{
  a.balance == ComputeBalanceFromHistory(a.history)
}

function ComputeBalanceFromHistory(history: seq<Transaction>): int
{
  if |history| == 0 then 0
  else history[|history|-1].balanceAfter
}
```

**Verification Points:**
- After every transaction
- After loading from persistence
- During account validation

**Proof Obligations:**
- Transaction history is append-only
- Balance snapshots are accurate
- No gaps or inconsistencies in history

#### INV-3: Fee Monotonicity

**Invariant:**
```dafny
predicate FeesNeverDecrease(a: Account)
{
  a.totalFeesCollected >= 0 &&
  forall i, j :: 0 <= i < j < |a.history| &&
    a.history[i].txType.Fee? && a.history[j].txType.Fee? ==>
    GetTotalFeesAtIndex(a.history, j) >= GetTotalFeesAtIndex(a.history, i)
}
```

**Verification Points:**
- After fee assessment
- After account modification

**Proof Obligations:**
- totalFeesCollected only increases
- Fee transactions always have negative amounts
- Fee amounts match tier calculation

#### INV-4: Transaction Linkage

**Invariant:**
```dafny
predicate ValidTransactionLinks(a: Account)
{
  forall tx :: tx in a.history ==>
    (tx.parentTxId.Some? ==>
      exists parent :: parent in a.history && parent.id == tx.parentTxId.value &&
                       tx.id in parent.childTxIds) &&
    (|tx.childTxIds| > 0 ==>
      forall childId :: childId in tx.childTxIds ==>
        exists child :: child in a.history && child.id == childId &&
                       child.parentTxId == Some(tx.id))
}
```

**Verification Points:**
- After creating linked transactions (transfers, fees)
- During transaction validation

**Proof Obligations:**
- Parent-child relationships are bidirectional
- No orphaned transactions
- No circular references

#### INV-5: Fund Conservation (Transfers)

**Invariant:**
```dafny
predicate TransferConservesFunds(
  fromAccount: Account,
  toAccount: Account,
  fromAccountOld: Account,
  toAccountOld: Account,
  amount: int,
  fee: int
)
{
  fromAccount.balance == fromAccountOld.balance - amount - fee &&
  toAccount.balance == toAccountOld.balance + amount
}
```

**Verification Points:**
- After every transfer operation

**Proof Obligations:**
- Total funds in system unchanged (excluding fees)
- Both accounts updated atomically
- Fee only assessed on from account

#### INV-6: Account Limits

**Invariant:**
```dafny
predicate AccountWithinLimits(a: Account)
{
  a.balance <= a.maxBalance &&
  a.overdraftLimit >= 0 &&
  a.maxBalance > 0 &&
  a.maxTransaction > 0 &&
  a.maxTransaction <= a.maxBalance
}
```

**Verification Points:**
- After account creation
- After limit changes
- After every transaction

**Proof Obligations:**
- Deposits don't exceed maxBalance
- Withdrawals/transfers respect maxTransaction
- Limit configuration is valid

#### INV-7: Transaction History Ordering

**Invariant:**
```dafny
predicate HistoryProperlyOrdered(a: Account)
{
  forall i, j :: 0 <= i < j < |a.history| ==>
    a.history[i].timestamp <= a.history[j].timestamp
}
```

**Verification Points:**
- After appending transactions
- After loading from file

**Proof Obligations:**
- Timestamps monotonically increasing
- Concurrent transactions (same timestamp) preserve order

#### INV-8: Bank Account Map Consistency

**Invariant:**
```dafny
predicate ValidBankState(b: Bank)
{
  (forall id :: id in b.accounts.Keys ==> id < b.nextAccountId) &&
  (forall a :: a in b.accounts.Values ==> ValidAccountBalance(a) &&
                                          BalanceMatchesHistory(a))
}
```

**Verification Points:**
- After every bank operation
- After loading from file

**Proof Obligations:**
- No account ID ≥ nextAccountId
- All accounts valid
- nextAccountId never decreases

### 4.2 Preconditions and Postconditions

#### 4.2.1 Deposit

**Preconditions:**
```dafny
method Deposit(accountId: nat, amount: int, description: string)
  returns (r: Result<Transaction>)
  requires amount > 0
  requires accountId in bank.accounts.Keys
  requires bank.accounts[accountId].status == Active
  requires bank.accounts[accountId].balance + amount <=
           bank.accounts[accountId].maxBalance
```

**Postconditions:**
```dafny
  ensures r.Success? ==>
    var newAccount := bank'.accounts[accountId];
    newAccount.balance == old(bank.accounts[accountId].balance) + amount &&
    |newAccount.history| == |old(bank.accounts[accountId].history)| + 1 &&
    ValidAccountBalance(newAccount) &&
    BalanceMatchesHistory(newAccount)
```

#### 4.2.2 Withdrawal

**Preconditions:**
```dafny
method Withdraw(accountId: nat, amount: int, description: string)
  returns (r: Result<(Transaction, Option<Transaction>)>)
  requires amount > 0
  requires amount <= bank.accounts[accountId].maxTransaction
  requires accountId in bank.accounts.Keys
  requires bank.accounts[accountId].status == Active
  requires var a := bank.accounts[accountId];
    if a.overdraftEnabled then
      a.balance - amount >= -a.overdraftLimit
    else
      a.balance - amount >= 0
```

**Postconditions:**
```dafny
  ensures r.Success? ==>
    var newAccount := bank'.accounts[accountId];
    var (withdrawal, maybeFee) := r.value;
    var totalDebit := amount + (if maybeFee.Some? then -maybeFee.value.amount else 0);
    newAccount.balance == old(bank.accounts[accountId].balance) - totalDebit &&
    ValidAccountBalance(newAccount) &&
    BalanceMatchesHistory(newAccount) &&
    (maybeFee.Some? ==>
      maybeFee.value.parentTxId == Some(withdrawal.id) &&
      withdrawal.id in newAccount.history[|newAccount.history|-2].childTxIds)
```

#### 4.2.3 Transfer

**Preconditions:**
```dafny
method Transfer(fromId: nat, toId: nat, amount: int, description: string)
  returns (r: Result<(Transaction, Transaction, Option<Transaction>)>)
  requires amount > 0
  requires fromId != toId
  requires fromId in bank.accounts.Keys
  requires toId in bank.accounts.Keys
  requires bank.accounts[fromId].status == Active
  requires bank.accounts[toId].status == Active
  requires amount <= bank.accounts[fromId].maxTransaction
  requires bank.accounts[toId].balance + amount <= bank.accounts[toId].maxBalance
  requires var a := bank.accounts[fromId];
    if a.overdraftEnabled then
      a.balance - amount >= -a.overdraftLimit
    else
      a.balance - amount >= 0
```

**Postconditions:**
```dafny
  ensures r.Success? ==>
    var (txOut, txIn, maybeFee) := r.value;
    var newFrom := bank'.accounts[fromId];
    var newTo := bank'.accounts[toId];
    var fee := if maybeFee.Some? then -maybeFee.value.amount else 0;
    TransferConservesFunds(newFrom, newTo,
                          old(bank.accounts[fromId]),
                          old(bank.accounts[toId]),
                          amount, fee) &&
    ValidAccountBalance(newFrom) &&
    ValidAccountBalance(newTo) &&
    txOut.parentTxId == Some(txIn.id) &&
    txIn.parentTxId == Some(txOut.id)
```

### 4.3 Termination

**Requirement:** All methods must provably terminate.

**Strategies:**
- Use bounded loops with explicit decreases clauses
- Avoid recursion where possible (use iteration)
- Sequence operations on bounded sequences
- File I/O through FFI (trusted, no proof obligation)

**Example:**
```dafny
method ComputeTotalFees(history: seq<Transaction>) returns (total: int)
  ensures total >= 0
  decreases |history|
{
  total := 0;
  var i := 0;
  while i < |history|
    invariant 0 <= i <= |history|
    invariant total >= 0
    decreases |history| - i
  {
    if history[i].txType.Fee? {
      total := total + (-history[i].amount);  // fees are negative
    }
    i := i + 1;
  }
}
```

### 4.4 Proof Strategies

#### 4.4.1 Balance Integrity

**Strategy:** Induction on transaction history

**Base Case:** New account with initial deposit
- Balance = initial deposit ≥ 0
- If overdraft enabled, limit > 0, so balance ≥ -limit

**Inductive Step:** Given valid account, after transaction
- Deposit: balance increases, stays valid
- Withdrawal: precondition ensures post-withdrawal balance ≥ minimum
- Fee: already overdrawn, fee doesn't violate limit (proven separately)

#### 4.4.2 Fee Calculation Correctness

**Theorem:**
```dafny
lemma FeeCalculationCorrect(overdraftAmount: int)
  requires overdraftAmount > 0
  ensures var fee := CalculateOverdraftFee(overdraftAmount);
    fee == GetTierFee(GetTier(overdraftAmount))
```

**Proof Approach:**
- Case analysis on overdraftAmount ranges
- Show tier determination is exhaustive and exclusive
- Verify fee lookup matches tier

#### 4.4.3 Atomicity

**Strategy:** Result type with ghost state

**Approach:**
- All operations return Result<T>
- On Failure, ghost state shows bank unchanged
- On Success, ghost state shows valid state transition

**Example:**
```dafny
method TransferAtomic(fromId: nat, toId: nat, amount: int)
  returns (r: Result<...>)
  ensures r.Failure? ==> bank' == old(bank)
  ensures r.Success? ==> ValidBankState(bank')
```

---

## 5. Error Handling Specifications

### 5.1 Error Categories

#### 5.1.1 Validation Errors (VE)

**VE-1: Invalid Amount**
- **Condition**: amount ≤ 0 for deposit/withdrawal/transfer
- **Error Code**: ERR_INVALID_AMOUNT
- **Message**: "Amount must be positive. Received: ${amount}"
- **Suggestion**: "Please enter an amount greater than zero."

**VE-2: Account Not Found**
- **Condition**: accountId not in bank.accounts.Keys
- **Error Code**: ERR_ACCOUNT_NOT_FOUND
- **Message**: "Account ID ${accountId} does not exist."
- **Suggestion**: "Use 'List Accounts' to see available accounts."

**VE-3: Invalid Account ID Format**
- **Condition**: User input cannot parse to nat
- **Error Code**: ERR_INVALID_ACCOUNT_ID
- **Message**: "Account ID must be a non-negative integer. Received: '${input}'"
- **Suggestion**: "Please enter a valid account number (e.g., 1, 2, 3)."

**VE-4: Empty Owner Name**
- **Condition**: owner is empty or whitespace-only
- **Error Code**: ERR_EMPTY_OWNER
- **Message**: "Account owner name cannot be empty."
- **Suggestion**: "Please enter a valid owner name (1-100 characters)."

**VE-5: Owner Name Too Long**
- **Condition**: |owner| > 100
- **Error Code**: ERR_OWNER_TOO_LONG
- **Message**: "Owner name exceeds maximum length of 100 characters."
- **Suggestion**: "Please shorten the name to 100 characters or less."

**VE-6: Negative Initial Deposit**
- **Condition**: initialDeposit < 0
- **Error Code**: ERR_NEGATIVE_INITIAL_DEPOSIT
- **Message**: "Initial deposit cannot be negative. Received: ${amount}"
- **Suggestion**: "Please enter a non-negative amount (minimum $0.00)."

**VE-7: Invalid Overdraft Configuration**
- **Condition**: overdraftEnabled = true but overdraftLimit ≤ 0
- **Error Code**: ERR_INVALID_OVERDRAFT_CONFIG
- **Message**: "Overdraft limit must be positive when overdraft is enabled."
- **Suggestion**: "Please specify a limit greater than $0.00, or disable overdraft."

**VE-8: Description Too Long**
- **Condition**: |description| > 200
- **Error Code**: ERR_DESCRIPTION_TOO_LONG
- **Message**: "Description exceeds maximum length of 200 characters."
- **Suggestion**: "Please shorten the description to 200 characters or less."

#### 5.1.2 Business Rule Errors (BR)

**BR-1: Insufficient Funds**
- **Condition**: balance - amount < 0 and !overdraftEnabled
- **Error Code**: ERR_INSUFFICIENT_FUNDS
- **Message**: "Insufficient funds. Balance: ${balance}, Required: ${amount}"
- **Suggestion**: "Enable overdraft protection, or deposit additional funds."
- **System State**: UNCHANGED

**BR-2: Overdraft Limit Exceeded**
- **Condition**: balance - amount < -overdraftLimit
- **Error Code**: ERR_OVERDRAFT_LIMIT_EXCEEDED
- **Message**: "Withdrawal would exceed overdraft limit. Balance: ${balance}, Limit: ${limit}, Requested: ${amount}"
- **Suggestion**: "Maximum withdrawal: ${maxWithdrawal}"
- **System State**: UNCHANGED

**BR-3: Balance Exceeds Maximum**
- **Condition**: balance + amount > maxBalance
- **Error Code**: ERR_MAX_BALANCE_EXCEEDED
- **Message**: "Deposit would exceed maximum balance of ${maxBalance}."
- **Suggestion**: "Maximum deposit: ${maxDeposit}"
- **System State**: UNCHANGED

**BR-4: Transaction Exceeds Limit**
- **Condition**: amount > maxTransaction
- **Error Code**: ERR_TRANSACTION_LIMIT_EXCEEDED
- **Message**: "Transaction amount ${amount} exceeds limit of ${maxTransaction}."
- **Suggestion**: "Please split into multiple transactions."
- **System State**: UNCHANGED

**BR-5: Transfer to Same Account**
- **Condition**: fromId == toId
- **Error Code**: ERR_TRANSFER_SAME_ACCOUNT
- **Message**: "Cannot transfer funds to the same account."
- **Suggestion**: "Please select a different destination account."
- **System State**: UNCHANGED

**BR-6: Account Suspended**
- **Condition**: account.status == Suspended
- **Error Code**: ERR_ACCOUNT_SUSPENDED
- **Message**: "Account ${accountId} is suspended. No transactions allowed."
- **Suggestion**: "Contact support to reactivate the account."
- **System State**: UNCHANGED

**BR-7: Account Closed**
- **Condition**: account.status == Closed
- **Error Code**: ERR_ACCOUNT_CLOSED
- **Message**: "Account ${accountId} is closed."
- **Suggestion**: "Create a new account to perform transactions."
- **System State**: UNCHANGED

**BR-8: Cannot Disable Overdraft While Overdrawn**
- **Condition**: Attempting to disable overdraft when balance < 0
- **Error Code**: ERR_OVERDRAWN_CANNOT_DISABLE
- **Message**: "Cannot disable overdraft while account is overdrawn. Current balance: ${balance}"
- **Suggestion**: "Deposit funds to bring balance to $0.00 or higher first."
- **System State**: UNCHANGED

**BR-9: Cannot Close Account With Non-Zero Balance**
- **Condition**: Attempting to close account when balance != 0
- **Error Code**: ERR_CANNOT_CLOSE_NONZERO
- **Message**: "Cannot close account with non-zero balance: ${balance}"
- **Suggestion**: "Withdraw or transfer all funds before closing."
- **System State**: UNCHANGED

**BR-10: Duplicate Account ID**
- **Condition**: Attempting to create account with existing ID (internal error)
- **Error Code**: ERR_DUPLICATE_ACCOUNT_ID
- **Message**: "Account ID ${accountId} already exists. This is a system error."
- **Suggestion**: "Please contact support."
- **System State**: UNCHANGED

#### 5.1.3 Persistence Errors (PE)

**PE-1: File Not Found**
- **Condition**: Data file doesn't exist at startup
- **Error Code**: ERR_FILE_NOT_FOUND
- **Message**: "Data file not found: ${filepath}"
- **Handling**: Create new empty bank, log info message
- **System State**: New empty bank initialized

**PE-2: Permission Denied**
- **Condition**: Cannot read/write data file due to permissions
- **Error Code**: ERR_PERMISSION_DENIED
- **Message**: "Permission denied accessing file: ${filepath}"
- **Suggestion**: "Check file permissions and user access rights."
- **System State**: Operation aborted, use in-memory state

**PE-3: Disk Full**
- **Condition**: Cannot write to disk (out of space)
- **Error Code**: ERR_DISK_FULL
- **Message**: "Cannot save data: disk is full."
- **Suggestion**: "Free up disk space and try again."
- **System State**: In-memory state preserved, save retried on next operation

**PE-4: File Locked**
- **Condition**: Another process has file open exclusively
- **Error Code**: ERR_FILE_LOCKED
- **Message**: "Data file is locked by another process."
- **Suggestion**: "Close other instances of the application."
- **System State**: Operation retried with exponential backoff

**PE-5: Corrupted Data File**
- **Condition**: JSON parsing fails or data validation fails
- **Error Code**: ERR_CORRUPTED_DATA
- **Message**: "Data file is corrupted: ${details}"
- **Handling**:
  1. Attempt to load most recent backup
  2. If backup also corrupted, load second-most recent
  3. If all backups fail, create new empty bank
- **System State**: Best available state loaded, user notified

**PE-6: Malformed JSON**
- **Condition**: JSON syntax error
- **Error Code**: ERR_MALFORMED_JSON
- **Message**: "Invalid JSON syntax in data file: ${parseError}"
- **Handling**: Same as PE-5
- **System State**: Fallback to backup

**PE-7: Invalid Timestamp**
- **Condition**: Timestamp in future or before epoch
- **Error Code**: ERR_INVALID_TIMESTAMP
- **Message**: "Invalid timestamp in transaction ${txId}: ${timestamp}"
- **Handling**: Skip transaction, log warning, continue loading
- **System State**: Partial load, flagged for review

**PE-8: Missing Required Field**
- **Condition**: Required JSON field absent
- **Error Code**: ERR_MISSING_FIELD
- **Message**: "Missing required field '${fieldName}' in ${context}"
- **Handling**: Same as PE-5
- **System State**: Fallback to backup

**PE-9: Backup Creation Failed**
- **Condition**: Cannot create backup file
- **Error Code**: ERR_BACKUP_FAILED
- **Message**: "Warning: Could not create backup: ${reason}"
- **Handling**: Log warning, continue with save
- **System State**: Operation continues

**PE-10: Data Inconsistency Detected**
- **Condition**: Loaded data violates invariants
- **Error Code**: ERR_DATA_INCONSISTENCY
- **Message**: "Data inconsistency detected: ${details}"
- **Handling**:
  1. Attempt to repair (e.g., recalculate balances)
  2. If repair fails, load backup
  3. If backup also inconsistent, create new bank
- **System State**: Repaired or fallback state

#### 5.1.4 System Errors (SE)

**SE-1: Unexpected Exception**
- **Condition**: Uncaught exception in C# FFI
- **Error Code**: ERR_UNEXPECTED
- **Message**: "An unexpected error occurred: ${exception}"
- **Handling**: Log full stack trace, return Failure to Dafny
- **System State**: UNCHANGED (transaction rolled back)

**SE-2: Timestamp Generation Failed**
- **Condition**: System clock unavailable
- **Error Code**: ERR_TIMESTAMP_FAILED
- **Message**: "Could not generate timestamp."
- **Handling**: Use fallback timestamp (last known + 1)
- **System State**: Operation continues with fallback

**SE-3: UUID Generation Failed**
- **Condition**: UUID library fails
- **Error Code**: ERR_UUID_FAILED
- **Message**: "Could not generate transaction ID."
- **Handling**: Use sequential ID fallback
- **System State**: Operation continues with fallback

### 5.2 Error Response Format

All errors follow consistent format:

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

**Example:**
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

### 5.3 Error Recovery

**Recovery Strategies:**

1. **Validation Errors**: Prompt user for corrected input
2. **Business Rule Errors**: Suggest alternative actions
3. **Persistence Errors**: Fallback to backups, continue in-memory
4. **System Errors**: Log, report, graceful degradation

**Logging Requirements:**

- All errors logged to `/logs/errors.log`
- Format: `[TIMESTAMP] [LEVEL] [ERROR_CODE] [CONTEXT] Message`
- Levels: ERROR, WARNING, INFO
- Context includes: account ID, operation type, user input
- Sensitive data (balances) only in ERROR level, not WARNING/INFO

---

## 6. User Interface Specifications

### 6.1 CLI Architecture

**Execution Model:** Interactive menu with FFI for input/output

**Flow:**
1. System startup and health checks
2. Display main menu
3. Accept user choice
4. Execute operation with progress feedback
5. Display result with confirmation
6. Return to menu
7. Repeat until exit

### 6.2 Main Menu

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

### 6.3 Operation Flows

#### 6.3.1 Create Account Flow

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

#### 6.3.2 Withdrawal Flow (with Overdraft)

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

#### 6.3.3 Transfer Flow

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

#### 6.3.4 Transaction History Flow

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

### 6.4 Loading Animations

**Spinner Styles:**
- `⟳` rotating for processing
- `✓` checkmark for completed steps
- `⚠` warning for attention items
- `✗` cross for errors

**Timing:**
- Validation steps: 100-200ms
- Computation steps: 200-300ms
- Persistence steps: 300-500ms
- Total minimum: 100ms for instant operations

**Purpose:**
- Provide user feedback during multi-step operations
- Create perception of thorough verification
- Educational: show verification steps

### 6.5 System Status Display

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

### 6.6 Startup Sequence

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

### 6.7 Shutdown Sequence

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

---

## 7. Implementation Architecture

### 7.1 Module Structure

```
bank-cli-dafny/
├── src/
│   ├── Main.dfy                    # Entry point, startup/shutdown
│   ├── datatypes/
│   │   ├── Transaction.dfy         # Transaction datatypes
│   │   ├── Account.dfy             # Account datatypes
│   │   └── Bank.dfy                # Bank datatype
│   ├── logic/
│   │   ├── OverdraftPolicy.dfy     # Fee calculation with proofs
│   │   ├── Validation.dfy          # Input validation functions
│   │   └── AccountOperations.dfy   # Core account operations
│   ├── persistence/
│   │   └── Persistence.dfy         # FFI boundary for I/O
│   └── ui/
│       └── CLI.dfy                 # Interactive menu system
├── ffi/
│   ├── IO.cs                       # Console I/O with ReadLine
│   ├── FileStorage.cs              # JSON save/load with backup
│   ├── LoadingAnimations.cs        # Progress indicators
│   └── Serialization.cs            # JSON serialization helpers
├── tests/
│   ├── unit/
│   │   ├── TransactionTests.dfy
│   │   ├── AccountTests.dfy
│   │   ├── OverdraftTests.dfy
│   │   └── ValidationTests.dfy
│   ├── integration/
│   │   ├── BankOperationsTests.dfy
│   │   └── PersistenceTests.dfy
│   └── verification/
│       └── InvariantTests.dfy
├── data/
│   ├── bank.json                   # Main data file
│   └── backups/                    # Automatic backups
├── logs/
│   ├── errors.log
│   └── sessions/
├── docs/
│   ├── SPEC.md                     # This document
│   ├── README.md                   # User guide
│   ├── CLAUDE.md                   # AI assistant context
│   └── AI_ASSISTED_GUIDE.md        # Development guide
└── build/
    └── Makefile
```

### 7.2 Module Responsibilities

#### 7.2.1 Main.dfy

**Purpose:** Application entry point and lifecycle management

**Responsibilities:**
- Initialize bank from persistence
- Run startup health checks
- Launch interactive CLI loop
- Handle graceful shutdown
- Create session reports

**Key Functions:**
```dafny
method {:main} Main()
  ensures ValidBankState(bank)
{
  var loadResult := LoadBankFromFile();
  match loadResult {
    case Success(bank) =>
      VerifyBankInvariants(bank);
      RunCLI(bank);
      SaveBankToFile(bank);
    case Failure(err) =>
      print "Error loading bank: ", err, "\n";
      var emptyBank := CreateEmptyBank();
      RunCLI(emptyBank);
  }
}
```

#### 7.2.2 Transaction.dfy

**Purpose:** Immutable transaction datatypes and operations

**Responsibilities:**
- Define Transaction datatype
- Define TransactionType and variants
- Define FeeCategory and FeeDetails
- Provide transaction creation helpers
- Maintain transaction immutability

**Key Functions:**
```dafny
function CreateDepositTransaction(
  id: string,
  accountId: nat,
  amount: int,
  description: string,
  timestamp: nat,
  balanceBefore: int
): Transaction
  requires amount > 0
  ensures var tx := CreateDepositTransaction(...);
    tx.txType.Deposit? &&
    tx.amount == amount &&
    tx.balanceAfter == balanceBefore + amount
```

#### 7.2.3 Account.dfy

**Purpose:** Immutable account datatypes and predicates

**Responsibilities:**
- Define Account datatype
- Define AccountStatus
- Provide account validation predicates
- Provide account update helpers (functional)
- Maintain account invariants

**Key Predicates:**
```dafny
predicate ValidAccount(a: Account)
{
  ValidAccountBalance(a) &&
  BalanceMatchesHistory(a) &&
  HistoryProperlyOrdered(a) &&
  AccountWithinLimits(a)
}

function UpdateAccountBalance(a: Account, delta: int): Account
  requires ValidAccount(a)
  ensures ValidAccount(UpdateAccountBalance(a, delta))
  ensures UpdateAccountBalance(a, delta).balance == a.balance + delta
```

#### 7.2.4 OverdraftPolicy.dfy

**Purpose:** Overdraft fee calculation with formal verification

**Responsibilities:**
- Define overdraft tier structure
- Calculate overdraft fees with tier logic
- Prove fee calculation correctness
- Create fee transactions with details

**Key Functions:**
```dafny
function CalculateOverdraftFee(overdraftAmount: int): (int, FeeDetails)
  requires overdraftAmount > 0
  ensures var (fee, details) := CalculateOverdraftFee(overdraftAmount);
    fee > 0 &&
    details.calculatedFee == fee &&
    details.overdraftAmount == overdraftAmount &&
    1 <= details.tier <= 4

lemma FeeCalculationIsCorrect(overdraftAmount: int)
  requires overdraftAmount > 0
  ensures var (fee, details) := CalculateOverdraftFee(overdraftAmount);
    fee == GetExpectedFeeForTier(details.tier)
```

#### 7.2.5 Bank.dfy

**Purpose:** Bank state management and atomic operations

**Responsibilities:**
- Define Bank datatype
- Implement all banking operations (deposit, withdraw, transfer)
- Ensure atomicity of operations
- Maintain bank-level invariants
- Manage account lifecycle

**Key Methods:**
```dafny
method Deposit(bank: Bank, accountId: nat, amount: int, description: string)
  returns (r: Result<(Bank, Transaction)>)
  requires ValidBankState(bank)
  requires amount > 0
  requires accountId in bank.accounts.Keys
  ensures r.Success? ==> ValidBankState(r.value.0)
  ensures r.Failure? ==> bank unchanged

method Transfer(
  bank: Bank,
  fromId: nat,
  toId: nat,
  amount: int,
  description: string
) returns (r: Result<(Bank, Transaction, Transaction, Option<Transaction>)>)
  requires ValidBankState(bank)
  requires amount > 0
  requires fromId != toId
  ensures r.Success? ==>
    var (newBank, txOut, txIn, maybeFee) := r.value;
    ValidBankState(newBank) &&
    TransferConservesFunds(...)
  ensures r.Failure? ==> bank unchanged
```

#### 7.2.6 Validation.dfy

**Purpose:** Input validation and business rule enforcement

**Responsibilities:**
- Validate user inputs (amounts, names, IDs)
- Check business rules (limits, status, balances)
- Return detailed error messages
- Provide validation predicates for preconditions

**Key Functions:**
```dafny
function ValidateAmount(amount: int, maxAmount: int): Result<int>
{
  if amount <= 0 then
    Failure("Amount must be positive")
  else if amount > maxAmount then
    Failure("Amount exceeds maximum of " + FormatCurrency(maxAmount))
  else
    Success(amount)
}

function ValidateWithdrawal(
  account: Account,
  amount: int
): Result<()>
{
  if account.status != Active then
    Failure("Account is not active")
  else if amount > account.maxTransaction then
    Failure("Amount exceeds transaction limit")
  else if !account.overdraftEnabled && account.balance < amount then
    Failure("Insufficient funds")
  else if account.overdraftEnabled &&
          account.balance - amount < -account.overdraftLimit then
    Failure("Withdrawal would exceed overdraft limit")
  else
    Success(())
}
```

#### 7.2.7 Persistence.dfy

**Purpose:** FFI boundary for file I/O operations

**Responsibilities:**
- Define FFI methods for save/load
- Handle JSON serialization boundary
- Manage backup creation
- Translate C# exceptions to Result types
- Maintain data integrity during I/O

**Key Methods:**
```dafny
method {:extern} SaveBankToFile(bank: Bank, filepath: string)
  returns (r: Result<()>)

method {:extern} LoadBankFromFile(filepath: string)
  returns (r: Result<Bank>)
  ensures r.Success? ==> ValidBankState(r.value)

method {:extern} CreateBackup(filepath: string)
  returns (r: Result<string>)
  ensures r.Success? ==> r.value contains timestamp
```

#### 7.2.8 CLI.dfy

**Purpose:** Interactive command-line interface

**Responsibilities:**
- Display main menu and sub-menus
- Accept and parse user input
- Call appropriate bank operations
- Display results with formatting
- Handle errors gracefully

**Key Methods:**
```dafny
method RunCLI(bank: Bank)
  requires ValidBankState(bank)
  ensures ValidBankState(bank)  // final state
{
  var running := true;
  while running
    invariant ValidBankState(bank)
  {
    DisplayMainMenu();
    var choice := ReadUserChoice();
    match choice {
      case 1 => bank := HandleCreateAccount(bank);
      case 2 => HandleListAccounts(bank);
      case 3 => bank := HandleDeposit(bank);
      // ... other cases
      case 0 => running := false;
    }
  }
}
```

### 7.3 FFI Layer (C#)

#### 7.3.1 IO.cs

**Purpose:** Console input/output with sanitization

**Responsibilities:**
- Read user input with ReadLine
- Write formatted output
- Sanitize input (trim, validate encoding)
- Handle console exceptions

**Key Methods:**
```csharp
public static class IO
{
    public static string ReadLine()
    {
        var input = Console.ReadLine();
        return SanitizeInput(input ?? "");
    }

    public static void WriteLine(string message)
    {
        Console.WriteLine(message);
    }

    private static string SanitizeInput(string input)
    {
        return input.Trim()
                   .Replace("\0", "")
                   .Substring(0, Math.Min(input.Length, 1000));
    }
}
```

#### 7.3.2 FileStorage.cs

**Purpose:** JSON persistence with backup and recovery

**Responsibilities:**
- Serialize Bank to JSON
- Deserialize JSON to Bank
- Create timestamped backups
- Handle file system errors
- Implement rollback on failure

**Key Methods:**
```csharp
public static class FileStorage
{
    public static Result<Unit> SaveBankToFile(Bank bank, string filepath)
    {
        try
        {
            var json = JsonSerializer.Serialize(bank, SerializerOptions);

            // Create backup before overwriting
            if (File.Exists(filepath))
            {
                CreateBackup(filepath);
            }

            // Atomic write: write to temp, then move
            var tempFile = filepath + ".tmp";
            File.WriteAllText(tempFile, json);
            File.Move(tempFile, filepath, overwrite: true);

            return Result<Unit>.Success(new Unit());
        }
        catch (Exception ex)
        {
            return Result<Unit>.Failure($"Save failed: {ex.Message}");
        }
    }

    public static Result<Bank> LoadBankFromFile(string filepath)
    {
        try
        {
            if (!File.Exists(filepath))
            {
                return Result<Bank>.Failure("ERR_FILE_NOT_FOUND");
            }

            var json = File.ReadAllText(filepath);
            var bank = JsonSerializer.Deserialize<Bank>(json, SerializerOptions);

            // Validate loaded data
            if (!ValidateBankData(bank))
            {
                // Try loading from backup
                return LoadFromMostRecentBackup(filepath);
            }

            return Result<Bank>.Success(bank);
        }
        catch (JsonException ex)
        {
            return LoadFromMostRecentBackup(filepath);
        }
        catch (Exception ex)
        {
            return Result<Bank>.Failure($"Load failed: {ex.Message}");
        }
    }

    private static Result<string> CreateBackup(string filepath)
    {
        var timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
        var backupDir = Path.Combine(Path.GetDirectoryName(filepath), "backups");
        Directory.CreateDirectory(backupDir);

        var backupFile = Path.Combine(
            backupDir,
            $"{Path.GetFileNameWithoutExtension(filepath)}_{timestamp}.json"
        );

        File.Copy(filepath, backupFile);

        // Keep only last 10 backups
        PruneOldBackups(backupDir, 10);

        return Result<string>.Success(backupFile);
    }
}
```

#### 7.3.3 LoadingAnimations.cs

**Purpose:** Progress indicators and delays

**Responsibilities:**
- Display spinner animations
- Show step-by-step progress
- Introduce realistic delays
- Format progress messages

**Key Methods:**
```csharp
public static class LoadingAnimations
{
    public static void ShowStep(int current, int total, string message)
    {
        Console.Write($"\r⟳ Step {current}/{total}: {message}...");
        Thread.Sleep(Random.Shared.Next(100, 300));
        Console.Write($"\r✓ Step {current}/{total}: {message}...   \n");
    }

    public static void ShowSpinner(string message, int durationMs)
    {
        var spinChars = new[] { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' };
        var iterations = durationMs / 100;

        for (int i = 0; i < iterations; i++)
        {
            Console.Write($"\r{spinChars[i % spinChars.Length]} {message}...");
            Thread.Sleep(100);
        }

        Console.Write($"\r✓ {message}...   \n");
    }
}
```

#### 7.3.4 Serialization.cs

**Purpose:** JSON serialization configuration

**Responsibilities:**
- Configure JSON serializer options
- Handle Dafny datatypes (sequences, maps, datatypes)
- Custom converters for special types
- Ensure roundtrip fidelity

**Key Classes:**
```csharp
public static class Serialization
{
    public static JsonSerializerOptions SerializerOptions = new()
    {
        WriteIndented = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        Converters =
        {
            new DafnySequenceConverter<Transaction>(),
            new DafnyMapConverter<int, Account>(),
            new TransactionTypeConverter(),
            new OptionConverter<string>()
        }
    };
}

public class TransactionTypeConverter : JsonConverter<TransactionType>
{
    public override TransactionType Read(
        ref Utf8JsonReader reader,
        Type typeToConvert,
        JsonSerializerOptions options)
    {
        // Deserialize discriminated union
        // Handle Deposit, Withdrawal, Fee(category, details), etc.
    }

    public override void Write(
        Utf8JsonWriter writer,
        TransactionType value,
        JsonSerializerOptions options)
    {
        // Serialize discriminated union
    }
}
```

### 7.4 Data Flow

#### 7.4.1 Deposit Flow

```
User Input (CLI)
    ↓
ReadLine() [IO.cs]
    ↓
Parse & Validate [Validation.dfy]
    ↓
Deposit() [Bank.dfy]
    ├─ ValidateAmount()
    ├─ CreateDepositTransaction() [Transaction.dfy]
    ├─ UpdateAccountBalance() [Account.dfy]
    ├─ Verify invariants
    └─ Return Result<(Bank, Transaction)>
    ↓
SaveBankToFile() [Persistence.dfy → FileStorage.cs]
    ├─ Serialize to JSON
    ├─ Create backup
    └─ Atomic write
    ↓
Display result [CLI.dfy]
    ↓
ShowStep() [LoadingAnimations.cs]
```

#### 7.4.2 Withdrawal with Overdraft Flow

```
User Input (CLI)
    ↓
Parse & Validate
    ↓
Withdraw() [Bank.dfy]
    ├─ ValidateWithdrawal() [Validation.dfy]
    ├─ CreateWithdrawalTransaction() [Transaction.dfy]
    ├─ UpdateAccountBalance() [Account.dfy]
    ├─ Check if balance < 0
    ├─ If yes:
    │   ├─ CalculateOverdraftFee() [OverdraftPolicy.dfy]
    │   ├─ CreateFeeTransaction() [Transaction.dfy]
    │   ├─ Link transactions (parent/child IDs)
    │   └─ Update totalFeesCollected
    ├─ Verify invariants
    └─ Return Result<(Bank, Transaction, Option<Transaction>)>
    ↓
Save & Display
```

#### 7.4.3 Transfer Flow

```
User Input (CLI)
    ↓
Parse & Validate (2 accounts, amount)
    ↓
Transfer() [Bank.dfy]
    ├─ ValidateTransfer() [Validation.dfy]
    ├─ CreateTransferOutTransaction() [Transaction.dfy]
    ├─ CreateTransferInTransaction() [Transaction.dfy]
    ├─ Link transactions bidirectionally
    ├─ UpdateAccountBalance() for fromAccount
    ├─ UpdateAccountBalance() for toAccount
    ├─ Check if fromAccount balance < 0
    ├─ If yes:
    │   ├─ CalculateOverdraftFee()
    │   ├─ CreateFeeTransaction()
    │   └─ Link to transferOut
    ├─ Verify fund conservation
    ├─ Verify all invariants
    └─ Return Result<(Bank, Tx, Tx, Option<Tx>)>
    ↓
Save & Display
```

### 7.5 Concurrency Model

**Current Implementation (v1):**
- Single-threaded, sequential execution
- No concurrent access to bank state
- File locking through OS (exclusive write)

**Future Considerations:**
- Document that concurrent access would require:
  - Optimistic locking with version numbers
  - Transaction log for serialization
  - Atomic compare-and-swap operations
- Not implemented in v1 (educational scope)

### 7.6 Build System

**Makefile:**
```makefile
.PHONY: all verify compile test run clean

all: verify compile

verify:
	dafny verify src/**/*.dfy tests/**/*.dfy

compile:
	dafny build src/Main.dfy -t:cs -o:build/BankCLI

test:
	dafny test tests/**/*.dfy

run: compile
	cd build && ./BankCLI

clean:
	rm -rf build/*
	rm -f data/*.tmp
```

**Dependencies:**
- Dafny 4.x
- .NET 6.0 SDK
- System.Text.Json (for serialization)

---

## 8. Testing Strategy

### 8.1 Unit Tests

#### 8.1.1 Transaction Tests (TransactionTests.dfy)

**Test Coverage:**
- Transaction creation with valid inputs
- Balance snapshot calculations
- Transaction type discrimination
- Fee detail construction
- Transaction linking (parent/child)

**Example Tests:**
```dafny
method TestCreateDepositTransaction()
{
  var tx := CreateDepositTransaction(
    "TX-001", 1, 10000, "Test deposit", 1000000, 50000
  );

  assert tx.txType.Deposit?;
  assert tx.amount == 10000;
  assert tx.balanceBefore == 50000;
  assert tx.balanceAfter == 60000;
  assert tx.parentTxId.None?;
  assert |tx.childTxIds| == 0;
}

method TestFeeTransactionLinking()
{
  var withdrawal := CreateWithdrawalTransaction(...);
  var fee := CreateFeeTransaction(..., Some(withdrawal.id));

  assert fee.parentTxId == Some(withdrawal.id);
  assert fee.txType.Fee?;
}
```

#### 8.1.2 Account Tests (AccountTests.dfy)

**Test Coverage:**
- Account creation with valid inputs
- Account balance validation
- Overdraft limit enforcement
- Account limit checks (maxBalance, maxTransaction)
- Account status transitions

**Example Tests:**
```dafny
method TestAccountCreation()
{
  var account := CreateAccount(1, "Alice", 100000, true, 50000);

  assert ValidAccount(account);
  assert account.balance == 100000;
  assert account.overdraftEnabled;
  assert account.overdraftLimit == 50000;
}

method TestBalanceIntegrityAfterTransactions()
{
  var account := CreateAccount(1, "Bob", 100000, false, 0);
  var tx1 := CreateDepositTransaction(...);
  var account' := AppendTransaction(account, tx1);

  assert BalanceMatchesHistory(account');
  assert account'.balance ==
    account'.history[|account'.history|-1].balanceAfter;
}
```

#### 8.1.3 Overdraft Tests (OverdraftTests.dfy)

**Test Coverage:**
- Tier determination for all ranges
- Fee calculation correctness
- Boundary conditions (tier edges)
- Fee details construction
- Zero/negative overdraft handling

**Example Tests:**
```dafny
method TestOverdraftTier1()
{
  var (fee, details) := CalculateOverdraftFee(5000);  // $50.00

  assert fee == 2500;  // $25.00
  assert details.tier == 1;
  assert details.tierRange == (1, 10000);
}

method TestOverdraftTier2()
{
  var (fee, details) := CalculateOverdraftFee(25000);  // $250.00

  assert fee == 3500;  // $35.00
  assert details.tier == 2;
}

method TestOverdraftBoundary()
{
  var (fee1, _) := CalculateOverdraftFee(10000);   // $100.00 - Tier 1
  var (fee2, _) := CalculateOverdraftFee(10001);   // $100.01 - Tier 2

  assert fee1 == 2500;
  assert fee2 == 3500;
}
```

#### 8.1.4 Validation Tests (ValidationTests.dfy)

**Test Coverage:**
- Amount validation (positive, limits)
- Account ID validation
- Owner name validation
- Overdraft configuration validation
- Business rule checks

**Example Tests:**
```dafny
method TestAmountValidation()
{
  var r1 := ValidateAmount(0, 10000);
  assert r1.Failure?;

  var r2 := ValidateAmount(-100, 10000);
  assert r2.Failure?;

  var r3 := ValidateAmount(5000, 10000);
  assert r3.Success?;

  var r4 := ValidateAmount(15000, 10000);
  assert r4.Failure?;
}

method TestOwnerNameValidation()
{
  var r1 := ValidateOwnerName("");
  assert r1.Failure?;

  var r2 := ValidateOwnerName("   ");
  assert r2.Failure?;

  var r3 := ValidateOwnerName("John Doe");
  assert r3.Success?;
}
```

### 8.2 Integration Tests

#### 8.2.1 Bank Operations Tests (BankOperationsTests.dfy)

**Test Coverage:**
- Complete deposit workflow
- Complete withdrawal workflow (with/without overdraft)
- Complete transfer workflow
- Account creation workflow
- Overdraft configuration workflow
- Multi-operation sequences

**Example Tests:**
```dafny
method TestDepositWorkflow()
{
  var bank := CreateEmptyBank();
  var createResult := CreateAccount(bank, "Alice", 0, false, 0);
  assert createResult.Success?;

  var (bank1, accountId) := createResult.value;
  var depositResult := Deposit(bank1, accountId, 50000, "Initial");
  assert depositResult.Success?;

  var (bank2, tx) := depositResult.value;
  assert bank2.accounts[accountId].balance == 50000;
  assert ValidBankState(bank2);
}

method TestWithdrawalWithOverdraftWorkflow()
{
  var bank := CreateBankWithAccount("Bob", 10000, true, 50000);
  var withdrawResult := Withdraw(bank, 0, 30000, "Test");
  assert withdrawResult.Success?;

  var (bank', withdrawal, maybeFee) := withdrawResult.value;
  assert maybeFee.Some?;  // fee should be assessed
  assert bank'.accounts[0].balance < 0;
  assert ValidBankState(bank');
}

method TestTransferWorkflow()
{
  var bank := CreateBankWithAccounts([
    ("Alice", 100000), ("Bob", 50000)
  ]);

  var transferResult := Transfer(bank, 0, 1, 30000, "Payment");
  assert transferResult.Success?;

  var (bank', txOut, txIn, maybeFee) := transferResult.value;
  assert bank'.accounts[0].balance == 70000;
  assert bank'.accounts[1].balance == 80000;
  assert txOut.parentTxId == Some(txIn.id);
  assert txIn.parentTxId == Some(txOut.id);
}
```

#### 8.2.2 Persistence Tests (PersistenceTests.dfy)

**Test Coverage:**
- Save and load roundtrip
- Backup creation
- Corrupted file recovery
- Missing file handling
- Invalid JSON handling
- Data validation after load

**Example Tests:**
```dafny
method TestSaveLoadRoundtrip()
{
  var bank := CreateBankWithMultipleAccounts();
  var saveResult := SaveBankToFile(bank, "test.json");
  assert saveResult.Success?;

  var loadResult := LoadBankFromFile("test.json");
  assert loadResult.Success?;

  var loadedBank := loadResult.value;
  assert BanksEqual(bank, loadedBank);
  assert ValidBankState(loadedBank);
}

method TestCorruptedFileRecovery()
{
  // Create valid bank and save
  var bank := CreateBankWithAccount("Alice", 100000, false, 0);
  SaveBankToFile(bank, "test.json");

  // Corrupt the file
  CorruptFile("test.json");

  // Load should fallback to backup
  var loadResult := LoadBankFromFile("test.json");
  assert loadResult.Success?;
  assert ValidBankState(loadResult.value);
}
```

### 8.3 Verification Tests

#### 8.3.1 Invariant Tests (InvariantTests.dfy)

**Test Coverage:**
- All invariants hold after each operation
- Invariants preserved across sequences
- Edge cases (limits, boundaries)
- Failure cases don't violate invariants

**Example Tests:**
```dafny
method TestInvariantsAfterDeposit()
{
  var bank := CreateBankWithAccount("Alice", 50000, false, 0);
  var result := Deposit(bank, 0, 25000, "Test");
  assert result.Success?;

  var (bank', tx) := result.value;
  assert ValidBankState(bank');
  assert ValidAccount(bank'.accounts[0]);
  assert BalanceMatchesHistory(bank'.accounts[0]);
}

method TestInvariantsAfterFailedWithdrawal()
{
  var bank := CreateBankWithAccount("Bob", 10000, false, 0);
  var result := Withdraw(bank, 0, 50000, "Test");
  assert result.Failure?;

  // Bank should be unchanged
  assert BanksEqual(bank, bank);  // Dafny proves no mutation
  assert ValidBankState(bank);
}

method TestFundConservationInTransfer()
{
  var bank := CreateBankWithAccounts([
    ("Alice", 100000), ("Bob", 50000)
  ]);

  var totalBefore := bank.accounts[0].balance + bank.accounts[1].balance;

  var result := Transfer(bank, 0, 1, 30000, "Test");
  assert result.Success?;

  var (bank', _, _, maybeFee) := result.value;
  var fee := if maybeFee.Some? then -maybeFee.value.amount else 0;
  var totalAfter := bank'.accounts[0].balance + bank'.accounts[1].balance;

  assert totalBefore == totalAfter + fee;  // Fund conservation
}
```

### 8.4 Property-Based Tests

**Test Coverage:**
- Random operation sequences
- Invariants hold for any valid input
- Failure modes don't corrupt state

**Approach:**
```dafny
method TestRandomOperationSequence()
{
  var bank := CreateEmptyBank();
  var operations := GenerateRandomOperations(100);

  var i := 0;
  while i < |operations|
    invariant ValidBankState(bank)
  {
    var op := operations[i];
    bank := ApplyOperation(bank, op);
    assert ValidBankState(bank);
    i := i + 1;
  }
}
```

### 8.5 Manual Testing Scenarios

**Scenario 1: Happy Path**
1. Start application
2. Create account with initial deposit
3. Deposit additional funds
4. Withdraw within balance
5. Transfer to another account
6. Check balance and history
7. Exit gracefully

**Scenario 2: Overdraft Path**
1. Create account with overdraft enabled
2. Withdraw beyond balance
3. Verify fee assessed
4. Check transaction history shows fee separately
5. Deposit to bring balance positive
6. Verify overdraft cleared

**Scenario 3: Error Handling**
1. Attempt withdrawal with insufficient funds (overdraft disabled)
2. Attempt transfer to same account
3. Attempt withdrawal exceeding transaction limit
4. Attempt to close account with non-zero balance
5. Verify all operations rejected with clear errors
6. Verify system state unchanged

**Scenario 4: Persistence**
1. Create accounts and perform transactions
2. Exit application
3. Restart application
4. Verify all data loaded correctly
5. Check backup files created
6. Simulate corrupted file, verify backup recovery

---

## 9. Performance Requirements

### 9.1 Operation Latency

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

### 9.2 Scalability Limits

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

### 9.3 Memory Usage

**Target:**
- Base memory: < 50 MB
- Per account: < 5 KB
- Per transaction: < 1 KB
- Total for 1,000 accounts with 10,000 txs: < 500 MB

**Monitoring:**
- Track memory usage in logs
- Report in system status

---

## 10. Security Considerations

### 10.1 Input Sanitization

**Requirements:**
- Trim whitespace from all string inputs
- Limit string lengths (owner: 100, description: 200, path: 1000)
- Remove null bytes and control characters
- Validate numeric inputs within bounds
- Prevent path traversal in file operations

**Implementation:** See IO.cs SanitizeInput()

### 10.2 Data Integrity

**Mechanisms:**
- Atomic file writes (write to temp, then move)
- Backup before overwrite
- Validation after load
- Checksum verification (future)
- Invariant checks before save

### 10.3 Access Control

**Current (v1):**
- No authentication (single-user CLI)
- File system permissions determine access
- No network exposure

**Future Considerations:**
- User authentication
- Account ownership verification
- Audit logging of all operations
- Encryption at rest

### 10.4 Error Information Disclosure

**Requirements:**
- Don't expose file system paths in user-facing errors
- Don't expose sensitive data in logs (balance amounts in ERROR only)
- Sanitize error messages from exceptions
- Use error codes instead of stack traces

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

**Bank JSON Structure:**
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

**Fee Transaction Example:**
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

**END OF SPECIFICATION**
