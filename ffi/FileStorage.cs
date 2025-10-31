using System;
using System.IO;
using System.Text;
using Dafny;

public class FileStorage {

  /// <summary>
  /// Saves JSON data to a file
  /// </summary>
  public static Persistence._IPersistenceResult<Persistence._IUnit> SaveData(
    ISequence<Rune> jsonData,
    ISequence<Rune> filePath
  ) {
    try {
      string path = RuneSequenceToString(filePath);
      string data = RuneSequenceToString(jsonData);

      // Create backup if file exists
      if (File.Exists(path)) {
        CreateBackup(filePath);
      }

      // Write to temp file first, then atomic rename
      string tempPath = path + ".tmp";
      File.WriteAllText(tempPath, data);

      // Atomic move (on most filesystems)
      if (File.Exists(path)) {
        File.Delete(path);
      }
      File.Move(tempPath, path);

      return Persistence.PersistenceResult<Persistence._IUnit>.create_Success(
        new Persistence.Unit()
      );
    }
    catch (UnauthorizedAccessException) {
      return Persistence.PersistenceResult<Persistence._IUnit>.create_PermissionDenied(
        filePath
      );
    }
    catch (IOException ex) {
      return Persistence.PersistenceResult<Persistence._IUnit>.create_IOError(
        Sequence<Rune>.UnicodeFromString(ex.Message)
      );
    }
    catch (Exception ex) {
      return Persistence.PersistenceResult<Persistence._IUnit>.create_IOError(
        Sequence<Rune>.UnicodeFromString(ex.Message)
      );
    }
  }

  /// <summary>
  /// Loads JSON data from a file
  /// </summary>
  public static Persistence._IPersistenceResult<ISequence<Rune>> LoadData(
    ISequence<Rune> filePath
  ) {
    try {
      string path = RuneSequenceToString(filePath);

      if (!File.Exists(path)) {
        return Persistence.PersistenceResult<ISequence<Rune>>.create_FileNotFound(filePath);
      }

      string data = File.ReadAllText(path);
      return Persistence.PersistenceResult<ISequence<Rune>>.create_Success(
        Sequence<Rune>.UnicodeFromString(data)
      );
    }
    catch (UnauthorizedAccessException) {
      return Persistence.PersistenceResult<ISequence<Rune>>.create_PermissionDenied(filePath);
    }
    catch (IOException ex) {
      return Persistence.PersistenceResult<ISequence<Rune>>.create_IOError(
        Sequence<Rune>.UnicodeFromString(ex.Message)
      );
    }
    catch (Exception ex) {
      return Persistence.PersistenceResult<ISequence<Rune>>.create_CorruptedData(
        Sequence<Rune>.UnicodeFromString(ex.Message)
      );
    }
  }

  /// <summary>
  /// Creates a timestamped backup of a file
  /// </summary>
  public static Persistence._IPersistenceResult<Persistence._IUnit> CreateBackup(
    ISequence<Rune> filePath
  ) {
    try {
      string path = RuneSequenceToString(filePath);

      if (!File.Exists(path)) {
        // No file to backup, return success
        return Persistence.PersistenceResult<Persistence._IUnit>.create_Success(
          new Persistence.Unit()
        );
      }

      string timestamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
      string backupPath = $"{path}.backup.{timestamp}.json";

      File.Copy(path, backupPath, overwrite: true);

      // Clean up old backups (keep last 30 as per configuration)
      CleanupOldBackups(path, 30);

      return Persistence.PersistenceResult<Persistence._IUnit>.create_Success(
        new Persistence.Unit()
      );
    }
    catch (UnauthorizedAccessException) {
      return Persistence.PersistenceResult<Persistence._IUnit>.create_PermissionDenied(filePath);
    }
    catch (IOException ex) {
      return Persistence.PersistenceResult<Persistence._IUnit>.create_IOError(
        Sequence<Rune>.UnicodeFromString(ex.Message)
      );
    }
    catch (Exception ex) {
      return Persistence.PersistenceResult<Persistence._IUnit>.create_IOError(
        Sequence<Rune>.UnicodeFromString(ex.Message)
      );
    }
  }

  /// <summary>
  /// Checks if a file exists
  /// </summary>
  public static bool FileExists(ISequence<Rune> filePath) {
    try {
      string path = RuneSequenceToString(filePath);
      return File.Exists(path);
    }
    catch {
      // Return false for any errors (permission issues, etc.)
      return false;
    }
  }

  /// <summary>
  /// Helper method to convert Dafny Rune sequence to C# string
  /// </summary>
  private static string RuneSequenceToString(ISequence<Rune> runes) {
    var sb = new StringBuilder();
    foreach (var rune in runes.Elements) {
      sb.Append((char)rune.Value);
    }
    return sb.ToString();
  }

  /// <summary>
  /// Cleans up old backup files, keeping only the most recent N backups
  /// </summary>
  private static void CleanupOldBackups(string originalPath, int keepCount) {
    try {
      string directory = Path.GetDirectoryName(originalPath) ?? ".";
      string fileName = Path.GetFileName(originalPath);
      string searchPattern = $"{fileName}.backup.*.json";

      var backupFiles = Directory.GetFiles(directory, searchPattern);

      if (backupFiles.Length <= keepCount) {
        return;
      }

      // Sort by creation time, oldest first
      Array.Sort(backupFiles, (a, b) =>
        File.GetCreationTime(a).CompareTo(File.GetCreationTime(b))
      );

      // Delete oldest files beyond keepCount
      int toDelete = backupFiles.Length - keepCount;
      for (int i = 0; i < toDelete; i++) {
        File.Delete(backupFiles[i]);
      }
    }
    catch {
      // Silently ignore cleanup errors
    }
  }
}
