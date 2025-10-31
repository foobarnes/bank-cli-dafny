using System;
using System.Globalization;
using System.Numerics;
using System.Text;
using Dafny;

public class StringHelpers {

  /// <summary>
  /// Tries to parse a string to a natural number (non-negative integer)
  /// </summary>
  public static void TryParseNat(ISequence<Dafny.Rune> str, out bool success, out BigInteger value) {
    string s = RuneSequenceToString(str);

    if (BigInteger.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out BigInteger result)) {
      if (result >= 0) {
        success = true;
        value = result;
        return;
      }
    }

    success = false;
    value = BigInteger.Zero;
  }

  /// <summary>
  /// Tries to parse a string to an integer (can be negative)
  /// </summary>
  public static void TryParseInt(ISequence<Dafny.Rune> str, out bool success, out BigInteger value) {
    string s = RuneSequenceToString(str);

    if (BigInteger.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out BigInteger result)) {
      success = true;
      value = result;
    } else {
      success = false;
      value = BigInteger.Zero;
    }
  }

  /// <summary>
  /// Converts a natural number to a string
  /// </summary>
  public static ISequence<Dafny.Rune> NatToString(BigInteger n) {
    return Sequence<Dafny.Rune>.UnicodeFromString(n.ToString());
  }

  /// <summary>
  /// Converts an integer to a string
  /// </summary>
  public static ISequence<Dafny.Rune> IntToString(BigInteger n) {
    return Sequence<Dafny.Rune>.UnicodeFromString(n.ToString());
  }

  /// <summary>
  /// Formats cents as dollars with $ sign and 2 decimal places
  /// Example: 125050 -> "$1,250.50"
  /// </summary>
  public static ISequence<Dafny.Rune> FormatCentsToDollars(BigInteger cents) {
    decimal dollars = (decimal)cents / 100m;
    string formatted = dollars.ToString("C2", CultureInfo.GetCultureInfo("en-US"));
    return Sequence<Dafny.Rune>.UnicodeFromString(formatted);
  }

  /// <summary>
  /// Formats cents as dollars WITHOUT $ sign (for calculations display)
  /// Example: 125050 -> "1,250.50"
  /// </summary>
  public static ISequence<Dafny.Rune> FormatCentsAsDecimal(BigInteger cents) {
    decimal dollars = (decimal)cents / 100m;
    string formatted = dollars.ToString("N2", CultureInfo.GetCultureInfo("en-US"));
    return Sequence<Dafny.Rune>.UnicodeFromString(formatted);
  }

  /// <summary>
  /// Converts a boolean to "Yes" or "No"
  /// </summary>
  public static ISequence<Dafny.Rune> BoolToYesNo(bool value) {
    return Sequence<Dafny.Rune>.UnicodeFromString(value ? "Yes" : "No");
  }

  /// <summary>
  /// Converts a boolean to "Enabled" or "Disabled"
  /// </summary>
  public static ISequence<Dafny.Rune> BoolToEnabledDisabled(bool value) {
    return Sequence<Dafny.Rune>.UnicodeFromString(value ? "Enabled" : "Disabled");
  }

  /// <summary>
  /// Concatenates two Dafny strings
  /// </summary>
  public static ISequence<Dafny.Rune> ConcatStrings(ISequence<Dafny.Rune> s1, ISequence<Dafny.Rune> s2) {
    string str1 = RuneSequenceToString(s1);
    string str2 = RuneSequenceToString(s2);
    return Sequence<Dafny.Rune>.UnicodeFromString(str1 + str2);
  }

  /// <summary>
  /// Helper method to convert Dafny Rune sequence to C# string
  /// </summary>
  private static string RuneSequenceToString(ISequence<Dafny.Rune> runes) {
    var sb = new StringBuilder();
    foreach (var rune in runes.Elements) {
      sb.Append((char)rune.Value);
    }
    return sb.ToString();
  }
}
