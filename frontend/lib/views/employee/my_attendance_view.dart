import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/employee_controller.dart';
import '../../models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/constants/app_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class MyAttendanceView extends StatelessWidget {
  const MyAttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmployeeController>();

    return Padding(
      padding: EdgeInsets.all(UiUtils.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (Responsive.isMobile(context)) ...[
            Row(
              children: [
                Expanded(child: _buildFilterDropdowns(controller)),
                SizedBox(width: 12),
                IconButton(
                  onPressed: () => controller.fetchMonthlySummary(),
                  icon: Icon(Icons.refresh_rounded, color: AppTheme.primaryTeal),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  Obx(() => _buildStatCard(context, 'إجمالي الخصم', '${controller.totalDiscount.toStringAsFixed(2)} ر.س', Icons.account_balance_wallet_rounded, AppTheme.errorRed)),
                  SizedBox(width: 12),
                  Obx(() => _buildStatCard(context, 'خصم الغياب', '${controller.totalAbsentDiscount.toStringAsFixed(2)} ر.س', Icons.event_busy_rounded, AppTheme.errorRed)),
                  SizedBox(width: 12),
                  Obx(() => _buildStatCard(context, 'خصم التأخير', '${controller.totalLateDiscount.toStringAsFixed(2)} ر.س', Icons.access_time_rounded, Colors.orange)),
                  SizedBox(width: 12),
                  Obx(() => _buildStatCard(context, 'خصم خروج مبكر', '${controller.totalEarlyExitDiscount.toStringAsFixed(2)} ر.س', Icons.logout_rounded, Colors.orange)),
                  SizedBox(width: 12),
                  Obx(() {
                    if (controller.totalOvertimeGained > 0) {
                      return _buildStatCard(context, 'مكافأة الإضافي', '+${controller.totalOvertimeGained.toStringAsFixed(2)} ر.س', Icons.more_time_rounded, AppTheme.successGreen);
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ] else ...[
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildFilterDropdowns(controller),
                Obx(() => _buildStatCard(context, 'إجمالي الخصم', '${controller.totalDiscount.toStringAsFixed(2)} ر.س', Icons.account_balance_wallet_rounded, AppTheme.errorRed)),
                Obx(() => _buildStatCard(context, 'خصم الغياب', '${controller.totalAbsentDiscount.toStringAsFixed(2)} ر.س', Icons.event_busy_rounded, AppTheme.errorRed)),
                Obx(() => _buildStatCard(context, 'خصم التأخير', '${controller.totalLateDiscount.toStringAsFixed(2)} ر.س', Icons.access_time_rounded, Colors.orange)),
                Obx(() => _buildStatCard(context, 'خصم خروج مبكر', '${controller.totalEarlyExitDiscount.toStringAsFixed(2)} ر.س', Icons.logout_rounded, Colors.orange)),
                Obx(() {
                  if (controller.totalOvertimeGained > 0) {
                    return _buildStatCard(context, 'مكافأة الإضافي', '+${controller.totalOvertimeGained.toStringAsFixed(2)} ر.س', Icons.more_time_rounded, AppTheme.successGreen);
                  }
                  return const SizedBox.shrink();
                }),
                IconButton(
                  onPressed: () => controller.fetchMonthlySummary(),
                  icon: Icon(Icons.refresh_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => await controller.fetchMonthlySummary(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Obx(() {
                  if (controller.filteredAttendance.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25),
                        const Center(
                            child: Text('لا توجد سجلات حضور حالياً',
                                style:
                                    TextStyle(color: AppTheme.textSecondary))),
                      ],
                    );
                  }
                  return ListView.separated(
                    itemCount: controller.filteredAttendance.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final att = controller.filteredAttendance[index];
                      final isApproved =
                          controller.isDayApprovedVacation(att.date);
                      final isPending =
                          controller.isDayPendingVacation(att.date);

                      final effectiveStatus = att.status;
                      final effectiveLate = att.lateMinutes;
                      final isEarlyExit = att.earlyExitMinutes > 0;
                      final dateObj = DateTime.parse(att.date);
                      final dayName = _getDayNameArabic(dateObj);

                      Color statusColor;
                      if (isApproved) {
                        statusColor = AppTheme.primaryTeal;
                      } else if (isPending) {
                        statusColor = Colors.orange;
                      } else {
                        switch (att.status) {
                          case 'present':
                            statusColor = effectiveLate > 0
                                ? Colors.orange
                                : AppTheme.successGreen;
                            break;
                          case 'late':
                          case 'early_exit':
                            statusColor = Colors.orange;
                            break;
                          case 'absent':
                            statusColor = AppTheme.errorRed;
                            break;
                          default:
                            statusColor = AppTheme.textSecondary;
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: statusColor, width: 5),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: InkWell(
                          onTap: att.status == 'pending'
                              ? null
                              : () =>
                                  _showAttendanceDetailsDialog(context, att),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Row
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded,
                                          size: 12,
                                          color: AppTheme.textSecondary),
                                      SizedBox(width: 6),
                                      Text('$dayName ${att.date}',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500)),
                                      const Spacer(),
                                      if (isPending)
                                        _buildStatusBadge(
                                            'pending_vacation', false, 0)
                                      else
                                        _buildStatusBadge(effectiveStatus,
                                            isApproved, effectiveLate),
                                      if (att.isCorrected) ...[
                                        SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.successGreen
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle_outline,
                                                  size: 10,
                                                  color: AppTheme.successGreen),
                                              SizedBox(width: 4),
                                              Text('مصحح',
                                                  style: TextStyle(
                                                      color:
                                                          AppTheme.successGreen,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (att.isPendingCorrection) ...[
                                        SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orange
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                  Icons.hourglass_empty_rounded,
                                                  size: 10,
                                                  color: Colors.orange),
                                              SizedBox(width: 4),
                                              Text('قيد التصحيح',
                                                  style: TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 16),

                                  // Time Section
                                  if ((effectiveStatus != 'absent' &&
                                          effectiveStatus != 'pending' &&
                                          !isApproved) ||
                                      att.isCorrected ||
                                      att.isPendingCorrection)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _buildCompactTime(
                                                'دخول',
                                                _formatTime(att.checkIn),
                                                Icons.login_rounded,
                                                AppTheme.successGreen,
                                                isCorrected:
                                                    att.isCheckInCorrected),
                                          ),
                                          Container(
                                              width: 1,
                                              height: 20,
                                              color: AppTheme.borderLight),
                                          Expanded(
                                            child: _buildCompactTime(
                                                'خروج',
                                                _formatTime(att.checkOut),
                                                Icons.logout_rounded,
                                                AppTheme.errorRed,
                                                isCorrected:
                                                    att.isCheckOutCorrected),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Critical Alerts / Info
                                  if (isEarlyExit ||
                                      (effectiveLate > 0) ||
                                      (effectiveStatus == 'absent' &&
                                          !isApproved)) ...[
                                    SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (isEarlyExit)
                                          _buildAlertChip(
                                              'خصم خروج مبكر (${att.earlyExitMinutes} دقيقة) (${att.earlyExitDiscount.toStringAsFixed(2)} ر.س)',
                                              Icons.logout_rounded,
                                              Colors.orange),
                                        if (effectiveLate > 0)
                                          _buildAlertChip(
                                              'خصم تأخير ($effectiveLate دقيقة) (${att.lateDiscount.toStringAsFixed(2)} ر.س)',
                                              Icons.access_time_rounded,
                                              Colors.orange),
                                        if (effectiveStatus == 'absent' &&
                                            !isApproved)
                                          _buildAlertChip(
                                              'خصم غياب (${att.discount.toStringAsFixed(2)} ر.س)',
                                              Icons.money_off_csred_rounded,
                                              AppTheme.errorRed),
                                        if (controller
                                                .getApprovedOvertimeMinutes(
                                                    att.date) >
                                            0)
                                          _buildAlertChip(
                                              'إضافي ${UiUtils.formatDuration(controller.getApprovedOvertimeMinutes(att.date))}',
                                              Icons.more_time_rounded,
                                              AppTheme.primaryTeal),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: Responsive.isMobile(context) ? 150 : 200,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterDropdowns(EmployeeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Obx(() => Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _buildDropdown(
                  value: controller.selectedMonth.value,
                  items: List.generate(12, (i) => i + 1),
                  onChanged: (v) => controller.selectedMonth.value = v!,
                  itemLabel: (v) => _getMonthNameArabic(v),
                ),
              ),
              Container(
                  width: 1,
                  height: 20,
                  color: AppTheme.borderLight,
                  margin: const EdgeInsets.symmetric(horizontal: 12)),
              Expanded(
                child: _buildDropdown(
                  value: controller.selectedYear.value,
                  items: List.generate(5, (i) => DateTime.now().year - 2 + i),
                  onChanged: (v) => controller.selectedYear.value = v!,
                  itemLabel: (v) => v.toString(),
                ),
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

  Widget _buildCompactTime(
      String label, String time, IconData icon, Color color,
      {bool isCorrected = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
            SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isCorrected)
              Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.edit_note_rounded,
                    size: 14, color: AppTheme.primaryTeal),
              ),
            Text(time,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '--:--';
    try {
      String timePart = dateTimeStr;
      if (dateTimeStr.contains(' ')) {
        timePart = dateTimeStr.split(' ')[1];
      }
      final time = DateFormat('HH:mm:ss').parse(timePart);
      return DateFormat('hh:mm a').format(time);
    } catch (e) {
      return '--:--';
    }
  }

  String _getDayNameArabic(DateTime date) {
    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    return days[date.weekday - 1];
  }

  Widget _buildStatusBadge(String status, bool isApproved, int lateMinutes) {
    Color color;
    String text;
    if ((status == 'absent' || status == 'vacation') && isApproved) {
      color = AppTheme.primaryTeal;
      text = 'إجازة مقبولة';
    } else if (status == 'pending_vacation') {
      color = Colors.orange;
      text = 'طلب إجازة قيد الانتظار';
    } else {
      switch (status) {
        case 'present':
          if (lateMinutes > 0) {
            color = Colors.orange;
            text = 'متأخر';
          } else {
            color = AppTheme.successGreen;
            text = 'حاضر';
          }
          break;
        case 'late':
          color = Colors.orange;
          text = 'متأخر';
          break;
        case 'absent':
          color = AppTheme.errorRed;
          text = 'غائب';
          break;
        case 'pending':
          color = AppTheme.textSecondary;
          text = 'قادم';
          break;
        case 'incomplete':
          if (lateMinutes > 0) {
            color = Colors.orange;
            text = 'تأخير / غير مكتمل';
          } else {
            color = AppTheme.primaryTeal;
            text = 'غير مكتمل';
          }
          break;
        case 'vacation':
          color = AppTheme.primaryTeal;
          text = 'إجازة';
          break;
        case 'early_exit':
          color = Colors.orange;
          text = 'خروج مبكر';
          break;
        case 'off':
          color = AppTheme.textSecondary;
          text = '-';
          break;
        case 'holiday':
          color = AppTheme.primaryTeal;
          text = 'إجازة رسمية';
          break;
        default:
          color = AppTheme.textSecondary;
          text = status == 'pending'
              ? 'قادم'
              : (status == 'vacation' ? 'إجازة' : status);
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildSelectableProTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryTeal.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryTeal : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryTeal.withValues(alpha: 0.2), blurRadius: 8, offset: Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryTeal : AppTheme.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppTheme.textSecondary, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? AppTheme.primaryTeal : AppTheme.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppTheme.primaryTeal : AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProTimeBox(String label, String time, IconData icon, Color color, {bool isCorrected = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
              SizedBox(width: 8),
              Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold))),
              if (isCorrected) Icon(Icons.edit_note_rounded, size: 16, color: AppTheme.primaryTeal),
            ],
          ),
          SizedBox(height: 8),
          Text(time, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  void _showCoverWithVacationDialog(BuildContext context, AttendanceModel att,
      {bool isAbsent = false}) {
    final controller = Get.find<EmployeeController>();

    // Calculate minutes available to cover
    int initialLateMins = isAbsent ? 0 : att.lateMinutes;
    int initialEarlyExitMins = isAbsent ? 0 : att.earlyExitMinutes;

    final showLate = false.obs;
    final showEarly = false.obs;

    final workDayMinutes = controller.getSystemWorkDayDurationInMinutes();
    final totalCreditMinutes = controller.employeeData.value?.vacationCredit ?? 0;
    final int usedMinutes = controller.myVacationRequests
        .where((v) =>
            v.vacationType == AppConstants.annualLeave &&
            v.status == 'pending')
        .fold(0, (sum, v) => sum + v.totalMinutes);
    final remainingMinutes = totalCreditMinutes - usedMinutes;

    final selectedType = AppConstants.annualLeave.obs;
    final vacationTypes = AppConstants.getVacationTypes();

    final reasonController = TextEditingController(
        text: isAbsent
            ? 'إجازة ليوم غياب بتاريخ ${att.date}'
            : 'تغطية تأخير/خروج مبكر بتاريخ ${att.date}');
    final RxBool isLoading = false.obs;
    final Rx<PlatformFile?> selectedAttachmentFile = Rx<PlatformFile?>(null);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: Responsive.isMobile(context) ? 16 : 32, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.isDesktop(context) ? 450 : 400,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pro Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                      ),
                      child: Icon(isAbsent ? Icons.event_busy_rounded : Icons.beach_access_rounded, color: AppTheme.primaryTeal, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAbsent ? 'طلب إجازة ليوم غياب' : 'تغطية تأخير أو خروج مبكر', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
                          Text(isAbsent ? 'تقديم طلب إجازة ليوم كامل' : 'تطبيق إجازة لتعويض الدقائق المفقودة', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                      style: IconButton.styleFrom(backgroundColor: Colors.white),
                    ),
                  ],
                ),
              ),

              // Pro Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isAbsent) ...[
                        const Text('تحديد الفترات المراد تغطيتها', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                        SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.05),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 18, color: Colors.blue),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'الرجاء اختيار الفترات التي تود تغطيتها. يمكنك تحديد فترة أو أكثر لتعويضها من رصيد الإجازات بدلاً من الخصم المالي.',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.blue[800],
                                      height: 1.5,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        if (initialLateMins > 0)
                          Obx(() => _buildSelectableProTile(
                                title: 'وقت التأخير',
                                subtitle: '$initialLateMins دقيقة',
                                icon: Icons.access_time_rounded,
                                isSelected: showLate.value,
                                onTap: () => showLate.value = !showLate.value,
                              )),
                        if (initialLateMins > 0 && initialEarlyExitMins > 0) SizedBox(height: 12),
                        if (initialEarlyExitMins > 0)
                          Obx(() => _buildSelectableProTile(
                                title: 'وقت الخروج المبكر',
                                subtitle: '$initialEarlyExitMins دقيقة',
                                icon: Icons.logout_rounded,
                                isSelected: showEarly.value,
                                onTap: () => showEarly.value = !showEarly.value,
                              )),
                        SizedBox(height: 20),
                      ],
                      
                      // Total Calculation Box
                      Obx(() {
                        final bool isLateSelected = showLate.value;
                        final bool isEarlySelected = showEarly.value;
                        int total = isAbsent ? workDayMinutes : ((isLateSelected ? initialLateMins : 0) + (isEarlySelected ? initialEarlyExitMins : 0));
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isAbsent ? 'مدة الإجازة (يوم كامل):' : 'إجمالي الدقائق المستقطعة:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('$total دقيقة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primaryTeal)),
                              ),
                            ],
                          ),
                        );
                      }),
                      
                      SizedBox(height: 24),
                      const Text('نوع الإجازة التعويضية', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                      SizedBox(height: 12),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                               color: Colors.white,
                               border: Border.all(color: AppTheme.borderLight),
                               borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedType.value,
                                isExpanded: true,
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                                items: vacationTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: TextStyle(fontWeight: FontWeight.bold)))).toList(),
                                onChanged: (v) => selectedType.value = v!,
                              ),
                            ),
                          )),

                      SizedBox(height: 12),
                      // Credit Status Info Alert
                      Obx(() => selectedType.value == AppConstants.annualLeave
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 20, color: AppTheme.primaryTeal),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'رصيد إجازاتك المتاح حالياً: ${UiUtils.formatDaysApproximate(remainingMinutes / workDayMinutes)} (${UiUtils.formatDuration(remainingMinutes)})',
                                      style: TextStyle(fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 20, color: Colors.orange),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'ملاحظة: هذا النوع من الإجازات لا يخصم من رصيد الإجازات السنوية، ويتطلب موافقة الإدارة.',
                                      style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            
                      SizedBox(height: 24),
                      const Text('السبب / الملاحظات (اختياري)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                      SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'أضف ملاحظة توضيحية...',
                          hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderLight)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderLight)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primaryTeal)),
                          filled: true,
                          fillColor: AppTheme.backgroundLight,
                        ),
                      ),
                      SizedBox(height: 16),
                      const Text('المرفقات (اختياري)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                      SizedBox(height: 12),
                      Obx(() => Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Column(
                              children: [
                                if (selectedAttachmentFile.value == null)
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                                        withData: kIsWeb,
                                      );
                                      if (result != null) {
                                        selectedAttachmentFile.value = result.files.single;
                                      }
                                    },
                                    icon: Icon(Icons.upload_file_rounded, size: 18),
                                    label: const Text('اختيار ملف أو صورة', style: TextStyle(fontSize: 12)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppTheme.primaryTeal,
                                      elevation: 0,
                                      side: BorderSide(color: AppTheme.primaryTeal),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: const Size(0, 40),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selectedAttachmentFile.value!.name,
                                          style: TextStyle(fontSize: 11, overflow: TextOverflow.ellipsis),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => selectedAttachmentFile.value = null,
                                        icon: Icon(Icons.cancel_outlined, color: AppTheme.errorRed, size: 18),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              // Action Buttons Bottom
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Obx(() {
                        int currentTotal = isAbsent ? workDayMinutes : ((showLate.value ? initialLateMins : 0) + (showEarly.value ? initialEarlyExitMins : 0));
                        bool hasEnoughCredit = selectedType.value != AppConstants.annualLeave || (totalCreditMinutes >= currentTotal);
                        bool canSubmit = currentTotal > 0 && hasEnoughCredit;

                        return ElevatedButton(
                          onPressed: isLoading.value || !canSubmit
                              ? null
                              : () async {
                                  // Validate if day has both check-in and check-out
                                  final targetAtt = controller.myAttendance.firstWhereOrNull((a) => a.date == att.date);
                                  if (targetAtt != null && (targetAtt.checkIn ?? '').isNotEmpty && (targetAtt.checkOut ?? '').isNotEmpty && isAbsent) {
                                    UiUtils.showErrorDialog('تنبيه', 'لا يمكنك طلب إجازة يوم كامل في يوم قمت بالبصمة فيه.');
                                    return;
                                  }

                                  String tag = "";
                                  if (!isAbsent) {
                                      if (showLate.value && showEarly.value) {
                                          tag = "[COVER_BOTH]";
                                      } else if (showLate.value) {
                                          tag = "[COVER_LATE]";
                                      } else if (showEarly.value) {
                                          tag = "[COVER_EARLY]";
                                      }
                                  }

                                  isLoading.value = true;
                                  final res = await controller.requestVacation(
                                    att.date,
                                    att.date,
                                    isAbsent ? 1 : 0, // days
                                    selectedType.value,
                                    isHourly: !isAbsent,
                                    totalMinutes: currentTotal,
                                    startTime: '',
                                    endTime: '',
                                    reason: '${reasonController.text} $tag',
                                    attachmentFile: selectedAttachmentFile.value,
                                  );
                                  isLoading.value = false;
                                  if (res == true) {
                                    Get.back();
                                    UiUtils.showSuccessDialog('تم التغطية بنجاح', 'تم تقديم طلب الإجازة واحتساب الدقائق المطلوبة.');
                                  } else {
                                    UiUtils.showErrorDialog('خطأ', res.toString());
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: isLoading.value
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('اعتماد التغطية', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        );
                      }),
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

  void _showAttendanceDetailsDialog(BuildContext context, AttendanceModel att) {
    final dateObj = DateTime.parse(att.date);
    final dayName = _getDayNameArabic(dateObj);
    final controller = Get.find<EmployeeController>();
    final approvedOvertime = controller.myOvertimeRequests
        .where((req) => req.date == att.date && req.status == 'approved')
        .toList();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: Responsive.isMobile(context) ? 16 : 32, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.isDesktop(context) ? 450 : 400,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pro Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                      ),
                      child: Icon(Icons.calendar_today_rounded, color: AppTheme.primaryTeal, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تفاصيل يوم $dayName', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
                          Text(att.date, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                      style: IconButton.styleFrom(backgroundColor: Colors.white),
                    ),
                  ],
                ),
              ),

              // Pro Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Section
                      _buildDetailRow('الحالة', _getStatusText(att)),
                      const Divider(height: 24),

                      // Times Section
                      if (att.status != 'absent' && att.status != 'pending') ...[
                        Row(
                          children: [
                            Expanded(child: _buildProTimeBox('وقت الدخول', _formatTime(att.checkIn), Icons.login_rounded, AppTheme.primaryTeal, isCorrected: att.isCheckInCorrected)),
                            SizedBox(width: 16),
                            Expanded(child: _buildProTimeBox('وقت الخروج', _formatTime(att.checkOut), Icons.logout_rounded, AppTheme.primaryTeal, isCorrected: att.isCheckOutCorrected)),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (att.lateMinutes > 0)
                          _buildDetailRow('التأخير', '${att.lateMinutes} دقيقة', color: Colors.orange),
                        if (att.earlyExitMinutes > 0)
                          _buildDetailRow('خروج مبكر', '${att.earlyExitMinutes} دقيقة', color: Colors.orange),
                        const Divider(height: 24),
                      ],

                      // Financial Section
                      const Text('التفاصيل المالية:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      SizedBox(height: 12),
                      if (att.lateDiscount > 0)
                        _buildDetailRow('خصم التأخير', '${att.lateDiscount.toStringAsFixed(2)} ر.س', color: Colors.orange),
                      if (att.earlyExitDiscount > 0)
                        _buildDetailRow('خصم الخروج مبكر', '${att.earlyExitDiscount.toStringAsFixed(2)} ر.س', color: Colors.orange),
                      if (att.status == 'absent' && !controller.isDayApprovedVacation(att.date))
                        _buildDetailRow('خصم الغياب', '${att.discount.toStringAsFixed(2)} ر.س', color: AppTheme.errorRed),

                      _buildDetailRow('إجمالي الخصم', '${att.discount.toStringAsFixed(2)} ر.س',
                          isBold: true,
                          color: att.discount > 0 ? AppTheme.errorRed : AppTheme.successGreen),

                      if (approvedOvertime.isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text('تفاصيل العمل الإضافي:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        SizedBox(height: 12),
                        ...approvedOvertime.map((req) {
                          final amount = req.totalMinutes * ((controller.employeeData.value?.salary ?? 0.0) / controller.daysInMonth / 480);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.08)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: AppTheme.primaryTeal.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: Icon(Icons.more_time_rounded, size: 18, color: AppTheme.primaryTeal),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('فترة العمل الإضافي', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                          Text('${_formatTime(req.startTime)} - ${_formatTime(req.endTime)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: AppTheme.successGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                      child: Text('+ ${amount.toStringAsFixed(2)} ر.س', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.successGreen)),
                                    ),
                                  ],
                                ),
                                if (req.reason != null && req.reason!.isNotEmpty) ...[
                                  SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textSecondary),
                                        SizedBox(width: 8),
                                        Expanded(child: Text(req.reason!.replaceAll(RegExp(r'\[COVER_(LATE|EARLY|BOTH)\]'), '').trim(), style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3))),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Spacer(),
                                    Icon(Icons.timer_outlined, size: 14, color: AppTheme.primaryTeal.withValues(alpha: 0.6)),
                                    SizedBox(width: 4),
                                    Text('المدة: ${UiUtils.formatDuration(req.totalMinutes)}', style: TextStyle(fontSize: 11, color: AppTheme.primaryTeal.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Notes Section
                      if (att.notes != null && att.notes!.isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text('ملاحظات:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(12)),
                          child: Text(att.notes!, style: TextStyle(fontSize: 13, height: 1.4)),
                        ),
                      ],

                      // Correction Details
                      Builder(builder: (context) {
                        final approvedCorrections = controller.myCorrectionRequests.where((c) => c.date == att.date && c.status == 'approved').toList();
                        if (approvedCorrections.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 24),
                            const Text('تصحيحات البصمة المعتمدة:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            SizedBox(height: 12),
                            ...approvedCorrections.map((c) {
                              String typeText = c.type == 'check_in' || c.type == 'missing_check_in' ? 'بصمة دخول' : 'بصمة خروج';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(typeText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purple)),
                                        if (c.reason.isNotEmpty)
                                          Text('السبب: ${c.reason}', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                    Text(_formatTime(c.requestedTime), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.purple)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        );
                      }),

                      // Correction Status (Pending)
                      if (att.isPendingCorrection) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_empty_rounded, size: 16, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(child: Text('يوجد طلب تصحيح قيد الانتظار لهذا اليوم', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إغلاق', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      ),
                    ),
                    if (att.status == 'absent' &&
                        !att.isPendingCorrection &&
                        !controller.isDayApprovedVacation(att.date) &&
                        (att.checkIn == null || att.checkIn!.isEmpty || att.checkOut == null || att.checkOut!.isEmpty)) ...[
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            _showCoverWithVacationDialog(context, att, isAbsent: true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: Icon(Icons.beach_access_rounded, size: 18),
                          label: const Text('طلب إجازة', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                    if ((att.lateMinutes > 0 || att.earlyExitMinutes > 0) &&
                        !att.isPendingCorrection) ...[
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            _showCoverWithVacationDialog(context, att);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: Icon(Icons.beach_access_rounded, size: 18),
                          label: const Text('تغطية بإجازة', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? color, bool isCorrected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCorrected)
                Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.edit_note_rounded,
                      size: 16, color: AppTheme.primaryTeal),
                ),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                      color: color ?? AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusText(AttendanceModel att) {
    final controller = Get.find<EmployeeController>();
    if (controller.isDayApprovedVacation(att.date)) return 'إجازة مقبولة';
    if (att.isPendingCorrection) return 'قيد التصحيح';

    String text = '';
    final status = att.status.toLowerCase();
    switch (status) {
      case 'present':
        text = 'حاضر';
        break;
      case 'late':
        text = 'متأخر';
        break;
      case 'absent':
        text = 'غائب';
        break;
      case 'incomplete':
        text = 'غير مكتمل';
        break;
      case 'early_exit':
        text = 'خروج مبكر';
        break;
      case 'holiday':
        text = 'إجازة رسمية';
        break;
      case 'vacation':
        text = 'إجازة';
        break;
      case 'off':
        text = '-';
        break;
      case 'pending':
        text = 'قادم';
        break;
      default:
        text = att.status;
    }
    if (att.earlyExitMinutes > 0 && (status == 'present' || status == 'late')) {
      text += ' (خروج مبكر)';
    }
    return text;
  }
}
