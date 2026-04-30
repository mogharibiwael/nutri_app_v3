import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nutri_guide/core/routes/app_route.dart';
import 'package:nutri_guide/core/service/serviecs.dart';
import 'package:nutri_guide/core/constant/api_link.dart';

import '../../../../core/class/status_request.dart';
import '../../../../core/constant/theme/colors.dart';
import '../../../../core/shared/widgets/app_bar.dart';
import '../../../../core/shared/widgets/drawer.dart';
import '../controller/doctor_patients_controller.dart';
import '../model/patient_model.dart';

class DoctorPatientsPage extends GetView<DoctorPatientsController> {
  const DoctorPatientsPage({super.key});

  /// When opened from drawer "Diets" / "Chat", show context title; otherwise patients list.
  static String _patientsPageTitle() {
    final args = Get.arguments;
    if (args is Map) {
      if (args['openedForChat'] == true) return "chatWithPatients".tr;
      if (args['openedForDiets'] == true) return "dietsPatientsTitle".tr;
      if (args['openedForCalculations'] == true) return "bodyCalculations".tr;
    }
    return "patientsList".tr;
  }

  static bool get _openedForChat {
    final args = Get.arguments;
    return args is Map && args['openedForChat'] == true;
  }

  static bool get _openedForDiets {
    final args = Get.arguments;
    return args is Map && args['openedForDiets'] == true;
  }

  static bool get _openedForCalculations {
    final args = Get.arguments;
    return args is Map && args['openedForCalculations'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DoctorPatientsController>(
      builder: (c) => SafeArea(
        child: Scaffold(
        drawer: HomeDrawer(controller: controller),
        backgroundColor: Colors.grey.shade100,
        appBar: CustomAppBar(
          title: _patientsPageTitle(),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu, color: AppColor.primary, size: 26),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
          actions: [
            IconButton(
              onPressed: c.refreshPatients,
              icon: Icon(Icons.refresh, color: AppColor.primary),
            ),
          ],
        ),
        body: Column(
          children: [
            _SearchBar(controller: c),
            if (!_openedForChat && !_openedForDiets && !_openedForCalculations)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final myServices = Get.find<MyServices>();
                      final did = myServices.doctorId;
                      final u = myServices.user;
                      final doc = (u?["doctor_profile"] ?? u?["doctorProfile"] ?? u?["doctor"]) as dynamic;
                      final doctorName = (doc is Map ? doc["name"] : null)?.toString() ??
                          u?["name"]?.toString() ??
                          "Doctor";
                      Get.toNamed(AppRoute.forums, arguments: {
                        "doctor_id": did,
                        "doctor_name": doctorName,
                      });
                    },
                    icon: const Icon(Icons.forum_outlined),
                    label: Text("goToYourForums".tr),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(child: _buildBody(c)),
          ],
        ),
      ),
    ));
  }

  Widget _buildBody(DoctorPatientsController c) {
    if (c.statusRequest == StatusRequest.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (c.statusRequest == StatusRequest.offlineFailure) {
      return _StateView(
        title: "No internet connection",
        buttonText: "Retry",
        onRetry: () => c.fetchPatients(first: true),
      );
    }

    if (c.statusRequest == StatusRequest.serverFailure ||
        c.statusRequest == StatusRequest.failure) {
      return _StateView(
        title: "Server error",
        buttonText: "Retry",
        onRetry: () => c.fetchPatients(first: true),
      );
    }

    final list = c.filteredPatients;
    if (list.isEmpty) {
      return _StateView(
        title: c.searchQuery.isEmpty ? "No patients found" : "No patients found".tr,
        buttonText: "refresh".tr,
        onRetry: c.refreshPatients,
      );
    }

    final openedForChat = _openedForChat;
    final openedForCalculations = _openedForCalculations;
    final myServices = Get.find<MyServices>();
    final doctorId = myServices.doctorId ?? 0;

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 120) {
          c.loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: c.refreshPatients,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final patient = list[i];
            return _PatientCard(
              patient: patient,
              onTap: () {
                if (openedForChat && doctorId > 0) {
                  Get.toNamed(AppRoute.chat, arguments: {
                    'doctor_id': doctorId,
                    'receiver_id': patient.userId,
                    'doctor_name': patient.fullname,
                  });
                } else if (openedForCalculations) {
                  Get.toNamed(AppRoute.doctorPatientCalculations, arguments: {
                    "patient": patient,
                    "patient_name": patient.fullname,
                    "patient_id": patient.effectivePatientId,
                    "doctor_id": doctorId,
                  });
                } else if (_openedForDiets) {
                  Get.toNamed(AppRoute.patientDietChoice, arguments: {
                    "patient": patient,
                    "patient_name": patient.fullname,
                    "patient_id": patient.effectivePatientId,
                    "doctor_id": doctorId,
                  });
                } else {
                  Get.toNamed(AppRoute.patientDetails, arguments: patient);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final DoctorPatientsController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: "searchForPatient".tr,
          prefixIcon: Icon(Icons.search, color: AppColor.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColor.primary.withOpacity(0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColor.primary.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColor.primary, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = patient.fullname;
    final email = patient.user?.email ?? "-";
    final phone = patient.phoneNumber ?? "-";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColor.primary.withOpacity(0.12),
              backgroundImage: patient.image != null
                  ? NetworkImage("${ApiLinks.storageBase}/${patient.image}")
                  : null,
              child: patient.image == null
                  ? Icon(Icons.person_outline, color: AppColor.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Pill(text: "Phone: $phone"),
                      const SizedBox(width: 8),
                      _Pill(text: "Gender: ${patient.gender ?? '-'}"),
                    ],
                  )
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _StateView extends StatelessWidget {
  final String title;
  final String buttonText;
  final VoidCallback onRetry;

  const _StateView({
    required this.title,
    required this.buttonText,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRetry,
                child: Text(buttonText),
              ),
            )
          ],
        ),
      ),
    );
  }
}
