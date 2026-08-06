import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_utils.dart';

class MonthlyClosingsView extends StatefulWidget {
  const MonthlyClosingsView({Key? key}) : super(key: key);

  @override
  State<MonthlyClosingsView> createState() => _MonthlyClosingsViewState();
}

class _MonthlyClosingsViewState extends State<MonthlyClosingsView> {
  final AdminController controller = Get.find<AdminController>();
  final RxSet<int> selectedIds = <int>{}.obs;
  final RxBool isSelectAll = false.obs;
  final RxString selectedDate = DateTime.now().toString().split(' ')[0].obs;

  @override
  void initState() {
    super.initState();
    // Default to today's date, or if it's past the 24th, maybe show a warning, but today is fine.
  }

  void _processBatchClosing() async {
    if (selectedIds.isEmpty) return;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: AppTheme.primaryTeal),
            const SizedBox(height: 24),
            const Text('جاري معالجة الإغلاق...',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('يرجى الانتظار، قد تستغرق هذه العملية بعض الوقت.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    int successCount = 0;
    List<Map<String, dynamic>> errorList = [];
    final empIds = selectedIds.toList();
    final startDateStr = DateTime.now().subtract(const Duration(days: 30)).toString().split(' ')[0];
    for (int id in empIds) {
      final emp = controller.employees.firstWhere((e) => e.id == id);
      final errorMap =
          await controller.splitEmployeePayroll(id, startDateStr, selectedDate.value);
      if (errorMap == null || errorMap['status'] == 'success') {
        successCount++;
      } else {
        errorList.add({
          'emp': emp.name,
          'message': errorMap['message'] ?? 'خطأ غير معروف',
          'duplicates': errorMap['duplicates'] ?? [],
        });
      }
    }

    Get.back(); // close loading dialog
    selectedIds.clear();
    isSelectAll.value = false;

    if (errorList.isEmpty) {
      if (successCount > 0) {
        UiUtils.showSuccessDialog('اكتمل الإغلاق',
            'تم إغلاق $successCount موظف بنجاح من أصل ${empIds.length}.');
      } else {
        UiUtils.showErrorDialog('تنبيه', 'لا يوجد بيانات لإغلاقها.');
      }
    } else {
      Get.dialog(
        AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.primaryGold),
              SizedBox(width: 8),
              Text('نتيجة الإغلاق',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (successCount > 0)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: AppTheme.successGreen),
                        SizedBox(width: 8),
                        Text('تم إغلاق $successCount موظف بنجاح.',
                            style: TextStyle(
                                color: AppTheme.successGreen,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                if (successCount > 0) SizedBox(height: 16),
                Text('يوجد تنبيهات للموظفين التاليين:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: errorList.length,
                    itemBuilder: (context, index) {
                      final item = errorList[index];
                      final List<dynamic> dups =
                          item['duplicates'] as List<dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.borderLight),
                        ),
                        color: AppTheme.backgroundLight,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 16, color: AppTheme.textSecondary),
                                  SizedBox(width: 6),
                                  Text(item['emp'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(item['message'],
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.errorRed,
                                      height: 1.5)),
                              if (dups.isNotEmpty) ...[
                                SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: dups.map((d) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryTeal
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        d.toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryTeal,
                                        ),
                                        textDirection: TextDirection.ltr,
                                      ),
                                    );
                                  }).toList(),
                                )
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child:
                  Text('حسناً', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.isMobile(context) ? 16.0 : 40.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lock_clock_rounded,
                    color: AppTheme.primaryTeal, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الإغلاقات الشهرية',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900)),
                    Text(
                        'قم بإغلاق وحفظ السجلات المالية والحضور للموظفين بنهاية كل فترة.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تاريخ الإغلاق:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Obx(() => InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.parse(selectedDate.value),
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          selectedDate.value = picked.toString().split(' ')[0];
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.borderLight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(selectedDate.value),
                            const SizedBox(width: 16),
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppTheme.primaryTeal),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
                const Text(
                    'تنبيه: سيتم حفظ الحسابات كفترة مستقلة لتاريخ الإغلاق المحدد ولن تتأثر بتعديلات لاحقة.',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      border: Border(
                          bottom: BorderSide(color: AppTheme.borderLight)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('تحديد الموظفين',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Obx(() => Row(
                              children: [
                                Checkbox(
                                  value: isSelectAll.value,
                                  activeColor: AppTheme.primaryTeal,
                                  onChanged: (val) {
                                    isSelectAll.value = val ?? false;
                                    if (isSelectAll.value) {
                                      selectedIds.addAll(controller.employees
                                          .map((e) => e.id!));
                                    } else {
                                      selectedIds.clear();
                                    }
                                  },
                                ),
                                const Text('تحديد الكل',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                              ],
                            )),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (controller.employees.isEmpty) {
                        return const Center(child: Text('لا يوجد موظفين'));
                      }
                      return ListView.separated(
                        itemCount: controller.employees.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final emp = controller.employees[index];
                          return Obx(() => CheckboxListTile(
                                title: Text(emp.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text('الرقم الوظيفي: #${emp.id}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary)),
                                value: selectedIds.contains(emp.id),
                                activeColor: AppTheme.primaryTeal,
                                onChanged: (val) {
                                  if (val == true) {
                                    selectedIds.add(emp.id!);
                                  } else {
                                    selectedIds.remove(emp.id);
                                    isSelectAll.value = false;
                                  }
                                  if (selectedIds.length ==
                                      controller.employees.length) {
                                    isSelectAll.value = true;
                                  }
                                },
                              ));
                        },
                      );
                    }),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16)),
                      border:
                          Border(top: BorderSide(color: AppTheme.borderLight)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() => Text('تم تحديد ${selectedIds.length} موظف',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryTeal))),
                        Obx(() => ElevatedButton.icon(
                              onPressed: selectedIds.isEmpty
                                  ? null
                                  : _processBatchClosing,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryTeal,
                                foregroundColor: Colors.white,
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.check_circle_rounded,
                                  size: 20),
                              label: const Text('حفظ وإغلاق السجلات',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
