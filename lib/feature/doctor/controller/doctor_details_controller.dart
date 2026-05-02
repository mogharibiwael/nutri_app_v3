import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/class/status_request.dart';
import '../../../core/routes/app_route.dart';
import '../../../core/service/serviecs.dart';
import '../data/doctors_data.dart';
import '../data/patient_doctors_data.dart';
import '../data/subscription_data.dart';
import '../model/doctor_model.dart';

class DoctorDetailsController extends GetxController {
  final MyServices myServices = Get.find();
  final SubscriptionData subscriptionData = SubscriptionData(Get.find());
  final DoctorsData doctorsData = DoctorsData(Get.find());
  final PatientDoctorsData patientDoctorsData = PatientDoctorsData(Get.find());
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardExpController = TextEditingController(); // MM/YY
  final TextEditingController cardCvvController = TextEditingController();

  final TextEditingController walletNameController = TextEditingController(); // e.g. "YemenPay"
  final TextEditingController walletNumberController = TextEditingController(); // wallet account/phone
  final TextEditingController walletRefController = TextEditingController(); // transaction ref

  final TextEditingController transferSenderController = TextEditingController(); // اسم المُرسل
  final TextEditingController transferReceiverController = TextEditingController(); // اسم المُستلم
  final TextEditingController transferRefController = TextEditingController(); // رقم/مرجع الحوالة
  final TextEditingController transferAmountController = TextEditingController(); // المبلغ

  late DoctorModel doctor;

  StatusRequest statusRequest = StatusRequest.success;

  // ✅ subscription state
  bool isSubscribed = false;
  bool isApproved = false;

  // Rating: from GET /doctors/{id}/rate (or doctor.rating from list)
  double? ratingAverage;
  int ratingCount = 0;
  int? myRating; // current user's rating (1-5) if subscribed and already rated
  StatusRequest rateStatus = StatusRequest.success;

  // virtual payment state
  String paymentMethod = "card"; // card | cash | wallet

  // plan state
  String planType = "basic";
  int durationMonths = 12;
  double price = 1200;

  int? _userId;

  bool get isLoading => statusRequest == StatusRequest.loading;

  @override
  void onInit() {
    super.onInit();

    final arg = Get.arguments;
    if (arg is DoctorModel) {
      doctor = arg;
    } else if (arg is Map<String, dynamic>) {
      doctor = DoctorModel.fromJson(arg);
    } else {
      doctor = DoctorModel(
        id: 0,
        name: "-",
        isVerified: false,
        isAvailable: false,
        rating: "0.00",
      );
    }

    _userId = myServices.userId;
    _loadSubscribedState();
    // Ensure the Subscribe/Chat button is correct even after app restart:
    // refresh subscribed doctors from backend, then re-evaluate this doctor's state.
    Future.microtask(_syncMyDoctorsAndRefreshState);
    _setRatingFromDoctor();
    _fetchDoctorRates();
    _fetchMyRate();
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? "") ?? 0;
  }

  int _extractDoctorRecordId(dynamic e) {
    if (e is! Map) return 0;
    // Common shapes:
    // - Doctor object: { id, user_id, name, ... }
    // - Subscription-ish: { doctor_id, doctor: { id, ... }, ... }
    final doctorId = _toInt(e["doctor_id"] ?? e["doctorId"]);
    if (doctorId > 0) return doctorId;
    final doctor = e["doctor"];
    if (doctor is Map) {
      final nestedId = _toInt(doctor["id"]);
      if (nestedId > 0) return nestedId;
    }
    // Only fall back to e["id"] if it looks like a doctor payload.
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
    var uid = _toInt(e["user_id"] ?? e["userId"]);
    if (uid > 0) return uid;
    final doctor = e["doctor"];
    if (doctor is Map) {
      uid = _toInt(doctor["user_id"] ?? doctor["userId"]);
    }
    return uid;
  }

  Future<void> _syncMyDoctorsAndRefreshState() async {
    // Only for logged-in patients/users
    if (!myServices.isLoggedIn) return;
    if (!myServices.isPatient) return;

    final token = myServices.token;
    if (token == null || token.trim().isEmpty) return;

    final res = await patientDoctorsData.getMyDoctors(token: token);
    await res.fold(
      (_) async {},
      (r) async {
        final raw = r["data"] ?? r["doctors"] ?? r;
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

    // Recompute state for this doctor
    _loadSubscribedState();
  }

  /// Fallback from doctor list payload until API responds
  void _setRatingFromDoctor() {
    ratingAverage = double.tryParse(doctor.rating);
    update();
  }

  /// GET /doctor/{id}/rates - update rating average and count on screen
  Future<void> _fetchDoctorRates() async {
    final res = await doctorsData.getDoctorRates(
      doctorId: doctor.id,
      token: myServices.token,
    );
    res.fold((l) {}, (r) {
      if (r["rating"] != null) {
        final v = r["rating"];
        if (v is num) {
          ratingAverage = v.toDouble();
        } else {
          ratingAverage = double.tryParse(v.toString());
        }
      }
      if (r["count"] != null) {
        ratingCount = r["count"] is int ? r["count"] as int : int.tryParse(r["count"].toString()) ?? 0;
      }
      if (r["avg"] != null) {
        final v = r["avg"];
        if (ratingAverage == null && v is num) ratingAverage = v.toDouble();
        else if (ratingAverage == null) ratingAverage = double.tryParse(v.toString());
      }
      update();
    });
  }

  /// GET /my-rates?doctor_id=X - show my rating if I already rated this doctor
  Future<void> _fetchMyRate() async {
    final res = await doctorsData.getMyRate(
      doctorId: doctor.id,
      token: myServices.token,
    );
    res.fold((l) {}, (r) {
      if (r["rate"] != null) {
        final v = r["rate"];
        myRating = v is int ? v : int.tryParse(v.toString());
      } else if (r["my_rating"] != null) {
        final v = r["my_rating"];
        myRating = v is int ? v : int.tryParse(v.toString());
      }
      update();
    });
  }

  /// Call after opening doctor or after rating to refresh rates and my rate on screen
  Future<void> refreshRates() async {
    await _fetchDoctorRates();
    await _fetchMyRate();
  }

   void _loadSubscribedState() {
    isSubscribed = myServices.isSubscribedToDoctor(doctor.id);
    isApproved = myServices.isApprovedToDoctor(doctor.id);
    update();
  }

  void refreshSubscribed() {
    _loadSubscribedState();
  }

  /// Submit rating (1-5). Only for subscribed patients.
  Future<void> submitRating(int stars) async {
    if (!isSubscribed) return;
    if (stars < 1 || stars > 5) return;

    rateStatus = StatusRequest.loading;
    update();

    final res = await doctorsData.submitDoctorRate(
      doctorId: doctor.id,
      rate: stars,
      token: myServices.token,
    );

    res.fold((l) {
      rateStatus = StatusRequest.failure;
      update();
      Get.snackbar("error".tr, "serverError".tr);
    }, (r) {
      rateStatus = StatusRequest.success;
      myRating = stars;
      if (r["rating"] != null) {
        final v = r["rating"];
        if (v is num) {
          ratingAverage = v.toDouble();
        } else {
          ratingAverage = double.tryParse(v.toString());
        }
      }
      if (r["count"] != null) {
        ratingCount = r["count"] is int ? r["count"] as int : int.tryParse(r["count"].toString()) ?? ratingCount;
      }
      update();
      Get.snackbar("success".tr, r["message"]?.toString() ?? "ratingSaved".tr);
      refreshRates();
    });
  }

   void openVirtualPaymentSheet() {
    // If user already subscribed (even pending), go to chat.
    if (isSubscribed) {
      goToChat();
      return;
    }
    goToSubscriptionInfo();
  }

  void goToSubscriptionInfo() {
    Get.toNamed(AppRoute.subscriptionInfo, arguments: {
      "doctor": doctor.toJson(),
    });
  }

  void setPaymentMethod(String method) {
    paymentMethod = method;
    update();
  }

  void setPlanType(String type) {
    planType = type;
    update();
  }

  void setDuration(int months) {
    durationMonths = months;
    update();
  }

  void setPrice(double p) {
    price = p;
    update();
  }

  Future<void> confirmPaymentAndSubscribe() async {
    // ✅ validate payment info based on method
    final ok = _validatePayment();
    if (!ok) return;

    statusRequest = StatusRequest.loading;
    update();

    await Future.delayed(const Duration(seconds: 1)); // fake processing

    if (Get.isBottomSheetOpen == true) Get.back();

    await subscribe();
  }

  bool _validatePayment() {
    String err = "";

    if (paymentMethod == "card") {
      if (cardHolderController.text.trim().isEmpty) err = "Enter card holder name";
      else if (cardNumberController.text.trim().length < 12) err = "Enter valid card number";
      else if (cardExpController.text.trim().isEmpty) err = "Enter expiry (MM/YY)";
      else if (cardCvvController.text.trim().length < 3) err = "Enter CVV";
    } else if (paymentMethod == "wallet") {
      if (walletNameController.text.trim().isEmpty) err = "Enter wallet name";
      else if (walletNumberController.text.trim().isEmpty) err = "Enter wallet number";
      else if (walletRefController.text.trim().isEmpty) err = "Enter transaction reference";
    } else if (paymentMethod == "transfer") {
      if (transferSenderController.text.trim().isEmpty) err = "Enter sender name";
      else if (transferReceiverController.text.trim().isEmpty) err = "Enter receiver name";
      else if (transferRefController.text.trim().isEmpty) err = "Enter transfer reference";
      else if (transferAmountController.text.trim().isEmpty) err = "Enter amount";
    }

    if (err.isNotEmpty) {
      Get.snackbar("Error", err, snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    return true;
  }


  Future<void> subscribe() async {
    if (_userId == null) {
      statusRequest = StatusRequest.failure;
      update();
      Get.snackbar("Error", "User session not found (missing user id)");
      return;
    }

    statusRequest = StatusRequest.loading;
    update();

    final startDate = DateTime.now();
    final endDate =
    DateTime(startDate.year, startDate.month + durationMonths, startDate.day);

    final body = {
      "user_id": _userId,
      "doctor_id": doctor.id,
      "plan": "premium",
      "plan_type": planType,
      "price": price,
      "duration_months": durationMonths,
      "start_date": startDate.toIso8601String().substring(0, 10),
      "end_date": endDate.toIso8601String().substring(0, 10),
    };

    final token = myServices.token;

    final res = await subscriptionData.createSubscription(body, token: token);

    // ✅ res = Either<StatusRequest, Map>
    res.fold(
          (l) {
        statusRequest = l;
        update();
        Get.snackbar("Error", "Request failed: $l");
      },
          (r) async {
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
        isSubscribed = true;

        update();

        Get.snackbar("Success", r["message"]?.toString() ?? "Subscription created successfully");
        await Get.toNamed(AppRoute.patientProfile);

        goToChat();
      },
    );
  }

  void goToChat() {
    if (!isSubscribed) return;

    // receiver_id should be the doctor's USER_ID (the one they login with), not the doctor's record ID.
    final receiverId = doctor.userId ?? doctor.id;

    Get.toNamed(AppRoute.chat, arguments: {
      "doctor_id": doctor.id,
      "receiver_id": receiverId,
      "doctor_name": doctor.name,
      // Backend history: GET /chat/history/{doctor_users.id}; POST messages use same id as conversation peer.
      "conversation_id": receiverId,
    });
  }




  // --- payment inputs ---


// ✅ methods: card | wallet | transfer

  Map<String, dynamic> get paymentInfo {
    switch (paymentMethod) {
      case "card":
        return {
          "method": "card",
          "holder_name": cardHolderController.text.trim(),
          "card_number": cardNumberController.text.trim(),
          "exp": cardExpController.text.trim(),
          "cvv": cardCvvController.text.trim(),
        };
      case "wallet":
        return {
          "method": "wallet",
          "wallet_name": walletNameController.text.trim(),
          "wallet_number": walletNumberController.text.trim(),
          "wallet_ref": walletRefController.text.trim(),
        };
      case "transfer":
        return {
          "method": "transfer",
          "sender_name": transferSenderController.text.trim(),
          "receiver_name": transferReceiverController.text.trim(),
          "transfer_ref": transferRefController.text.trim(),
          "amount": transferAmountController.text.trim(),
        };
      default:
        return {"method": paymentMethod};
    }
  }
  @override
  void onClose() {
    cardHolderController.dispose();
    cardNumberController.dispose();
    cardExpController.dispose();
    cardCvvController.dispose();

    walletNameController.dispose();
    walletNumberController.dispose();
    walletRefController.dispose();

    transferSenderController.dispose();
    transferReceiverController.dispose();
    transferRefController.dispose();
    transferAmountController.dispose();

    super.onClose();
  }

}
