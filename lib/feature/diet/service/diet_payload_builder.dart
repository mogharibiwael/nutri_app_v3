import '../model/exchange_model.dart';

/// Builds API payload (meals, meal_periods) from distribution and exchange plan.
class DietPayloadBuilder {
  DietPayloadBuilder._();

  /// Get meal keys in same order as periods (matches DietDistributionController)
  static List<String> _getMealKeys(List<Map<String, dynamic>> periods) {
    final keys = <String>[];
    var extraIdx = 0;
    for (final p in periods) {
      final type = p["meal_type"]?.toString() ?? "";
      final custom = p["custom_name"]?.toString();
      if (type == "extraSnack") {
        keys.add(custom != null && custom.isNotEmpty
            ? "extra_$custom"
            : "extraSnack_${++extraIdx}");
      } else if (type.isNotEmpty) {
        keys.add(type);
      }
    }
    if (keys.isEmpty) keys.addAll(["breakfast", "lunch", "dinner"]);
    return keys;
  }

  /// Name the doctor typed for this meal period (aligned with [mealKeys] / distribution keys).
  static String? userEnteredMealName(
    String mealKey,
    List<Map<String, dynamic>> periods,
  ) {
    final mealKeys = _getMealKeys(periods);
    final i = mealKeys.indexOf(mealKey);
    if (i < 0 || i >= periods.length) return null;
    final cn = periods[i]["custom_name"]?.toString().trim();
    if (cn == null || cn.isEmpty) return null;
    return cn;
  }

  static String _apiMealName(String mealKey, Map<String, dynamic>? period) {
    final cn = period?["custom_name"]?.toString().trim();
    if (cn != null && cn.isNotEmpty) return cn;
    if (mealKey.startsWith("extra_")) return mealKey.substring(6);
    if (mealKey.startsWith("extraSnack_")) {
      return "Snack ${mealKey.substring(11)}";
    }
    return mealKey;
  }

  /// Compute macros for a single meal from serving counts
  static (double carbs, double protein, double fat, double calories) _computeMealMacros(
    Map<String, double> servings,
    DailyExchangePlan plan,
  ) {
    final s = ExchangeDefinitions.starch;
    final f = ExchangeDefinitions.fruit;
    final v = ExchangeDefinitions.vegetables;
    final m = ExchangeDefinitions.getMilk(plan.milkType);
    final mt = ExchangeDefinitions.getMeat(plan.meatType);
    final ft = ExchangeDefinitions.fat;

    double carbs = 0, protein = 0, fat = 0, calories = 0;
    carbs += (servings["starch"] ?? 0.0) * s.carbsG;
    carbs += (servings["fruit"] ?? 0.0) * f.carbsG;
    carbs += (servings["vegetables"] ?? 0.0) * v.carbsG;
    carbs += (servings["milk"] ?? 0.0) * m.carbsG;
    carbs += (servings["meat"] ?? 0.0) * mt.carbsG;
    carbs += (servings["fat"] ?? 0.0) * ft.carbsG;

    protein += (servings["starch"] ?? 0.0) * s.proteinG;
    protein += (servings["fruit"] ?? 0.0) * f.proteinG;
    protein += (servings["vegetables"] ?? 0.0) * v.proteinG;
    protein += (servings["milk"] ?? 0.0) * m.proteinG;
    protein += (servings["meat"] ?? 0.0) * mt.proteinG;
    protein += (servings["fat"] ?? 0.0) * ft.proteinG;

    fat += (servings["starch"] ?? 0.0) * s.fatG;
    fat += (servings["fruit"] ?? 0.0) * f.fatG;
    fat += (servings["vegetables"] ?? 0.0) * v.fatG;
    fat += (servings["milk"] ?? 0.0) * m.fatG;
    fat += (servings["meat"] ?? 0.0) * mt.fatG;
    fat += (servings["fat"] ?? 0.0) * ft.fatG;

    calories += (servings["starch"] ?? 0.0) * s.calories;
    calories += (servings["fruit"] ?? 0.0) * f.calories;
    calories += (servings["vegetables"] ?? 0.0) * v.calories;
    calories += (servings["milk"] ?? 0.0) * m.calories;
    calories += (servings["meat"] ?? 0.0) * mt.calories;
    calories += (servings["fat"] ?? 0.0) * ft.calories;

    return (carbs, protein, fat, calories);
  }

  static String _servingSummary(
    Map<String, double> servings, {
    List<String>? mealItems,
  }) {
    final parts = <String>[];
    if ((servings["starch"] ?? 0.0) > 0.0) parts.add("${servings["starch"]?.toStringAsFixed(1)} starch");
    if ((servings["fruit"] ?? 0.0) > 0.0) parts.add("${servings["fruit"]?.toStringAsFixed(1)} fruit");
    if ((servings["vegetables"] ?? 0.0) > 0.0) parts.add("${servings["vegetables"]?.toStringAsFixed(1)} vegetables");
    if ((servings["milk"] ?? 0.0) > 0.0) parts.add("${servings["milk"]?.toStringAsFixed(1)} milk");
    if ((servings["meat"] ?? 0.0) > 0.0) parts.add("${servings["meat"]?.toStringAsFixed(1)} meat");
    if ((servings["fat"] ?? 0.0) > 0.0) parts.add("${servings["fat"]?.toStringAsFixed(1)} fat");
    String base = parts.isEmpty ? "-" : parts.join(", ");
    if (mealItems != null && mealItems.isNotEmpty) {
      base = "$base. ${mealItems.join("; ")}";
    }
    return base;
  }

  /// Build meals array from distribution and exchange plan
  static List<Map<String, dynamic>> buildMeals({
    required Map<String, Map<String, double>> distribution,
    required List<Map<String, dynamic>> periods,
    required DailyExchangePlan exchangePlan,
    Map<String, List<String>>? mealItems,
  }) {
    final mealKeys = _getMealKeys(periods);
    final meals = <Map<String, dynamic>>[];

    for (var i = 0; i < mealKeys.length; i++) {
      final key = mealKeys[i];
      final period = i < periods.length ? periods[i] : null;
      final servings = distribution[key] ?? {};
      final (carbs, protein, fat, calories) = _computeMealMacros(servings, exchangePlan);

      String mealType = "extraSnack";
      if (key.startsWith("extra_") || key.startsWith("extraSnack_")) {
        mealType = "extraSnack";
      } else {
        mealType = key;
      }

      final name = _apiMealName(key, period);

      final items = mealItems?[key];
      meals.add({
        "meal_type": mealType,
        "name": name,
        "serving_summary": _servingSummary(servings, mealItems: items),
        "carbs_g": carbs.round(),
        "protein_g": protein.round(),
        "fat_g": fat.round(),
        "calories": calories.round(),
      });
    }
    return meals;
  }

  /// Build meal_periods for API (hour, minute, meal_type)
  static List<Map<String, dynamic>> buildMealPeriods(List<Map<String, dynamic>> periods) {
    return periods
        .map((p) => {
              "meal_type": p["meal_type"] ?? "",
              "hour": p["hour"] ?? 0,
              "minute": p["minute"] ?? 0,
              if (p["custom_name"] != null && (p["custom_name"] as String).isNotEmpty)
                "custom_name": p["custom_name"],
            })
        .toList();
  }
}
