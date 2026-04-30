import 'package:dartz/dartz.dart';
import 'package:nutri_guide/core/constant/api_link.dart';
import '../../../core/class/status_request.dart';
import '../../../core/class/crud.dart';

class TipsData {
  final Crud crud;
  TipsData(this.crud);

  Future<Either<StatusRequest, Map<String, dynamic>>> fetchTips({
    required int page,
    String? token,
    int? categoryId,
  }) async {
    var url =
        "${ApiLinks.baseUrl}/public/tips?page=$page";
    if (categoryId != null && categoryId > 0) {
      url += "&category_id=$categoryId";
    }
    return await crud.getData(url, token: token);
  }
}
