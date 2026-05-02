import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constant/theme/colors.dart';
import '../../../core/class/status_request.dart';
import '../../../core/service/serviecs.dart';
import '../chat/data/patient_profile_data.dart';
import 'controller/doctor_details_controller.dart';
import 'data/subscription_data.dart';
import 'model/doctor_model.dart';


class PaymentInvoiceController extends GetxController {
  final MyServices myServices = Get.find();
  final SubscriptionData subscriptionData = SubscriptionData(Get.find());
  final PatientProfileData patientProfileData = PatientProfileData(Get.find());
  final ImagePicker _picker = ImagePicker();

  late DoctorModel doctor;
  late Map<String, dynamic> subscriptionForm;

  File? receiptImage;
  StatusRequest statusRequest = StatusRequest.success;
  int? _userId;

  bool get isLoading => statusRequest == StatusRequest.loading;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments as Map<String, dynamic>?;
    if (arg == null) return;
    doctor = DoctorModel.fromJson(arg['doctor'] as Map<String, dynamic>);
    subscriptionForm = Map<String, dynamic>.from(arg);
    _userId = myServices.userId;
  }

  String get doctorDisplayName {
    final n = doctor.name;
    if (n.startsWith("د.") || n.startsWith("Dr.")) return n;
    return Get.locale?.languageCode == 'ar' ? "د. $n" : "Dr. $n";
  }

  String get bankAccount => doctor.bankAccount ?? "-";
  String get dietPrice => doctor.consultationFee ?? "-";

  Future<void> pickReceipt() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      receiptImage = File(file.path);
      update();
    }
  }

  Future<void> submitSubscription() async {
    if (_userId == null) {
      Get.snackbar("Error", "User session not found");
      return;
    }

    statusRequest = StatusRequest.loading;
    update();

    const durationMonths = 12;
    final startDate = DateTime.now();
    final endDate = DateTime(
      startDate.year,
      startDate.month + durationMonths,
      startDate.day,
    );

    final priceValue = double.tryParse(
      dietPrice.replaceAll(RegExp(r'[^\d.]'), ''),
    ) ?? 0.0;

    final body = {
      "user_id": _userId,
      "doctor_id": doctor.id,
      "plan": "premium",
      "plan_type": "basic",
      "price": priceValue,
      "duration_months": durationMonths,
      "start_date": startDate.toIso8601String().substring(0, 10),
      "end_date": endDate.toIso8601String().substring(0, 10),
      "full_name": subscriptionForm["full_name"],
      "phone": subscriptionForm["phone"],
      "date_of_birth": subscriptionForm["date_of_birth"],
      "height_cm": subscriptionForm["height_cm"],
      "weight_kg": subscriptionForm["weight_kg"],
      "gender": subscriptionForm["gender"],
      "activity": subscriptionForm["activity"],
    };

    final token = myServices.token;
    final res = await subscriptionData.createSubscription(
      body, 
      receiptImage: receiptImage,
      token: token,
    );

    if (res is! Either<StatusRequest, Map<String, dynamic>>) {
      statusRequest = StatusRequest.serverFailure;
      update();
      Get.snackbar("Error", "subscribeFailed".tr);
      return;
    }

    res.fold(
      (l) {
        statusRequest = l;
        update();
        Get.snackbar("Error", "subscribeFailed".tr);
      },
      (r) async {
        // Crud always returns Right with _statusCode; treat non-2xx as failure.
        final code = r["_statusCode"];
        final statusCode = code is int ? code : int.tryParse(code?.toString() ?? "");
        final ok = statusCode == null || statusCode == 200 || statusCode == 201;
        if (!ok) {
          statusRequest = StatusRequest.failure;
          update();
          final msg = (r["message"] ?? r["error"] ?? "subscribeFailed".tr).toString();
          Get.snackbar("Error", msg);
          return;
        }

        statusRequest = StatusRequest.success;
        await myServices.markSubscribedDoctor(doctor.id);

        // After successful subscription, persist the patient body info into /api/patients/profile
        // so doctors and diet features can use correct height/weight/gender/activity.
        await _savePatientProfileFromSubscriptionForm();

        update();
        // Use closeOverlays: false to avoid "disposed snackbar" crash when popping
        Get.back(closeOverlays: false);
        Get.back(closeOverlays: false);
        try {
          Get.find<DoctorDetailsController>().refreshSubscribed();
        } catch (_) {}
        
        Get.snackbar(
          "success".tr, 
          "subscription_sent_pending_approval".tr,
          duration: const Duration(seconds: 5),
          backgroundColor: AppColor.primary.withOpacity(0.1),
        );
      },
    );
  }

  Future<void> _savePatientProfileFromSubscriptionForm() async {
    final token = myServices.token;
    if (token == null || token.trim().isEmpty) return;

    final dob = subscriptionForm["date_of_birth"]?.toString();
    final h = subscriptionForm["height_cm"];
    final w = subscriptionForm["weight_kg"];
    final gender = subscriptionForm["gender"]?.toString();
    final activity = subscriptionForm["activity"]?.toString();

    // Backend expects: gender, date_of_birth, height, current_weight, physical_activity, medical_history
    final body = <String, dynamic>{
      if (gender != null && gender.isNotEmpty) "gender": gender,
      if (dob != null && dob.isNotEmpty) "date_of_birth": dob,
      if (h != null) "height": h,
      if (w != null) "current_weight": w,
      if (activity != null && activity.isNotEmpty) "physical_activity": activity,
      "medical_history": "", // optional
    };

    try {
      final res = await patientProfileData.updateProfile(body, token: token);
      await res.fold((_) async {}, (response) async {
        // Merge returned patient_profile (if any) into stored session user map
        final d = response["data"];
        final profile = d is Map ? Map<String, dynamic>.from(d) : null;
        if (profile == null) return;
        final u = myServices.user ?? <String, dynamic>{};
        final merged = <String, dynamic>{...u, "patient_profile": profile};
        await myServices.saveSession(
          token: token,
          type: myServices.type ?? "user",
          user: merged,
        );
      });
    } catch (_) {
      // best-effort; ignore failures so subscription flow continues
    }
  }
}
