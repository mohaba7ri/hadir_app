import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/employee_controller.dart';
import '../../models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_utils.dart';

class MyOvertimeView extends StatelessWidget {
  const MyOvertimeView({Key? key}) : super(key: key);

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
              // Modern Header Row
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
                          Text('طلبات العمل الإضافي',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5)),
                          Text(
                            'تابع سجل ساعاتك الإضافية وطلباتك',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    if (UiUtils.isSmallScreen(context)) const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showOvertimeDialog(context),
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
                      label: const Text('طلب جديد',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Summary Stat Cards
              Obx(() {
                final int approved = controller.myOvertimeRequests
                    .where((r) => r.status == 'approved')
                    .fold(0, (sum, r) => sum + r.totalMinutes);
                final pending = controller.myOvertimeRequests
                    .where((r) => r.status == 'pending')
                    .length;

                return Row(
                  children: [
                    Expanded(
                      child: _buildQuickStat(
                        'الإجمالي المعتمد',
                        UiUtils.formatDuration(approved),
                        Icons.verified_rounded,
                        AppTheme.successGreen,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickStat(
                        'طلبات معلقة',
                        pending.toString(),
                        Icons.hourglass_empty_rounded,
                        Colors.orange,
                      ),
                    ),
                  ],
                );
              }),
              SizedBox(height: 32),

              // Scrollable List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.myOvertimeRequests.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: AppTheme.primaryTeal));
                  }
                  if (controller.myOvertimeRequests.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: controller.myOvertimeRequests.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final req = controller.myOvertimeRequests[index];
                      return _buildModernRequestCard(context, req);
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

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 16),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_toggle_off_rounded,
                size: 80, color: AppTheme.textSecondary.withValues(alpha: 0.2)),
          ),
          SizedBox(height: 24),
          const Text('لا توجد طلبات عمل إضافي',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          const Text('سيتم عرض سجلاتك هنا بمجرد تقديم طلب',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      String timePart = timeStr.contains(' ') ? timeStr.split(' ')[1] : timeStr;
      final parts = timePart.split(':');
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

  Widget _buildModernRequestCard(
      BuildContext context, OvertimeRequestModel req) {
    final controller = Get.find<EmployeeController>();
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: AppTheme.borderLight, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Container(width: 8, color: statusColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 28, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 16, color: AppTheme.textSecondary),
                              SizedBox(width: 8),
                              Text(req.date,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
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
                          _buildInfoBadge(Icons.access_time_filled_rounded,
                              '${_formatTime(req.startTime)} - ${_formatTime(req.endTime)}'),
                          _buildInfoBadge(Icons.more_time_rounded,
                              UiUtils.formatDuration(req.totalMinutes)),
                          if (req.status == 'approved')
                            _buildInfoBadge(Icons.payments_rounded,
                                'المكافأة: ${(req.totalMinutes * ((controller.employeeData.value?.salary ?? 0.0) / controller.daysInMonth / 480)).toStringAsFixed(2)} ر.س',
                                color: AppTheme.successGreen,
                                textColor: AppTheme.successGreen),
                        ],
                      ),
                      if (req.reason != null && req.reason!.isNotEmpty) ...[
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

  void _showOvertimeDialog(BuildContext context) {
    final controller = Get.find<EmployeeController>();
    final dateController = TextEditingController(
        text: DateTime.now().toIso8601String().split('T')[0]);
    final startController = TextEditingController();
    final endController = TextEditingController();
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('طلب عمل إضافي جديد',
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
                    firstDate: DateTime.now().subtract(const Duration(days: 7)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
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
              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerField(
                        context, 'وقت البدء', startController),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildTimePickerField(
                        context, 'وقت الانتهاء', endController),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'سبب العمل الإضافي',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, color: Colors.orange, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ملاحظة: يجب أن يكون الوقت خارج ساعات العمل الرسمية.',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
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
                    if (startController.text.isEmpty ||
                        endController.text.isEmpty) {
                      UiUtils.showErrorDialog(
                          'تنبيه', 'يرجى تحديد وقت البدء والانتهاء');
                      return;
                    }

                    // Prevent duplicate requests for the same date
                    bool hasExistingRequest = controller.myOvertimeRequests
                        .any((req) => req.date == dateController.text);

                    if (hasExistingRequest) {
                      UiUtils.showErrorDialog('تنبيه',
                          'لقد قمت بتقديم طلب عمل إضافي لهذا اليوم مسبقاً.');
                      return;
                    }

                    // Prevent overlap with work times
                    final emp = controller.employeeData.value;
                    final settings = controller.settings.value;

                    String? workStart = emp?.specialStartTime;
                    String? workEnd = emp?.specialEndTime;

                    if (workStart == null ||
                        workStart.isEmpty ||
                        workEnd == null ||
                        workEnd.isEmpty) {
                      if (settings?.ramadanMode == true) {
                        workStart = settings?.ramadanStartTime ?? '09:00:00';
                        workEnd = settings?.ramadanEndTime ?? '15:00:00';
                      } else {
                        workStart = settings?.defaultStartTime ?? '09:00:00';
                        workEnd = settings?.defaultEndTime ?? '17:00:00';
                      }
                    }

                    int timeToMinutes(String t) {
                      final p = t.split(':');
                      return int.parse(p[0]) * 60 + int.parse(p[1]);
                    }

                    try {
                      int ws = timeToMinutes(workStart);
                      int we = timeToMinutes(workEnd);
                      int os = timeToMinutes(startController.text);
                      int oe = timeToMinutes(endController.text);

                      bool hasOverlap = false;

                      if (ws < we && os < oe) {
                        hasOverlap = os < we && oe > ws;
                      } else if (ws > we && os < oe) {
                        hasOverlap = oe > ws || os < we;
                      } else if (ws < we && os > oe) {
                        hasOverlap = we > os || ws < oe;
                      } else {
                        hasOverlap = true;
                      }

                      if (hasOverlap) {
                        UiUtils.showErrorDialog('تداخل في الوقت',
                            'لا يمكن إضافة وقت إضافي خلال ساعات عملك المحددة (${_formatTime(workStart)} - ${_formatTime(workEnd)})');
                        return;
                      }
                    } catch (e) {
                      // Silently continue if parsing fails
                    }

                    final res = await controller.submitOvertimeRequest(
                      date: dateController.text,
                      startTime: startController.text,
                      endTime: endController.text,
                      reason: reasonController.text,
                    );

                    if (res == true) {
                      Get.back();
                      UiUtils.showSuccessDialog(
                          'تم التقديم', 'تم إرسال طلبك للمراجعة بنجاح');
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
                  child: const Text('إرسال الطلب'),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerField(BuildContext context, String label,
      TextEditingController textController) {
    return TextField(
      controller: textController,
      readOnly: true,
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time != null) {
          textController.text =
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.access_time_rounded, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
