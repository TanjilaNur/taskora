class AppConstants {
  AppConstants._();

  static const int maxTaskDepth = 4; // Levels 1-4 (3 nesting levels below root)
  static const int thumbnailSize = 250;
  static const int imageQuality = 85;
  static const String backupFileExtension = '.taskflow_backup';
  static const String dbName = 'taskflow_db';
}