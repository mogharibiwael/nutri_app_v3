import 'dart:io';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/class/crud.dart';
import '../../../core/class/status_request.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/service/serviecs.dart';

import '../../../doctorApp/feature/home/data/doctor_patients_data.dart';
import '../../../doctorApp/feature/home/model/patient_model.dart';
import '../data/medical_tests_data.dart';
import '../model/medical_test_model.dart';

class MedicalTestsController extends GetxController {
  final MedicalTestsData data = MedicalTestsData(Get.find<Crud>());
  final MyServices myServices = Get.find();
  DoctorPatientsData? get doctorPatientsData =>
      Get.isRegistered<Crud>() ? DoctorPatientsData(Get.find<Crud>()) : null;

  final statusRequest = Rx<StatusRequest>(StatusRequest.loading);
  final RxList<MedicalTestModel> tests = <MedicalTestModel>[].obs;

  int? selectedPatientUserId;
  String selectedPatientName = "";
  final RxList<PatientModel> patients = <PatientModel>[].obs;
  final patientsLoaded = false.obs;
  bool _loadingPatients = false;
  bool _refreshing = false;
  DateTime? _lastRateLimitAt;

  bool get isDoctor => Permissions(myServices).isDoctor || Permissions(myServices).isAdmin;
  String? get token => myServices.token;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?) ?? {};
    selectedPatientUserId = args["user_id"] is int
        ? args["user_id"] as int
        : (args["user_id"] != null ? int.tryParse("${args["user_id"]}") : null);
    selectedPatientName = (args["patient_name"] ?? "").toString();

    if (isDoctor && selectedPatientUserId == null) {
      _loadPatients();
    } else {
      loadTests(first: true);
    }
  }

  Future<void> _loadPatients() async {
    if (doctorPatientsData == null) {
      statusRequest.value = StatusRequest.success;
      patientsLoaded.value = true;
      return;
    }
    if (_loadingPatients) return;
    if (_lastRateLimitAt != null) {
      final elapsed = DateTime.now().difference(_lastRateLimitAt!);
      if (elapsed.inSeconds < 60) {
        statusRequest.value = StatusRequest.rateLimit;
        patientsLoaded.value = true;
        return;
      }
    }
    _loadingPatients = true;
    final res = await doctorPatientsData!.getPatients(page: 1, token: token);
    _loadingPatients = false;
    res.fold(
      (l) {
        if (l == StatusRequest.rateLimit) _lastRateLimitAt = DateTime.now();
        statusRequest.value = l;
        patientsLoaded.value = true;
      },
      (r) {
        _lastRateLimitAt = null;
        try {
          final raw = r["data"] ?? r["patients"] ?? r;
          final list = raw is List ? raw : <dynamic>[];
          final parsed = <PatientModel>[];
          for (final e in list) {
            if (e is! Map) continue;
            try {
              parsed.add(PatientModel.fromJson(Map<String, dynamic>.from(e)));
            } catch (_) {}
          }
          patients.value = parsed;
          statusRequest.value = StatusRequest.success;
        } catch (_) {
          statusRequest.value = StatusRequest.failure;
        }
        patientsLoaded.value = true;
      },
    );
  }

  void selectPatient(PatientModel patient) {
    selectedPatientUserId = patient.userId;
    selectedPatientName = patient.fullname;
    loadTests(first: true);
    update();
  }

  Future<void> loadTests({bool first = false}) async {
    if (first) {
      tests.clear();
      statusRequest.value = StatusRequest.loading;
    }

    int? userId;

    if (isDoctor) {
      userId = selectedPatientUserId;
      if (userId == null || userId <= 0) {
        statusRequest.value = StatusRequest.success;
        update();
        return;
      }
    } else {
      final u = myServices.user;
      final id = u?["id"];
      userId = id is int ? id : int.tryParse(id?.toString() ?? "");
    }

    final res = await data.getMedicalTests(userId: userId, token: token, page: 1);

    res.fold(
      (l) {
        statusRequest.value = l;
      },
      (r) {
        final list = (r["data"] as List?) ?? [];
        tests.value = list
            .whereType<Map>()
            .map((e) => MedicalTestModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        statusRequest.value = StatusRequest.success;
      },
    );
    update();
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      if (isDoctor && selectedPatientUserId == null) {
        if (_lastRateLimitAt != null) {
          final elapsed = DateTime.now().difference(_lastRateLimitAt!);
          if (elapsed.inSeconds < 60) return;
        }
        await _loadPatients();
      } else {
        await loadTests(first: true);
      }
    } finally {
      _refreshing = false;
    }
  }

  bool _looksLikeJsonBody(List<int> bytes) {
    if (bytes.isEmpty) return true;
    var i = 0;
    while (i < bytes.length &&
        (bytes[i] == 32 || bytes[i] == 9 || bytes[i] == 10 || bytes[i] == 13)) {
      i++;
    }
    if (i >= bytes.length) return true;
    final b = bytes[i];
    return b == 0x7b || b == 0x5b;
  }

  Future<void> downloadAndShow(MedicalTestModel test) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${dir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final ext = test.suggestedFileExtension;
      final savePath =
          '${downloadsDir.path}/${test.name.replaceAll(RegExp(r'[^\w\-.]'), '_')}.$ext';

      final headers = <String, String>{
        'Accept': 'application/octet-stream,image/*,*/*',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      for (final url in test.downloadCandidates) {
        try {
          var response = await http
              .get(Uri.parse(url), headers: headers)
              .timeout(const Duration(seconds: 45));
          // Public storage URLs sometimes reject Bearer tokens.
          if ((response.statusCode == 401 || response.statusCode == 403) &&
              !url.contains('/api/')) {
            response = await http.get(
              Uri.parse(url),
              headers: const {'Accept': 'application/octet-stream,image/*,*/*'},
            ).timeout(const Duration(seconds: 45));
          }
          if (response.statusCode != 200 && response.statusCode != 201) {
            continue;
          }
          final bytes = response.bodyBytes;
          if (bytes.isEmpty || _looksLikeJsonBody(bytes)) {
            continue;
          }
          await File(savePath).writeAsBytes(bytes);
          await OpenFilex.open(savePath);
          Get.snackbar("success".tr, "downloadSuccess".tr);
          return;
        } catch (_) {
          continue;
        }
      }

      Get.snackbar("error".tr, "downloadFailed".tr);
    } catch (e) {
      Get.snackbar("error".tr, "downloadFailed".tr);
    }
  }
}
