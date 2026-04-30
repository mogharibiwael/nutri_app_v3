import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constant/theme/colors.dart';
import 'package:nutri_guide/core/class/status_request.dart';
import 'package:nutri_guide/core/constant/asset.dart';
import 'package:nutri_guide/core/shared/widgets/app_bar.dart';
import 'package:nutri_guide/core/shared/widgets/drawer.dart';
import 'package:nutri_guide/feature/ads/model/ad_model.dart';
import 'package:nutri_guide/core/routes/app_route.dart';

import 'package:nutri_guide/feature/home/controller/home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  static const Color _lightLavender = AppColor.mutedPurple;
  static const Color _darkPurple = AppColor.deepPurple;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (_) => SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: CustomAppBar(
            title: "homeTitle".tr,
            showLogo: false,
            actions: [
              IconButton(
                onPressed: () => controller.logout(),
                icon: const Icon(Icons.logout, color: AppColor.deepPurple),
                tooltip: "logout".tr,
              ),
            ],
          ),
          drawer: HomeDrawer(controller: controller),
          body: Row(
            children: [
              // Main content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    // borderRadius: const BorderRadius.only(
                    //   topLeft: Radius.circular(24),
                    //   bottomLeft: Radius.circular(24),
                    // ),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.purple.withOpacity(0.06),
                    //     blurRadius: 12,
                    //     offset: const Offset(-2, 0),
                    //   ),
                    // ],
                  ),
                  child: RefreshIndicator(
                    onRefresh: controller.refreshHome,
                    color: AppColor.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        children: [
                        const SizedBox(height: 24),
                        // ─── Ads carousel (placeholder when API empty) ───
                        _buildAdsCarousel(controller),
                        const SizedBox(height: 28),
                        // ─── Menu buttons ───
                        // My clinic: only for approved doctors
                        if (controller.isDoctor && controller.isDoctorApproved) ...[
                          _HomeMenuButton(
                            title: "myClinic".tr,
                            icon: Icons.medical_services,
                            onTap: controller.goToDoctorHome,
                          ),
                          const SizedBox(height: 12),
                        ],
                        // ─── Pending Subscription Message ───
                        if (controller.isSubscriptionPending) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber.shade800),
                                const SizedBox(height: 8),
                                Text(
                                  "subscriptionPending".tr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "subscriptionPendingDesc".tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Diets / Virtual Clinic: for approved patients
                        if (!controller.isDoctor && controller.isSubscribedApproved) ...[
                          _HomeMenuButton(
                            title: "diets".tr,
                            icon: Icons.local_hospital_outlined,
                            onTap: () => Get.toNamed(AppRoute.patientDietWelcome),
                          ),
                          const SizedBox(height: 12),
                        ],

                        _HomeMenuButton(
                          title: "tips".tr,
                          icon: Icons.lightbulb_outline,
                          onTap: controller.goTips,
                        ),
                        const SizedBox(height: 12),
                        _HomeMenuButton(
                          title: "bmiCalc".tr,
                          icon: Icons.monitor_weight_outlined,
                          onTap: controller.goBmi,
                        ),
                        const SizedBox(height: 12),
                        // Doctors list: visible to everyone
                        _HomeMenuButton(
                          title: "doctorsList".tr,
                          icon: Icons.medical_services_outlined,
                          onTap: controller.goDoctors,
                        ),
                        const SizedBox(height: 12),
                        _HomeMenuButton(
                          title: "settings".tr,
                          icon: Icons.settings_outlined,
                          onTap: controller.goSettings,
                        ),
                        const SizedBox(height: 12),
                        _HomeMenuButton(
                          title: "stepCounter".tr,
                          icon: Icons.directions_walk,
                          onTap: controller.goStepCounter,
                        ),
                        const SizedBox(height: 12),
                        _HomeMenuButton(
                          title: "spiritualNutrition".tr,
                          icon: Icons.self_improvement,
                          onTap: controller.goSpiritualNutrition,
                        ),
                        const SizedBox(height: 12),
                        _HomeMenuButton(
                          title: "logout".tr,
                          icon: Icons.logout,
                          onTap: controller.logout,
                        ),
                      ],
                      ),
                    ),
                  ),
                ),
              ),
              // ─── Purple gradient strip (right edge) ───
              // Container(
              //   width: 8,
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       colors: [
              //         AppColor.primary.withOpacity(0.3),
              //         AppColor.primary.withOpacity(0.6),
              //       ],
              //       begin: Alignment.topCenter,
              //       end: Alignment.bottomCenter,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _lightLavender,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColor.textColor.withOpacity(0.06),
        //     blurRadius: 8,
        //     offset: const Offset(0, 3),
        //   ),
        // ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "homeTitle".tr,
              textAlign: isAr ? TextAlign.right : TextAlign.left,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _darkPurple,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                // boxShadow: [
                //   BoxShadow(
                //     color: AppColor.textColor.withOpacity(0.06),
                //     blurRadius: 6,
                //     offset: const Offset(0, 2),
                //   ),
                // ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    ImageAssets.logo,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdsCarousel(HomeController c) {
    if (c.adsStatus == StatusRequest.loading) {
      return SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: AppColor.primary),
        ),
      );
    }
    if (c.ads.isEmpty) {
      return Image.asset(
        ImageAssets.logo,
        height: 180,
        fit: BoxFit.contain,
      );
    }
    return _AdsCarousel(ads: c.ads);
  }
}

class _AdsCarousel extends StatefulWidget {
  final List<AdModel> ads;

  const _AdsCarousel({required this.ads});

  @override
  State<_AdsCarousel> createState() => _AdsCarouselState();
}

class _AdsCarouselState extends State<_AdsCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      if (!_pageController.hasClients) return;
      final p = _pageController.page?.round() ?? 0;
      if (p != _currentPage) {
        if (mounted) setState(() => _currentPage = p);
      }
    });

    // Start auto-slide timer
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_pageController.hasClients) return;
      final next = (_currentPage + 1) % widget.ads.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _adTitle(AdModel ad) {
    if (ad.title != null && ad.title!.trim().isNotEmpty) return ad.title!;
    if (ad.type != null && ad.type!.trim().isNotEmpty) return ad.type!;
    if (ad.description != null && ad.description!.trim().isNotEmpty) {
      final d = ad.description!.trim();
      return d.length > 40 ? "${d.substring(0, 40)}..." : d;
    }
    return "Ad";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.ads.length,
              itemBuilder: (_, i) {
                final ad = widget.ads[i];
                return _AdCard(
                  ad: ad,
                  title: _adTitle(ad),
                  onTap: () => Get.toNamed(AppRoute.adDetails, arguments: ad),
                );
              },
            ),
          ),
          if (widget.ads.length > 1) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.ads.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: i == _currentPage
                          ? const LinearGradient(
                              colors: [AppColor.secondary, AppColor.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: i != _currentPage ? Colors.grey.shade300 : null,
                    ),
                  ),
                ),
              ),
            ),

          ],
        ],
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final AdModel ad;
  final String title;
  final VoidCallback? onTap;

  const _AdCard({required this.ad, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = ad.imageUrl;
    final hasImage = url != null && url.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColor.primary.withOpacity(0.01),
        //     blurRadius: 18,
        //     offset: const Offset(0, 6),
        //     spreadRadius: -1,
        //   ),
        //   BoxShadow(
        //     color: AppColor.textColor.withOpacity(0.06),
        //     blurRadius: 8,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image layer - best display
            if (hasImage)
              Image.network(
                url!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                gaplessPlayback: true,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPlaceholder(),
                      Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColor.primary.withOpacity(0.8),
                            ),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),
            // Overlay - optimized gradient for image visibility + title readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.grey.withOpacity(0.12),
                      Colors.grey.withOpacity(0.55),
                      AppColor.secondary.withOpacity(0.2),
                    ],
                    stops: const [0.0, 0.4, 0.78, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    height: 1.35,
                    // shadows: [
                    //   Shadow(
                    //     color: AppColor.textColor.withOpacity(0.5),
                    //     offset: const Offset(0, 1),
                    //     blurRadius: 4,
                    //   ),
                    //   Shadow(
                    //     color: AppColor.textColor.withOpacity(0.3),
                    //     offset: const Offset(0, 2),
                    //     blurRadius: 8,
                    //   ),
                    // ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColor.primary.withOpacity(0.14),
            AppColor.primary.withOpacity(0.06),
            AppColor.primary.withOpacity(0.02),
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Image.asset(
          ImageAssets.logo,
          height: 90,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _HomeMenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeMenuButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  static const Color _lightLavender = AppColor.mutedPurple;
  static const Color _darkPurple = AppColor.deepPurple;

  @override
  Widget build(BuildContext context) {
    final isAr = Get.locale?.languageCode == 'ar';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _lightLavender,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: AppColor.textColor.withOpacity(0.06),
        //     blurRadius: 8,
        //     offset: const Offset(0, 3),
        //   ),
        // ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
            children: [
              if (isAr) ...[
                Icon(icon, color: AppColor.primary, size: 28),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  title,
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _darkPurple,
                  ),
                ),
              ),
              if (!isAr) ...[
                const SizedBox(width: 16),
                Icon(icon, color: AppColor.primary, size: 28),
              ],
            ],
          ),
        ),
      ),
    )
    );
  }
}
