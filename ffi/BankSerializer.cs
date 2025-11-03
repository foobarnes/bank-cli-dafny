using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Dafny;

/// <summary>
/// BankSerializer provides JSON serialization/deserialization for Bank datatypes.
/// Handles conversion between Dafny types and JSON with custom converters for discriminated unions.
/// </summary>
public class BankSerializer
{
    // ============================================================================
    // SERIALIZATION ENTRY POINTS
    // ============================================================================

    /// <summary>
    /// Serializes a Bank object to JSON string
    /// </summary>
    public static ISequence<Dafny.Rune> SerializeBank(Bank._IBank bank)
    {
        try
        {
            var options = CreateJsonOptions();
            var json = JsonSerializer.Serialize(bank, options);
            return Sequence<Dafny.Rune>.UnicodeFromString(json);
        }
        catch (Exception ex)
        {
            // Return empty string on serialization error
            // Caller should validate the result
            return Sequence<Dafny.Rune>.UnicodeFromString("");
        }
    }

    /// <summary>
    /// Deserializes JSON string to Bank object
    /// Returns PersistenceResult with success or error
    /// </summary>
    public static Persistence._IPersistenceResult<Bank._IBank> DeserializeBank(
        ISequence<Dafny.Rune> json
    )
    {
        try
        {
            string jsonString = RuneSequenceToString(json);

            if (string.IsNullOrWhiteSpace(jsonString))
            {
                return Persistence.PersistenceResult<Bank._IBank>.create_CorruptedData(
                    Sequence<Dafny.Rune>.UnicodeFromString("Empty JSON string")
                );
            }

            var options = CreateJsonOptions();
            var bank = JsonSerializer.Deserialize<Bank._IBank>(jsonString, options);

            if (bank == null)
            {
                return Persistence.PersistenceResult<Bank._IBank>.create_CorruptedData(
                    Sequence<Dafny.Rune>.UnicodeFromString("Deserialization returned null")
                );
            }

            return Persistence.PersistenceResult<Bank._IBank>.create_Success(bank);
        }
        catch (JsonException ex)
        {
            return Persistence.PersistenceResult<Bank._IBank>.create_CorruptedData(
                Sequence<Dafny.Rune>.UnicodeFromString($"JSON parse error: {ex.Message}")
            );
        }
        catch (Exception ex)
        {
            return Persistence.PersistenceResult<Bank._IBank>.create_IOError(
                Sequence<Dafny.Rune>.UnicodeFromString($"Deserialization error: {ex.Message}")
            );
        }
    }

    // ============================================================================
    // JSON OPTIONS CONFIGURATION
    // ============================================================================

    private static JsonSerializerOptions CreateJsonOptions()
    {
        var options = new JsonSerializerOptions
        {
            WriteIndented = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            DefaultIgnoreCondition = JsonIgnoreCondition.Never,
            Converters =
            {
                new BankConverter(),
                new AccountConverter(),
                new TransactionConverter(),
                new FeeCategoryConverter(),
                new TierChargeConverter(),
                new FeeDetailsConverter(),
                new TransactionTypeConverter(),
                new AccountStatusConverter(),
                new TransactionStatusConverter(),
                new OptionConverter(),
                new DafnyMapConverter(),
                new DafnySequenceConverter()
            }
        };
        return options;
    }

    // ============================================================================
    // HELPER METHODS
    // ============================================================================

    private static string RuneSequenceToString(ISequence<Dafny.Rune> runes)
    {
        var sb = new StringBuilder();
        foreach (var rune in runes.Elements)
        {
            sb.Append((char)rune.Value);
        }
        return sb.ToString();
    }

    // ============================================================================
    // CUSTOM JSON CONVERTERS
    // ============================================================================

    /// <summary>
    /// Converter for Bank datatype
    /// </summary>
    private class BankConverter : JsonConverter<Bank._IBank>
    {
        public override Bank._IBank Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
                throw new JsonException("Expected StartObject token");

            IMap<BigInteger, Account._IAccount> accounts = null;
            BigInteger nextTransactionId = BigInteger.Zero;
            BigInteger totalFees = BigInteger.Zero;

            while (reader.Read())
            {
                if (reader.TokenType == JsonTokenType.EndObject)
                    break;

                if (reader.TokenType != JsonTokenType.PropertyName)
                    throw new JsonException("Expected PropertyName token");

                string propertyName = reader.GetString();
                reader.Read();

                switch (propertyName)
                {
                    case "accounts":
                        var mapConverter = new DafnyMapConverter();
                        accounts = (IMap<BigInteger, Account._IAccount>)mapConverter.Read(ref reader, typeof(IMap<BigInteger, Account._IAccount>), options);
                        break;
                    case "nextTransactionId":
                        nextTransactionId = new BigInteger(reader.GetInt64());
                        break;
                    case "totalFees":
                        totalFees = new BigInteger(reader.GetInt64());
                        break;
                }
            }

            if (accounts == null)
                accounts = Map<BigInteger, Account._IAccount>.Empty;

            return new Bank._Bank(accounts, nextTransactionId, totalFees);
        }

        public override void Write(Utf8JsonWriter writer, Bank._IBank value, JsonSerializerOptions options)
        {
            var bank = (Bank._Bank)value;

            writer.WriteStartObject();

            writer.WritePropertyName("accounts");
            var mapConverter = new DafnyMapConverter();
            mapConverter.Write(writer, bank._accounts, options);

            writer.WriteNumber("nextTransactionId", (long)bank._nextTransactionId);
            writer.WriteNumber("totalFees", (long)bank._totalFees);

            writer.WriteEndObject();
        }
    }

    /// <summary>
    /// Converter for Account datatype
    /// </summary>
    private class AccountConverter : JsonConverter<Account._IAccount>
    {
        public override Account._IAccount Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
                throw new JsonException("Expected StartObject token");

            BigInteger id = BigInteger.Zero;
            string owner = "";
            BigInteger balance = BigInteger.Zero;
            ISequence<Transaction._ITransaction> history = Sequence<Transaction._ITransaction>.Empty;
            bool overdraftEnabled = false;
            BigInteger overdraftLimit = BigInteger.Zero;
            BigInteger maxBalance = BigInteger.Zero;
            BigInteger maxTransaction = BigInteger.Zero;
            BigInteger totalFeesCollected = BigInteger.Zero;
            Account._IAccountStatus status = Account.AccountStatus.create_Active();
            BigInteger createdAt = BigInteger.Zero;

            while (reader.Read())
            {
                if (reader.TokenType == JsonTokenType.EndObject)
                    break;

                if (reader.TokenType != JsonTokenType.PropertyName)
                    throw new JsonException("Expected PropertyName token");

                string propertyName = reader.GetString();
                reader.Read();

                switch (propertyName)
                {
                    case "id":
                        id = new BigInteger(reader.GetInt64());
                        break;
                    case "owner":
                        owner = reader.GetString() ?? "";
                        break;
                    case "balance":
                        balance = new BigInteger(reader.GetInt64());
                        break;
                    case "history":
                        var seqConverter = new DafnySequenceConverter();
                        history = (ISequence<Transaction._ITransaction>)seqConverter.Read(ref reader, typeof(ISequence<Transaction._ITransaction>), options);
                        break;
                    case "overdraftEnabled":
                        overdraftEnabled = reader.GetBoolean();
                        break;
                    case "overdraftLimit":
                        overdraftLimit = new BigInteger(reader.GetInt64());
                        break;
                    case "maxBalance":
                        maxBalance = new BigInteger(reader.GetInt64());
                        break;
                    case "maxTransaction":
                        maxTransaction = new BigInteger(reader.GetInt64());
                        break;
                    case "totalFeesCollected":
                        totalFeesCollected = new BigInteger(reader.GetInt64());
                        break;
                    case "status":
                        var statusConverter = new AccountStatusConverter();
                        status = statusConverter.Read(ref reader, typeof(Account._IAccountStatus), options);
                        break;
                    case "createdAt":
                        createdAt = new BigInteger(reader.GetInt64());
                        break;
                }
            }

            return new Account._Account(
                id,
                Sequence<Dafny.Rune>.UnicodeFromString(owner),
                balance,
                history,
                overdraftEnabled,
                overdraftLimit,
                maxBalance,
                maxTransaction,
                totalFeesCollected,
                status,
                createdAt
            );
        }

        public override void Write(Utf8JsonWriter writer, Account._IAccount value, JsonSerializerOptions options)
        {
            var account = (Account._Account)value;

            writer.WriteStartObject();
            writer.WriteNumber("id", (long)account._id);
            writer.WriteString("owner", RuneSequenceToString(account._owner));
            writer.WriteNumber("balance", (long)account._balance);

            writer.WritePropertyName("history");
            var seqConverter = new DafnySequenceConverter();
            seqConverter.Write(writer, account._history, options);

            writer.WriteBoolean("overdraftEnabled", account._overdraftEnabled);
            writer.WriteNumber("overdraftLimit", (long)account._overdraftLimit);
            writer.WriteNumber("maxBalance", (long)account._maxBalance);
            writer.WriteNumber("maxTransaction", (long)account._maxTransaction);
            writer.WriteNumber("totalFeesCollected", (long)account._totalFeesCollected);

            writer.WritePropertyName("status");
            var statusConverter = new AccountStatusConverter();
            statusConverter.Write(writer, account._status, options);

            writer.WriteNumber("createdAt", (long)account._createdAt);
            writer.WriteEndObject();
        }
    }

    /// <summary>
    /// Converter for Transaction datatype
    /// </summary>
    private class TransactionConverter : JsonConverter<Transaction._ITransaction>
    {
        public override Transaction._ITransaction Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
                throw new JsonException("Expected StartObject token");

            string id = "";
            BigInteger accountId = BigInteger.Zero;
            Transaction._ITransactionType txType = Transaction.TransactionType.create_Deposit();
            BigInteger amount = BigInteger.Zero;
            string description = "";
            BigInteger timestamp = BigInteger.Zero;
            BigInteger balanceBefore = BigInteger.Zero;
            BigInteger balanceAfter = BigInteger.Zero;
            Transaction._ITransactionStatus status = Transaction.TransactionStatus.create_Completed();
            Transaction._IOption<ISequence<Dafny.Rune>> parentTxId = Transaction.Option<ISequence<Dafny.Rune>>.create_None();
            ISequence<ISequence<Dafny.Rune>> childTxIds = Sequence<ISequence<Dafny.Rune>>.Empty;

            while (reader.Read())
            {
                if (reader.TokenType == JsonTokenType.EndObject)
                    break;

                if (reader.TokenType != JsonTokenType.PropertyName)
                    throw new JsonException("Expected PropertyName token");

                string propertyName = reader.GetString();
                reader.Read();

                switch (propertyName)
                {
                    case "id":
                        id = reader.GetString() ?? "";
                        break;
                    case "accountId":
                        accountId = new BigInteger(reader.GetInt64());
                        break;
                    case "txType":
                        var txTypeConverter = new TransactionTypeConverter();
                        txType = txTypeConverter.Read(ref reader, typeof(Transaction._ITransactionType), options);
                        break;
                    case "amount":
                        amount = new BigInteger(reader.GetInt64());
                        break;
                    case "description":
                        description = reader.GetString() ?? "";
                        break;
                    case "timestamp":
                        timestamp = new BigInteger(reader.GetInt64());
                        break;
                    case "balanceBefore":
                        balanceBefore = new BigInteger(reader.GetInt64());
                        break;
                    case "balanceAfter":
                        balanceAfter = new BigInteger(reader.GetInt64());
                        break;
                    case "status":
                        var statusConverter = new TransactionStatusConverter();
                        status = statusConverter.Read(ref reader, typeof(Transaction._ITransactionStatus), options);
                        break;
                    case "parentTxId":
                        var optionConverter = new OptionConverter();
                        parentTxId = (Transaction._IOption<ISequence<Dafny.Rune>>)optionConverter.Read(ref reader, typeof(Transaction._IOption<ISequence<Dafny.Rune>>), options);
                        break;
                    case "childTxIds":
                        childTxIds = ReadStringSequence(ref reader);
                        break;
                }
            }

            return new Transaction._Transaction(
                Sequence<Dafny.Rune>.UnicodeFromString(id),
                accountId,
                txType,
                amount,
                Sequence<Dafny.Rune>.UnicodeFromString(description),
                timestamp,
                balanceBefore,
                balanceAfter,
                status,
                parentTxId,
                childTxIds
            );
        }

        public override void Write(Utf8JsonWriter writer, Transaction._ITransaction value, JsonSerializerOptions options)
        {
            var tx = (Transaction._Transaction)value;

            writer.WriteStartObject();
            writer.WriteString("id", RuneSequenceToString(tx._id));
            writer.WriteNumber("accountId", (long)tx._accountId);

            writer.WritePropertyName("txType");
            var txTypeConverter = new TransactionTypeConverter();
            txTypeConverter.Write(writer, tx._txType, options);

            writer.WriteNumber("amount", (long)tx._amount);
            writer.WriteString("description", RuneSequenceToString(tx._description));
            writer.WriteNumber("timestamp", (long)tx._timestamp);
            writer.WriteNumber("balanceBefore", (long)tx._balanceBefore);
            writer.WriteNumber("balanceAfter", (long)tx._balanceAfter);

            writer.WritePropertyName("status");
            var statusConverter = new TransactionStatusConverter();
            statusConverter.Write(writer, tx._status, options);

            writer.WritePropertyName("parentTxId");
            var optionConverter = new OptionConverter();
            optionConverter.Write(writer, tx._parentTxId, options);

            writer.WritePropertyName("childTxIds");
            WriteStringSequence(writer, tx._childTxIds);

            writer.WriteEndObject();
        }

        private ISequence<ISequence<Dafny.Rune>> ReadStringSequence(ref Utf8JsonReader reader)
        {
            if (reader.TokenType != JsonTokenType.StartArray)
                throw new JsonException("Expected StartArray token");

            var list = new List<ISequence<Dafny.Rune>>();

            while (reader.Read())
            {
                if (reader.TokenType == JsonTokenType.EndArray)
                    break;

                if (reader.TokenType == JsonTokenType.String)
                {
                    list.Add(Sequence<Dafny.Rune>.UnicodeFromString(reader.GetString() ?? ""));
                }
            }

            return Sequence<ISequence<Dafny.Rune>>.FromArray(list.ToArray());
        }

        private void WriteStringSequence(Utf8JsonWriter writer, ISequence<ISequence<Dafny.Rune>> seq)
        {
            writer.WriteStartArray();
            foreach (var item in seq.Elements)
            {
                writer.WriteStringValue(RuneSequenceToString(item));
            }
            writer.WriteEndArray();
        }
    }

    /// <summary>
    /// Converter for TransactionType discriminated union
    /// </summary>
    private class TransactionTypeConverter : JsonConverter<Transaction._ITransactionType>
    {
        public override Transaction._ITransactionType Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
                throw new JsonException("Expected StartObject token");

            string tag = null;
            Transaction._IFeeCategory category = null;
            Transaction._IFeeDetails details = null;

            while (reader.Read())
            {
                if (reader.TokenType == JsonTokenType.EndObject)
                    break;

                if (reader.TokenType == JsonTokenType.PropertyName)
                {
                    string propertyName = reader.GetString();
                    reader.Read();

                    switch (propertyName)
                    {
                        case "tag":
                            tag = reader.GetString();
                            break;
                        case "category":
                            var categoryConverter = new FeeCategoryConverter();
                            category = categoryConverter.Read(ref reader, typeof(Transaction._IFeeCategory), options);
                            break;
                        case "details":
                            var detailsConverter = new FeeDetailsConverter();
                            details = detailsConverter.Read(ref reader, typeof(Transaction._IFeeDetails), options);
                            break;
                    }
                }
            }

            return tag switch
            {
                "Deposit" => Transaction.TransactionType.create_Deposit(),
                "Withdrawal" => Transaction.TransactionType.create_Withdrawal(),
                "TransferIn" => Transaction.TransactionType.create_TransferIn(),
                "TransferOut" => Transaction.TransactionType.create_TransferOut(),
                "Fee" => Transaction.TransactionType.create_Fee(
                    category ?? Transaction.FeeCategory.create_OverdraftFee(),
                    details ?? new Transaction.FeeDetails(
                        Sequence<Transaction._ITierCharge>.Empty,
                        BigInteger.Zero,
                        Sequence<Dafny.Rune>.UnicodeFromString("")
                    )
                ),
                "Interest" => Transaction.TransactionType.create_Interest(),
                "Adjustment" => Transaction.TransactionType.create_Adjustment(),
                _ => Transaction.TransactionType.create_Deposit() // Default fallback
            };
        }

        public override void Write(Utf8JsonWriter writer, Transaction._ITransactionType value, JsonSerializerOptions options)
        {
            writer.WriteStartObject();

            if (value.is_Deposit)
                writer.WriteString("tag", "Deposit");
            else if (value.is_Withdrawal)
                writer.WriteString("tag", "Withdrawal");
            else if (value.is_TransferIn)
                writer.WriteString("tag", "TransferIn");
            else if (value.is_TransferOut)
                writer.WriteString("tag", "TransferOut");
            else if (value.is_Interest)
                writer.WriteString("tag", "Interest");
            else if (value.is_Adjustment)
                writer.WriteString("tag", "Adjustment");
            else if (value.is_Fee)
            {
                writer.WriteString("tag", "Fee");

                writer.WritePropertyName("category");
                var categoryConverter = new FeeCategoryConverter();
                categoryConverter.Write(writer, value.dtor_category, options);

                writer.WritePropertyName("details");
                var detailsConverter = new FeeDetailsConverter();
                detailsConverter.Write(writer, value.dtor_details, options);
            }

            writer.WriteEndObject();
        }
    }

    /// <summary>
    /// Converter for AccountStatus enum
    /// </summary>
    private class AccountStatusConverter : JsonConverter<Account._IAccountStatus>
    {
        public override Account._IAccountStatus Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            string value = reader.GetString();
            return value switch
            {
                "Active" => Account.AccountStatus.create_Active(),
                "Suspended" => Account.AccountStatus.create_Suspended(),
                "Closed" => Account.AccountStatus.create_Closed(),
                _ => Account.AccountStatus.create_Active()
            };
        }

        public override void Write(Utf8JsonWriter writer, Account._IAccountStatus value, JsonSerializerOptions options)
        {
            if (value.is_Active)
                writer.WriteStringValue("Active");
            else if (value.is_Suspended)
                writer.WriteStringValue("Suspended");
            else if (value.is_Closed)
                writer.WriteStringValue("Closed");
        }
    }

    /// <summary>
    /// Converter for TransactionStatus enum
    /// </summary>
    private class TransactionStatusConverter : JsonConverter<Transaction._ITransactionStatus>
    {
        public override Transaction._ITransactionStatus Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            string value = reader.GetString();
            return value switch
            {
                "Pending" => Transaction.TransactionStatus.create_Pending(),
                "Completed" => Transaction.TransactionStatus.create_Completed(),
                "Failed" => Transaction.TransactionStatus.create_Failed(),
                "RolledBack" => Transaction.TransactionStatus.create_RolledBack(),
                _ => Transaction.TransactionStatus.create_Completed()
            };
        }

        public override void Write(Utf8JsonWriter writer, Transaction._ITransactionStatus value, JsonSerializerOptions options)
        {
            if (value.is_Pending)
                writer.WriteStringValue("Pending");
            else if (value.is_Completed)
                writer.WriteStringValue("Completed");
            else if (value.is_Failed)
                writer.WriteStringValue("Failed");
            else if (value.is_RolledBack)
                writer.WriteStringValue("RolledBack");
        }
    }

    /// <summary>
    /// Converter for FeeCategory enum
    /// </summary>
    private class FeeCategoryConverter : JsonConverter<Transaction._IFeeCategory>
    {
        public override Transaction._IFeeCategory Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            string value = reader.GetString();
            return value switch
            {
                "OverdraftFee" => Transaction.FeeCategory.create_OverdraftFee(),
                "MaintenanceFee" => Transaction.FeeCategory.create_MaintenanceFee(),
                "TransferFee" => Transaction.FeeCategory.create_TransferFee(),
                "ATMFee" => Transaction.FeeCategory.create_ATMFee(),
                "InsufficientFundsFee" => Transaction.FeeCategory.create_InsufficientFundsFee(),
                _ => Transaction.FeeCategory.create_OverdraftFee()
            };
        }

        public override void Write(Utf8JsonWriter writer, Transaction._IFeeCategory value, JsonSerializerOptions options)
        {
            if (value.is_OverdraftFee)
                writer.WriteStringValue("OverdraftFee");
            else if (value.is_MaintenanceFee)
                writer.WriteStringValue("MaintenanceFee");
            else if (value.is_TransferFee)
                writer.WriteStringValue("TransferFee");
            else if (value.is_ATMFee)
                writer.WriteStringValue("ATMFee");
            else if (value.is_InsufficientFundsFee)
                writer.WriteStringValue("InsufficientFundsFee");
        }
    }

    /// <summary>
    /// Converter for TierCharge datatype
    /// </summary>
    private class TierChargeConverter : JsonConverter<Transaction._ITierCharge>
    {
        public override Transaction._ITierCharge Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
                throw new JsonException("Expected StartObject token");

            BigInteger tier = BigInteger.Zero;
            BigInteger rangeStart = BigInteger.Zero;
            BigInteger rangeEnd = BigInteger.Zero;
            BigInteger applicableAmount = BigInteger.Zero;
            BigInteger feeRate = BigInteger.Zero;
            BigInteger charge = BigInteger.Zero;

            while (reader.Read())
            {
                if (reader.TokenType == JsonTokenType.EndObject)
                    break;

                if (reader.TokenType != JsonTokenType.PropertyName)
                    throw new JsonException("Expected PropertyName token");

                string propertyName = reader.GetString();
                reader.Read();

                switch (propertyName)
                {
                    case "tier":
                        tier = new BigInteger(reader.GetInt64());
                        break;
                    case "rangeStart":
                        rangeStart = new BigInteger(reader.GetInt64());
                        break;
                    case "rangeEnd":
                        rangeEnd = new BigInteger(reader.GetInt64());
                        break;
                    case "applicableAmount":
                        applicableAmount = new BigInteger(reader.GetInt64());
                        break;
                    case "feeRate":
                        feeRate = new BigInteger(reader.GetInt64());
                        break;
                    case "charge":
                        charge = new BigInteger(reader.GetInt64());
                        break;
                }
            }

            return new Transaction.TierCharge(tier, rangeStart, rangeEnd, applicableAmount, feeRate, charge);
        }

        public override void Write(Utf8JsonWriter writer, Transaction._ITierCharge value, JsonSerializerOptions options)
        {
            var tierCharge = (Transaction.TierCharge)value;

            writer.WriteStartObject();
            writer.WriteNumber("tier", (long)tierCharge._tier);
            writer.WriteNumber("rangeStart", (long)tierCharge._rangeStart);
            writer.WriteNumber("rangeEnd", (long)tierCharge._rangeEnd);
            writer.WriteNumber("applicableAmount", (long)tierCharge._applicableAmount);
            writer.WriteNumber("feeRate", (long)tierCharge._feeRate);
            writer.WriteNumber("charge", (long)tierCharge._charge);
            writer.WriteEndObject();
        }
    }

    /// <summary>
    /// Converter for FeeDetails datatype
    /// </summary>
    private class FeeDetailsConverter : JsonConverter<Transaction._IFeeDetails>
    {
        public override Transaction._IFeeDetails Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
                throw new JsonException("Expected StartObject token");

            ISequence<Transaction._ITierCharge> tierBreakdown = Sequence<Transaction._ITierCharge>.Empty;
            BigInteger baseAmount = BigInteger.Zero;
            string calculationNote = "";

            while (reader.Read())
            {
                if (reader.TokenType == JsonTokenType.EndObject)
                    break;

                if (reader.TokenType != JsonTokenType.PropertyName)
                    throw new JsonException("Expected PropertyName token");

                string propertyName = reader.GetString();
                reader.Read();

                switch (propertyName)
                {
                    case "tierBreakdown":
                        var seqConverter = new DafnySequenceConverter();
                        tierBreakdown = (ISequence<Transaction._ITierCharge>)seqConverter.Read(ref reader, typeof(ISequence<Transaction._ITierCharge>), options);
                        break;
                    case "baseAmount":
                        baseAmount = new BigInteger(reader.GetInt64());
                        break;
                    case "calculationNote":
                        calculationNote = reader.GetString() ?? "";
                        break;
                }
            }

            return new Transaction.FeeDetails(tierBreakdown, baseAmount, Sequence<Dafny.Rune>.UnicodeFromString(calculationNote));
        }

        public override void Write(Utf8JsonWriter writer, Transaction._IFeeDetails value, JsonSerializerOptions options)
        {
            var feeDetails = (Transaction.FeeDetails)value;

            writer.WriteStartObject();

            writer.WritePropertyName("tierBreakdown");
            var seqConverter = new DafnySequenceConverter();
            seqConverter.Write(writer, feeDetails._tierBreakdown, options);

            writer.WriteNumber("baseAmount", (long)feeDetails._baseAmount);
            writer.WriteString("calculationNote", RuneSequenceToString(feeDetails._calculationNote));

            writer.WriteEndObject();
        }
    }

    /// <summary>
    /// Converter for Option<T> discriminated union
    /// </summary>
    private class OptionConverter : JsonConverter<object>
    {
        public override bool CanConvert(Type typeToConvert)
        {
            return typeToConvert.IsGenericType &&
                   typeToConvert.GetGenericTypeDefinition().Name.Contains("Option");
        }

        public override object Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType == JsonTokenType.Null)
            {
                // Return None for null
                var noneMethod = typeToConvert.GetMethod("create_None");
                return noneMethod?.Invoke(null, null);
            }

            // For Some(value), read the value
            var innerType = typeToConvert.GetGenericArguments()[0];
            object value;

            if (innerType == typeof(ISequence<Dafny.Rune>))
            {
                value = Sequence<Dafny.Rune>.UnicodeFromString(reader.GetString() ?? "");
            }
            else
            {
                value = JsonSerializer.Deserialize(ref reader, innerType, options);
            }

            var someMethod = typeToConvert.GetMethod("create_Some");
            return someMethod?.Invoke(null, new[] { value });
        }

        public override void Write(Utf8JsonWriter writer, object value, JsonSerializerOptions options)
        {
            var type = value.GetType();
            var isNoneProperty = type.GetProperty("is_None");

            if (isNoneProperty != null && (bool)isNoneProperty.GetValue(value))
            {
                writer.WriteNullValue();
            }
            else
            {
                var valueProperty = type.GetProperty("value");
                if (valueProperty != null)
                {
                    var innerValue = valueProperty.GetValue(value);

                    if (innerValue is ISequence<Dafny.Rune> runes)
                    {
                        writer.WriteStringValue(RuneSequenceToString(runes));
                    }
                    else
                    {
                        JsonSerializer.Serialize(writer, innerValue, options);
                    }
                }
            }
        }
    }

    /// <summary>
    /// Converter for Dafny Map<K, V>
    /// </summary>
    private class DafnyMapConverter : JsonConverter<object>
    {
        public override bool CanConvert(Type typeToConvert)
        {
            return typeToConvert.IsGenericType &&
                   typeToConvert.GetGenericTypeDefinition().Name.Contains("IMap");
        }

        public override object Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType != JsonTokenType.StartObject)
                throw new JsonException("Expected StartObject token");

            var keyType = typeToConvert.GetGenericArguments()[0];
            var valueType = typeToConvert.GetGenericArguments()[1];
            var dict = new Dictionary<object, object>();

            while (reader.Read())
            {
                if (reader.TokenType == JsonTokenType.EndObject)
                    break;

                if (reader.TokenType == JsonTokenType.PropertyName)
                {
                    string keyString = reader.GetString();
                    reader.Read();

                    // Convert key from string to appropriate type
                    object key = keyType == typeof(BigInteger)
                        ? new BigInteger(long.Parse(keyString))
                        : keyString;

                    // Deserialize value
                    object value = JsonSerializer.Deserialize(ref reader, valueType, options);
                    dict[key] = value;
                }
            }

            // Convert Dictionary to Dafny Map
            var mapType = typeof(Map<,>).MakeGenericType(keyType, valueType);
            var fromCollectionMethod = mapType.GetMethod("FromCollection");

            var pairType = typeof(KeyValuePair<,>).MakeGenericType(keyType, valueType);
            var listType = typeof(List<>).MakeGenericType(pairType);
            var list = Activator.CreateInstance(listType);

            foreach (var kvp in dict)
            {
                var pair = Activator.CreateInstance(pairType, kvp.Key, kvp.Value);
                listType.GetMethod("Add").Invoke(list, new[] { pair });
            }

            return fromCollectionMethod?.Invoke(null, new[] { list });
        }

        public override void Write(Utf8JsonWriter writer, object value, JsonSerializerOptions options)
        {
            writer.WriteStartObject();

            var type = value.GetType();
            var keysProperty = type.GetProperty("Keys");
            var itemProperty = type.GetProperty("Item");

            if (keysProperty != null && itemProperty != null)
            {
                var keys = keysProperty.GetValue(value) as System.Collections.IEnumerable;

                if (keys != null)
                {
                    foreach (var key in keys)
                    {
                        string keyString = key.ToString();
                        writer.WritePropertyName(keyString);

                        var val = itemProperty.GetValue(value, new[] { key });
                        JsonSerializer.Serialize(writer, val, options);
                    }
                }
            }

            writer.WriteEndObject();
        }
    }

    /// <summary>
    /// Converter for Dafny Sequence<T>
    /// </summary>
    private class DafnySequenceConverter : JsonConverter<object>
    {
        public override bool CanConvert(Type typeToConvert)
        {
            return typeToConvert.IsGenericType &&
                   typeToConvert.GetGenericTypeDefinition().Name.Contains("ISequence");
        }

        public override object Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            if (reader.TokenType != JsonTokenType.StartArray)
                throw new JsonException("Expected StartArray token");

            var elementType = typeToConvert.GetGenericArguments()[0];
            var list = new List<object>();

            while (reader.Read())
            {
                if (reader.TokenType == JsonTokenType.EndArray)
                    break;

                var element = JsonSerializer.Deserialize(ref reader, elementType, options);
                list.Add(element);
            }

            // Convert List to Dafny Sequence
            var seqType = typeof(Sequence<>).MakeGenericType(elementType);
            var fromArrayMethod = seqType.GetMethod("FromArray");

            var arrayType = elementType.MakeArrayType();
            var array = Array.CreateInstance(elementType, list.Count);
            for (int i = 0; i < list.Count; i++)
            {
                array.SetValue(list[i], i);
            }

            return fromArrayMethod?.Invoke(null, new[] { array });
        }

        public override void Write(Utf8JsonWriter writer, object value, JsonSerializerOptions options)
        {
            writer.WriteStartArray();

            var type = value.GetType();
            var elementsProperty = type.GetProperty("Elements");

            if (elementsProperty != null)
            {
                var elements = elementsProperty.GetValue(value) as System.Collections.IEnumerable;

                if (elements != null)
                {
                    foreach (var element in elements)
                    {
                        JsonSerializer.Serialize(writer, element, options);
                    }
                }
            }

            writer.WriteEndArray();
        }
    }
}
