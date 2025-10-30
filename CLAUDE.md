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

## Architecture Considerations

### Bank CLI Domain
The application likely involves:
- Account management (creation, deletion, balance queries)
- Transaction processing (deposits, withdrawals, transfers)
- User authentication and authorization
- Data persistence mechanisms
- Command-line interface for user interaction

### Verification Strategy
- Define invariants for account balances (e.g., non-negative balances, conservation of total funds)
- Specify preconditions for operations (e.g., sufficient balance for withdrawals)
- Prove postconditions for state changes (e.g., correct balance updates after transactions)
- Verify security properties (e.g., users can only access their own accounts)
