# Bank CLI - Technical Specification (Index)

**Version 2.0** | **Last Updated: 2025-10-30**

This document serves as the master index for the Bank CLI technical specification. The complete specification has been organized into focused, modular documents for improved maintainability and context-efficient access.

## 📚 Documentation Hub

For comprehensive documentation navigation, see **[docs/README.md](docs/README.md)** - the central hub for all project documentation.

---

## 🎯 Quick Start by Role

### For Developers
1. [Architecture Overview](docs/specs/ARCHITECTURE.md) - System design and modules
2. [Configuration](docs/specs/CONFIGURATION.md) - System settings and fee tiers
3. [Data Models](docs/specs/DATA_MODELS.md) - Datatypes and structures
4. [Functional Requirements](docs/specs/FUNCTIONAL_REQUIREMENTS.md) - Feature specifications
5. [CLAUDE.md](CLAUDE.md) - Development workflow guide

### For Verification Engineers
1. [Verification Specifications](docs/specs/VERIFICATION_SPEC.md) - Invariants and proofs
2. [Data Models](docs/specs/DATA_MODELS.md) - Datatypes being verified
3. [AI-Assisted Guide](docs/guides/AI_ASSISTED_GUIDE.md) - AI-assisted verification

### For Testers
1. [Testing Specifications](docs/specs/TESTING_SPEC.md) - Testing strategy
2. [Requirements & Edge Cases](docs/guides/REQUIREMENTS_AND_EDGE_CASES.md) - Edge case catalog
3. [Error Handling](docs/specs/ERROR_HANDLING.md) - Error scenarios

### For Users
1. [README.md](README.md) - User guide and quick start

---

## 📋 Complete Specification Documents

### System Design & Architecture

#### [Architecture](docs/specs/ARCHITECTURE.md)
**System Overview | Module Structure | FFI Layer | Data Flow | Build System**

Comprehensive architecture documentation covering:
- System purpose, goals, and technology stack
- Complete module structure (Main, Transaction, Account, OverdraftPolicy, Bank, Validation, Persistence, CLI)
- Module responsibilities and interactions
- FFI layer with C# components (IO, FileStorage, LoadingAnimations, Serialization)
- Data flow diagrams for key operations
- Concurrency model and build system

📄 ~700 lines

---

#### [Data Models](docs/specs/DATA_MODELS.md)
**Core Datatypes | Helper Types | Configurations | Defaults**

Complete data model specifications:
- Core datatypes: Transaction, Account, Bank, TransactionType, FeeCategory
- Helper datatypes: Result<T>, Option<T>
- Overdraft tier configuration (4-tier fee structure)
- Default system limits
- Immutable design philosophy

📄 ~386 lines

---

#### [Configuration](docs/specs/CONFIGURATION.md)
**Centralized Config | Fee Tiers | Account Defaults | System Limits | Modification Guide**

Single source of truth for all system configuration:
- Overdraft fee tiers ($25, $35, $50, $75) with boundaries
- Account defaults (max balance, max transaction, overdraft limits)
- Transaction constraints and system-wide limits
- Configuration validation predicates
- CLI viewing (command 10) and developer modification workflow
- Impact analysis for configuration changes

📄 ~450 lines

---

### Functional Specifications

#### [Functional Requirements](docs/specs/FUNCTIONAL_REQUIREMENTS.md)
**FR-1 to FR-10 | Account Management | Transactions | Queries | Configuration**

All functional requirements with detailed specifications:
- FR-1 to FR-3: Account management (create, list, query)
- FR-4 to FR-6: Transaction operations (deposit, withdrawal, transfer)
- FR-7 to FR-8: Balance and transaction history queries
- FR-9 to FR-10: Configuration and status management
- Input/output specifications, business rules, invariants

📄 ~453 lines

---

#### [Error Handling](docs/specs/ERROR_HANDLING.md)
**Error Categories | Error Codes | Response Format | Recovery Strategies**

Comprehensive error handling specification:
- 4 error categories: Validation, Business Rule, Persistence, System
- 31 error types with codes, messages, and suggestions
- Standardized error response format
- Category-specific recovery strategies
- Logging requirements

📄 ~435 lines

---

### Verification & Quality

#### [Verification Specifications](docs/specs/VERIFICATION_SPEC.md)
**Core Invariants | Preconditions | Postconditions | Proof Strategies**

Formal verification requirements:
- 8 core invariants (balance integrity, fee monotonicity, fund conservation, etc.)
- Preconditions and postconditions for all operations
- Termination guarantees
- Proof strategies (induction, case analysis, atomicity)
- Verification workflow and best practices

📄 ~639 lines

---

#### [Testing Specifications](docs/specs/TESTING_SPEC.md)
**Unit Tests | Integration Tests | Verification Tests | Manual Scenarios**

Complete testing strategy:
- 4 unit test suites (Transaction, Account, Overdraft, Validation)
- 2 integration test suites (BankOperations, Persistence)
- Verification test approach
- Property-based testing
- 4 comprehensive manual testing scenarios

📄 ~406 lines

---

### User Interface

#### [UI Specification](docs/specs/UI_SPECIFICATION.md)
**CLI Architecture | Menu | Operation Flows | Animations | Status Display**

Complete user interface design:
- CLI architecture and execution model
- Main menu with 10 operations
- Detailed operation flows (create account, withdrawal, transfer, history)
- Loading animation specifications
- System status display
- Startup and shutdown sequences

📄 ~662 lines

---

### Non-Functional Requirements

#### [Performance & Security](docs/specs/PERFORMANCE_AND_SECURITY.md)
**Performance Targets | Scalability | Memory | Security Measures**

Performance and security specifications:
- Operation latency targets (95th percentile)
- Scalability limits (accounts, transactions, file sizes)
- Memory usage constraints
- Input sanitization requirements
- Data integrity mechanisms
- Access control model
- Error information disclosure prevention

📄 ~488 lines

---

### Reference Materials

#### [Reference](docs/specs/REFERENCE.md)
**Glossary | Constants | Error Codes | JSON Schema | Implementation Phases**

Quick reference appendices:
- Appendix A: Glossary of key terms
- Appendix B: Configuration constants
- Appendix C: Complete error codes reference (31 codes)
- Appendix D: JSON schema with examples
- Appendix E: Implementation phases (6-week plan)

📄 ~249 lines

---

## 📚 Development Guides

### [AI-Assisted Development Guide](docs/guides/AI_ASSISTED_GUIDE.md)
**Using AI tools for verified development**

Comprehensive guide for using AI tools (Claude, etc.) when developing Dafny code:
- Specification refinement techniques
- Invariant generation strategies
- Proof assistance and debugging verification failures
- Code generation from specifications
- Test case generation
- Best practices for AI-assisted verification
- Example workflows

📄 ~713 lines

---

### [Requirements & Edge Cases](docs/guides/REQUIREMENTS_AND_EDGE_CASES.md)
**Complete requirements catalog and edge case inventory**

Comprehensive requirements and edge case documentation:
- 60 functional requirements (FR-001 to FR-060)
- 25 non-functional requirements (NFR-001 to NFR-025)
- 107 edge cases (EC-001 to EC-107) organized by category
- Boundary conditions for all data types
- 16 invalid input cases
- 16 error recovery scenarios
- Requirements traceability matrices

📄 ~474 lines

---

## 🏗️ Project Structure Summary

```
bank-cli-dafny/
├── src/                           # Dafny source code
│   ├── Main.dfy                   # Entry point
│   ├── Transaction.dfy            # Transaction datatypes
│   ├── Account.dfy                # Account datatypes
│   ├── OverdraftPolicy.dfy        # Fee calculator with proofs
│   ├── Bank.dfy                   # State management
│   ├── Validation.dfy             # Input validation
│   ├── Persistence.dfy            # FFI boundary
│   └── CLI.dfy                    # Interactive interface
├── ffi/                           # C# FFI implementations
│   ├── IO.cs                      # Console I/O
│   ├── FileStorage.cs             # JSON persistence
│   ├── LoadingAnimations.cs       # Progress indicators
│   └── Serialization.cs           # JSON config
├── tests/                         # Test suites
│   ├── BankTests.dfy
│   ├── TransactionTests.dfy
│   └── ...
├── docs/                          # Documentation
│   ├── README.md                  # Documentation hub
│   ├── specs/                     # Technical specifications
│   │   ├── ARCHITECTURE.md
│   │   ├── DATA_MODELS.md
│   │   ├── VERIFICATION_SPEC.md
│   │   ├── FUNCTIONAL_REQUIREMENTS.md
│   │   ├── ERROR_HANDLING.md
│   │   ├── UI_SPECIFICATION.md
│   │   ├── TESTING_SPEC.md
│   │   ├── PERFORMANCE_AND_SECURITY.md
│   │   └── REFERENCE.md
│   └── guides/                    # Development guides
│       ├── AI_ASSISTED_GUIDE.md
│       └── REQUIREMENTS_AND_EDGE_CASES.md
├── README.md                      # User guide
├── SPEC.md                        # This file (specification index)
└── CLAUDE.md                      # Development workflow guide
```

---

## 🎯 Design Principles

### 1. **Formal Verification**
All critical properties are mathematically proven using Dafny's verification system.

### 2. **Immutability**
Accounts and transactions use immutable datatypes, making verification tractable and ensuring audit trails.

### 3. **Explicit Fees**
Overdraft fees are separate transaction entries linked via `parentTxId`, providing transparency and verifiable fee calculation.

### 4. **Atomic Operations**
All operations are all-or-nothing using the `Result<T>` pattern, ensuring data consistency.

### 5. **Type Safety**
Strong typing throughout with explicit error handling prevents runtime failures.

---

## 🔑 Critical Invariants (Summary)

1. **Balance Integrity**: `balance == ComputeBalanceFromHistory()`
2. **Balance Computation Consistency**: Balance recalculation is deterministic
3. **Fee Monotonicity**: Total fees never decrease
4. **Transaction Linkage**: All fee transactions have valid parent IDs
5. **Fund Conservation**: Transfers preserve total system funds
6. **Account Limits**: Balances respect configured limits
7. **Transaction Ordering**: History maintains temporal ordering
8. **Account Map Consistency**: Bank's account map is consistent with account list

For complete invariant specifications, see [Verification Specifications](docs/specs/VERIFICATION_SPEC.md).

---

## 📖 How to Use This Specification

### For Implementation
1. Start with [Architecture](docs/specs/ARCHITECTURE.md) to understand the system
2. Review [Data Models](docs/specs/DATA_MODELS.md) for datatypes
3. Follow [Functional Requirements](docs/specs/FUNCTIONAL_REQUIREMENTS.md) for features
4. Reference [Verification Specs](docs/specs/VERIFICATION_SPEC.md) while implementing
5. Use [CLAUDE.md](CLAUDE.md) for development workflow

### For Verification
1. Read [Verification Specifications](docs/specs/VERIFICATION_SPEC.md) for invariants
2. Study [Data Models](docs/specs/DATA_MODELS.md) for structure
3. Use [AI-Assisted Guide](docs/guides/AI_ASSISTED_GUIDE.md) for verification help
4. Reference [Testing Specs](docs/specs/TESTING_SPEC.md) for test coverage

### For Testing
1. Follow [Testing Specifications](docs/specs/TESTING_SPEC.md) for strategy
2. Use [Requirements & Edge Cases](docs/guides/REQUIREMENTS_AND_EDGE_CASES.md) as test catalog
3. Reference [Error Handling](docs/specs/ERROR_HANDLING.md) for error scenarios

### For Claude Code / AI Assistants
1. Start with [docs/README.md](docs/README.md) for navigation
2. Load only relevant specs for each task (context-efficient)
3. Reference [CLAUDE.md](CLAUDE.md) for common workflows
4. Use [AI-Assisted Guide](docs/guides/AI_ASSISTED_GUIDE.md) for verification patterns

---

## 📝 Document Conventions

- **Must / Shall**: Hard requirements
- **Should**: Strong recommendations
- **May**: Optional features or approaches
- **📄 Lines**: Approximate document size indicator

---

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2025-10-30 | Reorganized into modular specification structure for improved maintainability and AI tool compatibility |
| 1.0 | 2025-10-XX | Initial monolithic specification document |

---

## 📞 Getting Help

- **Documentation navigation**: See [docs/README.md](docs/README.md)
- **Development questions**: Check [CLAUDE.md](CLAUDE.md)
- **User guide**: Read [README.md](README.md)
- **AI-assisted development**: Reference [AI-Assisted Guide](docs/guides/AI_ASSISTED_GUIDE.md)

---

**Original monolithic SPEC.md backed up to SPEC.md.backup**

**This modular specification maintained for optimal Claude Code integration. 🤖**
