import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_utils.dart';

class PublicHolidaysView extends StatelessWidget {
  const PublicHolidaysView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return RefreshIndicator(
      onRefresh: () async => await controller.fetchHolidays(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(UiUtils.getPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (Responsive.isMobile(context))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text('أعياد وإجازات',
                  //     style: TextStyle(
                  //         fontSize: 24,
                  //         fontWeight: FontWeight.bold,
                  //         color: AppTheme.textPrimary)),
                  // SizedBox(height: 8),
                  // const Text('إدارة العطلات الرسمية والمناسبات الوطنية ',
                  //     style: TextStyle(color: AppTheme.textSecondary)),
                  // SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => controller.fetchHolidays(),
                        icon: Icon(Icons.refresh_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: AppTheme.borderLight),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showAddHolidayDialog(context, controller),
                          icon: Icon(Icons.add_rounded, size: 20),
                          label: const Text('إضافة إجازة'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('أعياد وإجازات',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary)),
                      SizedBox(height: 8),
                      const Text('إدارة العطلات الرسمية والمناسبات الوطنية ',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => controller.fetchHolidays(),
                        icon: Icon(Icons.refresh_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: AppTheme.borderLight),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(48, 48),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showAddHolidayDialog(context, controller),
                        icon: Icon(Icons.add_rounded, size: 20),
                        label: const Text('إضافة إجازة'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(160, 48),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            SizedBox(height: 40),
            _buildNotesSection(),
            SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderLight, width: 0.5),
              ),
              child: Obx(() {
                if (controller.holidays.isEmpty) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 64, color: AppTheme.borderLight),
                        SizedBox(height: 16),
                        Text('لا توجد إجازات مضافة حالياً',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.holidays.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: AppTheme.borderLight),
                  itemBuilder: (context, index) {
                    final holiday = controller.holidays[index];
                    final bool isRange = holiday.endDate != null &&
                        holiday.endDate != holiday.date;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Text(holiday.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          if (holiday.isRecurring) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('سنوية',
                                  style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                          isRange
                              ? '${holiday.date} ⟵ ${holiday.endDate}'
                              : holiday.date,
                          style:
                              TextStyle(color: AppTheme.textSecondary)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            color: AppTheme.errorRed, size: 22),
                        onPressed: () =>
                            _confirmDelete(context, controller, holiday),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.primaryTeal),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'تظهر هذه الإجازات تلقائياً في جداول حضور الموظفين ويتم اعتبارها أيام عطلة رسمية مدفوعة الأجر.',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddHolidayDialog(BuildContext context, AdminController controller) {
    DateTime? startDate;
    DateTime? endDate;
    final RxBool isRecurring = false.obs;
    final nameController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('إضافة إجازة رسمية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم المناسبة'),
            ),
            SizedBox(height: 16),
            StatefulBuilder(builder: (context, setState) {
              return Column(
                children: [
                  ListTile(
                    title: Text(startDate == null
                        ? 'تاريخ البداية'
                        : startDate.toString().split(' ')[0]),
                    trailing: Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => startDate = picked);
                    },
                  ),
                  ListTile(
                    title: Text(endDate == null
                        ? 'تاريخ النهاية (اختياري)'
                        : endDate.toString().split(' ')[0]),
                    trailing: Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => endDate = picked);
                    },
                  ),
                ],
              );
            }),
            Obx(() => CheckboxListTile(
                  title: const Text('إجازة سنوية متكررة'),
                  value: isRecurring.value,
                  onChanged: (v) => isRecurring.value = v!,
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        if (nameController.text.isNotEmpty &&
                            startDate != null) {
                          final success = await controller.addHoliday(
                            HolidayModel(
                              name: nameController.text,
                              date: startDate.toString().split(' ')[0],
                              endDate: endDate?.toString().split(' ')[0],
                              isRecurring: isRecurring.value,
                            ),
                          );
                          if (success) {
                            Get.back();
                            UiUtils.showSuccessDialog(
                                'تم بنجاح', 'تم إضافة الإجازة');
                          }
                        }
                      },
                child: controller.isLoading.value
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('إضافة'),
              )),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AdminController controller, HolidayModel holiday) {
    UiUtils.showConfirmDialog(
      title: 'حذف إجازة',
      message: 'هل أنت متأكد من حذف ${holiday.name}؟',
      confirmText: 'حذف',
      confirmColor: AppTheme.errorRed,
      onConfirm: () async {
        final success = await controller.deleteHoliday(holiday.id!);
        if (success) {
          UiUtils.showSuccessDialog('تم بنجاح', 'تم حذف الإجازة');
        }
      },
    );
  }
}
