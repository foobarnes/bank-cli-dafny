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
include "Validation.dfy"
include "Configuration.dfy"
include "Persistence.dfy"

module CLI {
  import opened Bank
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

  method RunCLI(initialBank: Bank, dataFilePath: string)
  {
    var currentBank := initialBank;
    var running := true;

    while running
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
        PrintLine("Create Account selected");
        PrintLine("(Not yet implemented)");
      } else if input == "2" {
        // List Accounts
        PrintLine("List Accounts selected");
        PrintLine("(Not yet implemented)");
      } else if input == "3" {
        // Query Account Balance
        PrintLine("Query Balance selected");
        PrintLine("(Not yet implemented)");
      } else if input == "4" {
        // Deposit
        PrintLine("Deposit selected");
        PrintLine("(Not yet implemented)");
      } else if input == "5" {
        // Withdraw
        PrintLine("Withdraw selected");
        PrintLine("(Not yet implemented)");
      } else if input == "6" {
        // Transfer
        PrintLine("Transfer selected");
        PrintLine("(Not yet implemented)");
      } else if input == "7" {
        // Balance with Breakdown
        PrintLine("Balance Breakdown selected");
        PrintLine("(Not yet implemented)");
      } else if input == "8" {
        // Transaction History
        PrintLine("Transaction History selected");
        PrintLine("(Not yet implemented)");
      } else if input == "9" {
        // Configure Overdraft
        PrintLine("Configure Overdraft selected");
        PrintLine("(Not yet implemented)");
      } else if input == "10" {
        // View Configuration
        var summary := GetConfigurationSummary();
        PrintLine(summary);
      } else {
        PrintLine("Invalid option. Please try again.");
      }
    }
  }
}
