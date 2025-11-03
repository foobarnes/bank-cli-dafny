# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a bank CLI application implemented in Dafny, a verification-aware programming language that allows formal verification of correctness properties.

## Build System

This project uses a clean build structure with all artifacts in `.build/` directory. See **docs/BUILD_STRUCTURE.md** for detailed architecture.

### Quick Build Commands

All build artifacts go to `.build/` and are excluded from version control.

```bash
# Default target: verify and build
make

# Just build (assumes verified)
make build

# Full workflow: verify, build, and run
make dev

# Release build
make publish

# Clean all artifacts
make clean
```

See `Makefile` for all available targets and `make help` for detailed options.

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
# or using Makefile:
make verify
```

**Build executable:**
```bash
# Using Makefile (recommended)
make build

# Or directly with Dafny + .NET
dafny translate csharp src/Main.dfy --output:.build/dafny/csharp/bank-cli.cs
dotnet build bank-cli.csproj
```

**Run application:**
```bash
# Simplest - use wrapper script
./bank-cli

# Or with Makefile
make run        # Build and run
make dev        # Verify, build, and run
make run-quick  # Run without rebuilding

# Or directly
./.build/bin/Debug/net9.0/bank-cli
```

**Run specific module verification:**
```bash
dafny verify src/Account.dfy
dafny verify src/Transaction.dfy
dafny verify src/OverdraftPolicy.dfy
```

**Run tests:**
```bash
# Using Makefile
make test

# Or directly
dafny test tests/BankTests.dfy
```

**Publish release build:**
```bash
# Creates optimized, self-contained executable
make publish
# Output in .build/publish/Release/
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
- **ffi/StringHelpers.cs**: String utilities

### Build Output Structure

All generated files go to `.build/` (never version controlled):

```
.build/
├── dafny/csharp/            # Generated bank-cli.cs from Dafny
├── bin/Debug/net9.0/        # Debug executable and DLLs
├── bin/Release/net9.0/      # Release executable and DLLs
├── obj/Debug/net9.0/        # .NET intermediate objects
├── obj/Release/net9.0/      # .NET intermediate objects
├── publish/Release/         # Self-contained distribution
├── cache/                   # Build cache
├── logs/                    # Build logs
└── temp/                    # Temporary build files
```

For detailed structure explanation, see **docs/BUILD_STRUCTURE.md**.

### Key Design Decisions

1. **Immutable Datatypes**: Accounts and transactions use immutable datatypes
2. **Separate Fee Transactions**: Fees are separate transaction entries linked via parentTxId
3. **Tiered Overdraft**: 4-tier fee structure ($25, $35, $50, $75)
4. **Atomic Operations**: All operations are all-or-nothing with Result<T> pattern
5. **File Persistence**: JSON storage with automatic backups
6. **Clean Build Structure**: All artifacts in `.build/` separated from source code

### Critical Invariants

1. **Balance integrity**: `balance == ComputeBalanceFromHistory()`
2. **Fee monotonicity**: Total fees never decrease
3. **Fund conservation**: Transfers preserve total funds
4. **Overdraft limits**: `balance >= -overdraftLimit` when enabled

### Documentation

**Quick Navigation:**
- **docs/README.md** - Documentation hub (start here for navigation)
- **docs/BUILD_STRUCTURE.md** - Build directory architecture and design
- **docs/MIGRATION_GUIDE.md** - Migration from legacy artifact locations
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
4. **Run verification** - Use `dafny verify` or `make verify` on affected modules
5. **Update documentation** - Keep specs and guides current
6. **Test edge cases** - Reference docs/guides/REQUIREMENTS_AND_EDGE_CASES.md for known scenarios
7. **Clean build** - Use `make clean build` to ensure no stale artifacts

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
- **Build system**: All build artifacts in `.build/`. Never commit generated files.
- **Build commands**: Use `make` targets instead of raw commands for consistency
- Use docs/guides/AI_ASSISTED_GUIDE.md for Claude-assisted feature development workflows
- All fee calculations must be mathematically proven in OverdraftPolicy.dfy
- Balance integrity is a critical invariant - verify after any transaction changes
- FFI calls to C# are unchecked - wrap with validation in Dafny
- Refer to SPEC.md for specification index, then load specific docs/specs/ files as needed
- For architecture: docs/specs/ARCHITECTURE.md
- For datatypes: docs/specs/DATA_MODELS.md
- For verification: docs/specs/VERIFICATION_SPEC.md
- For build system: docs/BUILD_STRUCTURE.md and docs/MIGRATION_GUIDE.md

## Build System Details

### Makefile Targets

The project includes a comprehensive `Makefile` with these main targets:

```
Main Targets:
  make              - Default: verify and build
  make build        - Compile to .build/bin/
  make rebuild      - Clean and build
  make verify       - Verify Dafny code
  make test         - Run Dafny tests
  make run          - Build and run application
  make publish      - Create Release distribution

Cleaning:
  make clean        - Remove all artifacts in .build/
  make clean-debug  - Remove Debug build only
  make clean-cache  - Remove build cache
  make clean-temp   - Remove temporary files

Convenience:
  make dev          - Verify, build, and run
  make quick        - Skip verification, just build and run
  make release      - Clean, test, and publish
```

For complete help: `make help`

### Configuration Files

**.csproj Project Files:**
- `bank-cli.csproj` - Minimal project file
- `bank-cli-full.csproj` - Complete project with FFI

Both configured to output to `.build/`:
```xml
<PropertyGroup>
  <OutputPath>.build/bin/$(Configuration)/$(TargetFramework)/</OutputPath>
  <IntermediateOutputPath>.build/obj/$(Configuration)/$(TargetFramework)/</IntermediateOutputPath>
  <PublishDir>.build/publish/$(Configuration)/</PublishDir>
</PropertyGroup>
```

**.gitignore**
- Excludes entire `.build/` directory
- Excludes generated `bank-cli.cs` file
- Excludes compiled binaries and DLLs
- Excludes cache and log directories
- See `.gitignore` for complete patterns

## Environment Setup

Required tools:
1. **Dafny** - Latest version from https://github.com/dafny-lang/dafny/releases
2. **.NET SDK** - Version 9.0 or later from https://dotnet.microsoft.com/download
3. **Make** (optional) - For using Makefile targets

Verify installation:
```bash
dafny --version
dotnet --version
```

Or use: `make check-deps`

## Troubleshooting Build Issues

### Common Issues

**"Cannot find dafny"**
- Install Dafny from https://github.com/dafny-lang/dafny/releases
- Add to PATH if installed manually

**"Cannot find dotnet"**
- Install .NET SDK from https://dotnet.microsoft.com/download

**Build fails with old artifacts**
- Clean build: `make clean build`
- Or: `rm -rf .build/ && dotnet clean && make build`

**Generated files in wrong location**
- Ensure `.csproj` files have OutputPath configured to `.build/`
- Run `dafny translate csharp` with `--output:.build/dafny/csharp/`

**Stale verification cache**
- Clear cache: `make clean-cache`
- Rebuild: `make verify build`

**Git tracking generated files**
- Run: `git rm -r --cached .build/ && git add .gitignore`
- Commit: `git commit -m "Remove tracked build artifacts"`

See **docs/MIGRATION_GUIDE.md** for detailed troubleshooting.

## Development Tips

1. **Use Makefile**: Consistent commands and proper artifact placement
2. **Verify first**: Run `make verify` before building to catch errors early
3. **Incremental development**: `make quick` for faster iteration during development
4. **Final testing**: `make test` to run full test suite before committing
5. **Check dependencies**: `make check-deps` to verify setup
6. **Clean before major changes**: `make clean` to ensure fresh build
7. **Use dev target**: `make dev` for quick verify-build-run cycle

## Getting Help

For questions about:
- **Build system**: See docs/BUILD_STRUCTURE.md or docs/MIGRATION_GUIDE.md
- **Development**: See docs/guides/AI_ASSISTED_GUIDE.md
- **Specifications**: See docs/specs/ and SPEC.md
- **Dafny syntax**: See https://dafny.org/docs/DafnyRef/DafnyRef
- **Features**: See FUNCTIONAL_REQUIREMENTS.md in docs/specs/
