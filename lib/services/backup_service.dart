import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

/// Service for database backup and restore
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  /// Export the SQLite database to external storage and return the path
  Future<String> exportDatabase() async {
    return DatabaseHelper.instance.exportDatabase();
  }

  /// Share the database backup file
  Future<void> shareBackup() async {
    final path = await exportDatabase();
    await Share.shareXFiles([XFile(path)], text: 'Tailor Shop Database Backup');
  }

  /// Import a database backup selected by the user
  Future<bool> importDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return false;
    final file = result.files.first;
    if (file.path == null) return false;
    await DatabaseHelper.instance.importDatabase(file.path!);
    return true;
  }
}
