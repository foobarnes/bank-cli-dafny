# Bank Serialization Guide

This guide explains how to use the Bank JSON serialization/deserialization functionality.

## Overview

The Bank CLI uses a custom JSON serialization layer implemented in C# that handles:
- Dafny discriminated unions (TransactionType, AccountStatus, etc.)
- Dafny collection types (Map, Sequence)
- Dafny Option types
- Proper conversion between Dafny strings (Rune sequences) and C# strings

## Architecture

### Files

- **ffi/BankSerializer.cs**: C# implementation of JSON converters
- **src/Persistence.dfy**: FFI declarations for serialization methods
- **System.Text.Json**: Used for JSON parsing and generation

### FFI Methods

#### SerializeBank

```dafny
method {:extern "BankSerializer", "SerializeBank"} SerializeBank(bank: Bank)
  returns (json: string)
```

Converts a Bank object to JSON string representation.

**Returns:**
- JSON string on success
- Empty string on error (caller should validate)

#### DeserializeBank

```dafny
method {:extern "BankSerializer", "DeserializeBank"} DeserializeBank(json: string)
  returns (result: PersistenceResult<Bank>)
```

Converts a JSON string to Bank object.

**Returns:**
- `Success(bank)`: Valid JSON was parsed successfully
- `CorruptedData(message)`: Malformed JSON or missing required fields
- `IOError(message)`: Other deserialization errors

## JSON Schema

### Bank Structure

```json
{
  "accounts": {
    "0": {
      "id": 0,
      "owner": "John Doe",
      "balance": 100000,
      "history": [...],
      "overdraftEnabled": true,
      "overdraftLimit": 50000,
      "maxBalance": 100000000,
      "maxTransaction": 10000000,
      "totalFeesCollected": 0,
      "status": "Active",
      "createdAt": 1730304000
    }
  },
  "nextTransactionId": 1,
  "totalFees": 0
}
```

### Transaction Structure

```json
{
  "id": "TX-00001",
  "accountId": 0,
  "txType": {
    "tag": "Deposit"
  },
  "amount": 100000,
  "description": "Initial deposit",
  "timestamp": 1730304000,
  "balanceBefore": 0,
  "balanceAfter": 100000,
  "status": "Completed",
  "parentTxId": null,
  "childTxIds": []
}
```

### TransactionType Discriminated Union

**Simple Types:**
```json
{"tag": "Deposit"}
{"tag": "Withdrawal"}
{"tag": "TransferIn"}
{"tag": "TransferOut"}
{"tag": "Interest"}
{"tag": "Adjustment"}
```

**Fee Type (with details - future enhancement):**
```json
{
  "tag": "Fee",
  "category": "OverdraftFee",
  "details": {
    "tierBreakdown": [...],
    "baseAmount": -3500,
    "calculationNote": "Overdraft fee - Tier 2"
  }
}
```

### AccountStatus Enum

String values:
- `"Active"`
- `"Suspended"`
- `"Closed"`

### TransactionStatus Enum

String values:
- `"Pending"`
- `"Completed"`
- `"Failed"`
- `"RolledBack"`

### Option Type

Option types are serialized as:
- `null` for `None`
- The value itself for `Some(value)`

Examples:
```json
"parentTxId": null                    // None
"parentTxId": "TX-00042"             // Some("TX-00042")
```

## Usage Examples

### Saving Bank State

```dafny
method SaveBankToFile(bank: Bank, filePath: string) returns (result: PersistenceResult<Unit>)
  requires ValidBank(bank)
{
  // Serialize bank to JSON
  var json := SerializeBank(bank);

  // Validate serialization succeeded
  if |json| == 0 {
    return IOError("Serialization failed");
  }

  // Save to file
  var saveResult := SaveData(json, filePath);
  return saveResult;
}
```

### Loading Bank State

```dafny
method LoadBankFromFile(filePath: string) returns (result: PersistenceResult<Bank>)
{
  // Load JSON from file
  var loadResult := LoadData(filePath);

  match loadResult {
    case Success(json) =>
      // Deserialize JSON to Bank
      var deserializeResult := DeserializeBank(json);
      return deserializeResult;

    case FileNotFound(path) =>
      return FileNotFound(path);

    case PermissionDenied(path) =>
      return PermissionDenied(path);

    case CorruptedData(msg) =>
      return CorruptedData(msg);

    case IOError(msg) =>
      return IOError(msg);
  }
}
```

### Complete Persistence Workflow

```dafny
method PersistBankWithBackup(bank: Bank, filePath: string)
  returns (result: PersistenceResult<Unit>)
  requires ValidBank(bank)
{
  // Create backup of existing file
  var backupResult := CreateBackup(filePath);

  // Check if backup succeeded (or file didn't exist)
  if backupResult.Success? {
    // Save bank state
    var saveResult := SaveBankToFile(bank, filePath);
    return saveResult;
  } else {
    return IOError("Backup failed");
  }
}
```

## Custom Converters

The serialization system includes custom JSON converters for Dafny types:

### BankConverter
Handles Bank datatype with map of accounts.

### AccountConverter
Handles Account datatype with transaction history.

### TransactionConverter
Handles Transaction datatype with discriminated union types.

### TransactionTypeConverter
Handles TransactionType discriminated union with tag-based serialization.

### AccountStatusConverter / TransactionStatusConverter
Handle enum-like datatypes as strings.

### OptionConverter
Handles Option<T> discriminated union as null/value.

### DafnyMapConverter
Converts Dafny Map<K,V> to JSON object with string keys.

### DafnySequenceConverter
Converts Dafny Sequence<T> to JSON array.

## Error Handling

### Serialization Errors

SerializeBank returns an empty string on error. Always validate:

```dafny
var json := SerializeBank(bank);
if |json| == 0 {
  // Handle serialization error
  return IOError("Failed to serialize bank");
}
```

### Deserialization Errors

DeserializeBank returns detailed error information:

```dafny
var result := DeserializeBank(json);
match result {
  case Success(bank) =>
    // Use bank object

  case CorruptedData(msg) =>
    // JSON was malformed or invalid structure
    // msg contains detailed error information

  case IOError(msg) =>
    // Other deserialization error
    // msg contains detailed error information

  case _ =>
    // Should not occur for deserialization
}
```

## Implementation Notes

### Dafny String Conversion

Dafny strings are represented as `ISequence<Dafny.Rune>`. The serializer includes helper methods to convert between Dafny strings and C# strings:

```csharp
private static string RuneSequenceToString(ISequence<Dafny.Rune> runes)
{
    var sb = new StringBuilder();
    foreach (var rune in runes.Elements)
    {
        sb.Append((char)rune.Value);
    }
    return sb.ToString();
}
```

### Numeric Types

- Dafny `nat` and `int` are represented as `BigInteger` in C#
- JSON serialization converts these to `long` (64-bit signed integer)
- This limits values to the range of `long` (-2^63 to 2^63-1)
- All monetary amounts are in cents, well within this range

### Map Key Serialization

JSON requires string keys. The DafnyMapConverter converts numeric account IDs to strings for JSON:

```json
"accounts": {
  "0": {...},
  "1": {...}
}
```

On deserialization, these strings are converted back to `BigInteger` keys.

## Future Enhancements

### Fee Details Serialization

Currently, Fee transactions with FeeDetails are serialized with minimal information. A future enhancement will include full tier breakdown serialization:

```json
{
  "tag": "Fee",
  "category": "OverdraftFee",
  "details": {
    "tierBreakdown": [
      {
        "tier": 0,
        "rangeStart": 1,
        "rangeEnd": 10000,
        "applicableAmount": 10000,
        "feeRate": 2500,
        "charge": -2500
      }
    ],
    "baseAmount": -2500,
    "calculationNote": "Overdraft fee calculation"
  }
}
```

### Schema Validation

Future versions may include JSON schema validation to ensure loaded data conforms to expected structure before deserialization.

### Versioning

Consider adding a version field to support schema evolution:

```json
{
  "version": "1.0",
  "accounts": {...},
  ...
}
```

## Testing

To test serialization:

1. Create a Bank object with test data
2. Serialize to JSON and inspect output
3. Deserialize back to Bank object
4. Verify Bank state matches original

Example test:

```dafny
method TestRoundTrip() returns (success: bool)
{
  // Create test bank
  var bank := CreateEmptyBank();

  // Serialize
  var json := SerializeBank(bank);
  if |json| == 0 {
    return false;
  }

  // Deserialize
  var result := DeserializeBank(json);
  match result {
    case Success(loadedBank) =>
      // Verify state matches
      success := loadedBank.nextTransactionId == bank.nextTransactionId
                 && loadedBank.totalFees == bank.totalFees;

    case _ =>
      success := false;
  }
}
```

## See Also

- **docs/specs/REFERENCE.md**: Complete JSON schema reference
- **docs/specs/ERROR_HANDLING.md**: Error handling specifications
- **ffi/FileStorage.cs**: File I/O implementation
- **src/Persistence.dfy**: FFI declarations
