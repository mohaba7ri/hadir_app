import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/employee_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_utils.dart';
import '../../models/app_models.dart';

class MyCorrectionsView extends StatelessWidget {
  const MyCorrectionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmployeeController>();

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
                          Text('طلبات تصحيح البصمات',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5)),
                          Text('إدارة طلبات تعديل وتصحيح الحضور والانصراف',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    if (UiUtils.isSmallScreen(context)) const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showCorrectionDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: Icon(Icons.add_rounded, size: 20),
                      label: const Text('طلب تصحيح',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final requests = controller.myCorrectionRequests.toList()
                    ..sort((a, b) => b.id.compareTo(a.id)); // Newest first

                  if (requests.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return _buildRequestCard(context, req);
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
            child: Icon(Icons.history_rounded,
                size: 64, color: AppTheme.textSecondary),
          ),
          SizedBox(height: 24),
          const Text('لا توجد طلبات تصحيح',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          const Text('لم تقم بتقديم أي طلبات لتصحيح البصمات حتى الآن',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
      BuildContext context, AttendanceCorrectionModel req) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (req.status) {
      case 'approved':
        statusColor = AppTheme.successGreen;
        statusText = 'مقبول';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'rejected':
        statusColor = AppTheme.errorRed;
        statusText = 'مرفوض';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
        statusIcon = Icons.hourglass_top_rounded;
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 26, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fingerprint_rounded,
                                  size: 20, color: AppTheme.primaryTeal),
                              SizedBox(width: 8),
                              Text(typeText,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: AppTheme.textPrimary)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                SizedBox(width: 6),
                                Text(statusText,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: statusColor,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildInfoBadge(
                              Icons.calendar_today_rounded, req.date),
                          if (req.originalTime != null &&
                              req.originalTime!.isNotEmpty)
                            _buildInfoBadge(Icons.history_rounded,
                                'الوقت الأصلي: ${_formatTime(req.originalTime!)}',
                                color: Colors.orange),
                          if (req.type != 'delete_record')
                            _buildInfoBadge(Icons.update_rounded,
                                'الوقت المطلوب: ${_formatTime(req.requestedTime)}'),
                        ],
                      ),
                      if (req.reason.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('السبب: ${req.reason}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.4)),
                        ),
                      ],
                      if (req.adminNote != null &&
                          req.adminNote!.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14, color: AppTheme.errorRed),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('ملاحظة الإدارة: ${req.adminNote}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.errorRed,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
  }

  Widget _buildInfoBadge(IconData icon, String label,
      {Color? color, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.1) ?? AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.primaryTeal),
          SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }

  void _showCorrectionDialog(BuildContext context) {
    final controller = Get.find<EmployeeController>();
    final dateController = TextEditingController(
        text: DateTime.now().toIso8601String().split('T')[0]);
    final originalTimeController = TextEditingController();
    final requestedTimeController = TextEditingController();
    final reasonController = TextEditingController();
    final selectedType = 'missing_check_in'.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('طلب تصحيح بصمة',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    dateController.text = date.toIso8601String().split('T')[0];
                  }
                },
                decoration: InputDecoration(
                  labelText: 'التاريخ',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              SizedBox(height: 16),

              // Type Dropdown
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType.value,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded),
                        items: const [
                          DropdownMenuItem(
                              value: 'missing_check_in',
                              child: Text('نسيان بصمة دخول')),
                          DropdownMenuItem(
                              value: 'missing_check_out',
                              child: Text('نسيان بصمة خروج')),
                          DropdownMenuItem(
                              value: 'edit_time',
                              child: Text('تعديل وقت البصمة')),
                          DropdownMenuItem(
                              value: 'delete_record',
                              child: Text('حذف بصمة خاطئة')),
                        ],
                        onChanged: (val) {
                          if (val != null) selectedType.value = val;
                        },
                      ),
                    ),
                  )),
              SizedBox(height: 16),

              Obx(() {
                if (selectedType.value == 'edit_time') {
                  return Column(
                    children: [
                      _buildTimePickerField(context, 'الوقت الأصلي المسجل',
                          originalTimeController),
                      SizedBox(height: 16),
                      _buildTimePickerField(context, 'الوقت الصحيح المطلوب',
                          requestedTimeController),
                    ],
                  );
                } else if (selectedType.value == 'delete_record') {
                  return _buildTimePickerField(context,
                      'وقت البصمة المراد حذفها', originalTimeController);
                } else {
                  return _buildTimePickerField(
                      context, 'وقت البصمة الصحيح', requestedTimeController);
                }
              }),

              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'السبب والمبرر',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.maxFinite,
            child: Row(
              children: [
                Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('إلغاء'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedType.value != 'delete_record' &&
                        requestedTimeController.text.isEmpty) {
                      UiUtils.showErrorDialog(
                          'تنبيه', 'يرجى تحديد الوقت المطلوب');
                      return;
                    }
                    if ((selectedType.value == 'edit_time' ||
                            selectedType.value == 'delete_record') &&
                        originalTimeController.text.isEmpty) {
                      UiUtils.showErrorDialog('تنبيه',
                          'يرجى تحديد الوقت الأصلي المسجل للتمكن من تغييره/حذفه');
                      return;
                    }

                    final res = await controller.submitCorrectionRequest(
                      date: dateController.text,
                      type: selectedType.value,
                      originalTime: originalTimeController.text.isEmpty
                          ? null
                          : originalTimeController.text,
                      requestedTime: requestedTimeController.text,
                      reason: reasonController.text,
                    );

                    if (res == true) {
                      Get.back();
                      UiUtils.showSuccessDialog(
                          'تم التقديم', 'تم إرسال طلب التصحيح للمراجعة بنجاح');
                    } else {
                      UiUtils.showErrorDialog('خطأ', res.toString());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('إرسال الطلب',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerField(
      BuildContext context, String label, TextEditingController tController) {
    return TextField(
      controller: tController,
      readOnly: true,
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          final h = time.hour.toString().padLeft(2, '0');
          final m = time.minute.toString().padLeft(2, '0');
          tController.text = '$h:$m:00';
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.access_time_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      String period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeStr;
    }
  }
}
