import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_route.dart';
import '../../../../doctorApp/feature/home/model/patient_model.dart';
import '../../../core/service/diet_calculator_service.dart';
import '../model/exchange_model.dart';
import '../model/portion_categories_model.dart';
import '../service/diet_payload_builder.dart';

class DetermineMealsController extends GetxController {
  int? patientId;
  String patientName = "";
  int? doctorId;
  PatientModel? patient;
  List<Map<String, dynamic>> periods = [];
  DietTargetsResult? targets;
  PortionCategoriesPlan? portionPlan;
  DailyExchangePlan? exchangePlan;
  Map<String, Map<String, double>> distribution = {};

  final Map<String, List<String>> mealItems = {};
  final TextEditingController notesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? {};
    patientId = args["patient_id"];
    patientName = (args["patient_name"] ?? "").toString();
    doctorId = args["doctor_id"] is int
        ? args["doctor_id"] as int
        : int.tryParse("${args["doctor_id"]}") ?? 0;
    patient = args["patient"] as PatientModel?;
    if (args["periods"] is List) {
      periods = (args["periods"] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    targets = args["targets"] as DietTargetsResult?;
    portionPlan = args["portion_plan"] as PortionCategoriesPlan?;
    if (args["exchange_plan"] is DailyExchangePlan) {
      exchangePlan = args["exchange_plan"] as DailyExchangePlan;
    } else if (args["exchange_plan_json"] is Map) {
      exchangePlan = DailyExchangePlan.fromJson(
        Map<String, dynamic>.from(args["exchange_plan_json"] as Map),
      );
    }
    if (args["distribution"] is Map) {
      final d = args["distribution"] as Map;
      for (final e in d.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is Map) {
          distribution[k] = Map<String, double>.from(
            (v as Map).map((k2, v2) =>
                MapEntry(k2.toString(), (v2 is num) ? v2.toDouble() : 0.0)),
          );
          mealItems[k] = [];
        }
      }
    }
  }

  List<String> getMealKeys() => distribution.keys.toList();

  String mealKeyToLabel(String key) {
    final custom = DietPayloadBuilder.userEnteredMealName(key, periods);
    if (custom != null && custom.isNotEmpty) return custom;
    if (key == "breakfast") return "breakfast".tr;
    if (key == "lunch") return "lunch".tr;
    if (key == "dinner") return "dinner".tr;
    if (key == "firstSnack") return "firstSnack".tr;
    if (key == "secondSnack") return "secondSnack".tr;
    if (key == "thirdSnack") return "thirdSnack".tr;
    if (key.startsWith("extra_")) return key.substring(6);
    if (key.startsWith("extraSnack_")) return "${"extraSnack".tr} ${key.substring(11)}";
    return key;
  }

  String getMealBreakdown(String mealKey) {
    final plan = portionPlan ?? exchangePlan;
    if (plan == null) return "";
    final d = distribution[mealKey];
    if (d == null) return "";
    final parts = <String>[];
    if ((d["starch"] ?? 0) > 0) parts.add("${"starch".tr}: ${d["starch"]?.toStringAsFixed(1)}");
    if ((d["fruit"] ?? 0) > 0) parts.add("${"fruit".tr}: ${d["fruit"]?.toStringAsFixed(1)}");
    if ((d["vegetables"] ?? 0) > 0) parts.add("${"vegetables".tr}: ${d["vegetables"]?.toStringAsFixed(1)}");
    if ((d["milk"] ?? 0) > 0) parts.add("${"milk".tr}: ${d["milk"]?.toStringAsFixed(1)}");
    if ((d["meat"] ?? 0) > 0) parts.add("${"meat".tr}: ${d["meat"]?.toStringAsFixed(1)}");
    if ((d["fat"] ?? 0) > 0) parts.add("${"fat".tr}: ${d["fat"]?.toStringAsFixed(1)}");
    return parts.join(", ");
  }

  void addMealItem(String mealKey, String item) {
    final trimmed = item.trim();
    if (trimmed.isEmpty) return;
    mealItems[mealKey] ??= [];
    mealItems[mealKey]!.add(trimmed);
    update();
  }

  void removeMealItem(String mealKey, int index) {
    mealItems[mealKey]?.removeAt(index);
    update();
  }

  List<String> getMealItems(String mealKey) =>
      mealItems[mealKey] ?? [];

  void goToCreateDiet() {
    if (patientId == null || doctorId == null) {
      Get.snackbar("error".tr, "fillFields".tr);
      return;
    }
    final notes = notesController.text.trim();
    final doctorNotes = notes.isNotEmpty ? [notes] : <String>[];
    Get.toNamed(
      AppRoute.createDietForPatient,
      arguments: {
        "patient_id": patientId,
        "patient_name": patientName,
        "doctor_id": doctorId,
        "patient": patient,
        "periods": periods,
        "targets": targets,
        "portion_plan": portionPlan,
        "exchange_plan": exchangePlan,
        "exchange_plan_json": exchangePlan?.toJson(),
        "distribution": Map.from(distribution),
        "meal_items": Map.from(mealItems),
        "doctor_notes": doctorNotes,
      },
    );
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }
}
