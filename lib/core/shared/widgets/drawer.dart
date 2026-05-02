import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nutri_guide/core/constant/asset.dart';
import 'package:nutri_guide/core/constant/theme/colors.dart';
import 'package:nutri_guide/core/permissions/permissions.dart';
import 'package:nutri_guide/core/routes/app_route.dart';
import 'package:nutri_guide/core/service/serviecs.dart';

/// Drawer matching the design: logo header, menu items, close button.
class HomeDrawer extends StatefulWidget {
  final dynamic controller;
  /// Only logo, name, [main menu / home], and logout — e.g. BMI screen.
  final bool homeOnly;
  const HomeDrawer({super.key, required this.controller, this.homeOnly = false});

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  static const Color _drawerBg = AppColor.primary;

  @override
  Widget build(BuildContext context) {
    final myServices = Get.find<MyServices>();
    final permissions = Permissions(myServices);
    final isDoctor = permissions.isDoctor || permissions.isAdmin;
    final isDoctorApproved = myServices.isDoctorApproved;
    final currentRoute = Get.currentRoute;
    final isInsidePatientDiet = !isDoctor && (myServices.isSubscriptionApproved || myServices.subscribedDoctorIds.isNotEmpty);
    final isPatientApproved = !isDoctor && myServices.isSubscriptionApproved;
    final userName = myServices.user?["name"]?.toString().trim();
    final displayName = (userName != null && userName.isNotEmpty) ? userName : "User";
    final isPatientSubscribed = !isDoctor && (myServices.isSubscriptionApproved || myServices.subscribedDoctorIds.isNotEmpty);
    final args = Get.arguments;
    final bool openedForDiets = args is Map && args['openedForDiets'] == true;
    final bool openedForChat = args is Map && args['openedForChat'] == true;
    final bool openedForCalculations = args is Map && args['openedForCalculations'] == true;

    final bool inVirtualClinic = !isDoctor && [
      AppRoute.patientDietWelcome,
      AppRoute.chat,
      AppRoute.diet,
      AppRoute.calculationsHistory,
      "/doctor-details",
    ].contains(currentRoute);

    if (widget.homeOnly) {
      return Drawer(
        child: Container(
          color: _drawerBg,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: () => _navigate(context, "/edit-profile"),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.textColor.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(ImageAssets.logo, fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _DrawerItem(
                        icon: Icons.home_outlined,
                        label: "mainMenu".tr,
                        isSelected: currentRoute == AppRoute.home,
                        onTap: () => _navigateToHome(context, isDoctor),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A0244),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "logout".tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Drawer(
      child: Container(
        color: _drawerBg,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 24),
                    // ─── Logo (tappable → profile/doctor info) ───
                    Center(
                      child: GestureDetector(
                        onTap: () => _navigate(context, "/edit-profile"),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColor.textColor.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(ImageAssets.logo, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ─── User/Doctor name under logo ───
                    Center(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (inVirtualClinic) ...[
                      // ─── Virtual Clinic Menu (Patient) ───
                      Builder(
                        builder: (ctx) {
                          final u = myServices.user;
                          final p = (u?["patient_profile"] ?? u?["patientProfile"]) as dynamic;
                          final activeSub = (p is Map) ? p["active_subscription"] : null;
                          final doc = (activeSub is Map) ? activeSub["doctor"] : null;
                          final doctorName = (p is Map ? p["doctor_name"] : null)?.toString() ??
                              (doc is Map ? doc["name"] : null)?.toString() ??
                              "";
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                            child: Center(
                              child: Text(
                                doctorName.isNotEmpty
                                    ? "welcomeToDoctorVirtualClinic".trParams({"name": doctorName})
                                    : "welcomeToClinicSub".tr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.group_outlined,
                        label: "specialistDoctorInfo".tr,
                        isSelected: currentRoute == "/doctor-details",
                        onTap: () {
                          final recordId = myServices.primaryDoctorRecordIdForChat;
                          if (recordId == null || recordId <= 0) {
                            _navigate(context, "/doctors");
                            return;
                          }
                          final u = myServices.user;
                          final p = (u?["patient_profile"] ?? u?["patientProfile"]) as dynamic;
                          final activeSub = (p is Map) ? p["active_subscription"] : null;
                          final doc = (activeSub is Map) ? activeSub["doctor"] : null;
                          var doctorUserId = (doc is Map)
                              ? (doc["user_id"] is int
                                  ? doc["user_id"] as int
                                  : int.tryParse("${doc["user_id"]}") ?? 0)
                              : 0;
                          if (doctorUserId <= 0) {
                            doctorUserId = myServices.userIdForDoctorRecord(recordId) ?? 0;
                          }
                          final doctorName = (p is Map ? p["doctor_name"] : null)?.toString() ??
                              (doc is Map ? doc["name"] : null)?.toString() ??
                              "Doctor";
                          _navigate(context, "/doctor-details", arguments: {
                            "id": recordId,
                            "name": doctorName,
                            "is_verified": true,
                            "is_available": true,
                            "rating": (doc is Map ? doc["rating"] : null) ?? "0.00",
                            "consultation_fee": (doc is Map ? doc["consultation_fee"] : null),
                            "user_id": doctorUserId > 0 ? doctorUserId : null,
                            "gender": (doc is Map ? doc["gender"] : null),
                          });
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.chat_bubble_outline,
                        label: "chat".tr,
                        isSelected: currentRoute == AppRoute.chat,
                        onTap: () {
                          final recordId = myServices.primaryDoctorRecordIdForChat;
                          if (recordId == null || recordId <= 0) {
                            _navigate(context, "/doctors");
                            return;
                          }
                          final u = myServices.user;
                          final p = (u?["patient_profile"] ?? u?["patientProfile"]) as dynamic;
                          final activeSub = (p is Map) ? p["active_subscription"] : null;
                          final doc = (activeSub is Map) ? activeSub["doctor"] : null;
                          var doctorUserId = (doc is Map)
                              ? (doc["user_id"] is int
                                  ? doc["user_id"] as int
                                  : int.tryParse("${doc["user_id"]}") ?? 0)
                              : 0;
                          if (doctorUserId <= 0) {
                            doctorUserId = myServices.userIdForDoctorRecord(recordId) ?? 0;
                          }
                          final doctorName = (p is Map ? p["doctor_name"] : null)?.toString() ??
                              (doc is Map ? doc["name"] : null)?.toString() ??
                              "Doctor";
                          final receiverId =
                              doctorUserId > 0 ? doctorUserId : recordId;
                          _navigate(context, AppRoute.chat, arguments: {
                            "doctor_id": recordId,
                            "receiver_id": receiverId,
                            "doctor_name": doctorName,
                            "conversation_id": receiverId,
                            "user_id": receiverId,
                          });
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.restaurant_menu_outlined,
                        label: "myDiet".tr,
                        isSelected: currentRoute == AppRoute.diet,
                        onTap: () => _navigate(context, AppRoute.diet),
                      ),
                      _DrawerItem(
                        icon: Icons.calculate_outlined,
                        label: "bodyCalculations".tr,
                        isSelected: currentRoute == "/bmi",
                        onTap: () => _navigate(context, "/bmi"),
                      ),
                      _DrawerItem(
                        icon: Icons.bar_chart_rounded,
                        label: "showBodyCalculations".tr,
                        isSelected: currentRoute == AppRoute.calculationsHistory,
                        onTap: () => _navigate(context, AppRoute.calculationsHistory),
                      ),
                      _DrawerItem(
                        icon: Icons.home_outlined,
                        label: "mainMenu".tr,
                        isSelected: currentRoute == AppRoute.home,
                        onTap: () => _navigateToHome(context, isDoctor),
                      ),
                    ] else ...[
                      // ─── Main Menu ───
                      if (isDoctor && isDoctorApproved) ...[
                        _DrawerItem(
                          icon: Icons.people_outline,
                          label: "personalPatientInfo".tr,
                          isSelected: currentRoute == AppRoute.doctorHome && !openedForDiets && !openedForChat && !openedForCalculations,
                          onTap: () => _navigate(context, AppRoute.doctorHome),
                        ),
                        _DrawerItem(
                          icon: Icons.forum_outlined,
                          label: "forums".tr,
                          isSelected: currentRoute == AppRoute.forums,
                          onTap: () => _navigate(context, AppRoute.forums),
                        ),
                        _DrawerItem(
                          icon: Icons.restaurant_menu_outlined,
                          label: "diets".tr,
                          isSelected: currentRoute == AppRoute.doctorHome && openedForDiets,
                          onTap: () => _navigate(context, AppRoute.doctorHome, arguments: {'openedForDiets': true}),
                        ),
                        _DrawerItem(
                          icon: Icons.chat_bubble_outline,
                          label: "chat".tr,
                          isSelected: currentRoute == AppRoute.doctorHome && openedForChat,
                          onTap: () => _navigate(context, AppRoute.doctorHome, arguments: {'openedForChat': true}),
                        ),
                        _DrawerItem(
                          icon: Icons.assessment_outlined,
                          label: "reports".tr,
                          onTap: () => _navigate(context, AppRoute.doctorDiets),
                        ),
                        _DrawerItem(
                          icon: Icons.calculate_outlined,
                          label: "bodyCalculations".tr,
                          isSelected: currentRoute == AppRoute.doctorHome && openedForCalculations,
                          onTap: () => _navigate(context, AppRoute.doctorHome, arguments: {'openedForCalculations': true}),
                        ),
                        _DrawerItem(
                          icon: Icons.medical_services_outlined,
                          label: "medicalExaminations".tr,
                          onTap: () => _navigate(context, AppRoute.medicalTests),
                        ),
                        _DrawerItem(
                          icon: Icons.help_outline,
                          label: "helpFiles".tr,
                          onTap: () => _navigate(context, AppRoute.medicalFiles),
                        ),
                      ],
                      _DrawerItem(
                        icon: Icons.home_outlined,
                        label: "mainMenu".tr,
                        isSelected: currentRoute == AppRoute.home,
                        onTap: () => _navigateToHome(context, isDoctor),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A0244),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "logout".tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route, {dynamic arguments}) {
    Get.back();
    if (Get.currentRoute == route) {
      Get.offNamed(route, arguments: arguments);
    } else {
      Get.toNamed(route, arguments: arguments);
    }
  }

  Future<void> _logout(BuildContext context) async {
    Get.back();
    final myServices = Get.find<MyServices>();
    await myServices.clearSession();
    Get.offAllNamed(AppRoute.login);
  }

  void _navigateToHome(BuildContext context, bool isDoctor) {
    Get.back();
    Get.offAllNamed(AppRoute.home);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(icon, color: Colors.white, size: 24),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          textAlign: isAr ? TextAlign.right : TextAlign.left,
        ),
        onTap: onTap,
      ),
    );
  }
}

