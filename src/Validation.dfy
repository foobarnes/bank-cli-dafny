// Validation.dfy
// Input validation and business rules for banking operations
//
// This module provides comprehensive validation functions for:
// - Amount validation (positive amounts, transaction limits, balance checks)
// - Account validation (IDs, owner names, initial deposits)
// - Transaction validation (transfers, overdrafts, balance limits)
//
// All validation functions integrate with Configuration module constants
// and return ValidationResult for detailed error reporting.

include "Configuration.dfy"

module Validation {
  import opened Configuration

  // ============================================================================
  // RESULT TYPE FOR VALIDATION
  // ============================================================================

  datatype ValidationResult =
    | Valid
    | Invalid(error: string)

  // Predicate to check if a validation result is valid
  predicate IsValidResult(result: ValidationResult)
  {
    result.Valid?
  }

  // ============================================================================
  // AMOUNT VALIDATION
  // ============================================================================

  // Validates that an amount is positive
  predicate ValidAmount(amount: int)
  {
    amount > 0
  }

  // Validates that a balance is acceptable given overdraft settings
  // - Without overdraft: balance must be >= 0
  // - With overdraft: balance can be negative up to overdraftLimit
  predicate ValidBalance(balance: int, overdraftEnabled: bool, overdraftLimit: int)
    requires overdraftLimit >= 0
  {
    if overdraftEnabled then
      balance >= -overdraftLimit
    else
      balance >= MIN_BALANCE_NO_OVERDRAFT_CENTS
  }

  // Validates that an amount is within transaction limits
  predicate ValidTransactionAmountRange(amount: int, maxTransaction: int)
    requires maxTransaction > 0
  {
    amount >= MIN_TRANSACTION_AMOUNT_CENTS && amount <= maxTransaction
  }

  // Combined validation for transaction amount with detailed result
  method ValidateTransactionAmount(amount: int, maxTransaction: int) returns (result: ValidationResult)
    requires maxTransaction > 0
    ensures result.Valid? <==> ValidTransactionAmountRange(amount, maxTransaction)
  {
    if amount < MIN_TRANSACTION_AMOUNT_CENTS {
      return Invalid("Transaction amount must be at least $0.01");
    } else if amount > maxTransaction {
      return Invalid("Transaction amount exceeds maximum allowed");
    } else {
      return Valid;
    }
  }

  // Validates balance with detailed error messages
  method ValidateBalance(balance: int, overdraftEnabled: bool, overdraftLimit: int)
    returns (result: ValidationResult)
    requires overdraftLimit >= 0
    ensures result.Valid? <==> ValidBalance(balance, overdraftEnabled, overdraftLimit)
  {
    if overdraftEnabled {
      if balance < -overdraftLimit {
        return Invalid("Balance exceeds overdraft limit");
      } else {
        return Valid;
      }
    } else {
      if balance < MIN_BALANCE_NO_OVERDRAFT_CENTS {
        return Invalid("Insufficient funds (overdraft not enabled)");
      } else {
        return Valid;
      }
    }
  }

  // ============================================================================
  // ACCOUNT VALIDATION
  // ============================================================================

  // Validates account ID (must be a valid natural number)
  predicate ValidAccountId(id: nat)
  {
    // Account IDs start from 1000, but we accept any nat for flexibility
    true
  }

  // Validates owner name length
  predicate ValidOwnerNameLength(name: string)
  {
    var len := |name|;
    len >= MIN_OWNER_NAME_LENGTH && len <= MAX_OWNER_NAME_LENGTH
  }

  // Validates owner name with detailed result
  method ValidateOwnerName(name: string) returns (result: ValidationResult)
    ensures result.Valid? <==> ValidOwnerNameLength(name)
  {
    var len := |name|;
    if len < MIN_OWNER_NAME_LENGTH {
      return Invalid("Owner name is too short (minimum 1 character)");
    } else if len > MAX_OWNER_NAME_LENGTH {
      return Invalid("Owner name is too long (maximum 255 characters)");
    } else {
      return Valid;
    }
  }

  // Validates initial deposit amount
  predicate ValidInitialDepositAmount(amount: int, maxBalance: int)
    requires maxBalance > 0
  {
    amount >= MIN_INITIAL_DEPOSIT_CENTS && amount <= maxBalance
  }

  // Validates initial deposit with detailed result
  method ValidateInitialDeposit(amount: int, maxBalance: int) returns (result: ValidationResult)
    requires maxBalance > 0
    ensures result.Valid? <==> ValidInitialDepositAmount(amount, maxBalance)
  {
    if amount < MIN_INITIAL_DEPOSIT_CENTS {
      return Invalid("Initial deposit cannot be negative");
    } else if amount > maxBalance {
      return Invalid("Initial deposit exceeds maximum balance limit");
    } else {
      return Valid;
    }
  }

  // ============================================================================
  // TRANSACTION VALIDATION
  // ============================================================================

  // Validates simple transaction amount (minimum check)
  predicate ValidTransactionAmount(amount: int)
  {
    amount >= MIN_TRANSACTION_AMOUNT_CENTS
  }

  // Validates transfer amount considering source account constraints
  predicate ValidTransferAmount(
    amount: int,
    sourceBalance: int,
    sourceOverdraft: bool,
    sourceOverdraftLimit: int
  )
    requires sourceOverdraftLimit >= 0
  {
    // Amount must be positive
    amount >= MIN_TRANSACTION_AMOUNT_CENTS &&
    // After transfer, source account must have valid balance
    ValidBalance(sourceBalance - amount, sourceOverdraft, sourceOverdraftLimit)
  }

  // Validates transfer with detailed result
  method ValidateTransfer(
    amount: int,
    sourceBalance: int,
    sourceOverdraft: bool,
    sourceOverdraftLimit: int,
    maxTransaction: int
  ) returns (result: ValidationResult)
    requires sourceOverdraftLimit >= 0
    requires maxTransaction > 0
    ensures result.Valid? <==> (
      ValidTransactionAmount(amount) &&
      ValidTransferAmount(amount, sourceBalance, sourceOverdraft, sourceOverdraftLimit) &&
      ValidTransactionAmountRange(amount, maxTransaction)
    )
  {
    // Check minimum amount
    if amount < MIN_TRANSACTION_AMOUNT_CENTS {
      return Invalid("Transfer amount must be at least $0.01");
    }

    // Check maximum transaction limit
    if amount > maxTransaction {
      return Invalid("Transfer amount exceeds maximum transaction limit");
    }

    // Check if source has sufficient funds (including overdraft)
    var newSourceBalance := sourceBalance - amount;
    if sourceOverdraft {
      if newSourceBalance < -sourceOverdraftLimit {
        return Invalid("Insufficient funds in source account (including overdraft)");
      }
    } else {
      if newSourceBalance < MIN_BALANCE_NO_OVERDRAFT_CENTS {
        return Invalid("Insufficient funds in source account");
      }
    }

    return Valid;
  }

  // Checks if adding an amount would exceed maximum balance
  predicate WouldExceedMaxBalance(currentBalance: int, amount: int, maxBalance: int)
    requires maxBalance > 0
    requires amount >= 0
    requires currentBalance >= 0
  {
    currentBalance + amount > maxBalance
  }

  // Validates deposit won't exceed maximum balance
  method ValidateDeposit(
    amount: int,
    currentBalance: int,
    maxBalance: int,
    maxTransaction: int
  ) returns (result: ValidationResult)
    requires maxBalance > 0
    requires maxTransaction > 0
    requires currentBalance >= 0
    ensures result.Valid? <==> (
      ValidTransactionAmount(amount) &&
      ValidTransactionAmountRange(amount, maxTransaction) &&
      !WouldExceedMaxBalance(currentBalance, amount, maxBalance)
    )
  {
    // Check minimum amount
    if amount < MIN_TRANSACTION_AMOUNT_CENTS {
      return Invalid("Deposit amount must be at least $0.01");
    }

    // Check maximum transaction limit
    if amount > maxTransaction {
      return Invalid("Deposit amount exceeds maximum transaction limit");
    }

    // Check if deposit would exceed maximum balance
    if WouldExceedMaxBalance(currentBalance, amount, maxBalance) {
      return Invalid("Deposit would exceed maximum account balance");
    }

    return Valid;
  }

  // Validates withdrawal considering overdraft settings
  method ValidateWithdrawal(
    amount: int,
    currentBalance: int,
    overdraftEnabled: bool,
    overdraftLimit: int,
    maxTransaction: int
  ) returns (result: ValidationResult)
    requires overdraftLimit >= 0
    requires maxTransaction > 0
    ensures result.Valid? <==> (
      ValidTransactionAmount(amount) &&
      ValidTransactionAmountRange(amount, maxTransaction) &&
      ValidBalance(currentBalance - amount, overdraftEnabled, overdraftLimit)
    )
  {
    // Check minimum amount
    if amount < MIN_TRANSACTION_AMOUNT_CENTS {
      return Invalid("Withdrawal amount must be at least $0.01");
    }

    // Check maximum transaction limit
    if amount > maxTransaction {
      return Invalid("Withdrawal amount exceeds maximum transaction limit");
    }

    // Check if withdrawal leaves valid balance
    var newBalance := currentBalance - amount;
    if overdraftEnabled {
      if newBalance < -overdraftLimit {
        return Invalid("Insufficient funds (including overdraft limit)");
      }
    } else {
      if newBalance < MIN_BALANCE_NO_OVERDRAFT_CENTS {
        return Invalid("Insufficient funds");
      }
    }

    return Valid;
  }

  // ============================================================================
  // ACCOUNT SETTINGS VALIDATION
  // ============================================================================

  // Validates maximum balance setting
  predicate ValidMaxBalanceSetting(maxBalance: int)
  {
    maxBalance > 0
  }

  method ValidateMaxBalanceSetting(maxBalance: int) returns (result: ValidationResult)
    ensures result.Valid? <==> ValidMaxBalanceSetting(maxBalance)
  {
    if maxBalance <= 0 {
      return Invalid("Maximum balance must be positive");
    } else {
      return Valid;
    }
  }

  // Validates maximum transaction setting
  predicate ValidMaxTransactionSetting(maxTransaction: int)
  {
    maxTransaction >= MIN_TRANSACTION_AMOUNT_CENTS
  }

  method ValidateMaxTransactionSetting(maxTransaction: int) returns (result: ValidationResult)
    ensures result.Valid? <==> ValidMaxTransactionSetting(maxTransaction)
  {
    if maxTransaction < MIN_TRANSACTION_AMOUNT_CENTS {
      return Invalid("Maximum transaction must be at least $0.01");
    } else {
      return Valid;
    }
  }

  // Validates overdraft limit setting
  predicate ValidOverdraftLimitSetting(overdraftLimit: int)
  {
    overdraftLimit >= 0
  }

  method ValidateOverdraftLimitSetting(overdraftLimit: int) returns (result: ValidationResult)
    ensures result.Valid? <==> ValidOverdraftLimitSetting(overdraftLimit)
  {
    if overdraftLimit < 0 {
      return Invalid("Overdraft limit cannot be negative");
    } else {
      return Valid;
    }
  }

  // ============================================================================
  // COMPOSITE VALIDATION
  // ============================================================================

  // Validates all account creation parameters
  method ValidateAccountCreation(
    ownerName: string,
    initialDeposit: int,
    maxBalance: int,
    overdraftLimit: int
  ) returns (result: ValidationResult)
    requires maxBalance > 0
    requires overdraftLimit >= 0
  {
    // Validate owner name
    var nameResult := ValidateOwnerName(ownerName);
    if nameResult.Invalid? {
      return nameResult;
    }

    // Validate initial deposit
    var depositResult := ValidateInitialDeposit(initialDeposit, maxBalance);
    if depositResult.Invalid? {
      return depositResult;
    }

    // Validate max balance setting
    var maxBalanceResult := ValidateMaxBalanceSetting(maxBalance);
    if maxBalanceResult.Invalid? {
      return maxBalanceResult;
    }

    // Validate overdraft limit setting
    var overdraftResult := ValidateOverdraftLimitSetting(overdraftLimit);
    if overdraftResult.Invalid? {
      return overdraftResult;
    }

    return Valid;
  }

  // ============================================================================
  // UTILITY LEMMAS
  // ============================================================================

  // Lemma: Valid amounts are positive
  lemma ValidAmountIsPositive(amount: int)
    requires ValidAmount(amount)
    ensures amount > 0
  {
    // Proof by definition
  }

  // Lemma: Valid transaction amounts meet minimum requirement
  lemma ValidTransactionMeetsMinimum(amount: int)
    requires ValidTransactionAmount(amount)
    ensures amount >= MIN_TRANSACTION_AMOUNT_CENTS
  {
    // Proof by definition
  }

  // Lemma: If transfer is valid, resulting balance is valid
  lemma ValidTransferMaintainsBalance(
    amount: int,
    sourceBalance: int,
    sourceOverdraft: bool,
    sourceOverdraftLimit: int
  )
    requires sourceOverdraftLimit >= 0
    requires ValidTransferAmount(amount, sourceBalance, sourceOverdraft, sourceOverdraftLimit)
    ensures ValidBalance(sourceBalance - amount, sourceOverdraft, sourceOverdraftLimit)
  {
    // Proof by definition of ValidTransferAmount
  }

  // Lemma: Depositing to account that won't exceed max maintains valid balance
  lemma ValidDepositMaintainsConstraints(
    amount: int,
    currentBalance: int,
    maxBalance: int
  )
    requires maxBalance > 0
    requires currentBalance >= 0
    requires amount >= 0
    requires !WouldExceedMaxBalance(currentBalance, amount, maxBalance)
    ensures currentBalance + amount <= maxBalance
  {
    // Proof by definition of WouldExceedMaxBalance
  }
}
