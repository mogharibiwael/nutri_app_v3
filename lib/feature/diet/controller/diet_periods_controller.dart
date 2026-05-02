import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_route.dart';
import '../../../../doctorApp/feature/home/model/patient_model.dart';

/// Meal/snack type for diet period
enum MealType {
  breakfast,
  lunch,
  dinner,
  firstSnack,
  secondSnack,
  thirdSnack,
  extraSnack,
}

extension MealTypeExt on MealType {
  /// Translated default (no user override) — used as hint under the name field.
  String defaultLabel({int? extraSnackIndex}) {
    switch (this) {
      case MealType.breakfast:
        return "breakfast".tr;
      case MealType.lunch:
        return "lunch".tr;
      case MealType.dinner:
        return "dinner".tr;
      case MealType.firstSnack:
        return "firstSnack".tr;
      case MealType.secondSnack:
        return "secondSnack".tr;
      case MealType.thirdSnack:
        return "thirdSnack".tr;
      case MealType.extraSnack:
        final idx = extraSnackIndex ?? 1;
        return "${"extraSnack".tr} $idx";
    }
  }

  String labelFor(DietPeriodModel? period) {
    if (period?.customName != null && period!.customName!.trim().isNotEmpty) {
      return period.customName!.trim();
    }
    switch (this) {
      case MealType.breakfast:
        return "breakfast".tr;
      case MealType.lunch:
        return "lunch".tr;
      case MealType.dinner:
        return "dinner".tr;
      case MealType.firstSnack:
        return "firstSnack".tr;
      case MealType.secondSnack:
        return "secondSnack".tr;
      case MealType.thirdSnack:
        return "thirdSnack".tr;
      case MealType.extraSnack:
        final idx = period?.extraSnackIndex ?? 1;
        return "${"extraSnack".tr} $idx";
    }
  }
}

class DietPeriodModel {
  MealType mealType;
  TimeOfDay time;
  int? extraSnackIndex;
  String? customName;

  DietPeriodModel({
    required this.mealType,
    required this.time,
    this.extraSnackIndex,
    this.customName,
  });

  DietPeriodModel copyWith({
    MealType? mealType,
    TimeOfDay? time,
    int? extraSnackIndex,
    String? customName,
  }) {
    return DietPeriodModel(
      mealType: mealType ?? this.mealType,
      time: time ?? this.time,
      extraSnackIndex: extraSnackIndex ?? this.extraSnackIndex,
      customName: customName ?? this.customName,
    );
  }

  Map<String, dynamic> toJson() => {
        "meal_type": mealType.name,
        "hour": time.hour,
        "minute": time.minute,
        if (extraSnackIndex != null) "extra_snack_index": extraSnackIndex,
        if (customName != null && customName!.trim().isNotEmpty) "custom_name": customName!.trim(),
      };
}

class DietPeriodsController extends GetxController {
  /// Fixed order: Breakfast, Lunch, Dinner, First Snack, Second Snack, Third Snack + extra snacks
  final List<DietPeriodModel> periods = [];

  int? patientId;
  String patientName = "";
  int? doctorId;
  PatientModel? patient;

  int _extraSnackCount = 0;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? {};
    patientId = args["patient_id"] is int
        ? args["patient_id"] as int
        : int.tryParse("${args["patient_id"]}") ?? 0;
    patientName = (args["patient_name"] ?? "").toString();
    doctorId = args["doctor_id"] is int
        ? args["doctor_id"] as int
        : int.tryParse("${args["doctor_id"]}") ?? 0;
    if (args["patient"] is PatientModel) {
      patient = args["patient"] as PatientModel;
      if (patientName.isEmpty && patient!.fullname.isNotEmpty) {
        patientName = patient!.fullname;
      }
    }

    if (periods.isEmpty) {
      _initAllPeriods();
    }
  }

  void _initAllPeriods() {
    periods.clear();
    periods.addAll([
      DietPeriodModel(mealType: MealType.breakfast, time: const TimeOfDay(hour: 8, minute: 0)),
      DietPeriodModel(mealType: MealType.lunch, time: const TimeOfDay(hour: 13, minute: 0)),
      DietPeriodModel(mealType: MealType.dinner, time: const TimeOfDay(hour: 19, minute: 0)),
      DietPeriodModel(mealType: MealType.firstSnack, time: const TimeOfDay(hour: 10, minute: 0)),
      DietPeriodModel(mealType: MealType.secondSnack, time: const TimeOfDay(hour: 16, minute: 0)),
      DietPeriodModel(mealType: MealType.thirdSnack, time: const TimeOfDay(hour: 21, minute: 0)),
    ]);
    update();
  }

  void addSnack() {
    _extraSnackCount++;
    periods.add(DietPeriodModel(
      mealType: MealType.extraSnack,
      time: const TimeOfDay(hour: 14, minute: 0),
      extraSnackIndex: _extraSnackCount,
    ));
    update();
  }

  void updatePeriodTime(int index, TimeOfDay time) {
    if (index < 0 || index >= periods.length) return;
    periods[index] = periods[index].copyWith(time: time);
    update();
  }

  void updatePeriodName(int index, String name) {
    if (index < 0 || index >= periods.length) return;
    periods[index] = periods[index].copyWith(customName: name.isEmpty ? null : name);
    update();
  }

  void removeExtraSnack(int index) {
    if (index >= 0 && index < periods.length && periods[index].mealType == MealType.extraSnack) {
      periods.removeAt(index);
      update();
    }
  }

  bool get hasExtraSnacks => periods.any((p) => p.mealType == MealType.extraSnack);

  void goToNextStep() {
    if (patientId == null || patientId! <= 0 || doctorId == null) {
      Get.snackbar("error".tr, "fillFields".tr);
      return;
    }
    Get.toNamed(
      AppRoute.dietTargets,
      arguments: {
        "patient_id": patientId,
        "patient_name": patientName,
        "doctor_id": doctorId,
        "patient": patient,
        "periods": periods.map((p) => p.toJson()).toList(),
      },
    );
  }

  static const List<MealType> coreMealTypes = [
    MealType.breakfast,
    MealType.lunch,
    MealType.dinner,
    MealType.firstSnack,
    MealType.secondSnack,
    MealType.thirdSnack,
  ];
}
