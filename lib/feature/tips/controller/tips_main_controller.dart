import 'package:get/get.dart';
import '../../../core/class/status_request.dart';
import '../data/tips_data.dart';
import '../model/tips.dart';

class TipsMainController extends GetxController {
  final TipsData tipsData = TipsData(Get.find());

  final Rx<StatusRequest> statusRequest = StatusRequest.loading.obs;
  final RxList<TipCategory> categories = <TipCategory>[].obs;

  bool _isFetching = false;

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse("$v") ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    if (_isFetching) return;
    _isFetching = true;
    statusRequest.value = StatusRequest.loading;

    try {
      final res = await tipsData.fetchTips(page: 1);

      res.fold((l) {
        statusRequest.value = l;
      }, (r) {
        try {
          categories.clear();
          List? pickListFrom(dynamic v) {
            if (v is List) return v;
            if (v is Map) {
              final m = Map<String, dynamic>.from(v);
              for (final c in [m["data"], m["tips"], m["items"], m["result"]]) {
                if (c is List) return c;
              }
              final nested = m["data"];
              if (nested is Map) {
                final m2 = Map<String, dynamic>.from(nested);
                for (final c in [m2["data"], m2["tips"], m2["items"], m2["result"]]) {
                  if (c is List) return c;
                }
              }
            }
            return null;
          }

          final List list = pickListFrom(r["data"]) ??
              pickListFrom(r["tips"]) ??
              pickListFrom(r["items"]) ??
              pickListFrom(r["result"]) ??
              const [];
          final seenIds = <int>{};
          final tempList = <TipCategory>[];

          for (final e in list) {
            if (e is! Map) continue;
            final cat = e["category"];
            if (cat is Map) {
              try {
                final tipCat = TipCategory.fromJson(Map<String, dynamic>.from(cat));
                if (!seenIds.contains(tipCat.id)) {
                  seenIds.add(tipCat.id);
                  tempList.add(tipCat);
                }
              } catch (_) {}
            } else {
              // Fallback: backend may return only category_id without embedding category object
              final id = _toInt(e["category_id"]);
              if (id > 0 && !seenIds.contains(id)) {
                seenIds.add(id);
                tempList.add(TipCategory(id: id, nameEn: "Category $id"));
              }
            }
          }

          // Always show "All tips" entry first (id=0 means no filter).
          // If backend doesn't provide categories at all, this will be the only item.
          tempList.sort((a, b) => a.id.compareTo(b.id));
          categories.addAll([
            TipCategory(id: 0, nameEn: "All tips", nameAr: "كل النصائح"),
            ...tempList,
          ]);
          statusRequest.value = StatusRequest.success;
        } catch (e, st) {
          print("TipsMainController parse error: $e $st");
          statusRequest.value = StatusRequest.serverFailure;
        }
      });
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    if (_isFetching) return;
    await fetchCategories();
  }
}
