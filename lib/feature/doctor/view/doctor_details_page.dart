import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/class/status_request.dart';
import '../../../core/constant/asset.dart';
import '../../../core/constant/theme/colors.dart';
import '../../../core/routes/app_route.dart';
import '../../../core/shared/widgets/app_bar.dart';
import '../../../core/permissions/permissions.dart';
import '../../../core/service/serviecs.dart';
import '../controller/doctor_details_controller.dart';

class DoctorDetailsPage extends StatefulWidget {
  const DoctorDetailsPage({super.key});

  @override
  State<DoctorDetailsPage> createState() => _DoctorDetailsPageState();
}

class _DoctorDetailsPageState extends State<DoctorDetailsPage> with WidgetsBindingObserver {
  static const Color _darkPurple = AppColor.deepPurple;
  static const Color _lightBlue = AppColor.customGrey;
  static const Color _lightPurple = AppColor.mutedPurple;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Get.find<DoctorDetailsController>().refreshSubscribed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';

    return GetBuilder<DoctorDetailsController>(
      builder: (c) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.grey.shade200,
            appBar: CustomAppBar(
              title: "doctorDetails".tr,
              showBackButton: true,
              showLogo: true,
            ),
            body: Stack(
              children: [
                ListView(
                  children: [
                    const SizedBox(height: 8),
                    // Top section - light grey with semi-circular blend and circle at bottom-left
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: AppColor.customGrey,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const SizedBox(height: 100),

                          Positioned(
                            left: 0,
                            bottom: -90,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: _lightBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColor.primary.withOpacity(0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  c.doctor.avatarAsset,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(52, 18, 24, 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.primary.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              _doctorDisplayName(c.doctor.name),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _darkPurple,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: Image.asset(
                              ImageAssets.logo,
                              width: 36,
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.primary.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _RatingRow(
                                  rating: c.ratingAverage ?? double.tryParse(c.doctor.rating) ?? 0,
                                  count: c.ratingCount,
                                ),
                                const SizedBox(height: 18),
                                _DetailRow(
                                  icon: Icons.email_outlined,
                                  label: "personalEmail".tr,
                                  value: c.doctor.email ?? "-",
                                ),
                                const SizedBox(height: 18),
                                _DetailRow(
                                  icon: Icons.phone_outlined,
                                  label: "phone".tr,
                                  value: c.doctor.phone ?? "-",
                                ),
                                const SizedBox(height: 18),
                                _DetailRow(
                                  icon: Icons.account_balance_outlined,
                                  label: "bankAccount".tr,
                                  value: c.doctor.bankAccount ?? "-",
                                ),
                                const SizedBox(height: 18),
                                _DetailRow(
                                  icon: Icons.payments_outlined,
                                  label: "dietPrice".tr,
                                  value: _formatFee(c.doctor.consultationFee),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: Image.asset(
                              ImageAssets.logo,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!Permissions(Get.find<MyServices>()).isDoctor && c.isApproved) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _RateDoctorSection(
                          myRating: c.myRating,
                          onRate: c.submitRating,
                          isLoading: c.rateStatus == StatusRequest.loading,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!Permissions(Get.find<MyServices>()).isDoctor)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            // Chat / Subscribe button
                            Expanded(
                              flex: 3,
                              child: ElevatedButton.icon(
                                 onPressed: c.statusRequest == StatusRequest.loading
                                    ? null
                                    : (c.isSubscribed ? c.goToChat : c.openVirtualPaymentSheet),
                                icon: Icon(c.isSubscribed ? Icons.chat_bubble_outline : Icons.lock_outline),
                                label: Text(c.isSubscribed ? "chat".tr : "subscribe".tr),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColor.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Doctor forums button (per-doctor)
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Open forums page filtered for this doctor (implementation in forums module)
                                  Get.toNamed(AppRoute.forums, arguments: {
                                    "doctor_id": c.doctor.id,
                                    "doctor_name": c.doctor.name,
                                  });
                                },
                                icon: const Icon(Icons.forum_outlined, color: AppColor.deepPurple),
                                label: Text(
                                  "forums".tr,
                                  style: const TextStyle(color: AppColor.deepPurple),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColor.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                if (c.statusRequest == StatusRequest.loading) const _LoadingOverlay(),
              ],
            ),
          ),
        ),
      ));

  }

  String _doctorDisplayName(String name) {
    if (name.startsWith("د.") || name.startsWith("Dr.")) return name;
    return Get.locale?.languageCode == 'ar' ? "د. $name" : "Dr. $name";
  }

  String _formatFee(String? fee) {
    if (fee == null || fee.isEmpty) return "-";
    final trimmed = fee.trim();
    if (trimmed.contains("\$") || trimmed.toUpperCase().contains("USD")) return trimmed;
    return "\$$trimmed";
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int count;

  const _RatingRow({required this.rating, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.star_outline_rounded, size: 24, color: _iconDark),
        const SizedBox(width: 8),
        Text(
          "rating".tr,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _labelPurple,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _darkPurple,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 22),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            rating <= 0
                ? "(${"noRatesYet".tr})"
                : "($count ${"reviews".tr})",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }


  static const Color _darkPurple = AppColor.deepPurple;
  static const Color _labelPurple = AppColor.deepPurple;
  static const Color _iconDark = AppColor.deepPurple;
}

class _RateDoctorSection extends StatefulWidget {
  final int? myRating;
  final void Function(int) onRate;
  final bool isLoading;

  const _RateDoctorSection({
    required this.myRating,
    required this.onRate,
    required this.isLoading,
  });

  @override
  State<_RateDoctorSection> createState() => _RateDoctorSectionState();
}

class _RateDoctorSectionState extends State<_RateDoctorSection> {
  int? _selectedStars;

  @override
  void initState() {
    super.initState();
    _selectedStars = widget.myRating;
  }

  @override
  void didUpdateWidget(_RateDoctorSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.myRating != oldWidget.myRating) {
      _selectedStars = widget.myRating;
    }
  }

  @override
  Widget build(BuildContext context) {
    final myRating = widget.myRating;
    final filledCount = _selectedStars ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.primary.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "rateDoctor".tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              final filled = filledCount >= star;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: IconButton(
                  onPressed: widget.isLoading
                      ? null
                      : () => setState(() => _selectedStars = star),
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: 36,
                    color: filled ? Colors.amber.shade600 : Colors.grey.shade400,
                  ),
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                myRating != null
                    ? "yourRating".tr + ": $myRating/5"
                    : "noRateYet".tr,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isLoading || _selectedStars == null
                  ? null
                  : () => widget.onRate(_selectedStars!),
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text("sendRate".tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color _labelPurple = AppColor.deepPurple;
  static const Color _iconDark = AppColor.deepPurple;

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';
    // RTL: value (gray, left) | label (purple) | icon (far right)
    // LTR: icon (far left) | label (purple) | value (gray, right)
    final labelValue = RichText(
      textAlign: isAr ? TextAlign.right : TextAlign.left,
      text: TextSpan(
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey.shade700,
          height: 1.4,
        ),
        children: !isAr
            ? [
                TextSpan(text: value),
                TextSpan(
                  text: " : $label",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _labelPurple,
                  ),
                ),
              ]
            : [
                TextSpan(
                  text: "$label : ",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _labelPurple,
                  ),
                ),
                TextSpan(text: value),
              ],
      ),
    );
    final iconWidget = Icon(icon, size: 24, color: _iconDark);

    if (!isAr) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: labelValue),
          const SizedBox(width: 14),
          iconWidget,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        iconWidget,
        const SizedBox(width: 14),
        Expanded(child: labelValue),
      ],
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColor.deepPurple.withOpacity(0.25),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
