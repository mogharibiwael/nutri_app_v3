import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/shared/widgets/drawer.dart';
import '../../../core/class/status_request.dart';
import '../../../core/constant/theme/colors.dart';
import '../../../core/shared/widgets/app_bar.dart';
import '../controller/diet_controller.dart';
import '../model/diet_model.dart';

class DietMealsPage extends GetView<DietController> {
  const DietMealsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DietController>(
      builder: (c) {
        // Never call loadMeals() synchronously during build — it triggers update().
        if (c.meals.isEmpty && c.mealsStatusRequest != StatusRequest.loading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctrl = Get.find<DietController>();
            if (ctrl.meals.isEmpty &&
                ctrl.mealsStatusRequest != StatusRequest.loading) {
              ctrl.loadMeals();
            }
          });
        }

        return SafeArea(
          child: Scaffold(
            drawer: HomeDrawer(controller: c),
            backgroundColor: Colors.grey.shade100,
            appBar: CustomAppBar(
              title: "dietMeals".tr,
              showBackButton: true,
              showLogo: true,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(Icons.menu, color: AppColor.primary, size: 26),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColor.deepPurple),
                  onPressed: c.loadMeals,
                ),
              ],
            ),
            body: _buildBody(c),
          ),
        );
      },
    );
  }

  Widget _buildBody(DietController c) {
    if (c.mealsStatusRequest == StatusRequest.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (c.mealsStatusRequest == StatusRequest.offlineFailure) {
      return _EmptyState(
        icon: Icons.wifi_off_rounded,
        title: "noInternet".tr,
        buttonText: "retry".tr,
        onRetry: c.loadMeals,
      );
    }

    if (c.mealsStatusRequest == StatusRequest.serverFailure ||
        c.mealsStatusRequest == StatusRequest.failure) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        title: "serverError".tr,
        buttonText: "retry".tr,
        onRetry: c.loadMeals,
      );
    }

    if (c.meals.isEmpty) {
      return _EmptyState(
        icon: Icons.restaurant_menu_outlined,
        title: "noMeals".tr,
        buttonText: "refresh".tr,
        onRetry: c.loadMeals,
      );
    }

    // Group meals by day
    final Map<int, List<DietMealModel>> mealsByDay = {};
    for (final meal in c.meals) {
      mealsByDay.putIfAbsent(meal.dayNumber, () => []).add(meal);
    }

    return RefreshIndicator(
      onRefresh: c.loadMeals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mealsByDay.length,
        itemBuilder: (context, index) {
          final day = mealsByDay.keys.elementAt(index);
          final dayMeals = mealsByDay[day]!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.shadowColor.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Day $day",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...dayMeals.map((meal) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meal.mealTypeDisplay,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (meal.mealName.isNotEmpty)
                                          Text(
                                            meal.mealName,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        if (meal.patientFoodNotes != null &&
                                            meal.patientFoodNotes!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            "mealFoodChoicesFromDoctor".tr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            meal.patientFoodNotes!,
                                            style: TextStyle(
                                              color: AppColor.primary,
                                              fontSize: 14,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColor.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "${meal.calories} kcal",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColor.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (meal.carbsG != null ||
                                  meal.proteinG != null ||
                                  meal.fatG != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "C: ${meal.carbsG ?? 0}g  P: ${meal.proteinG ?? 0}g  F: ${meal.fatG ?? 0}g",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String buttonText;
  final VoidCallback onRetry;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.buttonText,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
