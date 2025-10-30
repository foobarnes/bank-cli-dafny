# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a bank CLI application implemented in Dafny, a verification-aware programming language that allows formal verification of correctness properties.

## Dafny Development

### Verification and Compilation
- Verify Dafny code: `dafny verify <file.dfy>`
- Compile to executable: `dafny build <file.dfy>`
- Run compiled program: `dafny run <file.dfy>`
- Translate to target language (e.g., C#, Go, JavaScript): `dafny translate <language> <file.dfy>`

### Key Dafny Concepts
- Dafny requires explicit specifications including preconditions (`requires`), postconditions (`ensures`), and loop invariants
- Methods must be proven to satisfy their specifications at compile time
- Use `assert` statements to verify intermediate properties
- Functions are pure and must terminate; methods can have side effects
- Ghost code (marked with `ghost`) exists only for verification purposes and is erased at runtime

## Project-Specific Development

### Common Commands

**Verify all Dafny code:**
```bash
dafny verify src/Main.dfy
```

**Build executable:**
```bash
dafny build src/Main.dfy --output:bank-cli
```

**Run application:**
```bash
./bank-cli
```

**Run specific module verification:**
```bash
dafny verify src/Account.dfy
dafny verify src/Transaction.dfy
dafny verify src/OverdraftPolicy.dfy
```

**Run tests:**
```bash
dafny test tests/BankTests.dfy
```

### Project Architecture

- **src/Main.dfy**: Entry point with CLI loop
- **src/Transaction.dfy**: Transaction datatypes with fee details
- **src/Account.dfy**: Immutable account datatypes
- **src/OverdraftPolicy.dfy**: Tiered fee calculator with proofs
- **src/Bank.dfy**: Bank state management, atomic operations
- **src/Validation.dfy**: Input validation and business rules
- **src/Persistence.dfy**: FFI boundary for file I/O
- **src/CLI.dfy**: Interactive menu system
- **ffi/IO.cs**: C# FFI for ReadLine/WriteLine
- **ffi/FileStorage.cs**: JSON persistence
- **ffi/LoadingAnimations.cs**: Progress indicators

### Key Design Decisions

1. **Immutable Datatypes**: Accounts and transactions use immutable datatypes
2. **Separate Fee Transactions**: Fees are separate transaction entries linked via parentTxId
3. **Tiered Overdraft**: 4-tier fee structure ($25, $35, $50, $75)
4. **Atomic Operations**: All operations are all-or-nothing with Result<T> pattern
5. **File Persistence**: JSON storage with automatic backups

### Critical Invariants

1. **Balance integrity**: `balance == ComputeBalanceFromHistory()`
2. **Fee monotonicity**: Total fees never decrease
3. **Fund conservation**: Transfers preserve total funds
4. **Overdraft limits**: `balance >= -overdraftLimit` when enabled

### Documentation

**Quick Navigation:**
- **docs/README.md** - 📚 Documentation hub (start here for navigation)
- **README.md** - User guide and installation
- **SPEC.md** - Specification index with links to all specs

**Detailed Specifications** (docs/specs/):
- **ARCHITECTURE.md** - System design, modules, FFI, data flow
- **DATA_MODELS.md** - Datatypes and configurations
- **VERIFICATION_SPEC.md** - Invariants, proofs, verification requirements
- **FUNCTIONAL_REQUIREMENTS.md** - Feature specifications (FR-1 to FR-10)
- **ERROR_HANDLING.md** - Error categories, codes, recovery strategies
- **UI_SPECIFICATION.md** - CLI design and interaction flows
- **TESTING_SPEC.md** - Testing strategy and test suites
- **PERFORMANCE_AND_SECURITY.md** - Performance targets and security measures
- **REFERENCE.md** - Glossary, constants, error codes, JSON schema

**Development Guides** (docs/guides/):
- **AI_ASSISTED_GUIDE.md** - AI-assisted development workflows
- **REQUIREMENTS_AND_EDGE_CASES.md** - Edge case catalog and requirements

**Quick Reference:**
- **CLAUDE.md** - This file (development guide for Claude Code)

### Development Workflow

When working on new features or fixes:

1. **Understand the invariants** - Review critical invariants relevant to your change
2. **Write specifications** - Add `requires` and `ensures` clauses before implementation
3. **Implement with verification in mind** - Write code that Dafny can verify
4. **Run verification** - Use `dafny verify` on affected modules
5. **Update documentation** - Keep specs and guides current
6. **Test edge cases** - Reference docs/guides/REQUIREMENTS_AND_EDGE_CASES.md for known scenarios

### Common Verification Patterns

**Balance computation lemma:**
```dafny
lemma BalanceMatchesHistory(account: Account)
  ensures account.balance == ComputeBalance(account.history)
```

**Loop invariant example:**
```dafny
while i < |accounts|
  invariant 0 <= i <= |accounts|
  invariant totalBalance == SumBalances(accounts[..i])
{
  totalBalance := totalBalance + accounts[i].balance;
  i := i + 1;
}
```

**FFI boundary safety:**
```dafny
method {:extern} ReadLine() returns (line: string)
  ensures |line| >= 0
```

### Notes for AI-Assisted Development

- **Context-efficient documentation**: Use docs/README.md to navigate and load only relevant specs for each task
- Use docs/guides/AI_ASSISTED_GUIDE.md for Claude-assisted feature development workflows
- All fee calculations must be mathematically proven in OverdraftPolicy.dfy
- Balance integrity is a critical invariant - verify after any transaction changes
- FFI calls to C# are unchecked - wrap with validation in Dafny
- Refer to SPEC.md for specification index, then load specific docs/specs/ files as needed
- For architecture: docs/specs/ARCHITECTURE.md
- For datatypes: docs/specs/DATA_MODELS.md
- For verification: docs/specs/VERIFICATION_SPEC.md
