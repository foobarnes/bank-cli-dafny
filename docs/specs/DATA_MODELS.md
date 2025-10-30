# Bank CLI Data Models

## Overview

This document provides a comprehensive specification of all data models used in the Bank CLI application. The data models are implemented using Dafny datatypes, which are immutable by design and support formal verification of correctness properties.

### Design Philosophy

The Bank CLI data models follow these core principles:

1. **Immutability**: All datatypes are immutable, ensuring thread safety and enabling clear reasoning about state changes
2. **Explicit Structure**: Every field has a clear purpose and well-defined constraints
3. **Audit Trail**: Complete transaction history is preserved for verification and compliance
4. **Type Safety**: Strong typing prevents category errors and invalid state representations
5. **Verification-Friendly**: Datatypes are designed to support formal proofs of invariants and correctness properties

These models serve as the foundation for the entire system, enabling both runtime correctness and compile-time verification through Dafny's proof system.

---

## 3.1 Core Datatypes

### 3.1.1 Transaction

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

### 3.1.2 TransactionType

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

### 3.1.3 FeeCategory

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

### 3.1.4 FeeDetails

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

### 3.1.5 TransactionStatus

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

### 3.1.6 Account

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

### 3.1.7 AccountStatus

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

### 3.1.8 Bank

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

---

## 3.2 Helper Datatypes

### 3.2.1 Result<T>

```dafny
datatype Result<T> =
  | Success(value: T)
  | Failure(error: string)
```

**Usage**: All bank operations return Result<T> for error handling.

### 3.2.2 Option<T>

```dafny
datatype Option<T> =
  | Some(value: T)
  | None
```

**Usage**: For optional fields (parentTxId, filters, etc.).

---

## 3.3 Overdraft Tier Configuration

```dafny
const OVERDRAFT_TIERS: seq<(int, int, int)> := [
  (1, 10000, 2500),        // Tier 1: $0.01-$100.00 → $25.00
  (10001, 50000, 3500),    // Tier 2: $100.01-$500.00 → $35.00
  (50001, 100000, 5000),   // Tier 3: $500.01-$1000.00 → $50.00
  (100001, INT_MAX, 7500)  // Tier 4: $1000.01+ → $75.00
]
```

**Tuple Format**: `(minCents, maxCents, feeCents)`

The overdraft tier configuration defines a progressive fee structure based on the magnitude of the overdraft. Each tier is represented as a tuple containing:
- Minimum overdraft amount in cents (inclusive)
- Maximum overdraft amount in cents (inclusive)
- Fee assessed in cents

This tiered approach ensures that larger overdrafts incur proportionally higher fees, incentivizing customers to maintain positive balances while providing clear, predictable fee structures.

---

## 3.4 Default Limits

```dafny
const DEFAULT_MAX_BALANCE: int := 100_000_000;      // $1,000,000
const DEFAULT_MAX_TRANSACTION: int := 10_000_000;   // $100,000
const DEFAULT_OVERDRAFT_LIMIT: int := 100_000;      // $1,000
```

**Constant Specifications:**

- **DEFAULT_MAX_BALANCE**: Maximum account balance to prevent overflow
  - Set to $1,000,000 (100,000,000 cents)
  - Ensures safe arithmetic operations
  - Can be adjusted per account if needed

- **DEFAULT_MAX_TRANSACTION**: Maximum single transaction amount
  - Set to $100,000 (10,000,000 cents)
  - Applies to withdrawals and transfers
  - Prevents accidental large transactions

- **DEFAULT_OVERDRAFT_LIMIT**: Maximum negative balance when overdraft enabled
  - Set to $1,000 (100,000 cents)
  - Can be adjusted per account
  - Provides reasonable protection against excessive overdrafts

---

## Related Documentation

This data models specification is part of a comprehensive documentation suite. For additional context and details, refer to:

- **[ARCHITECTURE.md](./ARCHITECTURE.md)**: System architecture and component interactions showing how these data models are used throughout the system
- **[VERIFICATION_SPEC.md](./VERIFICATION_SPEC.md)**: Formal verification requirements including invariants that must hold for these datatypes
- **[FUNCTIONAL_REQUIREMENTS.md](./FUNCTIONAL_REQUIREMENTS.md)**: Functional requirements showing how these models support business operations
- **[../../SPEC.md](../../SPEC.md)**: Complete technical specification containing all sections in one document

---

**Document Version**: 1.0
**Last Updated**: 2025-10-30
**Status**: Current
