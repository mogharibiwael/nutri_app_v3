// bmi_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/shared/widgets/drawer.dart';
import 'package:nutri_guide/core/class/status_request.dart';
import 'package:nutri_guide/core/constant/theme/colors.dart';
import 'package:nutri_guide/core/shared/widgets/app_bar.dart';
import '../controller/bmi_controller.dart';

class BmiPage extends GetView<BmiController> {
  const BmiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BmiController>(
      builder: (c) => SafeArea(
          child: Scaffold(
            drawer: HomeDrawer(controller: c, homeOnly: true),
            appBar: CustomAppBar(
              title: "bmiBmrCalc".tr,
              showBackButton: true,
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(Icons.menu, color: AppColor.primary, size: 26),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "enterData".tr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // حقول الإدخال
              _InputField(
                label: "heightCm".tr,
                hint: "",
                controller: c.heightController,
                icon: Icons.height,
              ),
              const SizedBox(height: 12),
              _InputField(
                label: "weightKg".tr,
                hint: "",
                controller: c.weightController,
                icon: Icons.monitor_weight_outlined,
              ),
              const SizedBox(height: 12),
              _InputField(
                label: "age".tr,
                hint: "",
                controller: c.ageController,
                icon: Icons.cake_outlined,
              ),
              const SizedBox(height: 16),

              // اختيار الجنس
              _GenderSelector(
                value: c.gender,
                onChanged: (v) {
                  c.gender = v;
                  c.update();
                },
              ),
              const SizedBox(height: 16),

              // مستوى النشاط
              _ActivityDropdown(
                value: c.activityLevel,

                onChanged: (v) {
                  c.activityLevel = v;
                  c.update();
                },
              ),

              const SizedBox(height: 24),

              // زر الحساب
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: c.calculate,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColor.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "calculate".tr,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // عرض النتائج إذا كانت متوفرة
              if (c.bmi != null) ...[
                const SizedBox(height: 30),
                _ResultCard(
                  bmi: c.bmi,
                  bmiStatus: c.bmiStatus,
                  bmr: c.bmr,
                  pae: c.physicalActivityEnergy,
                  tef: c.tef,
                  totalKcal: c.totalKcal,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: c.saveStatus == StatusRequest.loading ? null : c.saveCalculation,
                    icon: c.saveStatus == StatusRequest.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text("saveCalculation".tr),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColor.primary),
                      foregroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _AdjustmentNote(),
              ],
            ],
          ),
        ),
      ),
    ));
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColor.primary),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _GenderSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _genderBtn("male", Icons.male, "male".tr),
          _genderBtn("female", Icons.female, "female".tr),
        ],
      ),
    );
  }

  Widget _genderBtn(String val, IconData icon, String label) {
    bool isSelected = value == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColor.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ActivityDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("activityLevel".tr, style: const TextStyle(fontWeight: FontWeight.w600,color: AppColor.textColor)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: (v) => onChanged(v!),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: [
            DropdownMenuItem(value: "sedentary", child: Text("activitySedentary".tr,style: TextStyle(fontWeight: FontWeight.w200,color: AppColor.textColor),)),
            DropdownMenuItem(value: "low", child: Text("activityLow".tr,style: TextStyle(fontWeight: FontWeight.w200,color: AppColor.textColor))),
            DropdownMenuItem(value: "active", child: Text("activityModerate".tr,style: TextStyle(fontWeight: FontWeight.w200,color: AppColor.textColor))),
            DropdownMenuItem(value: "very", child: Text("activityVery".tr,style: TextStyle(fontWeight: FontWeight.w200,color: AppColor.textColor))),
            DropdownMenuItem(value: "extra", child: Text("activityExtra".tr,style: TextStyle(fontWeight: FontWeight.w200,color: AppColor.textColor))),
          ],
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final double? bmi;
  final String bmiStatus;
  final double? bmr;
  final double? pae;
  final double? tef;
  final double? totalKcal;

  const _ResultCard({
    this.bmi,
    required this.bmiStatus,
    this.bmr,
    this.pae,
    this.tef,
    this.totalKcal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColor.textColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: AppColor.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          if (bmi != null)
            _resultRow("BMI", bmi!.toStringAsFixed(1), subtitle: bmiStatus.isEmpty ? null : bmiStatus),
          const Divider(height: 30),
          if (bmr != null) _resultRow("BMR (الأيض الأساسي)", "${bmr!.toStringAsFixed(0)} سعرة"),
          if (pae != null) _resultRow("مع النشاط البدني", "${pae!.toStringAsFixed(0)} سعرة"),
          if (tef != null) _resultRow("التأثير الحراري (TEF)", "${tef!.toStringAsFixed(0)} سعرة"),
          const Divider(height: 30),
          if (totalKcal != null)
            _resultRow(
              "إجمالي السعرات اليومية",
              "${totalKcal!.toStringAsFixed(0)} سعرة",
              isHighlight: true,
            ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String val, {String? subtitle, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                    fontSize: isHighlight ? 16 : 14,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColor.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppColor.primary : AppColor.textColor,
              fontSize: isHighlight ? 20 : 16,
            ),
          ),
        ],
      ),
    );
  }

}

class _AdjustmentNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "نصيحة علاجية: لخسارة الوزن اطرح 500 سعرة، ولزيادة الوزن أضف 500 سعرة للمجموع أعلاه.",
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }
}