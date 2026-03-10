import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/task_model.dart';

/// Singleton wrapper around the Isar instance.
/// Call [initialize] once in main() before runApp.
class IsarService {
  IsarService._();

  static late final Isar _isar;

  static Isar get instance => _isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [TaskModelSchema],
      directory: dir.path,
      name: 'taskflow_db',
    );
  }
}