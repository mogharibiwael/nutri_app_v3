import 'dart:convert';
import 'package:get/get.dart';
import 'package:nutri_guide/core/constant/api_link.dart';
import 'package:nutri_guide/core/service/serviecs.dart';
import 'package:nutri_guide/core/permissions/permissions.dart';
import 'package:nutri_guide/core/class/status_request.dart';
import 'package:nutri_guide/core/class/crud.dart';
import 'package:nutri_guide/feature/ads/data/ads_data.dart';
import 'package:nutri_guide/feature/ads/model/ad_model.dart';
import 'package:nutri_guide/feature/doctor/data/patient_doctors_data.dart';

import '../../../core/routes/app_route.dart';

class HomeController extends GetxController {
  final MyServices myServices = Get.find();
  late final Permissions permissions;
  final AdsData adsData = AdsData(Get.find());
  final Crud crud = Get.find();
  final PatientDoctorsData patientDoctorsData = PatientDoctorsData(Get.find());

  Map<String, dynamic>? user;

  /// Ads for top carousel (public/ads)
  final List<AdModel> ads = [];
  StatusRequest adsStatus = StatusRequest.success;

  @override
  void onInit() {
    super.onInit();
    permissions = Permissions(myServices);
    loadUser();
    fetchAds();
    // Make sure subscription gating (My Diet button) is correct even after status changes.
    syncSubscriptions();
  }

  Future<void> refreshHome() async {
    await Future.wait([
      fetchAds(),
      syncSubscriptions(),
    ]);
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? "") ?? 0;
  }

  int _extractDoctorRecordId(dynamic e) {
    if (e is! Map) return 0;
    final doctorId = _toInt(e["doctor_id"] ?? e["doctorId"]);
    if (doctorId > 0) return doctorId;
    final doctor = e["doctor"];
    if (doctor is Map) {
      final nestedId = _toInt(doctor["id"]);
      if (nestedId > 0) return nestedId;
    }
    final looksLikeDoctor = e.containsKey("is_verified") ||
        e.containsKey("specialization") ||
        e.containsKey("consultation_fee") ||
        e.containsKey("years_of_experience") ||
        e.containsKey("rating");
    if (looksLikeDoctor) {
      final id = _toInt(e["id"]);
      if (id > 0) return id;
    }
    return 0;
  }

  int _extractDoctorUserId(dynamic e) {
    if (e is! Map) return 0;
    final m = Map<String, dynamic>.from(e);
    var uid = _toInt(m["user_id"] ?? m["userId"]);
    if (uid > 0) return uid;
    final doctor = m["doctor"];
    if (doctor is Map) {
      uid = _toInt(doctor["user_id"] ?? doctor["userId"]);
    }
    return uid;
  }

  Future<void> syncSubscriptions() async {
    // Only relevant for patients/users.
    if (!myServices.isLoggedIn) return;
    if (!myServices.isPatient) return;

    final token = myServices.token;
    if (token == null || token.trim().isEmpty) return;

    final userId = myServices.userId;
    if (userId == null || userId <= 0) return;

    final res = await crud.getData(
      ApiLinks.usersSubscribedByUserId(userId),
      token: token,
    );
    res.fold((_) {}, (r) async {
      // Endpoint returns an OBJECT with subscription_status
      final status = (r["subscription_status"] ?? r["status"] ?? "")
          .toString()
          .toLowerCase()
          .trim();

      final isActive = status == "active";
      await myServices.setSubscriptionApprovedOverride(isActive);

      // Keep subscribed doctors list in sync so Doctor Details can show Chat after app restart.
      final myDocsRes = await patientDoctorsData.getMyDoctors(token: token);
      await myDocsRes.fold(
        (_) async {},
        (rr) async {
          final raw = rr["data"] ?? rr["doctors"] ?? rr;
          final list = raw is List ? raw : <dynamic>[];
          final ids = <int>{};
          final userMap = <int, int>{};
          for (final e in list) {
            final id = _extractDoctorRecordId(e);
            if (id > 0) ids.add(id);
            final uid = _extractDoctorUserId(e);
            if (id > 0 && uid > 0) userMap[id] = uid;
          }
          await myServices.setMyDoctorsApiCount(list.length);
          await myServices.setSubscribedDoctorIds(ids);
          await myServices.setDoctorRecordToUserIdMap(userMap);
        },
      );

      loadUser();
    });
  }

  Future<void> fetchAds() async {
    adsStatus = StatusRequest.loading;
    update();

    final res = await adsData.fetchAds();
    res.fold((l) {
      adsStatus = l;
      update();
    }, (r) {
      adsStatus = StatusRequest.success;
      List rawList = [];
      if (r["data"] is List) {
        rawList = r["data"] as List;
      } else if (r["ads"] is List) {
        rawList = r["ads"] as List;
      } else if (r["advertisements"] is List) {
        rawList = r["advertisements"] as List;
      } else if (r["data"] is Map && (r["data"] as Map)["data"] is List) {
        rawList = (r["data"] as Map)["data"] as List;
      }
      final storageBase = ApiLinks.storageBase;
      ads.clear();
      for (final e in rawList) {
        if (e is Map<String, dynamic>) {
          try {
            final ad = AdModel.fromJson(e, storageBase: storageBase);
            if (ad.isActive && ad.imageUrl != null && ad.imageUrl!.isNotEmpty) {
              ads.add(ad);
            }
          } catch (_) {}
        } else if (e is Map) {
          try {
            final ad = AdModel.fromJson(Map<String, dynamic>.from(e), storageBase: storageBase);
            if (ad.isActive && ad.imageUrl != null && ad.imageUrl!.isNotEmpty) {
              ads.add(ad);
            }
          } catch (_) {}
        }
      }
      update();
    });
  }

  void loadUser() {
    final userStr = myServices.sharedPreferences.getString("user");
    if (userStr == null || userStr.isEmpty) {
      user = null;
      update();
      return;
    }
    try {
      user = jsonDecode(userStr) as Map<String, dynamic>;
    } catch (_) {
      user = null;
    }
    update();
  }

  String get userName => (user?["name"] ?? "Guest").toString();
  String get userEmail => (user?["email"] ?? "-").toString();
  String get userPhone => (user?["phone"] ?? "-").toString();
  String get userRole  => (user?["role"] ?? "-").toString();

  /// Returns the name of the doctor the patient is subscribed to (if available in profile).
  String get subscribedDoctorName {
    final p = user?["patient_profile"] ?? user?["patientProfile"];
    if (p is Map) {
      final doc = p["doctor"];
      if (doc is Map && doc["name"] != null) return doc["name"].toString();
    }
    return "";
  }

  /// True when the patient has subscribed to at least one doctor.
  bool get isSubscribed => myServices.subscribedDoctorIds.isNotEmpty;

  /// True when the patient's subscription is approved by admin.
  bool get isSubscribedApproved => myServices.isSubscriptionApproved;

  /// True when subscription is submitted but waiting for admin approval.
  bool get isSubscriptionPending => myServices.hasPendingSubscription;

  bool get isDoctor => permissions.isDoctor || permissions.isAdmin;
  /// True when doctor is approved by admin (can see "My clinic" and enter doctor home).
  bool get isDoctorApproved => myServices.isDoctorApproved;

  void goToDoctorHome() => Get.offAllNamed(AppRoute.doctorWelcome);

  void goDoctors() => Get.toNamed("/doctors");
  void goTips() => Get.toNamed("/tips");
  void goBmi() => Get.toNamed("/bmi");
  void goForums() => Get.toNamed(AppRoute.forums);
  void goConsultations() => Get.toNamed(AppRoute.consultations);
  void goDiet() => Get.toNamed(AppRoute.diet);

  void goStepCounter() => Get.toNamed("/step-counter");
  void goSpiritualNutrition() => Get.toNamed("/spiritual-nutrition");
  void goSettings() => Get.toNamed("/settings");


  Future<void> logout() async {
    await myServices.clearSession();
    Get.offAllNamed(AppRoute.login);
  }
}
