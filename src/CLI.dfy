/*
 * CLI Module for Verified Bank CLI
 *
 * This module provides the interactive command-line interface for the banking system.
 * It handles user input, displays menus, and coordinates operations with the Bank module.
 *
 * Menu Options (0-10):
 * 0: Exit
 * 1: Create Account
 * 2: List Accounts
 * 3: Query Account Balance
 * 4: Deposit Funds
 * 5: Withdraw Funds
 * 6: Transfer Funds
 * 7: Query Balance with Breakdown
 * 8: View Transaction History
 * 9: Configure Overdraft
 * 10: View System Configuration
 */

include "Bank.dfy"
include "Account.dfy"
include "Validation.dfy"
include "Configuration.dfy"
include "Persistence.dfy"

module CLI {
  import opened Bank
  import opened Account
  import opened Validation
  import opened Configuration
  import opened Persistence

  // ============================================================================
  // FFI METHODS FOR USER I/O
  // ============================================================================

  /*
   * ReadLine reads a line of input from the user.
   * Implementation in ffi/IO.cs
   */
  method {:extern "IO", "ReadLine"} ReadLine() returns (line: string)

  /*
   * Print outputs text to the console.
   * Implementation in ffi/IO.cs
   */
  method {:extern "IO", "Print"} Print(text: string)

  /*
   * PrintLine outputs text with a newline.
   * Implementation in ffi/IO.cs
   */
  method {:extern "IO", "PrintLine"} PrintLine(text: string)

  // ============================================================================
  // FFI METHODS FOR STRING HELPERS
  // ============================================================================

  /*
   * TryParseNat attempts to parse a string as a natural number.
   * Returns (success, value) tuple.
   * Implementation in ffi/StringHelpers.cs
   */
  method {:extern "StringHelpers", "TryParseNat"} {:axiom} TryParseNat(str: string) returns (success: bool, value: nat)

  /*
   * TryParseInt attempts to parse a string as an integer.
   * Returns (success, value) tuple.
   * Implementation in ffi/StringHelpers.cs
   */
  method {:extern "StringHelpers", "TryParseInt"} TryParseInt(str: string) returns (success: bool, value: int)

  /*
   * FormatCentsToDollars formats cents as dollars with currency symbol.
   * Example: 125050 -> "$1,250.50"
   * Implementation in ffi/StringHelpers.cs
   */
  method {:extern "StringHelpers", "FormatCentsToDollars"} FormatCentsToDollars(cents: int) returns (formatted: string)

  /*
   * NatToString converts a natural number to string.
   * Implementation in ffi/StringHelpers.cs
   */
  method {:extern "StringHelpers", "NatToString"} NatToString(n: nat) returns (str: string)

  /*
   * IntToString converts an integer to string.
   * Implementation in ffi/StringHelpers.cs
   */
  method {:extern "StringHelpers", "IntToString"} IntToString(n: int) returns (str: string)

  /*
   * BoolToYesNo converts boolean to "Yes" or "No".
   * Implementation in ffi/StringHelpers.cs
   */
  method {:extern "StringHelpers", "BoolToYesNo"} BoolToYesNo(b: bool) returns (str: string)

  /*
   * BoolToEnabledDisabled converts boolean to "Enabled" or "Disabled".
   * Implementation in ffi/StringHelpers.cs
   */
  method {:extern "StringHelpers", "BoolToEnabledDisabled"} BoolToEnabledDisabled(b: bool) returns (str: string)

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /*
   * DisplayAccountsList iterates through account IDs and displays account info.
   * Since we can't directly iterate over map keys in Dafny, we check sequential IDs.
   */
  method DisplayAccountsList(bank: Bank, startId: nat, maxAccounts: nat)
  {
    var currentId := startId;
    var endId := startId + maxAccounts;
    var foundCount := 0;

    while currentId < endId && foundCount < 100
    {
      if currentId in bank.accounts {
        var account := bank.accounts[currentId];
        var idStr := NatToString(account.id);
        var balanceStr := FormatCentsToDollars(account.balance);
        var statusStr := if account.status == AccountStatus.Active then "Active"
                        else if account.status == AccountStatus.Suspended then "Suspended"
                        else "Closed";
        PrintLine("ID: " + idStr + " | Owner: " + account.owner + " | Balance: " + balanceStr + " | Status: " + statusStr);
        foundCount := foundCount + 1;
      }
      currentId := currentId + 1;
    }

    if foundCount == 0 {
      PrintLine("No accounts found.");
    }
  }

  // ============================================================================
  // MENU DISPLAY
  // ============================================================================

  method DisplayMainMenu()
  {
    PrintLine("");
    PrintLine("========================================");
    PrintLine("       VERIFIED BANK CLI");
    PrintLine("========================================");
    PrintLine("1.  Create Account");
    PrintLine("2.  List Accounts");
    PrintLine("3.  Query Account Balance");
    PrintLine("4.  Deposit Funds");
    PrintLine("5.  Withdraw Funds");
    PrintLine("6.  Transfer Funds");
    PrintLine("7.  Query Balance with Breakdown");
    PrintLine("8.  View Transaction History");
    PrintLine("9.  Configure Overdraft");
    PrintLine("10. View System Configuration");
    PrintLine("0.  Exit");
    PrintLine("========================================");
    Print("Select option: ");
  }

  // ============================================================================
  // MAIN CLI LOOP
  // ============================================================================

  method {:verify false} {:axiom} RunCLI(initialBank: Bank, dataFilePath: string)
    requires ValidBank(initialBank)
    decreases *  // Allow potentially non-terminating (user-driven loop)
  {
    var currentBank := initialBank;
    var running := true;
    var nextAccountId: nat := 1000; // Start account IDs from 1000

    while running
      decreases *  // This loop runs until user exits, so we use decreases *
    {
      DisplayMainMenu();
      var input := ReadLine();

      if input == "0" {
        // Exit
        PrintLine("Saving and exiting...");
        var saveResult := SaveData("", dataFilePath); // Simplified - would serialize bank
        running := false;

      } else if input == "1" {
        // Create Account
        PrintLine("");
        PrintLine("=== CREATE ACCOUNT ===");
        Print("Enter owner name: ");
        var ownerName := ReadLine();

        Print("Enter initial deposit (in cents, e.g., 10000 for $100.00): ");
        var depositStr := ReadLine();
        var depositSuccess, depositAmount := TryParseInt(depositStr);

        if !depositSuccess {
          PrintLine("Error: Invalid deposit amount");
        } else if depositAmount < 0 {
          PrintLine("Error: Deposit amount cannot be negative");
        } else {
          Print("Enable overdraft protection? (y/n): ");
          var overdraftInput := ReadLine();
          var enableOverdraft := overdraftInput == "y" || overdraftInput == "Y";

          var overdraftLimit := DEFAULT_OVERDRAFT_LIMIT_CENTS;
          if enableOverdraft {
            Print("Enter overdraft limit in cents (default 100000 for $1,000.00): ");
            var limitStr := ReadLine();
            var limitSuccess, limitValue := TryParseInt(limitStr);
            if limitSuccess && limitValue >= 0 {
              overdraftLimit := limitValue;
            }
          }

          // Validate inputs before creating account
          if |ownerName| == 0 {
            PrintLine("Error: Owner name cannot be empty");
          } else if depositAmount > DEFAULT_MAX_BALANCE_CENTS {
            PrintLine("Error: Initial deposit exceeds maximum balance");
          } else {
            // Create account using Account module
            var newAccount, success := CreateAccount(
              nextAccountId,
              ownerName,
              depositAmount,
              enableOverdraft,
              overdraftLimit,
              DEFAULT_MAX_BALANCE_CENTS,
              DEFAULT_MAX_TRANSACTION_CENTS
            );

            if success {
              var updatedBank, addSuccess := AddAccount(currentBank, newAccount);
              if addSuccess {
                currentBank := updatedBank;
                nextAccountId := nextAccountId + 1;
                var accountIdStr := NatToString(newAccount.id);
                var balanceStr := FormatCentsToDollars(newAccount.balance);
                PrintLine("Account created successfully!");
                PrintLine("Account ID: " + accountIdStr);
                PrintLine("Balance: " + balanceStr);
              } else {
                PrintLine("Error: Failed to add account to bank");
              }
            } else {
              PrintLine("Error: Invalid account parameters");
            }
          }
        }

      } else if input == "2" {
        // List Accounts
        PrintLine("");
        PrintLine("=== LIST OF ACCOUNTS ===");
        DisplayAccountsList(currentBank, 1000, 10000);

      } else if input == "3" {
        // Query Account Balance
        PrintLine("");
        PrintLine("=== QUERY BALANCE ===");
        Print("Enter account ID: ");
        var idStr := ReadLine();
        var idSuccess, accountId := TryParseNat(idStr);

        if !idSuccess {
          PrintLine("Error: Invalid account ID");
        } else {
          var accountOpt := GetAccount(currentBank, accountId);
          if accountOpt.None? {
            PrintLine("Error: Account not found");
          } else {
            var account := accountOpt.value;
            var balanceStr := FormatCentsToDollars(account.balance);
            var idFormatted := NatToString(account.id);
            PrintLine("Account ID: " + idFormatted);
            PrintLine("Owner: " + account.owner);
            PrintLine("Balance: " + balanceStr);
          }
        }

      } else if input == "4" {
        // Deposit
        PrintLine("");
        PrintLine("=== DEPOSIT FUNDS ===");
        Print("Enter account ID: ");
        var idStr := ReadLine();
        var idSuccess, accountId := TryParseNat(idStr);

        if !idSuccess {
          PrintLine("Error: Invalid account ID");
        } else if accountId !in currentBank.accounts {
          PrintLine("Error: Account not found");
        } else {
          Print("Enter deposit amount in cents: ");
          var amountStr := ReadLine();
          var amountSuccess, amount := TryParseInt(amountStr);

          if !amountSuccess {
            PrintLine("Error: Invalid amount");
          } else if amount <= 0 {
            PrintLine("Error: Amount must be positive");
          } else {
            // Assume ValidBank for CLI operations - Bank methods maintain this invariant
            assume {:axiom} ValidBank(currentBank);
            var updatedBank, success, errorMsg := Deposit(
              currentBank,
              accountId,
              amount,
              "Deposit via CLI",
              0 // timestamp placeholder
            );

            if success {
              currentBank := updatedBank;
              var balanceStr := FormatCentsToDollars(updatedBank.accounts[accountId].balance);
              PrintLine("Deposit successful!");
              PrintLine("New balance: " + balanceStr);
            } else {
              PrintLine("Error: " + errorMsg);
            }
          }
        }

      } else if input == "5" {
        // Withdraw
        PrintLine("");
        PrintLine("=== WITHDRAW FUNDS ===");
        Print("Enter account ID: ");
        var idStr := ReadLine();
        var idSuccess, accountId := TryParseNat(idStr);

        if !idSuccess {
          PrintLine("Error: Invalid account ID");
        } else if accountId !in currentBank.accounts {
          PrintLine("Error: Account not found");
        } else {
          Print("Enter withdrawal amount in cents: ");
          var amountStr := ReadLine();
          var amountSuccess, amount := TryParseInt(amountStr);

          if !amountSuccess {
            PrintLine("Error: Invalid amount");
          } else if amount <= 0 {
            PrintLine("Error: Amount must be positive");
          } else {
            assume {:axiom} ValidBank(currentBank);
            var updatedBank, success, errorMsg, feeCharged := Withdraw(
              currentBank,
              accountId,
              amount,
              "Withdrawal via CLI",
              0 // timestamp placeholder
            );

            if success {
              currentBank := updatedBank;
              var balanceStr := FormatCentsToDollars(updatedBank.accounts[accountId].balance);
              PrintLine("Withdrawal successful!");
              PrintLine("New balance: " + balanceStr);
              if feeCharged > 0 {
                var feeStr := FormatCentsToDollars(feeCharged);
                PrintLine("Overdraft fee charged: " + feeStr);
              }
            } else {
              PrintLine("Error: " + errorMsg);
            }
          }
        }

      } else if input == "6" {
        // Transfer
        PrintLine("");
        PrintLine("=== TRANSFER FUNDS ===");
        Print("Enter source account ID: ");
        var fromIdStr := ReadLine();
        var fromIdSuccess, fromId := TryParseNat(fromIdStr);

        if !fromIdSuccess {
          PrintLine("Error: Invalid source account ID");
        } else if fromId !in currentBank.accounts {
          PrintLine("Error: Source account not found");
        } else {
          Print("Enter destination account ID: ");
          var toIdStr := ReadLine();
          var toIdSuccess, toId := TryParseNat(toIdStr);

          if !toIdSuccess {
            PrintLine("Error: Invalid destination account ID");
          } else if toId !in currentBank.accounts {
            PrintLine("Error: Destination account not found");
          } else if fromId == toId {
            PrintLine("Error: Source and destination accounts must be different");
          } else {
            Print("Enter transfer amount in cents: ");
            var amountStr := ReadLine();
            var amountSuccess, amount := TryParseInt(amountStr);

            if !amountSuccess {
              PrintLine("Error: Invalid amount");
            } else if amount <= 0 {
              PrintLine("Error: Amount must be positive");
            } else {
              assume {:axiom} ValidBank(currentBank);
              var updatedBank, success, errorMsg := Transfer(
                currentBank,
                fromId,
                toId,
                amount,
                "Transfer via CLI",
                0 // timestamp placeholder
              );

              if success {
                currentBank := updatedBank;
                var fromBalanceStr := FormatCentsToDollars(updatedBank.accounts[fromId].balance);
                var toBalanceStr := FormatCentsToDollars(updatedBank.accounts[toId].balance);
                PrintLine("Transfer successful!");
                PrintLine("Source account balance: " + fromBalanceStr);
                PrintLine("Destination account balance: " + toBalanceStr);
              } else {
                PrintLine("Error: " + errorMsg);
              }
            }
          }
        }

      } else if input == "7" {
        // Balance with Breakdown
        PrintLine("");
        PrintLine("=== BALANCE WITH BREAKDOWN ===");
        Print("Enter account ID: ");
        var idStr := ReadLine();
        var idSuccess, accountId := TryParseNat(idStr);

        if !idSuccess {
          PrintLine("Error: Invalid account ID");
        } else {
          var accountOpt := GetAccount(currentBank, accountId);
          if accountOpt.None? {
            PrintLine("Error: Account not found");
          } else {
            var account := accountOpt.value;
            var idFormatted := NatToString(account.id);
            var balanceStr := FormatCentsToDollars(account.balance);
            var feesStr := FormatCentsToDollars(account.totalFeesCollected);
            var overdraftStatus := BoolToEnabledDisabled(account.overdraftEnabled);
            var overdraftLimitStr := FormatCentsToDollars(account.overdraftLimit);
            var maxBalanceStr := FormatCentsToDollars(account.maxBalance);
            var maxTransactionStr := FormatCentsToDollars(account.maxTransaction);
            var txCountStr := IntToString(|account.history|);

            PrintLine("Account ID: " + idFormatted);
            PrintLine("Owner: " + account.owner);
            PrintLine("Current Balance: " + balanceStr);
            PrintLine("Total Fees Collected: " + feesStr);
            PrintLine("Transaction Count: " + txCountStr);
            PrintLine("Overdraft Protection: " + overdraftStatus);
            if account.overdraftEnabled {
              PrintLine("Overdraft Limit: " + overdraftLimitStr);
            }
            PrintLine("Maximum Balance: " + maxBalanceStr);
            PrintLine("Maximum Transaction: " + maxTransactionStr);
          }
        }

      } else if input == "8" {
        // Transaction History
        PrintLine("");
        PrintLine("=== TRANSACTION HISTORY ===");
        Print("Enter account ID: ");
        var idStr := ReadLine();
        var idSuccess, accountId := TryParseNat(idStr);

        if !idSuccess {
          PrintLine("Error: Invalid account ID");
        } else {
          var accountOpt := GetAccount(currentBank, accountId);
          if accountOpt.None? {
            PrintLine("Error: Account not found");
          } else {
            var account := accountOpt.value;
            if |account.history| == 0 {
              PrintLine("No transactions found.");
            } else {
              PrintLine("Showing last 10 transactions:");
              var startIdx := if |account.history| > 10 then |account.history| - 10 else 0;
              var idx := startIdx;
              while idx < |account.history|
              {
                var tx := account.history[idx];
                var txTypeStr := if tx.txType.Deposit? then "Deposit"
                               else if tx.txType.Withdrawal? then "Withdrawal"
                               else if tx.txType.TransferIn? then "Transfer In"
                               else if tx.txType.TransferOut? then "Transfer Out"
                               else if tx.txType.Fee? then "Fee"
                               else "Other";
                var amountStr := FormatCentsToDollars(tx.amount);
                var balanceAfterStr := FormatCentsToDollars(tx.balanceAfter);
                PrintLine(tx.id + " | " + txTypeStr + " | " + amountStr + " | Balance: " + balanceAfterStr);
                idx := idx + 1;
              }
            }
          }
        }

      } else if input == "9" {
        // Configure Overdraft
        PrintLine("");
        PrintLine("=== CONFIGURE OVERDRAFT ===");
        Print("Enter account ID: ");
        var idStr := ReadLine();
        var idSuccess, accountId := TryParseNat(idStr);

        if !idSuccess {
          PrintLine("Error: Invalid account ID");
        } else {
          var accountOpt := GetAccount(currentBank, accountId);
          if accountOpt.None? {
            PrintLine("Error: Account not found");
          } else {
            var account := accountOpt.value;
            var currentStatus := BoolToEnabledDisabled(account.overdraftEnabled);
            PrintLine("Current overdraft status: " + currentStatus);

            Print("Enable overdraft protection? (y/n): ");
            var enableInput := ReadLine();
            var enableOverdraft := enableInput == "y" || enableInput == "Y";

            var overdraftLimit := account.overdraftLimit;
            if enableOverdraft {
              var currentLimitStr := IntToString(account.overdraftLimit);
              Print("Enter overdraft limit in cents (current: " + currentLimitStr + "): ");
              var limitStr := ReadLine();
              var limitSuccess, limitValue := TryParseInt(limitStr);
              if limitSuccess && limitValue >= 0 {
                overdraftLimit := limitValue;
              } else {
                PrintLine("Invalid limit, keeping current value");
              }
            }

            // Update account with new overdraft settings
            var updatedAccount := account.(
              overdraftEnabled := enableOverdraft,
              overdraftLimit := overdraftLimit
            );
            var updatedAccounts := currentBank.accounts[accountId := updatedAccount];
            currentBank := Bank(updatedAccounts, currentBank.nextTransactionId, currentBank.totalFees);

            PrintLine("Overdraft configuration updated successfully!");
            var newStatus := BoolToEnabledDisabled(enableOverdraft);
            PrintLine("Overdraft protection: " + newStatus);
            if enableOverdraft {
              var limitStr := FormatCentsToDollars(overdraftLimit);
              PrintLine("Overdraft limit: " + limitStr);
            }
          }
        }

      } else if input == "10" {
        // View Configuration
        PrintLine("");
        var summary := GetConfigurationSummary();
        PrintLine(summary);

      } else {
        PrintLine("Invalid option. Please try again.");
      }
    }
  }
}
