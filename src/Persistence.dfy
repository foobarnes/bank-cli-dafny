/*
 * Persistence Module for Verified Bank CLI
 *
 * This module provides the FFI (Foreign Function Interface) boundary between
 * verified Dafny code and external file I/O operations implemented in C#.
 *
 * Design Principles:
 * - Minimal trusted FFI surface - only essential file operations
 * - All FFI methods marked with {:extern} for C# implementation
 * - Returns Result types for explicit error handling
 * - Validation happens in Dafny before/after FFI calls
 * - No verification of FFI internals (trusted boundary)
 *
 * FFI Layer Contract:
 * - SaveBank: Serializes bank state to JSON file
 * - LoadBank: Deserializes bank state from JSON file
 * - CreateBackup: Creates timestamped backup before save
 * - FileExists: Checks if data file exists (for initialization)
 */

// Simplified Persistence module - FFI boundary only
// Full Bank integration will be in a separate PersistenceImpl module

module Persistence {

  // ============================================================================
  // RESULT TYPES FOR FILE OPERATIONS
  // ============================================================================

  /*
   * PersistenceResult wraps file operation outcomes with detailed error info.
   * Success case returns the operation result (Unit for saves, Bank for loads).
   */
  datatype PersistenceResult<T> =
    | Success(value: T)
    | FileNotFound(path: string)
    | PermissionDenied(path: string)
    | CorruptedData(message: string)
    | IOError(message: string)

  /*
   * Unit type for operations that don't return a value (like save)
   */
  datatype Unit = Unit

  // ============================================================================
  // FFI METHOD SIGNATURES
  // ============================================================================

  /*
   * SaveData persists a JSON string to file.
   *
   * FFI Contract:
   * - Writes jsonData string to filePath
   * - Creates backup of existing file before overwrite
   * - Atomically writes new file (write to temp, then rename)
   * - Returns Success(Unit) on success, error variant on failure
   *
   * The actual implementation is in ffi/FileStorage.cs
   */
  method {:extern "FileStorage", "SaveData"} SaveData(jsonData: string, filePath: string)
    returns (result: PersistenceResult<Unit>)
    ensures result.Success? ==> result.value == Unit

  /*
   * LoadData reads a JSON string from file.
   *
   * FFI Contract:
   * - Reads file contents as string
   * - Returns Success(jsonData) with file contents on success
   * - Returns appropriate error variant on failure
   *
   * The actual implementation is in ffi/FileStorage.cs
   */
  method {:extern "FileStorage", "LoadData"} LoadData(filePath: string)
    returns (result: PersistenceResult<string>)
    // No postconditions - we can't verify FFI behavior

  /*
   * CreateBackup creates a timestamped backup of the current data file.
   *
   * FFI Contract:
   * - Copies current file to backup with timestamp in filename
   * - Format: <filename>.backup.<timestamp>.json
   * - Only keeps last N backups (configured in Configuration module)
   * - Returns Success(Unit) on success
   *
   * The actual implementation is in ffi/FileStorage.cs
   */
  method {:extern "FileStorage", "CreateBackup"} CreateBackup(filePath: string)
    returns (result: PersistenceResult<Unit>)
    ensures result.Success? ==> result.value == Unit

  /*
   * FileExists checks if a file exists at the given path.
   *
   * FFI Contract:
   * - Returns true if file exists and is accessible
   * - Returns false if file doesn't exist
   * - Never throws exceptions - returns false for permission issues
   *
   * The actual implementation is in ffi/FileStorage.cs
   */
  method {:extern "FileStorage", "FileExists"} FileExists(filePath: string)
    returns (fileExists: bool)
    // Simple boolean return - no error cases

  // ============================================================================
  // VALIDATED PERSISTENCE OPERATIONS
  // ============================================================================

  /*
   * Note: The Bank-specific wrapper methods (SaveBankWithValidation, LoadBankWithValidation)
   * would be implemented in a separate module that imports both Persistence and Bank.
   * This keeps the FFI boundary module minimal and focused.
   */

  // ============================================================================
  // HELPER METHODS FOR ERROR HANDLING
  // ============================================================================

  /*
   * IsPersistenceError checks if a result represents an error
   */
  predicate IsPersistenceError<T>(result: PersistenceResult<T>)
  {
    !result.Success?
  }

  /*
   * GetErrorMessage extracts a human-readable error message from a result
   */
  method GetErrorMessage<T>(result: PersistenceResult<T>) returns (message: string)
    requires IsPersistenceError(result)
  {
    match result {
      case FileNotFound(path) =>
        message := "File not found: " + path;
      case PermissionDenied(path) =>
        message := "Permission denied: " + path;
      case CorruptedData(msg) =>
        message := "Corrupted data: " + msg;
      case IOError(msg) =>
        message := "I/O error: " + msg;
      case Success(_) =>
        message := ""; // Should never reach here due to precondition
    }
  }
}
