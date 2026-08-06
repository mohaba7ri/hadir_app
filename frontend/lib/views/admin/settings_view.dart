import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_utils.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    final startTime =
        (controller.settings.value?.defaultStartTime ?? '08:00:00').obs;
    final endTime =
        (controller.settings.value?.defaultEndTime ?? '16:00:00').obs;
    final lateMins =
        (controller.settings.value?.allowedLateMinutes.toString() ?? '15').obs;
    final ramadanMode = (controller.settings.value?.ramadanMode ?? false).obs;

    return SingleChildScrollView(
      padding: EdgeInsets.all(UiUtils.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إعدادات النظام',
              style: TextStyle(
                  fontSize: Responsive.isMobile(context) ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          const Text('تحكم في مواعيد العمل الافتراضية وخيارات النظام العام',
              style: TextStyle(color: AppTheme.textSecondary)),
          SizedBox(height: 40),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderLight, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('أوقات الدوام الرسمية',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 24),
                if (Responsive.isMobile(context))
                  Column(
                    children: [
                      _buildTimeInput(context, 'بداية الدوام', startTime),
                      SizedBox(height: 16),
                      _buildTimeInput(context, 'نهاية الدوام', endTime),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                          child: _buildTimeInput(
                              context, 'بداية الدوام', startTime)),
                      SizedBox(width: 24),
                      Expanded(
                          child: _buildTimeInput(
                              context, 'نهاية الدوام', endTime)),
                    ],
                  ),
                SizedBox(height: 32),
                const Text('سياسات التأخير',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 16),
                _buildNumberInput(
                    'الدقائق المسموح بها للتأخير (فترة السماح)', lateMins),
                SizedBox(height: 32),
                const Divider(),
                SizedBox(height: 32),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Expanded(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Text('وضع شهر رمضان ',
                //               style: TextStyle(
                //                   fontWeight: FontWeight.bold,
                //                   fontSize: Responsive.isMobile(context)
                //                       ? 16
                //                       : 18)),
                //           const Text('تفعيل مواعيد العمل الخاصة بشهر رمضان',
                //               style: TextStyle(
                //                   fontSize: 13, color: AppTheme.textSecondary)),
                //         ],
                //       ),
                //     ),
                //     Obx(() => Switch.adaptive(
                //           value: ramadanMode.value,
                //           activeColor: AppTheme.primaryTeal,
                //           onChanged: (v) => ramadanMode.value = v,
                //         )),
                //   ],
                // ),
                // SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value ? null : () async {
                      final newSettings = SettingsModel(
                        defaultStartTime: startTime.value,
                        defaultEndTime: endTime.value,
                        allowedLateMinutes: int.tryParse(lateMins.value) ?? 15,
                        ramadanStartTime:
                            controller.settings.value?.ramadanStartTime ??
                                '10:00:00',
                        ramadanEndTime:
                            controller.settings.value?.ramadanEndTime ??
                                '15:00:00',
                        lastRenewalYear:
                            controller.settings.value?.lastRenewalYear ?? 2026,
                        ramadanMode: ramadanMode.value,
                      );
                      bool success =
                          await controller.updateSettings(newSettings);
                      if (success) {
                        UiUtils.showSuccessDialog(
                            'تم الحفظ', 'تم تحديث إعدادات النظام بنجاح');
                      } else {
                        UiUtils.showErrorDialog(
                            'خطأ', 'تعذر حفظ التغييرات، يرجى المحاولة لاحقاً');
                      }
                    },
                    child: controller.isLoading.value 
                        ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('حفظ كافة التغييرات'),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput(BuildContext context, String label, RxString value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              value.value =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFE9E9EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Obx(() => Text(value.value,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
                ),
                Icon(Icons.access_time_rounded,
                    size: 20, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput(String label, RxString value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value.value)
            ..selection = TextSelection.fromPosition(
                TextPosition(offset: value.value.length)),
          onChanged: (v) => value.value = v,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            suffixText: 'دقيقة',
          ),
        ),
      ],
    );
  }
}
