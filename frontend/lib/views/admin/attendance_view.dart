import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final ScrollController _scrollController = ScrollController();
  final RxBool _showBackToTop = false.obs;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 400) {
        _showBackToTop.value = true;
      } else {
        _showBackToTop.value = false;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Responsive.isMobile(context)
            ? Obx(() => _showBackToTop.value
                ? FloatingActionButton(
                    onPressed: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                    mini: true,
                    backgroundColor: AppTheme.primaryTeal,
                    child: Icon(Icons.arrow_upward_rounded,
                        color: Colors.white),
                  )
                : const SizedBox.shrink())
            : null,
        body: Padding(
          padding: EdgeInsets.all(UiUtils.getPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildFilterDropdowns(controller),
                      if (!Responsive.isMobile(context)) ...[
                        Obx(() => controller.isLoading.value
                            ? SizedBox(
                                width: 40,
                                height: 40,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryTeal),
                                ),
                              )
                            : IconButton(
                                onPressed: () => controller.fetchAttendance(),
                                icon: Icon(Icons.refresh_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                      color: AppTheme.borderLight),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              )),
                      ],
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => await controller.fetchAttendance(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Obx(() {
                      if (controller.filteredAttendance.isEmpty) {
                        return ListView(
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.25),
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_rounded,
                                      size: 64, color: AppTheme.textSecondary),
                                  SizedBox(height: 16),
                                  Text('لا توجد بيانات حضور لهذا الشهر',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      // Group data by date
                      Map<String, List<AttendanceModel>> grouped = {};
                      for (var att in controller.filteredAttendance) {
                        grouped.putIfAbsent(att.date, () => []).add(att);
                      }
                      final sortedDates = grouped.keys.toList()
                        ..sort((a, b) => b.compareTo(a));

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                            horizontal: Responsive.isMobile(context) ? 6 : 24,
                            vertical: 24),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, dateIndex) {
                          final dateStr = sortedDates[dateIndex];
                          final dayItems = grouped[dateStr]!;
                          final dateObj = DateTime.parse(dateStr);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDateSectionHeader(context, dateObj),
                              SizedBox(height: 16),
                              if (Responsive.isMobile(context))
                                ...dayItems.map((att) {
                                  final emp = controller
                                      .getEmployeeById(att.employeeId);
                                  final holiday =
                                      controller.getHolidayForDate(att.date);
                                  final effectiveStatus =
                                      att.status;
                                  final effectiveLate = controller
                                      .getEffectiveLateMinutes(att, emp);
                                  return _buildMobileTile(
                                      att,
                                      emp,
                                      effectiveStatus,
                                      effectiveLate,
                                      holiday,
                                      controller,
                                      context);
                                })
                              else
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        Responsive.isDesktop(context) ? 4 : 2,
                                    mainAxisExtent: 200,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: dayItems.length,
                                  itemBuilder: (context, i) {
                                    final att = dayItems[i];
                                    final emp = controller
                                        .getEmployeeById(att.employeeId);
                                    final holiday =
                                        controller.getHolidayForDate(att.date);
                                    final effectiveStatus =
                                        att.status;
                                    final effectiveLate = controller
                                        .getEffectiveLateMinutes(att, emp);
                                    return _buildRecordCard(
                                        att,
                                        emp,
                                        effectiveStatus,
                                        effectiveLate,
                                        holiday,
                                        controller,
                                        context);
                                  },
                                ),
                              SizedBox(height: 32),
                            ],
                          );
                        },
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildMobileTile(
      AttendanceModel att,
      EmployeeModel? emp,
      String effectiveStatus,
      int effectiveLate,
      HolidayModel? holiday,
      AdminController controller,
      BuildContext context) {
    final dateObj = DateTime.parse(att.date);
    final dayName = _getDayNameArabic(dateObj);
    final isHoliday = holiday != null;
    final hasVacation = effectiveStatus == 'vacation';

    Color statusColor;
    if (isHoliday || hasVacation) {
      statusColor = AppTheme.primaryTeal;
    } else {
      switch (effectiveStatus) {
        case 'present':
          statusColor = AppTheme.successGreen;
          break;
        case 'late':
          statusColor = Colors.orange;
          break;
        case 'absent':
          statusColor = AppTheme.errorRed;
          break;
        default:
          statusColor = AppTheme.textSecondary;
      }
    }

    return InkWell(
      onTap: att.status == 'pending'
          ? null
          : () {
              _showRecordDetailsDialog(context, controller, att,
                  effectiveStatus, effectiveLate, holiday);
            },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: statusColor, width: 5),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
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
                // Header: Name and Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        emp?.name ?? att.employeeName ?? 'موظف مجهول',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppTheme.textPrimary),
                      ),
                    ),
                    _buildStatusIndicator(
                      effectiveStatus,
                      hasVacation,
                      lateMinutes: effectiveLate,
                      earlyExitMinutes: att.earlyExitMinutes,
                      holidayName: holiday?.name,
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Date Row
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppTheme.textSecondary),
                    SizedBox(width: 6),
                    Text('$dayName ${att.date}',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                SizedBox(height: 16),

                // Time Section (Horizontal Container)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                            AppTheme.successGreen),
                      ),
                      Container(
                          width: 1, height: 20, color: AppTheme.borderLight),
                      Expanded(
                        child: _buildCompactTime(
                            'خروج',
                            _formatTime(att.checkOut),
                            Icons.logout_rounded,
                            AppTheme.errorRed),
                      ),
                    ],
                  ),
                ),

                // Critical Alerts / Info
                if (att.earlyExitMinutes > 0 ||
                    effectiveLate > 0 ||
                    (effectiveStatus == 'absent' &&
                        !hasVacation &&
                        !isHoliday) ||
                    att.overtimeMinutes > 0 ||
                    controller.correctionRequests.any((c) =>
                        c.date == att.date &&
                        c.employeeId == att.employeeId &&
                        c.status == 'approved')) ...[
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (att.earlyExitMinutes > 0)
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
                          !hasVacation &&
                          !isHoliday)
                        _buildAlertChip(
                            'خصم غياب (${((att.salary > 0 ? att.salary : emp!.salary) / controller.daysInMonth).toStringAsFixed(2)} ر.س)',
                            Icons.money_off_csred_rounded,
                            AppTheme.errorRed),
                      if (att.overtimeMinutes > 0)
                        _buildAlertChip(
                            'إضافي ${UiUtils.formatDuration(att.overtimeMinutes)}',
                            Icons.more_time_rounded,
                            AppTheme.primaryTeal),
                      if (controller.correctionRequests.any((c) =>
                          c.date == att.date &&
                          c.employeeId == att.employeeId &&
                          c.status == 'approved'))
                        Builder(builder: (context) {
                          final approvedCorr = controller.correctionRequests
                              .where((c) =>
                                  c.date == att.date &&
                                  c.employeeId == att.employeeId &&
                                  c.status == 'approved')
                              .toList();
                          final details = approvedCorr
                              .map((c) =>
                                  '${c.type == 'check_in' || c.type == 'missing_check_in' ? 'دخول' : 'خروج'}: ${_formatTime(c.requestedTime)}')
                              .join(' | ');
                          return _buildAlertChip('تم تصحيح بصمات ($details)',
                              Icons.edit_calendar_rounded, Colors.purple);
                        }),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTime(
      String label, String time, IconData icon, Color color) {
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
        Text(time,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
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

  Widget _buildRecordCard(
      AttendanceModel att,
      EmployeeModel? emp,
      String effectiveStatus,
      int effectiveLate,
      HolidayModel? holiday,
      AdminController controller,
      BuildContext context) {
    Color color;
    String statusText;
    bool isHoliday = holiday != null;
    bool hasVacation = effectiveStatus == 'vacation';

    if (isHoliday) {
      color = AppTheme.primaryTeal;
      statusText = holiday.name;
    } else if (hasVacation) {
      color = Colors.teal;
      statusText = 'إجازة معتمدة';
    } else {
      color = _getStatusColor(effectiveStatus);
      statusText = _getStatusText(effectiveStatus, (att.earlyExitMinutes) > 0);
    }

    return InkWell(
      onTap: () {
        _showRecordDetailsDialog(
            context, controller, att, effectiveStatus, effectiveLate, holiday);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(emp?.name ?? att.employeeName ?? 'مجهول',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(statusText,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('${_getDayNameArabic(DateTime.parse(att.date))} ${att.date}',
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildTimeBadge('دخول', _formatTime(att.checkIn))),
              SizedBox(width: 8),
              Expanded(
                  child: _buildTimeBadge('خروج', _formatTime(att.checkOut))),
            ],
          ),
          if (effectiveStatus == 'absent' && !hasVacation && !isHoliday) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.money_off_csred_rounded,
                    size: 14, color: AppTheme.errorRed),
                SizedBox(width: 4),
                const Text('خصم غياب',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                    '- ${(att.salary / controller.daysInMonth).toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                Icon(Icons.touch_app_rounded,
                    size: 14, color: AppTheme.textSecondary),
                SizedBox(width: 4),
                Text('اضغط لتحويلها لإجازة',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ],
          if (att.earlyExitMinutes > 0) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.logout_rounded,
                    size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                    'خصم الخروج المبكر (${att.earlyExitMinutes} دقيقة)',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                    '- ${att.earlyExitDiscount.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          if (effectiveLate > 0) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Text('خصم التأخير ($effectiveLate دقيقة)',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                    '- ${att.lateDiscount.toStringAsFixed(2)} ر.س',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          if (att.overtimeMinutes > 0) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.more_time_rounded,
                    size: 14, color: AppTheme.primaryTeal),
                SizedBox(width: 4),
                Text(
                    'إضافي معتمد ${UiUtils.formatDuration(att.overtimeMinutes)}',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          if (controller.correctionRequests.any((c) =>
              c.date == att.date &&
              c.employeeId == att.employeeId &&
              c.status == 'approved')) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.edit_calendar_rounded,
                    size: 14, color: Colors.purple),
                SizedBox(width: 4),
                Builder(builder: (context) {
                  final approvedCorr = controller.correctionRequests
                      .where((c) =>
                          c.date == att.date &&
                          c.employeeId == att.employeeId &&
                          c.status == 'approved')
                      .toList();
                  final details = approvedCorr
                      .map((c) =>
                          '${c.type == 'check_in' || c.type == 'missing_check_in' ? 'دخول' : 'خروج'}: ${_formatTime(c.requestedTime)}')
                      .join(' | ');
                  return Text('تم إجراء تصحيح بصمات ($details)',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.purple,
                          fontWeight: FontWeight.bold));
                }),
              ],
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildFilterDropdowns(AdminController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Obx(() => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDropdown<int>(
                value: controller.selectedMonth.value,
                items: List.generate(12, (i) => i + 1),
                onChanged: (v) => controller.selectedMonth.value = v!,
                itemLabel: (v) => _getMonthNameArabic(v),
              ),
              const VerticalDivider(width: 20, indent: 10, endIndent: 10),
              _buildDropdown<int>(
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
          fontFamily: 'Janat',
          fontWeight: FontWeight.w600,
          fontSize: 13),
    );
  }

  Widget _buildDateSectionHeader(BuildContext context, DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded,
              size: 18, color: AppTheme.primaryTeal),
          SizedBox(width: 8),
          Text(
            '${_getDayNameArabic(date)} ${DateFormat('yyyy-MM-dd').format(date)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTeal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status, bool hasApprovedVacation,
      {String? holidayName, int lateMinutes = 0, int earlyExitMinutes = 0}) {
    Color color;
    String text;
    if (status == 'holiday') {
      color = AppTheme.primaryTeal;
      text = holidayName ?? 'إجازة رسمية';
    } else if (status == 'vacation') {
      color = AppTheme.primaryTeal;
      text = 'إجازة معتمدة';
    } else {
      bool isLate = (lateMinutes > 0);
      bool isEarly = (earlyExitMinutes > 0);

      if (isLate && isEarly) {
        color = Colors.orange;
        text = 'تأخير وخروج مبكر';
      } else if (isEarly) {
        color = Colors.orange;
        text = 'خروج مبكر';
      } else if (isLate) {
        color = Colors.orange;
        text = 'متأخر';
      } else {
        switch (status) {
          case 'present':
            color = AppTheme.successGreen;
            text = 'حاضر';
            break;
          case 'absent':
            color = AppTheme.errorRed;
            text = 'غائب';
            break;
          case 'incomplete':
            color = AppTheme.primaryTeal;
            text = 'غير مكتمل';
            break;
          default:
            color = AppTheme.textSecondary;
            text = status;
        }
      }
    }
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }

  String _getDayNameArabic(DateTime date) {
    const days = [
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    return days[date.weekday % 7];
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

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '--:--';
    try {
      String timePart = dateTimeStr;
      if (dateTimeStr.contains(' ')) {
        timePart = dateTimeStr.split(' ')[1];
      }
      final time = DateFormat('HH:mm:ss').parse(timePart);
      return DateFormat('hh:mm a', 'en').format(time);
    } catch (e) {
      return '--:--';
    }
  }

  Widget _buildTimeBadge(String label, String? time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9EB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold)),
          Text(time ?? '--:--',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }



  void _showAddVacationOverrideDialog(
      BuildContext context, AdminController controller, AttendanceModel att) {
    if (controller.hasPendingVacation(att.employeeId, att.date)) {
      UiUtils.showErrorDialog(
        'طلب إجازة معلق',
        'يوجد طلب إجازة قيد الانتظار لهذا الموظف في هذا اليوم. يرجى مراجعته من شاشة طلبات الإجازة أولاً.',
      );
      return;
    }
    
    final employee = controller.getEmployeeById(att.employeeId);
    final credit = employee?.vacationCredit ?? 0;

    final selectedType =
        (credit > 0 ? AppConstants.annualLeave : AppConstants.businessMission)
            .obs;
    final types = AppConstants.getVacationTypes();

    final Rx<PlatformFile?> selectedAttachmentFile = Rx<PlatformFile?>(null);

    Get.dialog(
      AlertDialog(
        title: Text('تحويل غياب "${att.employeeName}" لإجازة'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('التاريخ: ${att.date}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                const Text('اختر نوع الإجازة:', style: TextStyle(fontSize: 13)),
                SizedBox(height: 12),
                Obx(() {
                  String creditStr = '${UiUtils.formatDaysApproximate(credit / controller.getSystemWorkDayDurationInMinutes())} (${UiUtils.formatDuration(credit)})';

                  return Column(
                    children: types.map((type) {
                      bool isDisabled = false;
                      String title = type;
                      if (type == AppConstants.annualLeave) {
                        title = '$type (الرصيد: $creditStr)';
                        if (credit <= 0) isDisabled = true;
                      }

                      return RadioListTile<String>(
                        title: Text(title,
                            style: TextStyle(
                                color: isDisabled
                                    ? AppTheme.textSecondary
                                        .withValues(alpha: 0.5)
                                    : AppTheme.textPrimary,
                                fontSize: 14)),
                        value: type,
                        groupValue: selectedType.value,
                        activeColor: AppTheme.primaryTeal,
                        onChanged:
                            isDisabled ? null : (v) => selectedType.value = v!,
                      );
                    }).toList(),
                  );
                }),
                SizedBox(height: 16),
                const Divider(),
                SizedBox(height: 8),
                const Text('المرفقات (اختياري للمدير)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary)),
                SizedBox(height: 8),
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
                                FilePickerResult? result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: [
                                    'jpg',
                                    'jpeg',
                                    'png',
                                    'pdf'
                                  ],
                                  withData: kIsWeb,
                                );
                                if (result != null) {
                                  selectedAttachmentFile.value =
                                      result.files.single;
                                }
                              },
                              icon: Icon(Icons.upload_file_rounded,
                                  size: 18),
                              label: const Text('اختيار ملف أو صورة',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryTeal,
                                elevation: 0,
                                side: BorderSide(
                                    color: AppTheme.primaryTeal),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                minimumSize: const Size(0, 40),
                              ),
                            )
                          else
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: AppTheme.successGreen, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedAttachmentFile.value!.name,
                                    style: TextStyle(
                                        fontSize: 11,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      selectedAttachmentFile.value = null,
                                  icon: Icon(Icons.cancel_outlined,
                                      color: AppTheme.errorRed, size: 18),
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
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Get.back(), child: const Text('إلغاء')),
              SizedBox(width: 8),
              Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            final request = VacationRequestModel(
                              employeeId: att.employeeId,
                              startDate: att.date,
                              endDate: att.date,
                              totalDays: 1,
                              status: 'approved',
                              vacationType: selectedType.value,
                            );
                            final errorMsg = await controller.addVacationRequestWithReason(
                              request,
                              attachmentFile: selectedAttachmentFile.value,
                            );
                            if (errorMsg == null) {
                              Get.back();
                              UiUtils.showSuccessDialog('تم بنجاح',
                                  'تم تحويل يوم الغياب إلى ${selectedType.value}');
                              controller.fetchAttendance();
                            } else {
                              if (errorMsg is Map && errorMsg['error_type'] == 'limit_exceeded_with_remaining' && errorMsg['remaining_minutes'] != null) {
                                int remaining = int.tryParse(errorMsg['remaining_minutes'].toString()) ?? 0;
                                if (remaining > 0) {
                                  Get.defaultDialog(
                                    title: 'تجاوز الحد المسموح',
                                    middleText: '${errorMsg['message']}\n\nهل تود عمل طلب إجازة بالوقت المتبقي فقط؟',
                                    textConfirm: 'نعم',
                                    textCancel: 'لا',
                                    confirmTextColor: Colors.white,
                                    onConfirm: () async {
                                      Get.back();
                                      request.totalMinutes = remaining;
                                      request.isHourly = true;
                                      request.totalDays = 0;
                                      final retryRes = await controller.addVacationRequestWithReason(request, attachmentFile: selectedAttachmentFile.value);
                                      if (retryRes == null) {
                                          Get.back();
                                          UiUtils.showSuccessDialog('تم بنجاح', 'تم تحويل يوم الغياب إلى ${selectedType.value} بالوقت المتبقي');
                                          controller.fetchAttendance();
                                      } else {
                                          String msg = retryRes is Map ? (retryRes['message']?.toString() ?? 'خطأ') : retryRes.toString();
                                          UiUtils.showErrorDialog('تعذر حفظ الإجازة', msg);
                                      }
                                    }
                                  );
                                } else {
                                  String msg = errorMsg['message']?.toString() ?? 'خطأ';
                                  UiUtils.showErrorDialog('تعذر حفظ الإجازة', msg);
                                }
                              } else {
                                String msg = errorMsg is Map ? (errorMsg['message']?.toString() ?? 'خطأ') : errorMsg.toString();
                                UiUtils.showErrorDialog('تعذر حفظ الإجازة', msg);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 45)),
                    child: controller.isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('حفظ الإجازة'),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  void _showCoverWithVacationDialog(BuildContext context, AdminController controller, AttendanceModel att, EmployeeModel employee) {
    if (controller.hasPendingVacation(att.employeeId, att.date)) {
      UiUtils.showErrorDialog(
        'طلب إجازة معلق',
        'يوجد طلب إجازة قيد الانتظار لهذا الموظف في هذا اليوم. يرجى مراجعته من شاشة طلبات الإجازة أولاً.',
      );
      return;
    }

    int initialLateMins = controller.getEffectiveLateMinutes(att, employee);
    int initialEarlyExitMins = controller.getEarlyExitMinutes(att, employee);

    final showLate = (initialLateMins > 0).obs;
    final showEarly = (initialEarlyExitMins > 0).obs;
    final totalCreditMinutes = employee.vacationCredit;
    final selectedType = AppConstants.annualLeave.obs;
    final vacationTypes = AppConstants.getVacationTypes();
    final reasonController = TextEditingController(text: 'تغطية تأخير/خروج مبكر بتاريخ ${att.date} من قبل الإدارة');
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
                      child: Icon(Icons.beach_access_rounded, color: AppTheme.primaryTeal, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تغطية تأخير أو خروج مبكر', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
                          Text('تطبيق إجازة لتعويض الدقائق المفقودة', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
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
                      const Text('تحديد الفترات المراد تغطيتها', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                      SizedBox(height: 12),
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
                      
                      // Total Calculation Box
                      Obx(() {
                        int total = (showLate.value ? initialLateMins : 0) + (showEarly.value ? initialEarlyExitMins : 0);
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
                              Text('إجمالي الدقائق المستقطعة:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
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
                                      'رصيد إجازات الموظف المتاح حالياً: ${UiUtils.formatDaysApproximate(employee.vacationCredit / controller.getSystemWorkDayDurationInMinutes())} (${UiUtils.formatDuration(employee.vacationCredit)})',
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
                                      'ملاحظة: هذا النوع من الإجازات لا يخصم من رصيد الإجازات السنوية للموظف.',
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
                          hintText: 'أضف ملاحظة توضيحية للإدارة...',
                          hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderLight)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderLight)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primaryTeal)),
                          filled: true,
                          fillColor: AppTheme.backgroundLight,
                        ),
                      ),
                      SizedBox(height: 16),
                      const Text('المرفقات (اختياري للمدير)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
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
                        int currentTotal = (showLate.value ? initialLateMins : 0) + (showEarly.value ? initialEarlyExitMins : 0);
                        bool hasEnoughCredit = selectedType.value != AppConstants.annualLeave || (totalCreditMinutes >= currentTotal);
                        bool canSubmit = currentTotal > 0 && hasEnoughCredit;

                        return ElevatedButton(
                          onPressed: controller.isLoading.value || !canSubmit
                              ? null
                              : () async {
                                  String tag = "";
                                  if (showLate.value && showEarly.value) {
                                      tag = "[COVER_BOTH]";
                                  } else if (showLate.value) {
                                      tag = "[COVER_LATE]";
                                  } else if (showEarly.value) {
                                      tag = "[COVER_EARLY]";
                                  }

                                  final request = VacationRequestModel(
                                    employeeId: att.employeeId,
                                    startDate: att.date,
                                    endDate: att.date,
                                    totalDays: 0,
                                    totalMinutes: currentTotal,
                                    status: 'approved',
                                    vacationType: selectedType.value,
                                    reason: '${reasonController.text} $tag',
                                    isHourly: true,
                                    startTime: '',
                                    endTime: '',
                                  );
                                  final errorMsg = await controller.addVacationRequestWithReason(request, attachmentFile: selectedAttachmentFile.value);
                                  if (errorMsg == null) {
                                    Get.back();
                                    UiUtils.showSuccessDialog('تم التغطية بنجاح', 'تم تطبيق الإجازة واحتساب الدقائق المطلوبة.');
                                    controller.fetchAttendance();
                                  } else {
                                    if (errorMsg is Map && errorMsg['error_type'] == 'limit_exceeded_with_remaining' && errorMsg['remaining_minutes'] != null) {
                                      int remaining = int.tryParse(errorMsg['remaining_minutes'].toString()) ?? 0;
                                      if (remaining > 0) {
                                        Get.defaultDialog(
                                          title: 'تجاوز الحد المسموح',
                                          middleText: '${errorMsg['message']}\n\nهل تود عمل طلب إجازة بالوقت المتبقي فقط؟',
                                          textConfirm: 'نعم',
                                          textCancel: 'لا',
                                          confirmTextColor: Colors.white,
                                          onConfirm: () async {
                                            Get.back();
                                            request.totalMinutes = remaining;
                                            request.isHourly = true;
                                            request.totalDays = 0;
                                            final retryRes = await controller.addVacationRequestWithReason(request, attachmentFile: selectedAttachmentFile.value);
                                            if (retryRes == null) {
                                              Get.back();
                                              UiUtils.showSuccessDialog('تم التغطية بنجاح', 'تم تطبيق الإجازة واحتساب الدقائق المتبقية فقط.');
                                              controller.fetchAttendance();
                                          } else {
                                              String msg = retryRes is Map ? (retryRes['message']?.toString() ?? 'خطأ') : retryRes.toString();
                                              UiUtils.showErrorDialog('تعذر حفظ التغطية', msg);
                                          }
                                        }
                                      );
                                    } else {
                                      String msg = errorMsg['message']?.toString() ?? 'خطأ';
                                      UiUtils.showErrorDialog('تعذر حفظ التغطية', msg);
                                    }
                                  } else {
                                    String msg = errorMsg is Map ? (errorMsg['message']?.toString() ?? 'خطأ') : errorMsg.toString();
                                    UiUtils.showErrorDialog('خطأ', msg);
                                  }
                                }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: controller.isLoading.value
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

  Widget _buildSelectableProTile({required String title, required String subtitle, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryTeal.withValues(alpha: 0.05) : Colors.white,
          border: Border.all(color: isSelected ? AppTheme.primaryTeal : AppTheme.borderLight, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryTeal : AppTheme.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: isSelected ? Colors.white : AppTheme.textSecondary),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isSelected ? AppTheme.primaryTeal : AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isSelected ? AppTheme.primaryTeal : AppTheme.borderLight),
          ],
        ),
      ),
    );
  }

  void _showRecordDetailsDialog(
      BuildContext context,
      AdminController controller,
      AttendanceModel att,
      String effectiveStatus,
      int effectiveLate,
      HolidayModel? holiday) {
    final emp = controller.getEmployeeById(att.employeeId);
    final hasVacation = effectiveStatus == 'vacation';
    final isHoliday = holiday != null;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: Responsive.isMobile(context) ? 16 : 32, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.isDesktop(context) ? 500 : 450,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom Header
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
                      child: Icon(Icons.calendar_month_rounded, color: AppTheme.primaryTeal, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تفاصيل السجل', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimary)),
                          Text(att.date, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
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

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Employee Name
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.person_rounded, size: 18, color: AppTheme.textSecondary),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الموظف', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                                Text(emp?.name ?? att.employeeName ?? "مجهول", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.textPrimary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(effectiveStatus).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getStatusColor(effectiveStatus).withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              isHoliday ? holiday.name : (hasVacation ? 'إجازة معتمدة' : _getStatusText(effectiveStatus, att.earlyExitMinutes > 0)),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: isHoliday || hasVacation ? (hasVacation ? Colors.teal : AppTheme.primaryTeal) : _getStatusColor(effectiveStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Time cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildProTimeBox('وقت الدخول', _formatTime(att.checkIn), Icons.login_rounded, AppTheme.successGreen),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildProTimeBox('وقت الخروج', _formatTime(att.checkOut), Icons.logout_rounded, AppTheme.errorRed),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Financial Details
                      Builder(builder: (context) {
                        final earlyMins = att.earlyExitMinutes;
                        final minuteRate = (att.lateDiscount > 0 && att.lateMinutes > 0) ? (att.lateDiscount / att.lateMinutes) : 0;
                        final lateDisc = effectiveLate * minuteRate;
                        final earlyDisc = earlyMins * minuteRate;
                        final absenceDisc = (effectiveStatus == 'absent' && !controller.hasApprovedVacation(att.employeeId, att.date))
                            ? (att.salary / controller.daysInMonth)
                            : 0.0;
                        final totalDisc = lateDisc + earlyDisc + absenceDisc;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: totalDisc > 0 ? AppTheme.errorRed.withValues(alpha: 0.04) : AppTheme.successGreen.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: totalDisc > 0 ? AppTheme.errorRed.withValues(alpha: 0.1) : AppTheme.successGreen.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_rounded, size: 18, color: totalDisc > 0 ? AppTheme.errorRed : AppTheme.successGreen),
                                  SizedBox(width: 8),
                                  Text('التفاصيل المالية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: totalDisc > 0 ? AppTheme.errorRed : AppTheme.successGreen)),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildInfoRow('إجمالي الخصم:', '${totalDisc.toStringAsFixed(2)} ر.س', isBold: true, color: totalDisc > 0 ? AppTheme.errorRed : AppTheme.successGreen),
                              if (lateDisc > 0) ...[ SizedBox(height: 8), _buildInfoRow('خصم التأخير:', '${lateDisc.toStringAsFixed(2)} ر.س', color: Colors.orange) ],
                              if (earlyDisc > 0) ...[ SizedBox(height: 8), _buildInfoRow('خصم خروج مبكر:', '${earlyDisc.toStringAsFixed(2)} ر.س', color: Colors.orange) ],
                              if (absenceDisc > 0) ...[ SizedBox(height: 8), _buildInfoRow('خصم غياب:', '${absenceDisc.toStringAsFixed(2)} ر.س', color: AppTheme.errorRed) ],
                            ],
                          ),
                        );
                      }),
                      SizedBox(height: 24),

                      // Overtime Details
                      Builder(builder: (context) {
                        final approvedOvertime = controller.overtimeRequests.where((req) => req.employeeId == att.employeeId && req.date == att.date && req.status == 'approved').toList();
                        if (approvedOvertime.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تفاصيل العمل الإضافي المعتمد:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            SizedBox(height: 12),
                            ...approvedOvertime.map((req) {
                              final amount = req.totalMinutes * ((emp?.salary ?? 0.0) / controller.daysInMonth / controller.getWorkDayDurationInMinutes(emp));
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.more_time_rounded, size: 20, color: AppTheme.primaryTeal),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text('${_formatTime(req.startTime)} - ${_formatTime(req.endTime)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.successGreen.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('+ ${amount.toStringAsFixed(2)} ر.س', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.successGreen)),
                                        ),
                                      ],
                                    ),
                                    if (req.reason != null && req.reason!.isNotEmpty) ...[
                                      SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.format_quote_rounded, size: 14, color: AppTheme.textSecondary),
                                            SizedBox(width: 8),
                                            Expanded(child: Text(req.reason!, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4))),
                                          ],
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              );
                            }),
                            SizedBox(height: 12),
                          ],
                        );
                      }),

                      // Corrections
                      Builder(builder: (context) {
                        final approvedCorrections = controller.correctionRequests.where((c) => c.employeeId == att.employeeId && c.date == att.date && c.status == 'approved').toList();
                        if (approvedCorrections.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تصحيحات البصمة المعتمدة:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                            SizedBox(height: 12),
                            ...approvedCorrections.map((c) {
                              String typeText = c.type == 'check_in' || c.type == 'missing_check_in' ? 'بصمة دخول' : 'بصمة خروج';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_calendar_rounded, size: 18, color: AppTheme.primaryGold),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(typeText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                                          if (c.reason.isNotEmpty) Text(c.reason, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Text(_formatTime(c.requestedTime), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryGold)),
                                  ],
                                ),
                              );
                            }),
                            SizedBox(height: 16),
                          ],
                        );
                      }),

                      // Vacations & Hourly Coverages
                      Builder(builder: (context) {
                        final targetDate = DateTime.tryParse(att.date);
                        if (targetDate == null) return const SizedBox.shrink();

                        final dayVacations = controller.vacationRequests.where((v) {
                          if (v.employeeId != att.employeeId) return false;
                          final start = DateTime.tryParse(v.startDate);
                          final end = DateTime.tryParse(v.endDate);
                          if (start == null || end == null) return false;
                          
                          if (v.isHourly || start.isAtSameMomentAs(end)) {
                            return targetDate.isAtSameMomentAs(start);
                          }
                          
                          return (targetDate.isAtSameMomentAs(start) || targetDate.isAfter(start)) &&
                                 (targetDate.isAtSameMomentAs(end) || targetDate.isBefore(end));
                        }).toList();

                        if (dayVacations.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الإجازات والتغطية المرتبطة:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14)),
                            SizedBox(height: 12),
                            ...dayVacations.map((v) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.primaryTeal.withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.beach_access_rounded,
                                            size: 18, color: AppTheme.primaryTeal),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(v.vacationType,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.primaryTeal)),
                                              if (v.reason != null && v.reason!.isNotEmpty)
                                                Text(v.reason!.replaceAll(RegExp(r'\[COVER_(LATE|EARLY|BOTH)\]'), '').trim(),
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme.textSecondary)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: v.status == 'approved' ? AppTheme.successGreen.withValues(alpha: 0.1) : 
                                                   v.status == 'rejected' ? AppTheme.errorRed.withValues(alpha: 0.1) : 
                                                   Colors.orange.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            v.status == 'approved' ? 'مقبولة' : 
                                            v.status == 'rejected' ? 'مرفوضة' : 'معلقة',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: v.status == 'approved' ? AppTheme.successGreen : 
                                                     v.status == 'rejected' ? AppTheme.errorRed : 
                                                     Colors.orange,
                                            )
                                          )
                                        )
                                      ],
                                    ),
                                    if (v.attachment != null && v.attachment!.isNotEmpty) ...[
                                      SizedBox(height: 12),
                                      InkWell(
                                        onTap: () async {
                                          final url = Uri.parse('${ApiService.baseApiUrl}/${v.attachment}');
                                          if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                          } else {
                                            UiUtils.showErrorDialog('تعذر الفتح', 'لا يمكن فتح المرفق حالياً');
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.attach_file_rounded, size: 14, color: AppTheme.primaryTeal),
                                              SizedBox(width: 4),
                                              Text('عرض المرفق', style: TextStyle(color: AppTheme.primaryTeal, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              );
                            }),
                            SizedBox(height: 16),
                          ],
                        );
                      }),

                      // Admin Notes
                      const Text('ملاحظات الإدارة:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      SizedBox(height: 12),
                      Builder(builder: (context) {
                        final noteController = TextEditingController(text: att.notes ?? '');
                        return Column(
                          children: [
                            TextField(
                              controller: noteController,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'أدخل أي ملاحظة حول الحضور هنا...',
                                hintStyle: const TextStyle(fontSize: 13),
                                fillColor: AppTheme.backgroundLight,
                                filled: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primaryTeal)),
                              ),
                            ),
                            SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () async {
                                  if (att.id == null) {
                                    UiUtils.showErrorDialog('تنبيه', 'لا يمكن إضافة ملاحظة لسجل غير مسجل في النظام');
                                    return;
                                  }
                                  final success = await controller.updateAttendanceNote(att.id!, noteController.text);
                                  if (success) {
                                    Get.back();
                                    UiUtils.showSuccessDialog('تم بنجاح', 'تم حفظ الملاحظة');
                                  } else {
                                    UiUtils.showErrorDialog('فشل', 'تعذر حفظ الملاحظة');
                                  }
                                },
                                icon: Icon(Icons.save_rounded, size: 16),
                                label: const Text('حفظ الملاحظة', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: TextButton.styleFrom(
                                  backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                                  foregroundColor: AppTheme.primaryTeal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      
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
                child: Column(
                  children: [
                    if (emp != null && (controller.getEffectiveLateMinutes(att, emp) > 0 || att.earlyExitMinutes > 0)) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            _showCoverWithVacationDialog(context, controller, att, emp);
                          },
                          icon: Icon(Icons.beach_access_rounded, size: 18),
                          label: const Text('تغطية تأخير/خروج مبكر بإجازة', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (effectiveStatus == 'absent' && !hasVacation && !isHoliday) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            _showAddVacationOverrideDialog(context, controller, att);
                          },
                          icon: Icon(Icons.beach_access_rounded, size: 18),
                          label: const Text('تحويل غياب الموظف لإجازة', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          _showAddCorrectionDialog(context, controller, att);
                        },
                        icon: Icon(Icons.edit_calendar_rounded, size: 18),
                        label: const Text('إجراء تصحيح بصمات', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0),
                      ),
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

  Widget _buildProTimeBox(String label, String time, IconData icon, Color color) {
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
              Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text(time, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  void _showAddCorrectionDialog(
      BuildContext context, AdminController controller, AttendanceModel att) {
    final selectedType = 'check_in'.obs;
    final requestedTime = TimeOfDay.now().obs;
    final reasonController =
        TextEditingController(text: 'تصحيح من لوحة التحكم');

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_calendar_rounded,
                    color: AppTheme.primaryGold, size: 32),
              ),
              SizedBox(height: 16),
              const Text('تصحيح بصمة',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              Text(att.employeeName ?? 'الموظف',
                  style: TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: 8),
                    Text('التاريخ: ${att.date}',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 24),
                const Text('نوع البصمة المطلوب تصحيحها:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Obx(() => Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('دخول',
                                  style: TextStyle(fontSize: 13)),
                              value: 'check_in',
                              groupValue: selectedType.value,
                              onChanged: (v) => selectedType.value = v!,
                              activeColor: AppTheme.primaryGold,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('خروج',
                                  style: TextStyle(fontSize: 13)),
                              value: 'check_out',
                              groupValue: selectedType.value,
                              onChanged: (v) => selectedType.value = v!,
                              activeColor: AppTheme.primaryGold,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    )),
                SizedBox(height: 24),
                const Text('الوقت المصحح:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Obx(() => InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: requestedTime.value,
                        );
                        if (picked != null) requestedTime.value = picked;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(requestedTime.value.format(context),
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w900)),
                            Icon(Icons.access_time_filled_rounded,
                                color: AppTheme.primaryGold),
                          ],
                        ),
                      ),
                    )),
                SizedBox(height: 24),
                const Text('السبب:',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'أدخل سبب التصحيح هنا...',
                    fillColor: AppTheme.backgroundLight,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(24),
        actions: [
          Row(
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
                child: Obx(() => ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : () async {
                              controller.isLoading.value = true;
                              try {
                                final apiService = Get.find<ApiService>();
                                final timeStr =
                                    '${requestedTime.value.hour.toString().padLeft(2, '0')}:${requestedTime.value.minute.toString().padLeft(2, '0')}:00';
                                final originalTime =
                                    selectedType.value == 'check_in'
                                        ? att.checkIn
                                        : att.checkOut;

                                final payload = {
                                  'employee_id': att.employeeId,
                                  'date': att.date,
                                  'type': selectedType.value,
                                  'original_time': originalTime,
                                  'requested_time': timeStr,
                                  'reason': reasonController.text,
                                  'status': 'approved',
                                };

                                final res = await apiService.postData(
                                    'attendance-corrections', payload);

                                if (res != null) {
                                  await controller.fetchCorrectionRequests();
                                  Get.back();
                                  UiUtils.showSuccessDialog(
                                      'تم بنجاح', 'تم تصحيح البصمة بنجاح');
                                  controller.fetchAttendance();
                                } else {
                                  UiUtils.showErrorDialog(
                                      'خطأ', 'تعذر تقديم طلب التصحيح');
                                }
                              } finally {
                                controller.isLoading.value = false;
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: controller.isLoading.value
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('حفظ وتأكيد',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return AppTheme.successGreen;
      case 'late':
        return AppTheme.primaryGold;
      case 'absent':
        return AppTheme.errorRed;
      case 'early_exit':
        return Colors.orange;
      case 'incomplete':
        return AppTheme.primaryGold;
      case 'holiday':
        return AppTheme.primaryTeal;
      case 'vacation':
        return AppTheme.successGreen;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusText(String status, [bool hasEarlyExit = false]) {
    String text = '';
    switch (status.toLowerCase()) {
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
        text = status;
    }
    if (hasEarlyExit && (status == 'present' || status == 'late')) {
      text += ' (خروج مبكر)';
    }
    return text;
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
        ],
      ),
    );
  }
}
