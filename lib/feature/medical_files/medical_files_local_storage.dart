import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// On-device folder where copies of chat uploads (images/files) are stored for "Medical files".
class MedicalFilesLocalStorage {
  static const String folderName = 'medical_files';

  static Future<Directory> directory() async {
    final d = await getApplicationDocumentsDirectory();
    final dir = Directory('${d.path}/$folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copy a file sent from chat into [medical_files] so it appears in Help / Medical files list.
  static Future<void> copyFromChatUpload(String sourcePath, String? originalName) async {
    final src = File(sourcePath);
    if (!await src.exists()) return;
    final dir = await directory();
    final raw = originalName ??
        sourcePath.replaceAll(r'\', '/').split('/').last;
    final safe = raw.replaceAll(RegExp(r'[^\w.\- \u0600-\u06FF]'), '_');
    final name = '${DateTime.now().millisecondsSinceEpoch}_$safe';
    await src.copy('${dir.path}${Platform.pathSeparator}$name');
  }
}
