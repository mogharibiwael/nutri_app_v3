import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/class/status_request.dart';
import '../../../core/constant/theme/colors.dart';
import '../medical_files_local_storage.dart';
import '../model/medical_file_model.dart';

class MedicalFilesController extends GetxController {
  /// Help PDFs from [assets/files] only (no API).
  static final List<MedicalFileModel> _bundledHelpFiles = [
    MedicalFileModel.bundled(
      id: -1,
      assetPath: 'assets/files/jurd.pdf',
      fileName: 'jurd.pdf',
      titleKey: 'helpFileJurd',
    ),
    MedicalFileModel.bundled(
      id: -2,
      assetPath: 'assets/files/krause.pdf',
      fileName: 'krause.pdf',
      titleKey: 'helpFileKrause',
    ),
    MedicalFileModel.bundled(
      id: -3,
      assetPath: 'assets/files/alter.pdf',
      fileName: 'alter.pdf',
      titleKey: 'helpFileAlter',
    ),
  ];

  final statusRequest = Rx<StatusRequest>(StatusRequest.success);
  final RxList<MedicalFileModel> files = <MedicalFileModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    files.assignAll(_bundledHelpFiles);
    _reloadFiles();
  }

  Future<void> _reloadFiles() async {
    final local = await _scanLocalMedicalDir();
    files.assignAll([..._bundledHelpFiles, ...local]);
    statusRequest.value = StatusRequest.success;
  }

  Future<List<MedicalFileModel>> _scanLocalMedicalDir() async {
    try {
      final dir = await MedicalFilesLocalStorage.directory();
      final out = <MedicalFileModel>[];
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        if (!await entity.exists()) continue;
        out.add(MedicalFileModel.fromLocalPath(entity.path));
      }
      out.sort((a, b) => b.fileName.compareTo(a.fileName));
      return out;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> refresh() async {
    await _reloadFiles();
  }

  String displayTitle(MedicalFileModel file) {
    final k = file.titleKey;
    if (k != null && k.isNotEmpty) return k.tr;
    return file.fileName;
  }

  /// Save asset PDF to device, or return existing local path.
  Future<String?> downloadFile(MedicalFileModel file) async {
    if (file.isLocalDeviceFile && file.localDiskPath != null) {
      final f = File(file.localDiskPath!);
      if (await f.exists()) return file.localDiskPath;
      Get.snackbar("error".tr, "downloadFailed".tr);
      return null;
    }

    final path = file.assetBundlePath;
    if (path == null || path.isEmpty) {
      Get.snackbar("error".tr, "downloadFailed".tr);
      return null;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = file.fileName.contains('.')
          ? file.fileName
          : '${file.fileName}.${file.fileType}';
      final savePath = '${downloadsDir.path}/$fileName';

      final bundleData = await rootBundle.load(path);
      final bytes = bundleData.buffer.asUint8List();

      if (bytes.isEmpty) {
        Get.snackbar("error".tr, "downloadFailed".tr);
        return null;
      }

      await File(savePath).writeAsBytes(bytes);
      return savePath;
    } catch (e) {
      Get.snackbar("error".tr, "downloadFailed".tr);
      return null;
    }
  }

  Future<void> downloadAndShow(MedicalFileModel file) async {
    final path = await downloadFile(file);
    if (path != null) {
      final result = await OpenFilex.open(path);
      if (result.type == ResultType.done) {
        Get.snackbar("success".tr, "downloadSuccess".tr);
      } else {
        Get.dialog(
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppColor.primary, size: 28),
                const SizedBox(width: 12),
                Text("downloadSuccess".tr),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("fileDownloadedTo".tr),
                const SizedBox(height: 8),
                SelectableText(
                  path,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text("close".tr),
              ),
            ],
          ),
        );
      }
    }
  }
}
