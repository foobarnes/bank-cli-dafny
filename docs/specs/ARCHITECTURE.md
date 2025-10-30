# Bank CLI Architecture

## Introduction

This document describes the complete system architecture of the Verified Bank CLI application. It covers the system's purpose, goals, technology choices, module organization, data flow patterns, and build infrastructure.

This architecture documentation is extracted from the comprehensive specification to provide a focused view for developers, architects, and contributors who need to understand the system's structural design and implementation approach.

For details on data structures and types, see [DATA_MODELS.md](DATA_MODELS.md). For verification requirements and formal specifications, see [VERIFICATION_SPEC.md](VERIFICATION_SPEC.md). For functional requirements and feature specifications, see [FUNCTIONAL_REQUIREMENTS.md](FUNCTIONAL_REQUIREMENTS.md).

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

## Related Documentation

- **[DATA_MODELS.md](DATA_MODELS.md)** - Complete data structure specifications including Transaction, Account, Bank datatypes, and all related types with their invariants and relationships
- **[VERIFICATION_SPEC.md](VERIFICATION_SPEC.md)** - Formal verification requirements including invariants, preconditions, postconditions, lemmas, and proof obligations
- **[FUNCTIONAL_REQUIREMENTS.md](FUNCTIONAL_REQUIREMENTS.md)** - Feature specifications for all banking operations including deposits, withdrawals, transfers, account management, and overdraft handling
- **[../../SPEC.md](../../SPEC.md)** - Complete system specification including all sections (architecture, requirements, data models, verification, testing, performance, and security)
- **[../../CLAUDE.md](../../CLAUDE.md)** - Development guide for working with this codebase including Dafny commands, verification patterns, and AI-assisted development workflows
- **[../AI_ASSISTED_GUIDE.md](../AI_ASSISTED_GUIDE.md)** - Guide for AI-assisted feature development and enhancement
- **[../REQUIREMENTS_AND_EDGE_CASES.md](../REQUIREMENTS_AND_EDGE_CASES.md)** - Comprehensive edge case catalog and requirement scenarios
