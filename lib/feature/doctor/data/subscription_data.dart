import 'dart:io';
import 'package:nutri_guide/core/constant/api_link.dart';

import '../../../core/class/crud.dart';

class SubscriptionData {
  final Crud crud;
  SubscriptionData(this.crud);

  /// GET /api/subscriptions - legacy endpoint (if still enabled)
  Future<dynamic> getMySubscriptions({String? token}) async {
    return await crud.getData(ApiLinks.subscriptions, token: token);
  }

  /// GET /api/users-subscribed - new endpoint (your backend)
  Future<dynamic> getMyUsersSubscribed({String? token}) async {
    return await crud.getData(ApiLinks.usersSubscribed, token: token);
  }

  Future<dynamic> createSubscription(Map<String, dynamic> body, {File? receiptImage, String? token}) async {
    if (receiptImage == null) {
      return await crud.postData(ApiLinks.usersSubscribed, body, token: token);
    }
    return await crud.postMultipart(
      ApiLinks.usersSubscribed,
      fields: body.map((k, v) => MapEntry(k, v.toString())),
      files: [
        MultipartFileField(fieldName: "receipt_image", filePath: receiptImage.path),
      ],
      token: token,
    );
  }
}
