import 'package:get/get.dart';
import 'package:dartz/dartz.dart';
import '../../../core/class/status_request.dart';
import '../../../core/function/handel_data.dart';
import '../../../core/service/serviecs.dart';
import '../data/tips_data.dart';
import '../model/tips.dart';

class TipsController extends GetxController {
  final TipsData tipsData = TipsData(Get.find());
  final MyServices myServices = Get.find();

  StatusRequest statusRequest = StatusRequest.loading;

  final List<TipModel> tips = [];

  int currentPage = 1;
  bool hasNextPage = false;
  bool isLoadingMore = false;
  int? categoryId;

  String? get token => myServices.sharedPreferences.getString("token");

  List _extractTipsList(Map<String, dynamic> r) {
    // Support multiple common list shapes:
    // - { data: [ ... ] }
    // - { data: { data: [ ... ] } } (Laravel paginator nested)
    // - { tips: [ ... ] }
    // - { data: { tips: [ ... ] } }
    // - { items: [ ... ] } / { data: { items: [ ... ] } }
    List? pickListFrom(dynamic v) {
      if (v is List) return v;
      if (v is Map) {
        final m = Map<String, dynamic>.from(v);
        final candidates = <dynamic>[
          m["data"],
          m["tips"],
          m["items"],
          m["result"],
        ];
        for (final c in candidates) {
          if (c is List) return c;
        }
        // Sometimes nested twice
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

    return pickListFrom(r["data"]) ??
        pickListFrom(r["tips"]) ??
        pickListFrom(r["items"]) ??
        pickListFrom(r["result"]) ??
        const [];
  }

  bool _hasNextPage(Map<String, dynamic> r) {
    // Support multiple common pagination shapes:
    // - Laravel paginator: next_page_url at root
    // - JSON:API-ish: links.next
    // - Resource pagination: meta.current_page + meta.last_page
    final nextPageUrl = r["next_page_url"];
    if (nextPageUrl != null && nextPageUrl.toString().isNotEmpty) return true;

    final links = r["links"];
    if (links is Map) {
      final next = links["next"];
      if (next != null && next.toString().isNotEmpty) return true;
    }

    final meta = r["meta"];
    if (meta is Map) {
      final current = meta["current_page"];
      final last = meta["last_page"];
      final currentInt = _toInt(current);
      final lastInt = _toInt(last);
      if (currentInt > 0 && lastInt > 0) return currentInt < lastInt;
    }

    // Alternative paginator shape nested under "data"
    final data = r["data"];
    if (data is Map) {
      final next2 = data["next_page_url"];
      if (next2 != null && next2.toString().isNotEmpty) return true;
      final links2 = data["links"];
      if (links2 is Map) {
        final next = links2["next"];
        if (next != null && next.toString().isNotEmpty) return true;
      }
      final meta2 = data["meta"];
      if (meta2 is Map) {
        final current = meta2["current_page"];
        final last = meta2["last_page"];
        final currentInt = _toInt(current);
        final lastInt = _toInt(last);
        if (currentInt > 0 && lastInt > 0) return currentInt < lastInt;
      }
    }

    return false;
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse("$v") ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map?;
    categoryId = args?["categoryId"] as int?;
    fetchFirstPage();
  }

  Future<void> fetchFirstPage() async {
    currentPage = 1;
    tips.clear();
    statusRequest = StatusRequest.loading;
    update();

    final Either<StatusRequest, Map<String, dynamic>> res =
        await tipsData.fetchTips(page: currentPage, token: token, categoryId: categoryId);

    res.fold((l) {
      statusRequest = l;
      update();
    }, (r) {
      statusRequest = handelData(r);

      final List data = _extractTipsList(r);
      tips.addAll(
        data.whereType<Object>().map((e) {
          if (e is Map<String, dynamic>) return TipModel.fromJson(e);
          if (e is Map) return TipModel.fromJson(Map<String, dynamic>.from(e));
          return TipModel.fromJson(const {});
        }),
      );

      hasNextPage = _hasNextPage(r);
      statusRequest = StatusRequest.success;
      update();
    });
  }

  Future<void> refreshTips() async {
    await fetchFirstPage();
  }

  Future<void> loadMore() async {
    if (!hasNextPage || isLoadingMore || statusRequest == StatusRequest.loading) return;

    isLoadingMore = true;
    update();

    final nextPage = currentPage + 1;

    final res = await tipsData.fetchTips(page: nextPage, token: token, categoryId: categoryId);

    res.fold((l) {
      // keep current list, only stop load-more
      isLoadingMore = false;
      update();
    }, (r) {
      final List data = _extractTipsList(r);
      tips.addAll(
        data.whereType<Object>().map((e) {
          if (e is Map<String, dynamic>) return TipModel.fromJson(e);
          if (e is Map) return TipModel.fromJson(Map<String, dynamic>.from(e));
          return TipModel.fromJson(const {});
        }),
      );

      currentPage = nextPage;
      hasNextPage = _hasNextPage(r);

      isLoadingMore = false;
      update();
    });
  }
}
