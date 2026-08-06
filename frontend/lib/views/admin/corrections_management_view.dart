import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_utils.dart';
import '../../models/app_models.dart';

class CorrectionsManagementView extends StatelessWidget {
  const CorrectionsManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    final statusFilter = 'all'.obs;

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
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!UiUtils.isSmallScreen(context))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إدارة طلبات تصحيح البصمات',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5)),
                          Text('مراجعة طلبات تصحيح البصمات ومعالجتها',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    
                    // Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Obx(() => DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: statusFilter.value,
                          icon: Icon(Icons.filter_list_rounded, color: AppTheme.primaryTeal, size: 20),
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontFamily: 'Tajawal'),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('جميع الطلبات')),
                            DropdownMenuItem(value: 'pending', child: Text('الطلبات المعلقة')),
                            DropdownMenuItem(value: 'approved', child: Text('الطلبات المقبولة')),
                            DropdownMenuItem(value: 'rejected', child: Text('الطلبات المرفوضة')),
                          ],
                          onChanged: (val) {
                            if (val != null) statusFilter.value = val;
                          },
                        ),
                      )),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value && controller.correctionRequests.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var requests = controller.correctionRequests.toList();
                  
                  if (statusFilter.value != 'all') {
                    requests = requests.where((r) => r.status == statusFilter.value).toList();
                  }
                  
                  requests.sort((a, b) => b.id.compareTo(a.id));

                  if (requests.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return _buildRequestCard(context, req, controller);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 64, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 24),
          const Text('لا توجد طلبات',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          const Text('لا توجد طلبات تصحيح بصمات مطابقة للبحث',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
      BuildContext context, AttendanceCorrectionModel req, AdminController controller) {
    Color statusColor;
    String statusText;

    switch (req.status) {
      case 'approved':
        statusColor = AppTheme.successGreen;
        statusText = 'مقبول';
        break;
      case 'rejected':
        statusColor = AppTheme.errorRed;
        statusText = 'مرفوض';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
    }

    String typeText = '';
    switch (req.type) {
      case 'missing_check_in':
        typeText = 'نسيان بصمة دخول';
        break;
      case 'missing_check_out':
        typeText = 'نسيان بصمة خروج';
        break;
      case 'edit_time':
        typeText = 'تعديل وقت البصمة';
        break;
      case 'delete_record':
        typeText = 'حذف بصمة خاطئة';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      child: Icon(Icons.person, color: AppTheme.primaryTeal),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.employeeName ?? 'موظف غير معروف',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textPrimary)),
                        Text(typeText,
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusText,
                      style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoBadge(Icons.calendar_today, req.date),
                if (req.originalTime != null && req.originalTime!.isNotEmpty)
                  _buildInfoBadge(Icons.history, 'الأصلي: ${_formatTime(req.originalTime!)}', color: Colors.orange),
                if (req.type != 'delete_record')
                  _buildInfoBadge(Icons.update, 'المطلوب: ${_formatTime(req.requestedTime)}', color: AppTheme.primaryTeal),
              ],
            ),
            if (req.reason.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('السبب / المبرر:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                    SizedBox(height: 4),
                    Text(req.reason,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
            if (req.adminNote != null && req.adminNote!.isNotEmpty) ...[
              SizedBox(height: 12),
              Text('ملاحظتك السابقة: ${req.adminNote}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.bold)),
            ],
            if (req.status == 'pending') ...[
              SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showActionDialog(context, req, controller, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.zero,
                      foregroundColor: AppTheme.errorRed,
                      side: BorderSide(color: AppTheme.errorRed),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(Icons.close_rounded, size: 18),
                    label: const Text('رفض الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showActionDialog(context, req, controller, 'approved'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: Icon(Icons.check_rounded, size: 18),
                    label: const Text('قبول واعتماد الطلب', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.textSecondary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.textSecondary),
          SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color ?? AppTheme.textSecondary)),
        ],
      ),
    );
  }

  void _showActionDialog(BuildContext context, AttendanceCorrectionModel req,
      AdminController controller, String actionStatus) {
    final noteController = TextEditingController();
    bool isApprove = actionStatus == 'approved';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isApprove ? 'قبول طلب التصحيح' : 'رفض طلب التصحيح',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isApprove ? AppTheme.successGreen : AppTheme.errorRed)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                isApprove
                    ? 'هل أنت متأكد من قبول الطلب؟ سيتم تعديل سجل حضور الموظف بناءً على هذا الطلب واعتماد أوقات الدوام والتأخيرات الجديدة تلقائياً.'
                    : 'هل أنت متأكد من رفض طلب تصحيح البصمة الخاص بهذا الموظف؟',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5)),
            SizedBox(height: 20),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: 'ملاحظة للإدارة والموظف (اختياري)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final res = await controller.updateCorrectionStatus(
                  req.id, actionStatus, noteController.text);
              if (res == true) {
                Get.back();
                UiUtils.showSuccessDialog(
                    'تم التحديث', 'تم تحديث حالة الطلب بنجاح');
              } else {
                UiUtils.showErrorDialog('خطأ', res.toString());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppTheme.successGreen : AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('تأكيد ${isApprove ? 'القبول' : 'الرفض'}'),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      String period = hour >= 12 ? 'م' : 'ص';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeStr;
    }
  }
}
