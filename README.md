# Bank CLI - A Formally Verified Banking System in Dafny

A comprehensive educational project demonstrating formal verification techniques applied to a real-world banking system. This CLI application showcases how Dafny's verification capabilities ensure correctness properties like balance integrity, fund conservation, and transaction atomicity.

## Features

### Core Banking Operations
- ✅ Account creation and management with unique identifiers
- ✅ Deposit operations with balance validation
- ✅ Withdrawal operations with overdraft protection
- ✅ Transfer operations between accounts with atomic guarantees
- ✅ Balance inquiries with real-time accuracy

### Advanced Features
- ✅ Transaction history tracking with filtering capabilities
- ✅ Tiered overdraft protection system (4 configurable tiers)
- ✅ File-based persistence with automatic backup
- ✅ Interactive command-line interface with FFI for input
- ✅ Comprehensive error handling with actionable messages

### Formal Verification
- ✅ Balance integrity proofs
- ✅ Fee monotonicity guarantees
- ✅ Fund conservation across transfers
- ✅ Transaction completeness verification
- ✅ Atomicity of multi-step operations

## Installation

### Install Dafny

**macOS:**
```bash
# Install .NET 8 via Homebrew
brew install dotnet@8

# Add .NET to your PATH (add to ~/.zshrc or ~/.bash_profile)
export PATH="/opt/homebrew/opt/dotnet@8/bin:$PATH"

# Apply the changes
source ~/.zshrc  # or source ~/.bash_profile

# Install Dafny
brew install dafny

# Verify .NET installation
dotnet --version
# Expected: 8.0.x
```

**Linux (Ubuntu/Debian):**
```bash
# Install .NET SDK first
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y dotnet-sdk-8.0

# Install Dafny
dotnet tool install --global dafny
```

**Windows:**
```powershell
# Install .NET SDK
winget install Microsoft.DotNet.SDK.8

# Using .NET tool to install Dafny
dotnet tool install --global dafny
```

### Verify Installation
```bash
dafny --version
# Expected: Dafny 4.11.0 or higher

dotnet --version
# Expected: 8.0.x or higher
```

## Quick Start

### First Time Setup
```bash
# Install dependencies (macOS)
brew install dafny dotnet@8

# Add .NET to your PATH (add to ~/.zshrc or ~/.bash_profile)
export PATH="/opt/homebrew/opt/dotnet@8/bin:$PATH"

# Build the project
make build
```

### Running the Application

**Simple command (recommended for users):**
```bash
./bank-cli
```

**Developer workflow:**
```bash
make dev        # Verify + build + run (full workflow)
make run        # Build + run (skip verification)
make run-quick  # Run without rebuilding
```

**Direct execution:**
```bash
./.build/bin/Debug/net8.0/bank-cli
```

### Building

```bash
make build      # Build executable
make verify     # Verify Dafny code only
make clean      # Remove all build artifacts
```

See `make help` for all available commands.

## Usage Example

```bash
# 1. Start the application
./bank-cli

# 2. Create your first account (option 1)
Account ID: 1001
Owner Name: Alice Smith
Initial Deposit (cents): 100000
Enable Overdraft? (y/n): y

# 3. Make a deposit (option 3)
Account ID: 1001
Amount (cents): 50000

# 4. Check balance (option 6)
Account ID: 1001
# Shows: Current Balance: $1,500.00

# 5. Exit (option 0)
```

## Complete API Reference

### 1. Create Account
**Command:** `1`

**Inputs:**
- Account ID (nat, unique)
- Owner Name (string)
- Initial Deposit (cents, >= 0)
- Enable Overdraft (boolean)
- Max Balance Limit (cents, optional)
- Max Transaction Limit (cents, optional)

**Example:**
```
✓ Account 1001 created successfully!
  Owner: Alice Smith
  Balance: $1,000.00
  Overdraft: Enabled
```

### 2. List Accounts
**Command:** `2`

**Output:** Table of all accounts with balances and status

### 3. Deposit
**Command:** `3`

**Inputs:**
- Account ID (nat, must exist)
- Amount (cents, > 0)
- Description (string)

**Example:**
```
✓ Deposit successful!
  Previous Balance: $1,000.00
  New Balance: $1,250.00
  Transaction ID: TXN-000001
```

### 4. Withdraw
**Command:** `4`

**Inputs:**
- Account ID (nat, must exist)
- Amount (cents, > 0)
- Description (string)

**With Overdraft Example:**
```
⚠ Withdrawal triggers overdraft!
  Requested: $1,000.00
  Current Balance: $750.00
  Shortfall: $250.00

Overdraft Fee Calculation:
  Tier 1 ($0.01 - $100.00): $100.00 @ $25 = $25.00
  Tier 2 ($100.01 - $500.00): $150.00 @ $35 = $35.00
  Total Fee: $60.00

Proceed? (y/n): y

✓ Withdrawal successful!
  Transaction ID: TXN-000003 (Withdrawal)
  Transaction ID: TXN-000004 (Overdraft Fee)
  Final Balance: -$310.00
```

### 5. Transfer
**Command:** `5`

**Inputs:**
- From Account ID (nat)
- To Account ID (nat, different from source)
- Amount (cents, > 0)
- Description (string)

**Example:**
```
✓ Transfer successful!
  From: 1001 (Alice Smith) → $-810.00
  To: 1002 (Bob Johnson) → $3,000.00
  Amount: $500.00
  ✓ Fund conservation verified
```

### 6. Check Balance
**Command:** `6`

**Output:**
```
Account: 1001 (Alice Smith)
Current Balance: -$810.00

Balance Breakdown:
  Total Deposits: $1,450.00
  Total Withdrawals: -$2,000.00
  Total Fees: -$60.00
  Net Transfers: -$200.00
  ──────────────────────
  Current Balance: -$810.00
```

### 7. View Transaction History
**Command:** `7`

**Inputs:**
- Account ID (nat)
- Last N transactions (optional)

**Output:** Table showing:
- Transaction ID
- Timestamp
- Type (Deposit/Withdrawal/Transfer/Fee)
- Amount
- Balance Before/After
- Fee (if applicable)
- Status

### 8. Configure Overdraft
**Command:** `8`

**Options:**
- Enable/disable overdraft protection
- Set overdraft limit
- View tier structure

### 9. View System Status
**Command:** `9`

**Output:**
- Total accounts and balances
- Transaction statistics
- Fee revenue breakdown
- Verification status
- Last backup time

### 10. View System Configuration
**Command:** `10`

**Purpose:** Display all system configuration settings

**Output:**
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

**Example:**
```
> 10
[Configuration display shown above]
```

### 0. Exit
**Command:** `0`

Safely exits with final verification and backup.

## Configuration

### Overdraft Tier Structure

```
Tier 1: $0.01 - $100.00 → $25.00 fee
Tier 2: $100.01 - $500.00 → $35.00 fee
Tier 3: $500.01 - $1,000.00 → $50.00 fee
Tier 4: $1,000.01+ → $75.00 fee
```

### Account Limits

```
Maximum balance per account: $1,000,000.00 (configurable)
Maximum transaction amount: $10,000.00 (configurable)
Maximum overdraft limit: $1,000.00 (configurable)
```

### File Paths

```
./data/bank_accounts.json - Account data
./data/backups/ - Automatic backups
./logs/ - Activity and error logs
```

### Viewing Current Configuration

You can view all system settings at any time:
```bash
# From CLI
> 10

# Configuration is centralized in src/Configuration.dfy
# All values can be reviewed there
```

## Verification Properties

### 1. Balance Integrity
**Property:** Account balances always reflect the sum of all transactions

**Dafny Specification:**
```dafny
ghost predicate BalanceMatchesHistory(account: Account)
{
  account.balance == ComputeBalanceFromHistory(account.history)
}
```

### 2. Fee Monotonicity
**Property:** Overdraft fees never decrease as overdraft amount increases

**Dafny Specification:**
```dafny
ghost predicate FeeMonotonicity(history: seq<Transaction>)
{
  forall i, j :: 0 <= i < j < |history| ==>
    TotalFees(history[..i]) <= TotalFees(history[..j])
}
```

### 3. Fund Conservation
**Property:** Transfers preserve total system funds

**Dafny Specification:**
```dafny
ensures newFrom.balance + newTo.balance ==
        old(from.balance) + old(to.balance) - totalFees
```

### 4. Transaction Completeness
**Property:** Every operation generates exactly one transaction record

### 5. Atomicity
**Property:** Multi-step operations either complete fully or have no effect

## Architecture

### Module Structure

```
src/
├── Main.dfy              # Entry point and CLI loop
├── Transaction.dfy       # Transaction datatypes with fee details
├── Account.dfy           # Account datatypes with limits
├── OverdraftPolicy.dfy   # Tiered fee calculator
├── Bank.dfy              # Bank state management
├── Validation.dfy        # Input validation
├── Persistence.dfy       # FFI boundary for file I/O
└── CLI.dfy               # Interactive menu system

ffi/
├── IO.cs                 # ReadLine/WriteLine (C#)
├── FileStorage.cs        # JSON persistence (C#)
└── LoadingAnimations.cs  # Progress indicators (C#)
```

### Design Principles

**Immutable Datatypes:**
```dafny
datatype Account = Account(
  id: nat,
  owner: string,
  balance: int,
  history: seq<Transaction>,
  overdraftEnabled: bool,
  maxBalance: int,
  maxTransaction: int
)
// Accounts never modified in-place; new instances created
```

**Separate Fee Transactions:**
```dafny
datatype Transaction = Transaction(
  id: string,
  txType: TransactionType,
  amount: int,
  parentTxId: Option<string>,  // Links fee to triggering transaction
  childTxIds: seq<string>      // Links transaction to resulting fees
)

datatype TransactionType =
  | Deposit | Withdrawal | TransferIn | TransferOut
  | Fee(category: FeeCategory, details: FeeDetails)
```

## Error Handling

The system provides clear, actionable error messages:

**Account Not Found:**
```
✗ ERROR: Account Not Found
  Account ID: 9999

  Suggestions:
  • Use option 2 to list all accounts
  • Verify the account ID is correct
```

**Insufficient Funds:**
```
✗ ERROR: Insufficient Funds
  Current Balance: $150.00
  Requested: $200.00
  Shortfall: $50.00

  Options:
  • Reduce withdrawal to $150.00
  • Enable overdraft protection
```

**Overdraft Limit Exceeded:**
```
✗ ERROR: Overdraft Limit Exceeded
  This transaction would exceed limit by $50.00

  Solutions:
  • Request higher limit (option 8)
  • Make a deposit first
```

## Development

### Running Tests
```bash
dafny verify src/*.dfy
dafny test tests/BankTests.dfy
```

### Adding New Features

See SPEC.md for the specification index and docs/README.md for complete documentation navigation.

## Documentation

**Quick Start:**
- **docs/README.md** - 📚 Documentation hub and navigation guide
- **SPEC.md** - Technical specification index with links to all specs

**For Developers:**
- **docs/specs/** - Detailed specifications (Architecture, Data Models, Verification, etc.)
- **docs/guides/REQUIREMENTS_AND_EDGE_CASES.md** - Exhaustive edge case catalog
- **docs/guides/AI_ASSISTED_GUIDE.md** - AI-assisted development guide
- **CLAUDE.md** - Development workflow guide

See [docs/README.md](docs/README.md) for complete documentation navigation.

## Requirements

**Software:**
- Dafny 4.11.0+
- .NET 8.0 runtime
- Z3 theorem prover (included with Dafny)

**Platforms:**
- macOS 11+ (Big Sur or higher)
- Ubuntu 20.04+ / Debian 11+
- Windows 10/11 or Windows Server 2019+

**Hardware:**
- Minimum: 2 cores, 4 GB RAM, 500 MB disk
- Recommended: 4+ cores, 8+ GB RAM, 1 GB disk

## License

Educational use. Copyright 2025.

---

**Built with Dafny** - Formal Verification Made Practical

**Version:** 1.0.0
**Last Updated:** 2025-10-30
**Verification Status:** All properties verified
