import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nutri_guide/core/class/crud.dart';
import 'package:nutri_guide/core/class/status_request.dart';
import 'package:nutri_guide/core/function/handel_data.dart';
import 'package:nutri_guide/core/routes/app_route.dart';
import 'package:nutri_guide/feature/auth/data/login_data.dart';
import 'package:nutri_guide/feature/doctor/data/subscription_data.dart';
import 'package:nutri_guide/feature/chat/data/patient_profile_data.dart';
import 'package:nutri_guide/feature/doctor/data/patient_doctors_data.dart';
import '../../../core/function/show_dialog.dart';
import '../../../core/service/serviecs.dart';


class LoginController extends GetxController {
  late TextEditingController emailController;
  late TextEditingController passwordController;

  final LoginData loginData = LoginData(Get.find());
  final MyServices myServices = Get.find();
  final PatientProfileData patientProfileData = PatientProfileData(Get.find());
  final PatientDoctorsData patientDoctorsData = PatientDoctorsData(Get.find());

  StatusRequest statusRequest = StatusRequest.success; // start idle

  bool get isLoading => statusRequest == StatusRequest.loading;

  /// Password field visibility
  bool isPasswordVisible = false;

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    update();
  }

  Future<void> login() async {
    if (isLoading) return; // prevent double tap

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showAwesomeDialog(
        type: DialogType.warning,
        title: "Validation",
        desc: "Please enter email and password",
      );
      return;
    }

    statusRequest = StatusRequest.loading;
    update();

    final response = await loginData.getData(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    statusRequest = handelData(response);

    response.fold(
          (l) {

        statusRequest = l; // failure / offline / serverFailure
        String msg = "Invalid email or password";
        if (l == StatusRequest.offlineFailure) {
          msg = "No internet connection";
        } else if (l == StatusRequest.serverFailure) {
          msg = "Server error, try again later";
        }

        showAwesomeDialog(
          type: DialogType.error,
          title: "login_failed".tr,
          desc: msg,
        );

        update();
      },
          (r) async {

        try {
          // Support both top-level and nested data (e.g. r['data']['token'])
          final Map<String, dynamic> data = (r is Map && r['data'] is Map)
              ? Map<String, dynamic>.from(r['data'] as Map)
              : (r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{});

          // Handle error responses (message but no token)
          final token = data['token'] ?? data['access_token'] ?? (r is Map ? r['token'] ?? r['access_token'] : null);
          if (token == null || token.toString().trim().isEmpty) {
            final serverMessage = (data["message"] ?? (r is Map ? (r as Map)["message"] : null))?.toString() ?? "";
            statusRequest = StatusRequest.failure;
            update();
            // Detect "pending approval" (Arabic: موافقة / انتظار, or English "pending")
            final isPendingApproval = serverMessage.contains("موافقة") ||
                serverMessage.contains("انتظار") ||
                serverMessage.toLowerCase().contains("pending");
            if (isPendingApproval) {
              showAwesomeDialog(
                type: DialogType.warning,
                title: "accountPendingApproval".tr,
                desc: "accountPendingApprovalHint".tr,
              );
            } else {
              showAwesomeDialog(
                type: DialogType.error,
                title: "login_failed".tr,
                desc: serverMessage.isNotEmpty
                    ? serverMessage
                    : "Token not returned from server",
              );
            }
            return;
          }

          final rawUser = data['user'] ?? (r is Map ? (r as Map)['user'] : null);
          final userMap = (rawUser is Map)
              ? Map<String, dynamic>.from(rawUser)
              : <String, dynamic>{};

          // Infer type ONLY from backend profile keys:
          // - doctor_profile != null => doctor screens
          // - else => patient/user screens
          String userType = (userMap['type'] ?? '').toString().trim().toLowerCase();
          final docProfile = userMap['doctor_profile'] ?? userMap['doctorProfile'] ?? userMap['doctor'];
          if (docProfile is Map) {
            userType = 'doctor';
          } else {
            userType = 'user';
          }

          await myServices.saveSession(
            token: token.toString(),
            type: userType,
            user: userMap.isEmpty ? null : userMap,
          );

          // Load subscriptions from backend for patients (so Chat shows for subscribed doctors after re-login)
          if (userType == "user" || userType == "patient" || userType == "payed") {
            // IMPORTANT: await subscriptions sync so UI gating (My Diet / Chat) is correct on first render.
            await _syncMyDoctors(token.toString());
            // Profile sync is for navigation helpers (current doctor id/name), but should not override my-doctors list.
            await _syncPatientProfileAndCurrentDoctor(token.toString());
          }

          statusRequest = StatusRequest.success;
          update();

          // All users (including doctors not yet approved) go to gate → home.
          Get.offAllNamed(AppRoute.gate);

        } catch (e) {
          statusRequest = StatusRequest.failure;
          update();
          showAwesomeDialog(
            type: DialogType.error,
            title: "Error",
            desc: "Something went wrong while saving session",
            dismissOnTouchOutside: false,
          );
        }
      }

      ,
    );
  }

  goToSignup() => Get.toNamed(AppRoute.signUp);
  goToForget() => Get.toNamed(AppRoute.forgotPassword);

  Future<void> _loadSubscriptionsFromBackend(String token) async {
    try {
      final subscriptionData = SubscriptionData(Get.find<Crud>());
      final res = await subscriptionData.getMySubscriptions(token: token);
      res.fold(
        (_) {},
        (r) {
          final raw = r["data"] ?? r["subscriptions"] ?? r;
          final list = raw is List ? raw : <dynamic>[];
          final doctorIds = <int>{};
          for (final e in list) {
            if (e is! Map) continue;
            final did = e["doctor_id"] ?? e["doctorId"];
            if (did != null) {
              final id = did is int ? did : int.tryParse(did.toString());
              if (id != null && id > 0) doctorIds.add(id);
            }
          }
          // Always write (even empty) so we don't keep stale subscriptions.
          myServices.setSubscribedDoctorIds(doctorIds);
        },
      );
    } catch (_) {}
  }

  Future<void> _syncMyDoctors(String token) async {
    try {
      final res = await patientDoctorsData.getMyDoctors(token: token);
      res.fold((_) {}, (r) async {
        final raw = r["data"] ?? r["doctors"] ?? r;
        final list = raw is List ? raw : <dynamic>[];
        final ids = <int>{};
        final userMap = <int, int>{};
        for (final e in list) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final did = m["id"] ?? m["doctor_id"] ?? m["doctorId"];
          final id = did is int ? did : int.tryParse(did?.toString() ?? "");
          if (id != null && id > 0) ids.add(id);
          final uidRaw = m["user_id"] ?? m["userId"];
          final uid = uidRaw is int ? uidRaw : int.tryParse("$uidRaw") ?? 0;
          if (id != null && id > 0 && uid > 0) userMap[id] = uid;
        }
        // Always write (even empty) so My Diet and Chat can hide correctly.
        await myServices.setMyDoctorsApiCount(list.length);
        await myServices.setSubscribedDoctorIds(ids);
        await myServices.setDoctorRecordToUserIdMap(userMap);
      });
    } catch (_) {}
  }

  Future<void> _syncPatientProfileAndCurrentDoctor(String token) async {
    try {
      final res = await patientProfileData.getProfile(token: token);
      res.fold((_) {}, (r) async {
        final data = r["data"] is Map ? Map<String, dynamic>.from(r["data"]) : null;
        if (data == null) return;

        // Merge patient_profile into stored user map
        final u = myServices.user ?? <String, dynamic>{};
        final merged = <String, dynamic>{...u, "patient_profile": data};
        await myServices.saveSession(
          token: token,
          type: myServices.type ?? "user",
          user: merged,
        );
      });
    } catch (_) {}
  }

  @override
  void onInit() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    super.onInit();
  }


}
