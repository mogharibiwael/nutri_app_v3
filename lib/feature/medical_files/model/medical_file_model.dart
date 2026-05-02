import 'dart:io';

import '../../../core/constant/api_link.dart';

class MedicalFileModel {
  final int id;
  final int? patientId;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String? description;
  final String? uploadedAt;
  final String? status;
  final String? downloadUrl; // Full URL from backend if provided
  /// When set, file bytes come from app assets (help PDFs), not the server.
  final String? assetBundlePath;
  /// GetX key for the label in the help list (e.g. [helpFileJurd]).
  final String? titleKey;

  /// Absolute path on device (scanned from app `medical_files` folder — e.g. chat image copies).
  final String? localDiskPath;

  MedicalFileModel({
    required this.id,
    this.patientId,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.description,
    this.uploadedAt,
    this.status,
    this.downloadUrl,
    this.assetBundlePath,
    this.titleKey,
    this.localDiskPath,
  });

  bool get isBundled => assetBundlePath != null && assetBundlePath!.isNotEmpty;

  bool get isLocalDeviceFile =>
      localDiskPath != null && localDiskPath!.trim().isNotEmpty;

  /// Whether list UI should show an image thumbnail ([localDiskPath] image files).
  bool get showsImageThumbnail {
    if (!isLocalDeviceFile) return false;
    final n = fileName.toLowerCase();
    return n.endsWith('.png') ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.gif') ||
        n.endsWith('.webp') ||
        n.endsWith('.bmp');
  }

  /// Laravel storage URL: domain.com/storage/uploads/...
  String get storageUrl {
    final base = ApiLinks.storageBase;
    final path = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$base/storage/$path';
  }

  /// Direct URL: domain.com/uploads/... (when files are in public/uploads)
  String get directUrl {
    final base = ApiLinks.storageBase;
    final path = filePath.startsWith('/') ? filePath : '/$filePath';
    return '$base$path';
  }

  /// API path for file (some backends serve at /api/...)
  String get apiStorageUrl {
    final base = ApiLinks.storageBase;
    final path = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$base/api/storage/$path';
  }

  /// URL via API base (some backends: domain.com/api/uploads/...)
  String get apiUploadsUrl {
    final base = ApiLinks.storageBase.replaceFirst(RegExp(r'/api$'), '');
    final path = filePath.startsWith('/') ? filePath : '/$filePath';
    return '$base/api$path';
  }

  /// All possible download URLs to try (backend URL first if provided).
  /// Tries direct/storage URLs first (common Laravel), then API download endpoint.
  List<String> get downloadUrls {
    if (isBundled) return <String>[];
    if (isLocalDeviceFile) return <String>[];
    final urls = <String>[];
    if (downloadUrl != null && downloadUrl!.trim().isNotEmpty) {
      urls.add(downloadUrl!.trim());
    }
    // Try direct and storage URLs first (files in public/ or storage link)
    urls.add(directUrl);
    urls.add(storageUrl);
    // Then API download endpoint (requires backend to implement GET /api/medical-files/:id/download)
    urls.add(ApiLinks.medicalFileDownload(id));
    urls.add(apiUploadsUrl);
    urls.add(apiStorageUrl);
    return urls;
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory MedicalFileModel.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return MedicalFileModel(
      id: _toInt(json["id"]),
      patientId: json["patient_id"] != null ? _toInt(json["patient_id"]) : null,
      fileName: (json["file_name"] ?? "").toString(),
      filePath: (json["file_path"] ?? "").toString(),
      fileType: (json["file_type"] ?? "pdf").toString().toLowerCase(),
      fileSize: _toInt(json["file_size"] ?? 0),
      description: json["description"]?.toString(),
      uploadedAt: json["uploaded_at"]?.toString(),
      status: json["status"]?.toString(),
      downloadUrl: json["download_url"]?.toString() ?? json["url"]?.toString(),
      assetBundlePath: json["asset_bundle_path"]?.toString(),
      titleKey: json["title_key"]?.toString(),
      localDiskPath: json["local_disk_path"]?.toString(),
    );
  }

  /// File already saved under app documents (e.g. [medical_files] from chat).
  factory MedicalFileModel.fromLocalPath(String absolutePath) {
    final f = File(absolutePath);
    var size = 0;
    try {
      size = f.lengthSync();
    } catch (_) {}
    final name = absolutePath.replaceAll(r'\', '/').split('/').last;
    final dot = name.lastIndexOf('.');
    final ext = dot > 0 ? name.substring(dot + 1).toLowerCase() : 'file';
    return MedicalFileModel(
      id: absolutePath.hashCode & 0x7fffffff,
      fileName: name,
      filePath: absolutePath,
      fileType: ext,
      fileSize: size,
      localDiskPath: absolutePath,
    );
  }

  /// Built-in help PDFs shipped under [assetBundlePath] (e.g. assets/files/…).
  factory MedicalFileModel.bundled({
    required int id,
    required String assetPath,
    required String fileName,
    required String titleKey,
  }) {
    return MedicalFileModel(
      id: id,
      fileName: fileName,
      filePath: assetPath,
      fileType: 'pdf',
      fileSize: 0,
      assetBundlePath: assetPath,
      titleKey: titleKey,
      localDiskPath: null,
    );
  }
}
