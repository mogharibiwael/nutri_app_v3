import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/shared/widgets/drawer.dart';
import '../../../core/constant/theme/colors.dart';
import '../../../core/shared/widgets/app_bar.dart';
import '../controller/medical_files_controller.dart';
import '../model/medical_file_model.dart';

class MedicalFilesPage extends GetView<MedicalFilesController> {
  const MedicalFilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MedicalFilesController>();
    return Obx(() => SafeArea(
      child: Scaffold(
        drawer: HomeDrawer(controller: c),
        backgroundColor: Colors.grey.shade100,
        appBar: CustomAppBar(
          title: "helpFiles".tr,
          showBackButton: true,
          showLogo: true,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu, color: AppColor.primary, size: 26),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        body: _buildBody(c),
      ),
    ));
  }

  Widget _buildBody(MedicalFilesController c) {
    if (c.files.isEmpty) {
      return _EmptyState(
        icon: Icons.folder_open_outlined,
        title: "noHelpFiles".tr,
        onRetry: c.refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: c.files.length,
        itemBuilder: (context, index) {
          final f = c.files[index];
          return _FileCard(
            file: f,
            displayName: c.displayTitle(f),
            onOpen: () => c.downloadAndShow(f),
          );
        },
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  final MedicalFileModel file;
  final String displayName;
  final VoidCallback onOpen;

  const _FileCard({
    required this.file,
    required this.displayName,
    required this.onOpen,
  });

  Widget? _leadingThumb() {
    if (!file.showsImageThumbnail || kIsWeb) return null;
    final p = file.localDiskPath;
    if (p == null) return null;
    final f = File(p);
    if (!f.existsSync()) return null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Image.file(
          f,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.image_not_supported_outlined,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';
    final thumb = _leadingThumb();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            if (!isAr && thumb != null) ...[
              thumb,
              const SizedBox(width: 12),
            ],
            if (!isAr)
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            IconButton(
              onPressed: onOpen,
              icon: Icon(
                file.isLocalDeviceFile ? Icons.open_in_new_rounded : Icons.download_rounded,
                color: AppColor.primary,
                size: 28,
              ),
              tooltip: file.isLocalDeviceFile ? "openFile".tr : "download".tr,
            ),
            if (isAr)
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            if (isAr && thumb != null) ...[
              const SizedBox(width: 12),
              thumb,
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onRetry;

  const _EmptyState({
    required this.icon,
    required this.title,
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
              child: Text("retry".tr),
            ),
          ],
        ),
      ),
    );
  }
}
