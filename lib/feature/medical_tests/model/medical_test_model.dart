import '../../../core/constant/api_link.dart';

class MedicalTestModel {
  final int id;
  final String name;
  /// API returns "image" - file path or URL
  final String? image;
  final int? userId;
  final int? doctorId;
  final String? createdAt;
  final String? patientName;
  final String? status;

  MedicalTestModel({
    required this.id,
    required this.name,
    this.image,
    this.userId,
    this.doctorId,
    this.createdAt,
    this.patientName,
    this.status,
  });

  /// Primary route used by older client code.
  String get downloadUrl => ApiLinks.medicalTestDownload(id);

  /// Try direct file URLs first (many backends only expose `image`), then API download.
  List<String> get downloadCandidates {
    final seen = <String>{};
    final out = <String>[];

    void addOne(String? u) {
      if (u == null || u.isEmpty) return;
      final n = u.trim();
      if (!seen.add(n)) return;
      out.add(n);
    }

    final img = image?.trim();
    if (img != null && img.isNotEmpty) {
      if (img.startsWith('http://') || img.startsWith('https://')) {
        addOne(img.replaceFirst(RegExp(r'^http://'), 'https://'));
      } else {
        final base = ApiLinks.storageBase.replaceFirst(RegExp(r'/$'), '');
        final withSlash = img.startsWith('/') ? img : '/$img';
        addOne('$base$withSlash');
        final noLeading = img.startsWith('/') ? img.substring(1) : img;
        addOne('$base/storage/$noLeading');
        addOne('$base/uploads/$noLeading');
      }
    }

    addOne(ApiLinks.medicalTestDownload(id));
    return out;
  }

  /// Extension for saved file on disk.
  String get suggestedFileExtension {
    final img = image;
    if (img != null && img.contains('.')) {
      final seg = img.split(RegExp(r'[/\\]')).last;
      final parts = seg.split('.');
      if (parts.length >= 2) {
        final e = parts.last.toLowerCase();
        if (e.length <= 6 && RegExp(r'^[a-z0-9]+$').hasMatch(e)) return e;
      }
    }
    return 'bin';
  }

  factory MedicalTestModel.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    final user = json["user"];
    final userName = user is Map ? (user["name"]?.toString()) : null;

    return MedicalTestModel(
      id: _toInt(json["id"]),
      name: (json["name"] ?? "").toString(),
      image: json["image"]?.toString() ??
          json["file"]?.toString() ??
          json["file_path"]?.toString() ??
          json["attachment"]?.toString(),
      userId: json["user_id"] != null ? _toInt(json["user_id"]) : null,
      doctorId: json["doctor_id"] != null ? _toInt(json["doctor_id"]) : null,
      createdAt: json["created_at"]?.toString(),
      patientName: json["patient_name"]?.toString() ?? userName,
      status: json["status"]?.toString(),
    );
  }
}
