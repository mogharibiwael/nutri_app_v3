import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutri_guide/core/constant/api_link.dart';

class MyServices extends GetxService {
  late SharedPreferences sharedPreferences;

  Future<MyServices> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    return this;
  }

  Future<void> saveSession({
    required String token,
    required String type, // user / doctor / admin ...
    Map<String, dynamic>? user,
  }) async {
    await sharedPreferences.setString("token", token);
    await sharedPreferences.setString("type", type);
    if (user != null) {
      await sharedPreferences.setString("user", jsonEncode(user));
    }
  }

  String? get token => sharedPreferences.getString("token");

  /// User type: "doctor", "user", "admin". Falls back to user["type"] or "doctor" if user has doctor object.
  String? get type {
    final stored = sharedPreferences.getString("type");
    if (stored != null && stored.trim().isNotEmpty) return stored;
    final u = user;
    if (u == null) return null;
    final t = (u["type"] ?? "").toString().trim().toLowerCase();
    if (t.isNotEmpty) return t;
    if (u["doctor"] != null || u["doctor_profile"] != null || u["doctorProfile"] != null) return "doctor";
    return "user";
  }

  bool get isLoggedIn => token != null && token!.trim().isNotEmpty;

  Map<String, dynamic>? get user {
    final s = sharedPreferences.getString("user");
    if (s == null || s.trim().isEmpty) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Backend shape helpers
  bool get hasDoctorProfile {
    final u = user;
    if (u == null) return false;
    final doc = u["doctor_profile"] ?? u["doctorProfile"] ?? u["doctor"];
    return doc is Map;
  }

  bool get hasPatientProfile {
    final u = user;
    if (u == null) return false;
    final pat = u["patient_profile"] ?? u["patientProfile"];
    return pat is Map;
  }

  int? get userId {
    final u = user;
    if (u == null) return null;
    final id = u["id"];
    if (id is int) return id;
    return int.tryParse(id?.toString() ?? "");
  }

  /// Global profile image URL logic
  String? get profileImageUrl {
    final u = user;
    if (u == null) return null;
    
    // Check patient's profile image
    final pat = u["patient_profile"] ?? u["patientProfile"] ?? u["patient"];
    if (pat is Map && pat["image"] != null && pat["image"].toString().isNotEmpty) {
      return "${ApiLinks.storageBase}/${pat["image"]}";
    }

    // Check doctor's profile image
    final doc = u["doctor_profile"] ?? u["doctorProfile"] ?? u["doctor"];
    if (doc is Map && doc["profile_image"] != null && doc["profile_image"].toString().isNotEmpty) {
      return "${ApiLinks.storageBase}/${doc["profile_image"]}";
    }
    
    return null;
  }

  /// Doctor's record id (from doctors table). Required for diet-plans API.
  /// Backend expects doctor_id, not user_id. Read from user["doctor_id"] or user["doctor"]["id"].
  int? get doctorId {
    final u = user;
    if (u == null) return null;
    final did = u["doctor_id"];
    if (did != null) {
      if (did is int) return did;
      final parsed = int.tryParse(did.toString());
      if (parsed != null) return parsed;
    }
    final doctor = u["doctor"] ?? u["doctor_profile"] ?? u["doctorProfile"];
    if (doctor is Map) {
      final id = doctor["id"];
      if (id is int) return id;
      return int.tryParse(id?.toString() ?? "");
    }
    return null;
  }

  // -------------------------------
  // ✅ Subscriptions cache (doctor ids)
  static const String _subsKey = "subscribed_doctor_ids";
  static const String _subApprovedOverrideKey = "subscription_approved_override";
  static const String _myDoctorsApiCountKey = "my_doctors_api_count";
  /// JSON map: doctor table id -> doctor's users.id (from GET /patients/my-doctors).
  static const String _doctorRecordToUserIdKey = "doctor_record_to_user_id_json";

  Set<int> get subscribedDoctorIds {
    final list = sharedPreferences.getStringList(_subsKey) ?? <String>[];
    return list.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  int? get currentDoctorIdFromPatientProfile {
    final u = user;
    if (u == null) return null;
    final p = u["patient_profile"] ?? u["patientProfile"];
    if (p is! Map) return null;
    final v = p["current_doctor_id"];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? "");
  }

  bool get isSubscribedFromPatientProfile {
    final u = user;
    if (u == null) return false;
    final p = u["patient_profile"] ?? u["patientProfile"];
    if (p is! Map) return false;
    return p["is_subscribed"] == true;
  }

  bool isSubscribedToDoctor(int doctorId) {
    if (subscribedDoctorIds.contains(doctorId)) return true;
    return isApprovedToDoctor(doctorId);
  }

  bool isApprovedToDoctor(int doctorId) {
    final cur = currentDoctorIdFromPatientProfile;
    return cur != null && cur == doctorId && isSubscribedFromPatientProfile;
  }

  Future<void> markSubscribedDoctor(int doctorId) async {
    final ids = subscribedDoctorIds;
    ids.add(doctorId);
    await sharedPreferences.setStringList(
      _subsKey,
      ids.map((e) => e.toString()).toList(),
    );
  }

  /// When backend exposes subscription status outside patient_profile,
  /// allow the app to override approval state (e.g. /users-subscribed).
  bool? get subscriptionApprovedOverride {
    if (!sharedPreferences.containsKey(_subApprovedOverrideKey)) return null;
    return sharedPreferences.getBool(_subApprovedOverrideKey);
  }

  Future<void> setSubscriptionApprovedOverride(bool? approved) async {
    if (approved == null) {
      await sharedPreferences.remove(_subApprovedOverrideKey);
      return;
    }
    await sharedPreferences.setBool(_subApprovedOverrideKey, approved);
  }

  /// Last `data` length from GET /patients/my-doctors (-1 = not synced yet).
  int get myDoctorsApiCount {
    if (!sharedPreferences.containsKey(_myDoctorsApiCountKey)) return -1;
    return sharedPreferences.getInt(_myDoctorsApiCountKey) ?? 0;
  }

  Future<void> setMyDoctorsApiCount(int count) async {
    await sharedPreferences.setInt(_myDoctorsApiCountKey, count);
  }

  /// Cached login user id for a doctor **record** id (for chat receiver_id / history path).
  int? userIdForDoctorRecord(int doctorRecordId) {
    if (doctorRecordId <= 0) return null;
    final s = sharedPreferences.getString(_doctorRecordToUserIdKey);
    if (s == null || s.isEmpty) return null;
    try {
      final decoded = jsonDecode(s) as Map<String, dynamic>;
      final v = decoded["$doctorRecordId"];
      if (v is int) return v;
      return int.tryParse("$v");
    } catch (_) {
      return null;
    }
  }

  Future<void> setDoctorRecordToUserIdMap(Map<int, int> recordToUser) async {
    if (recordToUser.isEmpty) {
      await sharedPreferences.remove(_doctorRecordToUserIdKey);
      return;
    }
    final jsonMap = <String, int>{
      for (final e in recordToUser.entries) "${e.key}": e.value,
    };
    await sharedPreferences.setString(
      _doctorRecordToUserIdKey,
      jsonEncode(jsonMap),
    );
  }

  /// [patient_profile.current_doctor_id] if set, else first id from my-doctors sync.
  int? get primaryDoctorRecordIdForChat {
    final cur = currentDoctorIdFromPatientProfile;
    if (cur != null && cur > 0) return cur;
    final subs = subscribedDoctorIds.toList()..sort();
    if (subs.isEmpty) return null;
    return subs.first;
  }

  /// True when a patient has a subscription that is approved by admin.
  /// Backend returns is_subscribed: true in patient_profile when approved.
  bool get isSubscriptionApproved {
    if (!isPatient) return false;
    // Prefer explicit override if present (e.g. from /users-subscribed)
    final override = subscriptionApprovedOverride;
    if (override != null) return override;
    return isSubscribedFromPatientProfile;
  }

  /// Show patient diet / "My Diet" when profile is approved or GET /patients/my-doctors returned doctors.
  bool get canAccessPatientDiet {
    if (!isPatient) return false;
    if (isSubscriptionApproved) return true;
    return myDoctorsApiCount > 0;
  }

  /// True when a patient has requested a subscription (uploaded invoice) but not yet approved.
  bool get hasPendingSubscription {
    if (!isPatient) return false;
    // If my-doctors returned at least one doctor, hide "pending approval" home banner.
    if (myDoctorsApiCount > 0) return false;
    // If backend says active via override, never show pending alert.
    final override = subscriptionApprovedOverride;
    if (override == true) return false;
    // If override explicitly says not approved, treat as pending when any subscription exists.
    if (override == false) return subscribedDoctorIds.isNotEmpty;
    // Fallback to legacy patient_profile fields.
    return subscribedDoctorIds.isNotEmpty && !isSubscribedFromPatientProfile;
  }

  Future<void> setSubscribedDoctorIds(Set<int> ids) async {
    await sharedPreferences.setStringList(
      _subsKey,
      ids.map((e) => e.toString()).toList(),
    );
  }

  Future<void> clearSession() async {
    await sharedPreferences.remove("token");
    await sharedPreferences.remove("type");
    await sharedPreferences.remove("user");
    await sharedPreferences.remove(_subsKey );
    await sharedPreferences.remove(_subApprovedOverrideKey);
    await sharedPreferences.remove(_myDoctorsApiCountKey);
    await sharedPreferences.remove(_doctorRecordToUserIdKey);
  }

  // ─────────────────────────────────────────────────────
  // Role helpers
  // ─────────────────────────────────────────────────────

  /// Check if user is patient (type: "patient" or "payed" or "user")
  bool get isPatient {
    if (!isLoggedIn) return false;
    final type = (this.type ?? "").toLowerCase();
    return type == "patient" || type == "payed" || type == "user";
  }

  /// Check if user is doctor
  bool get isDoctor {
    if (!isLoggedIn) return false;
    return (type ?? "").toLowerCase() == "doctor";
  }

  /// True when doctor's account is approved by admin (application_status == "approved" or is_verified == true).
  /// Used to show "My clinic" and doctor home access.
  bool get isDoctorApproved {
    if (!isDoctor) return false;
    // Backend can return doctor info under: user["doctor"], user["doctor_profile"], or user["doctor"]["..."]
    final u = user;
    final dynamic doc = u?["doctor"] ?? u?["doctor_profile"] ?? u?["doctorProfile"];
    if (doc is! Map) return false;
    final status = (doc["application_status"] ?? "").toString().toLowerCase();
    if (status == "approved") return true;
    if (doc["is_verified"] == true) return true;
    return false;
  }

  /// Check if user is admin
  bool get isAdmin {
    if (!isLoggedIn) return false;
    return (type ?? "").toLowerCase() == "admin";
  }
}

Future<void> initialServices() async {
  await Get.putAsync(() => MyServices().init());
}
