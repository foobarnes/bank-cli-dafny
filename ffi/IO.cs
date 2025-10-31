using System;
using System.Text;
using Dafny;

public class IO {
  /// <summary>
  /// Reads a line of text from standard input
  /// </summary>
  public static ISequence<Dafny.Rune> ReadLine() {
    string? input = Console.ReadLine();
    return input == null
      ? Sequence<Dafny.Rune>.Empty
      : Sequence<Dafny.Rune>.UnicodeFromString(input);
  }

  /// <summary>
  /// Prints text to console without a newline
  /// </summary>
  public static void Print(ISequence<Dafny.Rune> text) {
    Console.Write(RuneSequenceToString(text));
  }

  /// <summary>
  /// Prints text to console with a newline
  /// </summary>
  public static void PrintLine(ISequence<Dafny.Rune> text) {
    Console.WriteLine(RuneSequenceToString(text));
  }

  /// <summary>
  /// Converts a Dafny sequence of Runes to a C# string
  /// </summary>
  private static string RuneSequenceToString(ISequence<Dafny.Rune> runes) {
    var sb = new StringBuilder();
    foreach (var rune in runes.Elements) {
      sb.Append((char)rune.Value);
    }
    return sb.ToString();
  }
}
