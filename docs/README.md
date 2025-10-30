# Bank CLI Documentation Hub

Welcome to the Bank CLI documentation. This guide helps you navigate the comprehensive documentation for this formally verified banking application built with Dafny.

## Documentation Overview

The documentation is organized into three main categories:

### 📋 **Specifications** (`docs/specs/`)
Detailed technical specifications for developers, architects, and verification engineers.

### 📚 **Guides** (`docs/guides/`)
Practical guides for development workflows, testing, and edge case handling.

### 🏠 **Root Documentation** (`../`)
User-facing documentation and quick reference materials.

---

## Quick Navigation

### I want to...

**Understand the system architecture**
- Start with: [`specs/ARCHITECTURE.md`](specs/ARCHITECTURE.md)
- Also see: [`../SPEC.md`](../SPEC.md) (overview index)

**Learn about data structures**
- Go to: [`specs/DATA_MODELS.md`](specs/DATA_MODELS.md)

**Work with formal verification**
- Read: [`specs/VERIFICATION_SPEC.md`](specs/VERIFICATION_SPEC.md)
- Use AI assistance: [`guides/AI_ASSISTED_GUIDE.md`](guides/AI_ASSISTED_GUIDE.md)

**Implement a feature**
- Start: [`specs/FUNCTIONAL_REQUIREMENTS.md`](specs/FUNCTIONAL_REQUIREMENTS.md)
- Then: [`specs/ARCHITECTURE.md`](specs/ARCHITECTURE.md)
- Reference: [`../CLAUDE.md`](../CLAUDE.md) (development workflow)

**Handle errors properly**
- Reference: [`specs/ERROR_HANDLING.md`](specs/ERROR_HANDLING.md)
- See codes: [`specs/REFERENCE.md`](specs/REFERENCE.md#appendix-c-error-codes-reference)

**Design the user interface**
- Follow: [`specs/UI_SPECIFICATION.md`](specs/UI_SPECIFICATION.md)

**Write tests**
- Strategy: [`specs/TESTING_SPEC.md`](specs/TESTING_SPEC.md)
- Edge cases: [`guides/REQUIREMENTS_AND_EDGE_CASES.md`](guides/REQUIREMENTS_AND_EDGE_CASES.md)

**Look up constants or error codes**
- Reference: [`specs/REFERENCE.md`](specs/REFERENCE.md)

**Get started as a user**
- User guide: [`../README.md`](../README.md)

**Use AI tools (Claude, etc.) for development**
- Best practices: [`guides/AI_ASSISTED_GUIDE.md`](guides/AI_ASSISTED_GUIDE.md)
- Quick ref: [`../CLAUDE.md`](../CLAUDE.md)

---

## Complete File Directory

### Root Documentation

| File | Description | Audience | Size |
|------|-------------|----------|------|
| [`../README.md`](../README.md) | User guide, installation, quick start, API reference | End users, new developers | ~490 lines |
| [`../SPEC.md`](../SPEC.md) | Master specification index with links to all specs | All developers | ~100 lines |
| [`../CLAUDE.md`](../CLAUDE.md) | Quick reference for AI-assisted development | Claude Code, AI tools | ~135 lines |

### Specifications (`docs/specs/`)

| File | Description | Key Sections | Size |
|------|-------------|--------------|------|
| [`ARCHITECTURE.md`](specs/ARCHITECTURE.md) | System design, modules, FFI, data flow | System overview, module structure, FFI layer, build system | ~700 lines |
| [`DATA_MODELS.md`](specs/DATA_MODELS.md) | All datatypes and configurations | Transaction, Account, Bank, Result, Option, defaults | ~386 lines |
| [`VERIFICATION_SPEC.md`](specs/VERIFICATION_SPEC.md) | Formal verification requirements | 8 core invariants, preconditions, postconditions, proofs | ~639 lines |
| [`FUNCTIONAL_REQUIREMENTS.md`](specs/FUNCTIONAL_REQUIREMENTS.md) | Feature specifications (FR-1 to FR-10) | Account management, transactions, queries, configuration | ~453 lines |
| [`ERROR_HANDLING.md`](specs/ERROR_HANDLING.md) | Error categories, codes, responses | 4 error categories, 31 error types, recovery strategies | ~435 lines |
| [`UI_SPECIFICATION.md`](specs/UI_SPECIFICATION.md) | CLI design and interaction flows | Menu, operation flows, animations, status display | ~662 lines |
| [`TESTING_SPEC.md`](specs/TESTING_SPEC.md) | Testing strategy and test suites | Unit tests, integration tests, verification tests, manual scenarios | ~406 lines |
| [`PERFORMANCE_AND_SECURITY.md`](specs/PERFORMANCE_AND_SECURITY.md) | Performance targets and security measures | Latency, scalability, memory, input sanitization, data integrity | ~488 lines |
| [`REFERENCE.md`](specs/REFERENCE.md) | Appendices and quick reference | Glossary, constants, error codes, JSON schema, implementation phases | ~249 lines |

### Guides (`docs/guides/`)

| File | Description | Key Topics | Size |
|------|-------------|------------|------|
| [`AI_ASSISTED_GUIDE.md`](guides/AI_ASSISTED_GUIDE.md) | Using AI tools for verified development | Specification refinement, invariant generation, proof assistance, code generation | ~713 lines |
| [`REQUIREMENTS_AND_EDGE_CASES.md`](guides/REQUIREMENTS_AND_EDGE_CASES.md) | Comprehensive requirements and edge case catalog | 85 functional/non-functional requirements, 107 edge cases, boundary conditions | ~474 lines |

---

## Documentation Usage by Role

### 👨‍💻 **Application Developer**

**Essential Reading:**
1. [`../README.md`](../README.md) - Get familiar with the application
2. [`specs/ARCHITECTURE.md`](specs/ARCHITECTURE.md) - Understand the structure
3. [`specs/FUNCTIONAL_REQUIREMENTS.md`](specs/FUNCTIONAL_REQUIREMENTS.md) - Know what to implement
4. [`../CLAUDE.md`](../CLAUDE.md) - Development workflow

**Reference Material:**
- [`specs/DATA_MODELS.md`](specs/DATA_MODELS.md) - When working with datatypes
- [`specs/ERROR_HANDLING.md`](specs/ERROR_HANDLING.md) - When handling errors
- [`specs/REFERENCE.md`](specs/REFERENCE.md) - For constants and codes

### 🔬 **Verification Engineer**

**Essential Reading:**
1. [`specs/VERIFICATION_SPEC.md`](specs/VERIFICATION_SPEC.md) - Core invariants and proofs
2. [`specs/DATA_MODELS.md`](specs/DATA_MODELS.md) - Datatypes being verified
3. [`guides/AI_ASSISTED_GUIDE.md`](guides/AI_ASSISTED_GUIDE.md) - AI-assisted verification

**Reference Material:**
- [`specs/FUNCTIONAL_REQUIREMENTS.md`](specs/FUNCTIONAL_REQUIREMENTS.md) - What to verify
- [`specs/ARCHITECTURE.md`](specs/ARCHITECTURE.md) - Module interactions

### 🧪 **QA/Test Engineer**

**Essential Reading:**
1. [`specs/TESTING_SPEC.md`](specs/TESTING_SPEC.md) - Testing strategy
2. [`guides/REQUIREMENTS_AND_EDGE_CASES.md`](guides/REQUIREMENTS_AND_EDGE_CASES.md) - Edge cases to test
3. [`specs/FUNCTIONAL_REQUIREMENTS.md`](specs/FUNCTIONAL_REQUIREMENTS.md) - Features to validate

**Reference Material:**
- [`specs/ERROR_HANDLING.md`](specs/ERROR_HANDLING.md) - Error scenarios
- [`specs/VERIFICATION_SPEC.md`](specs/VERIFICATION_SPEC.md) - Invariants to test

### 🎨 **UI/UX Designer**

**Essential Reading:**
1. [`specs/UI_SPECIFICATION.md`](specs/UI_SPECIFICATION.md) - Complete UI design
2. [`../README.md`](../README.md) - User-facing features
3. [`specs/ERROR_HANDLING.md`](specs/ERROR_HANDLING.md) - Error messages

### 🏗️ **Architect**

**Essential Reading:**
1. [`specs/ARCHITECTURE.md`](specs/ARCHITECTURE.md) - System architecture
2. [`specs/DATA_MODELS.md`](specs/DATA_MODELS.md) - Data design
3. [`specs/VERIFICATION_SPEC.md`](specs/VERIFICATION_SPEC.md) - Correctness requirements
4. [`specs/PERFORMANCE_AND_SECURITY.md`](specs/PERFORMANCE_AND_SECURITY.md) - Non-functional requirements

### 🤖 **AI Assistant (Claude Code)**

**Primary References:**
1. [`../CLAUDE.md`](../CLAUDE.md) - Quick commands and workflow
2. [`specs/ARCHITECTURE.md`](specs/ARCHITECTURE.md) - Codebase structure
3. [`guides/AI_ASSISTED_GUIDE.md`](guides/AI_ASSISTED_GUIDE.md) - AI-specific patterns
4. This file (`docs/README.md`) - Navigation for context-efficient doc loading

**Context-Efficient Loading:**
- Load only relevant specs for each task to stay within context limits
- Use this hub to identify which 1-2 specs are needed per task
- Cross-references in each spec guide further reading

---

## Documentation Principles

### 1. **Modular Organization**
Each specification file is focused on a single topic and can be read independently.

### 2. **Cross-Referenced**
Documents link to related content for deeper exploration without duplication.

### 3. **Context-Efficient**
No single document exceeds ~700 lines, making them manageable for AI tools and human readers.

### 4. **Role-Based**
Documentation organized by use case rather than forcing sequential reading.

### 5. **Stand-Alone**
Each document includes sufficient context to be understood independently.

---

## Contributing to Documentation

When updating documentation:

1. **Update the relevant spec file** - Don't modify multiple files for a single change
2. **Maintain cross-references** - Update links if document relationships change
3. **Follow the structure** - Each spec has a consistent format with "Related Documentation" section
4. **Keep it concise** - If a spec grows beyond ~800 lines, consider splitting it
5. **Update this hub** - Add new documents to the tables above

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2025-10-30 | Reorganized into modular specs/ and guides/ structure |
| 1.0 | 2025-10-XX | Initial monolithic SPEC.md |

---

## Need Help?

- **For code questions**: Check [`../CLAUDE.md`](../CLAUDE.md) for development workflow
- **For specifications**: Browse `specs/` files by topic
- **For testing/edge cases**: See `guides/` documentation
- **For getting started**: Read [`../README.md`](../README.md)
- **For using AI tools**: Reference [`guides/AI_ASSISTED_GUIDE.md`](guides/AI_ASSISTED_GUIDE.md)

**This documentation hub maintained for optimal Claude Code integration. 🤖**
