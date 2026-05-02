import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constant/theme/colors.dart';
import '../../../core/shared/widgets/app_bar.dart';
import '../controller/diet_periods_controller.dart';

/// Doctor: Define diet periods (meal times) - first step when creating a diet.
/// Each meal/snack has its own time. All saved when going to next step.
class DietPeriodsPage extends GetView<DietPeriodsController> {
  const DietPeriodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DietPeriodsController>(
      builder: (c) => SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: CustomAppBar(
            title: "dietPeriods".tr,
            subtitle: c.patientName.isNotEmpty ? c.patientName : null,
            showBackButton: true,
            showLogo: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (c.patientName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          "Patient: ${c.patientName}",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                    Text(
                      "setTimeForEachMeal".tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(c.periods.length, (i) {
                      final period = c.periods[i];
                      final isExtra = period.mealType == MealType.extraSnack;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PeriodRow(
                          label: period.mealType.labelFor(period),
                          nameHint: period.mealType.defaultLabel(
                            extraSnackIndex: period.extraSnackIndex,
                          ),
                          time: period.time,
                          isEditableName: true,
                          customName: period.customName,
                          onNameChanged: (name) => c.updatePeriodName(i, name),
                          onTimeTap: () => _pickTime(context, c, i),
                          onRemove: isExtra
                              ? () => c.removeExtraSnack(i)
                              : null,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black12),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BottomButton(
                      label: "addSnack".tr,
                      icon: Icons.add,
                      onTap: c.addSnack,
                      isOutlined: true,
                    ),
                    const SizedBox(height: 12),
                    _BottomButton(
                      label: "nextStep".tr,
                      icon: Icons.arrow_forward,
                      onTap: c.goToNextStep,
                      isOutlined: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(
      BuildContext context, DietPeriodsController c, int index) async {
    final initial = c.periods[index].time;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColor.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      c.updatePeriodTime(index, picked);
    }
  }
}

class _PeriodRow extends StatelessWidget {
  final String label;
  /// Shown as hint when the name field is editable (default meal label, not the typed value).
  final String nameHint;
  final TimeOfDay time;
  final bool isEditableName;
  final String? customName;
  final ValueChanged<String>? onNameChanged;
  final VoidCallback onTimeTap;
  final VoidCallback? onRemove;

  const _PeriodRow({
    required this.label,
    required this.nameHint,
    required this.time,
    this.isEditableName = false,
    this.customName,
    this.onNameChanged,
    required this.onTimeTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(time);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          Expanded(
            child: isEditableName && onNameChanged != null
                ? _EditableNameField(
                    initialValue: customName ?? label,
                    hint: nameHint,
                    onChanged: onNameChanged!,
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade900,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Material(
            color: AppColor.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTimeTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 20, color: AppColor.primary),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.remove_circle_outline,
                  color: Colors.red.shade400, size: 24),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final period = t.hour < 12 ? 'AM' : 'PM';
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    return '$period ${h.toString().padLeft(2, '0')}:$m';
  }
}

class _EditableNameField extends StatefulWidget {
  final String initialValue;
  final String hint;
  final ValueChanged<String> onChanged;

  const _EditableNameField({
    required this.initialValue,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_EditableNameField> createState() => _EditableNameFieldState();
}

class _EditableNameFieldState extends State<_EditableNameField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _EditableNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColor.primary, width: 1.5),
        ),
      ),
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade900,
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isOutlined;

  const _BottomButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isOutlined,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 22),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColor.primary,
            side: BorderSide(color: AppColor.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
