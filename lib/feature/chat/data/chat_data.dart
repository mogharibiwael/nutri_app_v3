import '../../../core/class/crud.dart';
import '../../../core/constant/api_link.dart';

class ChatData {
  final Crud crud;
  ChatData(this.crud);

  /// Patient: GET /chat/history/{peerUserId} — path uses the other party's **users.id** (doctor `user_id`),
  /// same value as `receiver_id` for POST /chat/messages. Fallback: `doctorId` (doctor record id).
  /// Doctor: GET /chat/conversations/{patientId}/messages.
  Future<dynamic> getHistory({
    required int doctorId,
    required int page,
    int? receiverId,
    bool isDoctor = false,
    String? token,
  }) {
    if (isDoctor && receiverId != null && receiverId > 0) {
      final url = "${ApiLinks.chatConversationMessages(receiverId)}?page=$page";
      return crud.getData(url, token: token);
    }
    final pathUserId =
        (receiverId != null && receiverId! > 0) ? receiverId! : doctorId;
    final buffer = StringBuffer("${ApiLinks.chatHistory}/$pathUserId?page=$page");
    if (receiverId != null && receiverId! > 0) {
      buffer.write("&receiver_id=$receiverId&user_id=$receiverId&patient_id=$receiverId");
    }
    return crud.getData(buffer.toString(), token: token);
  }

  Future<dynamic> sendMessage({
    required int conversationId,
    required int receiverId,
    required String message,
    String? token,
  }) {
    return crud.postData(
      ApiLinks.chatMessages,
      {
        "conversation_id": conversationId,
        "receiver_id": receiverId,
        "message": message,
      },
      token: token,
    );
  }

  /// Send message with file attachment (multipart). Backend should accept: conversation_id, receiver_id, message, file.
  Future<dynamic> sendMessageWithFile({
    required int conversationId,
    required int receiverId,
    required String message,
    required String filePath,
    String? fileName,
    String? token,
  }) async {
    final fields = <String, String>{
      "conversation_id": conversationId.toString(),
      "receiver_id": receiverId.toString(),
      "message": message,
    };
    final files = [
      MultipartFileField(
        fieldName: "file",
        filePath: filePath,
        fileName: fileName,
      ),
    ];
    return crud.postMultipart(
      ApiLinks.chatMessages,
      fields: fields,
      files: files,
      token: token,
    );
  }

  /// POST /api/medical-tests - Upload medical test (name + file) from patient chat
  Future<dynamic> uploadMedicalTest({
    required String name,
    required String filePath,
    String? fileName,
    required int doctorId,
    required int userId,
    String? token,
  }) async {
    final fields = <String, String>{
      "name": name,
      "doctor_id": doctorId.toString(),
      "user_id": userId.toString(),
    };
    final files = [
      MultipartFileField(
        fieldName: "file",
        filePath: filePath,
        fileName: fileName,
      ),
    ];
    return crud.postMultipart(
      ApiLinks.medicalTests,
      fields: fields,
      files: files,
      token: token,
    );
  }

  /// POST /api/medical-files - Upload auxiliary file (الملفات المساعدة) from patient chat
  Future<dynamic> uploadMedicalFile({
    required String filePath,
    String? fileName,
    required int patientId,
    String? token,
  }) async {
    final fields = <String, String>{
      "patient_id": patientId.toString(),
      "description": "Shared via chat",
    };
    final files = [
      MultipartFileField(
        fieldName: "file",
        filePath: filePath,
        fileName: fileName,
      ),
    ];
    return crud.postMultipart(
      ApiLinks.medicalFiles,
      fields: fields,
      files: files,
      token: token,
    );
  }

  Future<dynamic> markAsRead({
    required int messageId,
    String? token,
  }) {
    return crud.postData(
      "${ApiLinks.chatMessages}/$messageId/read",
      {}, // غالبًا POST بدون body
      token: token,
    );
  }
}
