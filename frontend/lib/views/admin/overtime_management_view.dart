import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_utils.dart';

class OvertimeManagementView extends StatelessWidget {
  const OvertimeManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Padding(
          padding: EdgeInsets.all(UiUtils.getPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إدارة العمل الإضافي',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary)),
                  Text('مراجعة واعتماد طلبات الموظفين',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
              SizedBox(height: 24),
              // Search and Filter Row
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      onChanged: (v) =>
                          controller.overtimeSearchQuery.value = v,
                      decoration: InputDecoration(
                        hintText: 'بحث عن موظف (الاسم أو الرقم)...',
                        prefixIcon: Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppTheme.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                    ),
                  ),
                  _buildDateFilterDropdowns(controller),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Obx(() => _buildDropdown<String>(
                          value: controller.overtimeStatusFilter.value,
                          items: const [
                            'all',
                            'approved',
                            'rejected',
                            'pending'
                          ],
                          onChanged: (v) =>
                              controller.overtimeStatusFilter.value = v!,
                          itemLabel: (v) {
                            switch (v) {
                              case 'approved':
                                return 'مقبول';
                              case 'rejected':
                                return 'مرفوض';
                              case 'pending':
                                return 'معلق';
                              default:
                                return 'الكل';
                            }
                          },
                        )),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.filteredOvertimeRequests.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: AppTheme.primaryTeal));
                  }

                  return _buildRequestList(
                      context, controller.filteredOvertimeRequests);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList(
      BuildContext context, List<OvertimeRequestModel> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_rtl_rounded,
                size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.2)),
            SizedBox(height: 16),
            const Text('لا توجد طلبات تطابق الفلتر',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: requests.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        final req = requests[index];
        return _buildAdminRequestCard(context, req, req.status == 'pending');
      },
    );
  }

  Widget _buildAdminRequestCard(
      BuildContext context, OvertimeRequestModel req, bool isPending) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight, width: 0.8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded,
                      color: AppTheme.primaryTeal),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req.employeeName ?? 'موظف',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppTheme.textPrimary)),
                      Text(req.date,
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                if (!isPending)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (req.status == 'approved'
                              ? AppTheme.successGreen
                              : AppTheme.errorRed)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      req.status == 'approved' ? 'مقبول' : 'مرفوض',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: req.status == 'approved'
                              ? AppTheme.successGreen
                              : AppTheme.errorRed),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                _buildInfoChip(Icons.access_time_filled_rounded,
                    '${req.startTime} - ${req.endTime}'),
                SizedBox(width: 12),
                _buildInfoChip(Icons.more_time_rounded,
                    UiUtils.formatDuration(req.totalMinutes)),
              ],
            ),
            if (req.reason != null && req.reason!.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(req.reason!,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4)),
            ],
            if (isPending) ...[
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _handleStatusChange(context, req, 'rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: AppTheme.errorRed),
                      ),
                      child: const Text('رفض الطلب',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _handleStatusChange(context, req, 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('اعتماد الطلب',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else if (req.adminNote != null && req.adminNote!.isNotEmpty) ...[
              SizedBox(height: 16),
              const Divider(),
              SizedBox(height: 8),
              Text('ملاحظة الإدارة: ${req.adminNote}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryTeal),
          SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  void _handleStatusChange(
      BuildContext context, OvertimeRequestModel req, String status) {
    final controller = Get.find<AdminController>();
    final noteController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(status == 'approved' ? 'الموافقة على الإضافي' : 'رفض الطلب',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'هل أنت متأكد من ${status == 'approved' ? 'الموافقة على' : 'رفض'} طلب الموظف ${req.employeeName}؟',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'ملاحظة إدارية (اختياري)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                    onPressed: () => Get.back(), child: const Text('إلغاء')),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final res = await controller.updateOvertimeStatus(
                      req.id!,
                      status,
                      adminNote: noteController.text,
                    );
                    if (res) {
                      Get.back();
                      UiUtils.showSuccessDialog(
                          'تم التحديث', 'تم تحديث حالة الطلب بنجاح');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: status == 'approved'
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('تأكيد'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterDropdowns(AdminController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Obx(() => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdown(
                value: controller.selectedMonth.value,
                items: List.generate(12, (i) => i + 1),
                onChanged: (v) => controller.selectedMonth.value = v!,
                itemLabel: (v) => _getMonthNameArabic(v),
              ),
              Container(
                  width: 1,
                  height: 20,
                  color: AppTheme.borderLight,
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              _buildDropdown(
                value: controller.selectedYear.value,
                items: List.generate(5, (i) => DateTime.now().year - 2 + i),
                onChanged: (v) => controller.selectedYear.value = v!,
                itemLabel: (v) => v.toString(),
              ),
            ],
          )),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) itemLabel,
  }) {
    return DropdownButton<T>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(itemLabel(e))))
          .toList(),
      onChanged: onChanged,
      underline: SizedBox(),
      icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20),
      style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13),
    );
  }

  String _getMonthNameArabic(int month) {
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month];
  }
}
