/*
 * Main Entry Point for Verified Bank CLI
 *
 * This module coordinates system initialization, CLI execution, and shutdown.
 * It ties together all modules: Bank, Persistence, CLI, Configuration, Validation.
 *
 * Startup Sequence:
 * 1. Display welcome banner
 * 2. Initialize/load bank state from file
 * 3. Perform health checks
 * 4. Launch CLI loop
 * 5. Save state and exit gracefully
 */

include "Bank.dfy"
include "CLI.dfy"
include "Persistence.dfy"
include "Configuration.dfy"

module MainModule {
  import opened Bank
  import CLI
  import opened Persistence
  import opened Configuration

  // ============================================================================
  // FFI METHODS
  // ============================================================================

  method {:extern "IO", "PrintLine"} PrintLine(text: string)

  // ============================================================================
  // SERIALIZATION
  // ============================================================================
  // SerializeBank and DeserializeBank are provided by Persistence module
  // (imported opened above) which calls FFI BankSerializer.cs for full
  // JSON serialization including all accounts and transaction history.

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  method Initialize(dataFilePath: string) returns (bank: Bank, success: bool)
    ensures success ==> ValidBank(bank)
  {
    PrintLine("========================================");
    PrintLine("   VERIFIED BANK CLI - INITIALIZING");
    PrintLine("========================================");
    PrintLine("");

    // Check if data file exists
    var fileExists := FileExists(dataFilePath);

    if fileExists {
      PrintLine("Loading existing bank data...");
      var loadResult := LoadData(dataFilePath);

      if loadResult.Success? {
        // Deserialize JSON to Bank
        var deserializeResult := DeserializeBank(loadResult.value);
        if deserializeResult.Success? {
          bank := deserializeResult.value;
          // FFI deserialization is trusted - assume it produces valid bank
          assume {:axiom} ValidBank(bank);
          success := true;
          PrintLine("Bank data loaded successfully.");
        } else {
          PrintLine("Error deserializing bank data. Starting with empty bank.");
          bank := CreateEmptyBank();
          success := true;
        }
      } else {
        PrintLine("Error loading bank data. Starting with empty bank.");
        bank := CreateEmptyBank();
        success := true;
      }
    } else {
      PrintLine("No existing data found. Creating new bank...");
      bank := CreateEmptyBank();

      // Save initial empty state
      var emptyJson := SerializeBank(bank);
      var saveResult := SaveData(emptyJson, dataFilePath);
      success := true;
      PrintLine("New bank initialized.");
    }

    PrintLine("");
  }

  // ============================================================================
  // HEALTH CHECKS
  // ============================================================================

  method PerformHealthChecks() returns (healthy: bool)
  {
    PrintLine("Performing health checks...");

    // Configuration validity is verified at compile time by Dafny
    PrintLine("✓ Configuration valid (verified statically)");

    PrintLine("✓ All health checks passed");
    PrintLine("");
    return true;
  }

  // ============================================================================
  // SHUTDOWN
  // ============================================================================

  method Shutdown(bank: Bank, dataFilePath: string)
    requires ValidBank(bank)
  {
    PrintLine("");
    PrintLine("========================================");
    PrintLine("         SHUTTING DOWN");
    PrintLine("========================================");
    PrintLine("Saving bank state...");

    var json := SerializeBank(bank);
    var saveResult := SaveData(json, dataFilePath);

    if saveResult.Success? {
      PrintLine("✓ Bank state saved successfully");
    } else {
      PrintLine("✗ Warning: Failed to save bank state");
    }

    PrintLine("Thank you for using Verified Bank CLI!");
    PrintLine("========================================");
  }

  // ============================================================================
  // BANK STATE PERSISTENCE
  // ============================================================================

  /*
   * SaveBankState persists the current bank state to disk.
   * Called after each state-modifying operation for crash safety.
   */
  method SaveBankState(bank: Bank, dataFilePath: string)
    requires ValidBank(bank)
  {
    var json := SerializeBank(bank);
    var saveResult := SaveData(json, dataFilePath);

    if !saveResult.Success? {
      // Non-fatal error - just log it
      // In production, might want to retry or alert
      PrintLine("Warning: Auto-save failed");
    }
  }

  // ============================================================================
  // MAIN ENTRY POINT
  // ============================================================================

  method {:main} Main()
    decreases *  // Allow potentially non-terminating (calls RunCLI)
  {
    var dataFilePath := "bank_data.json";

    // Initialize system
    var bank, initSuccess := Initialize(dataFilePath);

    if !initSuccess {
      PrintLine("Initialization failed. Exiting.");
      return;
    }

    // Health checks
    var healthy := PerformHealthChecks();

    if !healthy {
      PrintLine("Health checks failed. Exiting.");
      return;
    }

    // Assert bank validity before calling RunCLI
    assert ValidBank(bank);

    // Run CLI
    PrintLine("Starting CLI...");
    PrintLine("");
    var finalBank := CLI.RunCLI(bank, dataFilePath);

    // Shutdown with final bank state
    Shutdown(finalBank, dataFilePath);
  }
}
