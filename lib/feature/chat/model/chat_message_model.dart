import '../../../core/constant/api_link.dart';

class ChatMessageModel {
  final int id;
  final int userId;
  final int doctorId;
  final String message;
  final DateTime createdAt;
  final bool isMe;
  final bool pending;
  final bool read;
  /// From API: "doctor" | "user" (patient). Used for layout: doctor = right, user = left.
  final String? senderType;

  /// Resolved HTTPS URL for attachment from API (images/files).
  final String? attachmentRemoteUrl;

  /// Local path right after picking an image (optimistic bubble).
  final String? attachmentLocalPath;

  /// Optional mime from API (`mime_type`, `content_type`).
  final String? mimeType;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.message,
    required this.createdAt,
    required this.isMe,
    this.pending = false,
    this.read = false,
    this.senderType,
    this.attachmentRemoteUrl,
    this.attachmentLocalPath,
    this.mimeType,
  });

  /// True if sender_type is "doctor".
  bool get isFromDoctor =>
      (senderType ?? "").toString().toLowerCase().trim() == "doctor";

  /// Show an inline image preview (local optimistic or remote URL looks like image).
  bool get shouldShowImage {
    if (attachmentLocalPath != null && attachmentLocalPath!.isNotEmpty) {
      return _looksLikeImage(attachmentLocalPath!, mimeType);
    }
    final u = attachmentRemoteUrl;
    if (u == null || u.isEmpty) return false;
    return _looksLikeImage(u, mimeType);
  }

  ChatMessageModel copyWith({
    bool? pending,
    bool? read,
    String? attachmentRemoteUrl,
    String? attachmentLocalPath,
  }) {
    return ChatMessageModel(
      id: id,
      userId: userId,
      doctorId: doctorId,
      message: message,
      createdAt: createdAt,
      isMe: isMe,
      pending: pending ?? this.pending,
      read: read ?? this.read,
      senderType: senderType,
      attachmentRemoteUrl: attachmentRemoteUrl ?? this.attachmentRemoteUrl,
      attachmentLocalPath: attachmentLocalPath ?? this.attachmentLocalPath,
      mimeType: mimeType,
    );
  }

  factory ChatMessageModel.fromHistoryJson(
    Map<String, dynamic> json, {
    required int myUserId,
    int? myDoctorId,
  }) {
    final uid =
        (json["user_id"] is int) ? json["user_id"] : int.tryParse("${json["user_id"]}") ?? 0;
    final did =
        (json["doctor_id"] is int) ? json["doctor_id"] : int.tryParse("${json["doctor_id"]}") ?? 0;
    final readRaw = (json["read"] ?? "false").toString().toLowerCase();
    final isRead = readRaw == "true" || readRaw == "1";
    final isMe = uid == myUserId || (myDoctorId != null && myDoctorId > 0 && did == myDoctorId);
    final senderTypeRaw = (json["sender_type"] ?? "").toString().trim().toLowerCase();
    final senderType = senderTypeRaw.isEmpty ? null : senderTypeRaw;

    final mime = _firstString(json, ["mime_type", "content_type", "mime"]);
    final rawAttach = _extractAttachmentRaw(json);
    final resolved = rawAttach != null ? _resolveToAbsoluteUrl(rawAttach) : null;

    return ChatMessageModel(
      id: (json["id"] is int) ? json["id"] : int.tryParse("${json["id"]}") ?? 0,
      userId: uid,
      doctorId: did,
      message: (json["message"] ?? "").toString(),
      createdAt: DateTime.tryParse((json["created_at"] ?? "").toString()) ?? DateTime.now(),
      isMe: isMe,
      read: isRead,
      senderType: senderType,
      attachmentRemoteUrl: resolved,
      attachmentLocalPath: null,
      mimeType: mime,
    );
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static String? _extractAttachmentRaw(Map<String, dynamic> json) {
    final nested = json["file"];
    if (nested is Map) {
      final m = Map<String, dynamic>.from(nested);
      final u = _firstString(m, ["url", "path", "file_path", "full_url", "public_url"]);
      if (u != null) return u;
    }
    return _firstString(json, [
      "image_url",
      "file_url",
      "attachment_url",
      "media_url",
      "file_path",
      "image",
      "attachment",
      "file",
      "path",
      "url",
      "media",
    ]);
  }

  static String? _resolveToAbsoluteUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.startsWith("http://") || t.startsWith("https://")) {
      return t.replaceFirst(RegExp(r"^http://"), "https://");
    }
    final base = ApiLinks.storageBase.replaceFirst(RegExp(r"/$"), "");
    final path = t.startsWith("/") ? t : "/$t";
    return "$base$path";
  }

  static bool _looksLikeImage(String pathOrUrl, String? mime) {
    final m = (mime ?? "").toLowerCase().trim();
    if (m.startsWith("image/")) return true;
    final lower = pathOrUrl.toLowerCase();
    return lower.endsWith(".png") ||
        lower.endsWith(".jpg") ||
        lower.endsWith(".jpeg") ||
        lower.endsWith(".gif") ||
        lower.endsWith(".webp") ||
        lower.endsWith(".bmp");
  }
}
