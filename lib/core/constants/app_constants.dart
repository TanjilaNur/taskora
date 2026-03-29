/// Holds all compile-time constants used across the app.
/// Change values here and they propagate everywhere automatically.
class AppConstants {
  AppConstants._();

  /// Maximum nesting depth (root = 1, max subtask level = 4).
  static const int maxTaskDepth = 4;

  /// Thumbnail compressed to this size in pixels (width & height).
  static const int thumbnailSize = 250;

  /// JPEG compression quality for saved images (0–100).
  static const int imageQuality = 85;

  /// File extension used when exporting a backup.
  static const String backupFileExtension = '.taskora_backup';

  /// Isar database name. Changing this creates a new empty database.
  static const String dbName = 'taskora_db';
}