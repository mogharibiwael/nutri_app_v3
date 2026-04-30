import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nutri_guide/core/constant/api_link.dart';
import 'package:nutri_guide/core/constant/asset.dart';
import 'package:nutri_guide/core/constant/theme/colors.dart';
import 'package:nutri_guide/core/shared/widgets/app_bar.dart';
import 'package:nutri_guide/feature/ads/model/ad_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AdDetailsPage extends StatelessWidget {
  const AdDetailsPage({super.key});

  static AdModel? _parseArgs(dynamic args) {
    if (args is AdModel) return args;
    if (args is Map) {
      try {
        return AdModel.fromJson(
          Map<String, dynamic>.from(args),
          storageBase: ApiLinks.storageBase,
        );
      } catch (_) {}
    }
    return null;
  }

  static String _displayTitle(AdModel ad) {
    if (ad.title != null && ad.title!.trim().isNotEmpty) return ad.title!.trim();
    if (ad.type != null && ad.type!.trim().isNotEmpty) return ad.type!.trim();
    return "adDetails".tr;
  }

  static Future<void> _launchUrl(String raw) async {
    var u = raw.trim();
    if (u.isEmpty) return;
    if (u.startsWith("http://")) {
      u = "https://${u.substring("http://".length)}";
    }
    final uri = Uri.tryParse(u);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> _launchPhone(String raw) async {
    final digits = raw.replaceAll(RegExp(r"\s"), "");
    if (digits.isEmpty) return;
    final uri = Uri(scheme: "tel", path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = _parseArgs(Get.arguments);
    final isAr = Get.locale?.languageCode == "ar";

    if (ad == null) {
      return SafeArea(
        child: Scaffold(
          appBar: CustomAppBar(title: "adDetails".tr, showBackButton: true),
          body: Center(child: Text("noTipsFound".tr)),
        ),
      );
    }

    final title = _displayTitle(ad);
    final hasImage = ad.imageUrl != null && ad.imageUrl!.isNotEmpty;
    final hasLink = ad.link != null && ad.link!.trim().isNotEmpty;
    final hasPhone = ad.phoneNumber != null && ad.phoneNumber!.trim().isNotEmpty;
    final hasDescription =
        ad.description != null && ad.description!.trim().isNotEmpty;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: CustomAppBar(
            title: title,
            showBackButton: true,
            showLogo: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: hasImage
                        ? Image.network(
                            ad.imageUrl!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (_, __, ___) => _placeholder(),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: AppColor.mutedPurple.withValues(alpha: 0.3),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColor.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : _placeholder(),
                  ),
                ),
                const SizedBox(height: 20),
                if (ad.type != null && ad.type!.trim().isNotEmpty) ...[
                  Align(
                    alignment:
                        isAr ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.mutedPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ad.type!.trim(),
                        style: TextStyle(
                          color: AppColor.deepPurple,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (hasDescription) ...[
                  Text(
                    "adDescription".tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ad.description!.trim(),
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      color: AppColor.deepPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (hasPhone) ...[
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, color: AppColor.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ad.phoneNumber!.trim(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (hasLink)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _launchUrl(ad.link!),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      label: Text("openLink".tr),
                    ),
                  ),
                if (hasLink && hasPhone) const SizedBox(height: 12),
                if (hasPhone)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _launchPhone(ad.phoneNumber!),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.primary,
                        side: BorderSide(color: AppColor.primary.withValues(alpha: 0.6)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.call_rounded, size: 20),
                      label: Text("callNow".tr),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _placeholder() {
    return Container(
      color: AppColor.mutedPurple.withValues(alpha: 0.35),
      child: Center(
        child: Image.asset(
          ImageAssets.logo,
          height: 80,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
