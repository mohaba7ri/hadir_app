import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/app_models.dart';
import '../../controllers/admin_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/utils/pdf_helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeDetailsView extends StatefulWidget {
  const EmployeeDetailsView({Key? key}) : super(key: key);

  @override
  State<EmployeeDetailsView> createState() => _EmployeeDetailsViewState();
}

class _EmployeeDetailsViewState extends State<EmployeeDetailsView> {
  late EmployeeModel employee;
  final controller = Get.find<AdminController>();

  @override
  void initState() {
    super.initState();
    if (Get.arguments != null) {
      employee = Get.arguments as EmployeeModel;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchEmployeeMonthlySummary(employee.id!);
        controller.fetchEmployeeClosings(employee.id!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Get.arguments == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الموظف'),
        ),
        body: const Center(
          child: Text('يرجى اختيار موظف أولاً لعرض تفاصيله.'),
        ),
      );
    }

    final isMobile = Responsive.isMobile(context);

    return Obx(() {
      if (controller.isLoading.value &&
          controller.selectedEmployeeSummaryDays.isEmpty) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final latestEmp = controller.employees
          .firstWhere((e) => e.id == employee.id, orElse: () => employee);

      final filtered = controller.selectedEmployeeSummaryDays;
      final totals = controller.selectedEmployeeSummaryTotals;

      // Stats from API
      int present = (totals['present_days'] ?? 0).toInt();
      int actualUnexcusedAbsences = (totals['absent_days'] ?? 0).toInt();
      int approvedVacations = (totals['vacation_days'] ?? 0).toInt();

      double lateDiscount = (totals['late_deduction'] ?? 0).toDouble();
      double earlyExitDiscount =
          (totals['early_exit_deduction'] ?? 0).toDouble();
      double absenceDiscount = (totals['absence_deduction'] ?? 0).toDouble();
      double monthTotalDiscount = (totals['total_deduction'] ?? 0).toDouble();
      int lateCountTotal = (totals['late_count'] ?? 0).toInt();

      return Scaffold(
        appBar: AppBar(
          title: const Text('تفاصيل الموظف',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          centerTitle: false,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.primaryTeal),
              tooltip: 'المزيد من الإجراءات',
              onSelected: (value) {
                if (value == 'vacations') {
                  _showVacationsHistoryDialog(context, controller, latestEmp);
                } else if (value == 'closings') {
                  _showClosingsBottomSheet(context);
                } else if (value == 'monthly_close') {
                  _showSplitPayrollDialog(context, latestEmp, controller);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'vacations',
                  child: Row(
                    children: [
                      Icon(Icons.beach_access_rounded, size: 20, color: AppTheme.primaryTeal),
                      SizedBox(width: 12),
                      Text('سجل طلبات الإجازة', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'closings',
                  child: Row(
                    children: [
                      Icon(Icons.history_edu_rounded, size: 20, color: AppTheme.primaryTeal),
                      SizedBox(width: 12),
                      Text('سجل الإغلاقات', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'monthly_close',
                  child: Row(
                    children: [
                      Icon(Icons.lock_clock_rounded, size: 20, color: AppTheme.primaryTeal),
                      SizedBox(width: 12),
                      Text('إغلاق شهري', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            children: [
              _buildHeader(
                  context,
                  latestEmp,
                  isMobile,
                  present,
                  actualUnexcusedAbsences,
                  approvedVacations,
                  lateCountTotal,
                  monthTotalDiscount,
                  lateDiscount,
                  earlyExitDiscount,
                  absenceDiscount,
                  controller),
              SizedBox(height: 16),
              if (filtered.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 48, color: AppTheme.textSecondary),
                        SizedBox(height: 12),
                        Text('لا توجد بيانات لهذا الشهر',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                _buildAttendanceList(context, filtered, latestEmp, isMobile),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFilterDropdowns(AdminController controller) {
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
              _buildDropdown(
                value: controller.selectedMonth.value,
                items: List.generate(12, (i) => i + 1),
                onChanged: (v) {
                  controller.selectedMonth.value = v!;
                  controller.fetchEmployeeMonthlySummary(employee.id!);
                },
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
                onChanged: (v) {
                  controller.selectedYear.value = v!;
                  controller.fetchEmployeeMonthlySummary(employee.id!);
                },
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

  Widget _buildStatusChip(String status) {
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? AppTheme.successGreen : AppTheme.errorRed)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'نشط' : 'غير نشط',
        style: TextStyle(
          color: isActive ? AppTheme.successGreen : AppTheme.errorRed,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  int _getRemainingMonthlyLimit(EmployeeModel emp, int selectedMonth, int selectedYear) {
    int monthlyLimit = emp.monthlyAnnualLeaveLimitMinutes;
    
    int startMonth = selectedMonth == 1 ? 12 : selectedMonth - 1;
    int startYear = selectedMonth == 1 ? selectedYear - 1 : selectedYear;
    
    DateTime cycleStart = DateTime(startYear, startMonth, 25);
    DateTime cycleEnd = DateTime(selectedYear, selectedMonth, 24, 23, 59, 59);
    
    int usedMinutes = controller.vacationRequests.where((v) {
      if (v.employeeId != emp.id) return false;
      if (v.vacationType != AppConstants.annualLeave) return false;
      if (v.status != 'pending' && v.status != 'approved') return false;
      
      try {
        final reqStart = DateTime.parse(v.startDate);
        return (reqStart.isAfter(cycleStart) || reqStart.isAtSameMomentAs(cycleStart)) && 
               (reqStart.isBefore(cycleEnd) || reqStart.isAtSameMomentAs(cycleEnd));
      } catch (_) {
        return false;
      }
    }).fold(0, (sum, v) => sum + v.totalMinutes);

    return monthlyLimit - usedMinutes;
  }

  Widget _buildHeader(
      BuildContext context,
      EmployeeModel employee,
      bool isMobile,
      int present,
      int absent,
      int vacations,
      int late,
      double totalDiscount,
      double lateDiscountTotal,
      double earlyExitDiscountTotal,
      double absenceDiscountTotal,
      AdminController controller) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                            child: Text(employee.name,
                                style: TextStyle(
                                    fontSize: isMobile ? 18 : 24,
                                    fontWeight: FontWeight.w900),
                                overflow: TextOverflow.ellipsis)),
                        SizedBox(width: 8),
                        _buildStatusChip(employee.status),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'الرقم الوظيفي: #${employee.id} | الراتب: ${employee.salary} ر.س | رصيد الإجازات: ${UiUtils.formatDaysApproximate(employee.vacationCredit / controller.getSystemWorkDayDurationInMinutes())} (${UiUtils.formatDuration(employee.vacationCredit)})',
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'المتبقي من حد الإجازة السنوية لشهر ${_getMonthNameArabic(controller.selectedMonth.value)}: ${UiUtils.formatDuration(_getRemainingMonthlyLimit(employee, controller.selectedMonth.value, controller.selectedYear.value))}',
                      style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.print_rounded, color: AppTheme.primaryTeal),
                tooltip: 'طباعة التقارير',
                onSelected: (type) => _showPrintOptionsDialog(
                    context, employee, controller, type),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'vacations', child: Text('طباعة سجل الإجازات')),
                  const PopupMenuItem(
                      value: 'absent', child: Text('طباعة سجل الغياب فقط')),
                  const PopupMenuItem(
                      value: 'all', child: Text('طباعة سجل الحضور والغياب')),
                  const PopupMenuItem(
                      value: 'overtime',
                      child: Text('طباعة تقرير العمل الإضافي')),
                ],
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                _buildFilterDropdowns(controller),
              ],
            ],
          ),
          if (!isMobile) ...[
            SizedBox(height: 20),
            const Divider(height: 1),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactStat(Icons.event_busy_rounded, 'الغياب غير المبرر',
                    absent.toString(), AppTheme.errorRed),
                _buildCompactStat(Icons.beach_access_rounded, 'إجازات معتمدة',
                    vacations.toString(), AppTheme.primaryTeal),
                _buildCompactStat(Icons.access_time_filled_rounded,
                    'مرات التأخير', late.toString(), Colors.orange),
                Container(width: 1, height: 40, color: AppTheme.borderLight),
                _buildCompactStat(
                    Icons.event_busy_rounded,
                    'خصم الغياب',
                    '${absenceDiscountTotal.toStringAsFixed(2)} ر.س',
                    AppTheme.errorRed),
                _buildCompactStat(
                    Icons.access_time_rounded,
                    'خصم التأخير',
                    '${lateDiscountTotal.toStringAsFixed(2)} ر.س',
                    AppTheme.errorRed),
                _buildCompactStat(
                    Icons.logout_rounded,
                    'خصم خروج مبكر',
                    '${earlyExitDiscountTotal.toStringAsFixed(2)} ر.س',
                    AppTheme.errorRed),
                _buildCompactStat(
                    Icons.account_balance_wallet_rounded,
                    'إجمالي الخصم',
                    '${totalDiscount.toStringAsFixed(2)} ر.س',
                    AppTheme.errorRed,
                    isBold: true),
              ],
            ),
          ] else ...[
            SizedBox(height: 16),
            if (isMobile) _buildFilterDropdowns(controller),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactStat(Icons.event_busy_rounded, 'غياب',
                    absent.toString(), AppTheme.errorRed),
                _buildCompactStat(Icons.beach_access_rounded, 'إجازة',
                    vacations.toString(), AppTheme.primaryTeal),
                _buildCompactStat(
                    Icons.account_balance_wallet_rounded,
                    'الخصم',
                    '${totalDiscount.toStringAsFixed(2)} ر.س',
                    AppTheme.errorRed,
                    isBold: true),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactStat(
                    Icons.event_busy_rounded,
                    'خصم غياب',
                    '${absenceDiscountTotal.toStringAsFixed(1)} ر.س',
                    AppTheme.errorRed),
                _buildCompactStat(
                    Icons.access_time_rounded,
                    'خصم تأخير',
                    '${lateDiscountTotal.toStringAsFixed(1)} ر.س',
                    AppTheme.errorRed),
                _buildCompactStat(
                    Icons.logout_rounded,
                    'خصم خروج مبكر',
                    '${earlyExitDiscountTotal.toStringAsFixed(1)} ر.س',
                    AppTheme.errorRed),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceList(BuildContext context,
      List<AttendanceModel> records, EmployeeModel employee, bool isMobile) {
    final controller = Get.find<AdminController>();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: isMobile
            ? ListView.separated(
                itemCount: records.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final r = records[index];
                  final vacation =
                      controller.getApprovedVacation(r.employeeId, r.date);
                  return _buildMobileTile(
                      r, vacation, controller, context, employee);
                },
              )
            : GridView.builder(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.antiAlias,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.isDesktop(context) ? 4 : 2,
                  mainAxisExtent: 160,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final r = records[index];
                  final vacation =
                      controller.getApprovedVacation(r.employeeId, r.date);
                  return _buildRecordCard(
                      r, vacation, controller, context, employee);
                },
              ),
      ),
    );
  }

  Widget _buildMobileTile(
      AttendanceModel att,
      VacationRequestModel? vacation,
      AdminController controller,
      BuildContext context,
      EmployeeModel employee) {
    final dateObj = DateTime.parse(att.date);
    final dayName = _getDayNameArabic(dateObj);
    final isHoliday = att.status == 'holiday';
    final hasVacation = vacation != null;
    final effectiveLate = att.lateMinutes;

    Color statusColor = AppTheme.textSecondary;
    if (isHoliday || (att.status == 'absent' && hasVacation) || att.status == 'vacation') {
      statusColor = AppTheme.primaryTeal;
    } else if (att.status == 'present' || att.status == 'late') {
      statusColor = effectiveLate > 0 ? Colors.orange : AppTheme.successGreen;
    } else if (att.status == 'absent') {
      statusColor = AppTheme.errorRed;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: statusColor.withValues(alpha: 0.2), width: 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (att.status == 'absent' && !hasVacation && !isHoliday) {
                _showAddVacationOverrideDialog(context, controller, att);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(att.date.split('-')[2],
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                        Text(
                            _getMonthShortNameArabic(
                                int.parse(att.date.split('-')[1])),
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10)),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(dayName,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const Spacer(),
                            _buildMiniStatusBadge(att, vacation, effectiveLate,
                                isHoliday, controller, employee),
                          ],
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.login_rounded,
                                size: 12, color: AppTheme.textSecondary),
                            SizedBox(width: 4),
                            Text(
                                att.checkIn != null
                                    ? _formatTime(att.checkIn)
                                    : '--:--',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                            SizedBox(width: 12),
                            Icon(Icons.logout_rounded,
                                size: 12, color: AppTheme.textSecondary),
                            SizedBox(width: 4),
                            Text(
                                att.checkOut != null
                                    ? _formatTime(att.checkOut)
                                    : '--:--',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                        Builder(builder: (context) {
                          final hourlyVac = controller.getHourlyVacationRequest(
                              employee.id ?? 0, att.date);
                          if (hourlyVac != null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'تم طلب (${hourlyVac.totalMinutes}د) من (${hourlyVac.vacationType})',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryTeal,
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        if (att.earlyExitMinutes > 0) ...[
                          SizedBox(height: 4),
                          Text(
                              'خصم الخروج المبكر (${att.earlyExitMinutes} دقيقة) (${att.earlyExitDiscount.toStringAsFixed(2)} ر.س)',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold)),
                        ],
                        if (effectiveLate > 0) ...[
                          SizedBox(height: 4),
                          Text(
                              'خصم التأخير ($effectiveLate دقيقة) (${att.lateDiscount.toStringAsFixed(2)} ر.س)',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.bold)),
                        ],
                        if (att.status == 'absent' &&
                            !hasVacation &&
                            !isHoliday) ...[
                          SizedBox(height: 4),
                          Text(
                              'خصم غياب (-${((att.salary > 0 ? att.salary : employee.salary) / controller.daysInMonth).toStringAsFixed(2)} ر.س)',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.bold)),
                        ],
                        if (controller.correctionRequests.any((c) =>
                            c.date == att.date &&
                            c.employeeId == att.employeeId &&
                            c.status == 'approved')) ...[
                          SizedBox(height: 4),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatusBadge(
      AttendanceModel att,
      VacationRequestModel? vacation,
      int effectiveLate,
      bool isHoliday,
      AdminController controller,
      EmployeeModel employee) {
    String text = '';
    Color color = AppTheme.textSecondary;

    if (isHoliday) {
      text = 'إجازة رسمية';
      color = AppTheme.primaryTeal;
    } else if (att.status == 'absent' && vacation != null) {
      String extra = vacation.isHourly
          ? '(${vacation.startDate} | ${vacation.totalMinutes} د)'
          : (vacation.startDate == vacation.endDate)
              ? '(${vacation.startDate})'
              : '(${vacation.startDate} - ${vacation.endDate})';
      text = '${vacation.vacationType} $extra';
      color = AppTheme.primaryTeal;
    } else if (att.status == 'present' ||
        att.status == 'late' ||
        att.status == 'early_exit') {
      bool isEarly = att.status == 'early_exit' || att.earlyExitMinutes > 0;
      bool isLate = effectiveLate > 0;

      if (isEarly && isLate) {
        text = 'تأخير وخروج مبكر';
        color = Colors.orange;
      } else if (isEarly) {
        text = 'خروج مبكر';
        color = Colors.orange;
      } else if (isLate) {
        text = 'متأخر';
        color = Colors.orange;
      } else {
        text = 'حاضر';
        color = AppTheme.successGreen;
      }
    } else if (att.status == 'absent') {
      text = 'غائب';
      color = AppTheme.errorRed;
    } else if (att.status == 'pending') {
      text = 'قادم';
      color = AppTheme.textSecondary;
    } else if (att.status == 'incomplete') {
      if (effectiveLate > 0) {
        text = 'تأخير / غير مكتمل';
        color = Colors.orange;
      } else {
        text = 'غير مكتمل';
        color = AppTheme.primaryTeal;
      }
    } else if (att.status == 'off') {
      text = '-';
      color = AppTheme.textSecondary;
    } else if (att.status == 'vacation') {
      text = vacation?.vacationType ?? 'إجازة';
      color = AppTheme.primaryTeal;
    } else {
      text = att.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRecordCard(
      AttendanceModel att,
      VacationRequestModel? vacation,
      AdminController controller,
      BuildContext context,
      EmployeeModel employee) {
    Color color;
    String statusText;
    bool isHoliday = att.status == 'holiday';
    final hasVacation = vacation != null;
    final effectiveLate = att.lateMinutes;

    if (isHoliday) {
      color = AppTheme.primaryTeal;
      statusText = att.employeeName ?? 'إجازة رسمية';
    } else if (att.status == 'absent' && vacation != null) {
      color = AppTheme.primaryTeal;
      String datesText = (vacation.startDate == vacation.endDate)
          ? vacation.startDate
          : '${vacation.startDate.split('-')[1]}/${vacation.startDate.split('-')[2]} - ${vacation.endDate.split('-')[1]}/${vacation.endDate.split('-')[2]}';
      statusText = '${vacation.vacationType} ($datesText)';
    } else {
      bool isEarly = att.status == 'early_exit' || att.earlyExitMinutes > 0;
      bool isLate = effectiveLate > 0;

      if (att.status == 'absent') {
        color = AppTheme.errorRed;
        statusText = 'غائب';
      } else if (att.status == 'pending') {
        color = AppTheme.textSecondary;
        statusText = 'قادم';
      } else if (att.status == 'incomplete') {
        if (effectiveLate > 0) {
          color = Colors.orange;
          statusText = 'تأخير / غير مكتمل';
        } else {
          color = AppTheme.primaryTeal;
          statusText = 'غير مكتمل';
        }
      } else if (att.status == 'off') {
        color = AppTheme.textSecondary;
        statusText = '-';
      } else if (att.status == 'vacation') {
        color = AppTheme.primaryTeal;
        statusText = vacation?.vacationType ?? 'إجازة';
      } else {
        if (isEarly && isLate) {
          color = Colors.orange;
          statusText = 'تأخير وخروج مبكر';
        } else if (isEarly) {
          color = Colors.orange;
          statusText = 'خروج مبكر';
        } else if (isLate) {
          color = Colors.orange;
          statusText = 'متأخر';
        } else {
          color = AppTheme.successGreen;
          statusText = 'حاضر';
        }
      }
    }

    final hourlyVac =
        controller.getHourlyVacationRequest(employee.id ?? 0, att.date);
    if (hourlyVac != null) {
      String hourlyText =
          'تم طلب (${hourlyVac.totalMinutes}د) من (${hourlyVac.vacationType})';
      if (statusText.isNotEmpty && statusText != 'حاضر') {
        statusText += ' | $hourlyText';
      } else {
        statusText = hourlyText;
      }
    }

    return InkWell(
      onTap: att.status == 'pending'
          ? null
          : () {
              if (att.status == 'absent' && !hasVacation && !isHoliday) {
                _showAddVacationOverrideDialog(context, controller, att);
              } else {
                _showRecordDetailsDialog(context, controller, att, employee);
              }
            },
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: color.withValues(
                  alpha: Responsive.isDesktop(context) ? 0.4 : 0.12),
              width: Responsive.isDesktop(context) ? 2.0 : 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                      '${_getDayNameArabic(DateTime.parse(att.date))} ${att.date.split('-')[2]}',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
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
            SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                    child: _buildTimeBadge('دخول', _formatTime(att.checkIn))),
                SizedBox(width: 8),
                Expanded(
                    child: _buildTimeBadge('خروج', _formatTime(att.checkOut))),
              ],
            ),
            if (att.status == 'absent' && !hasVacation && !isHoliday) ...[
              SizedBox(height: 3),
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
                      '- ${(employee.salary / controller.daysInMonth).toStringAsFixed(2)} ر.س',
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
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ] else ...[
              if (att.earlyExitMinutes > 0) ...[
                SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text('خصم الخروج المبكر (${att.earlyExitMinutes} دقيقة)',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('- ${att.earlyExitDiscount.toStringAsFixed(2)} ر.س',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              if (effectiveLate > 0) ...[
                SizedBox(height: 3),
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
                    Text('- ${att.lateDiscount.toStringAsFixed(2)} ر.س',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ],
            if (controller.correctionRequests.any((c) =>
                c.date == att.date &&
                c.employeeId == att.employeeId &&
                c.status == 'approved')) ...[
              SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBadge(String label, String? time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  fontSize: 11,
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
    
    final employee =
        controller.employees.firstWhereOrNull((e) => e.id == att.employeeId);
    final credit = employee?.vacationCredit ?? 0;

    final selectedType =
        (credit > 0 ? AppConstants.annualLeave : AppConstants.businessMission)
            .obs;
    final types = AppConstants.getVacationTypes();

    final Rx<PlatformFile?> selectedAttachmentFile = Rx<PlatformFile?>(null);

    Get.dialog(
      AlertDialog(
        title: const Text('تحويل غياب الموظف لإجازة'),
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
                  final totalHours = (credit / 60).floor();
                  final mins = (credit % 60).toInt();

                  String creditStr = '';
                  if (totalHours > 0) creditStr += '$totalHours ساعة ';
                  if (mins > 0 || credit == 0) creditStr += '$mins دقيقة';
                  creditStr = creditStr.trim();

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
                              icon: Icon(Icons.upload_file_rounded, size: 18),
                              label: const Text('اختيار ملف أو صورة',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryTeal,
                                elevation: 0,
                                side: BorderSide(color: AppTheme.primaryTeal),
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
                              totalMinutes: controller
                                  .getWorkDayDurationInMinutes(employee),
                              status: 'approved',
                              vacationType: selectedType.value,
                            );
                            final errorMsg =
                                await controller.addVacationRequestWithReason(
                              request,
                              attachmentFile: selectedAttachmentFile.value,
                            );
                            if (errorMsg == null) {
                              Get.back();
                              UiUtils.showSuccessDialog('تم بنجاح',
                                  'تم تحويل يوم الغياب إلى ${selectedType.value}');
                              controller
                                  .fetchEmployeeMonthlySummary(att.employeeId);
                            } else {
                              if (errorMsg is Map && errorMsg['error_type'] == 'limit_exceeded_with_remaining' && errorMsg['remaining_minutes'] != null && errorMsg['remaining_minutes'] > 0) {
                                int remaining = errorMsg['remaining_minutes'];
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
                                        controller.fetchEmployeeMonthlySummary(att.employeeId);
                                    } else {
                                        String msg = retryRes is Map ? (retryRes['message']?.toString() ?? 'خطأ') : retryRes.toString();
                                        UiUtils.showErrorDialog('تعذر حفظ الإجازة', msg);
                                    }
                                  }
                                );
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

  void _showCoverWithVacationDialog(BuildContext context,
      AdminController controller, AttendanceModel att, EmployeeModel employee) {
    if (controller.hasPendingVacation(att.employeeId, att.date)) {
      UiUtils.showErrorDialog(
        'طلب إجازة معلق',
        'يوجد طلب إجازة قيد الانتظار لهذا الموظف في هذا اليوم. يرجى مراجعته من شاشة طلبات الإجازة أولاً.',
      );
      return;
    }

    int initialLateMins = att.lateMinutes;
    int initialEarlyExitMins = att.earlyExitMinutes;

    final showLate = false.obs;
    final showEarly = false.obs;
    final totalCreditMinutes = employee.vacationCredit;
    final selectedType = AppConstants.annualLeave.obs;
    final vacationTypes = AppConstants.getVacationTypes();
    final reasonController = TextEditingController(
        text: 'تغطية تأخير/خروج مبكر بتاريخ ${att.date} من قبل الإدارة');
    final Rx<PlatformFile?> selectedAttachmentFile = Rx<PlatformFile?>(null);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
            horizontal: Responsive.isMobile(context) ? 16 : 32, vertical: 24),
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border:
                      Border(bottom: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10)
                        ],
                      ),
                      child: Icon(Icons.beach_access_rounded,
                          color: AppTheme.primaryTeal, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تغطية تأخير أو خروج مبكر',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary)),
                          Text('تطبيق إجازة لتعويض الدقائق المفقودة',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close_rounded,
                          color: AppTheme.textSecondary),
                      style:
                          IconButton.styleFrom(backgroundColor: Colors.white),
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
                      const Text('تحديد الفترات المراد تغطيتها',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900)),
                      SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.15)),
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
                      if (initialLateMins > 0 && initialEarlyExitMins > 0)
                        SizedBox(height: 12),
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
                        int total = (showLate.value ? initialLateMins : 0) +
                            (showEarly.value ? initialEarlyExitMins : 0);
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
                              Text('إجمالي الدقائق المستقطعة:',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textSecondary)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('$total دقيقة',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primaryTeal)),
                              ),
                            ],
                          ),
                        );
                      }),

                      SizedBox(height: 24),
                      const Text('نوع الإجازة التعويضية',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900)),
                      SizedBox(height: 12),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppTheme.borderLight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedType.value,
                                isExpanded: true,
                                icon: Icon(Icons.keyboard_arrow_down_rounded,
                                    color: AppTheme.textSecondary),
                                items: vacationTypes
                                    .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))))
                                    .toList(),
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
                                color: AppTheme.primaryTeal
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.primaryTeal
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      size: 20, color: AppTheme.primaryTeal),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'رصيد إجازات الموظف المتاح حالياً: ${UiUtils.formatDaysApproximate(employee.vacationCredit / controller.getSystemWorkDayDurationInMinutes())} (${UiUtils.formatDuration(employee.vacationCredit)})',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryTeal,
                                          fontWeight: FontWeight.bold,
                                          height: 1.4),
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
                                border: Border.all(
                                    color:
                                        Colors.orange.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      size: 20, color: Colors.orange),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'ملاحظة: هذا النوع من الإجازات لا يخصم من رصيد الإجازات السنوية للموظف.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            )),

                      SizedBox(height: 24),
                      const Text('السبب / الملاحظات (اختياري)',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900)),
                      SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'أضف ملاحظة توضيحية للإدارة...',
                          hintStyle: TextStyle(
                              color:
                                  AppTheme.textSecondary.withValues(alpha: 0.5),
                              fontSize: 13),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppTheme.borderLight)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppTheme.borderLight)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppTheme.primaryTeal)),
                          filled: true,
                          fillColor: AppTheme.backgroundLight,
                        ),
                      ),
                      SizedBox(height: 16),
                      const Text('المرفقات (اختياري للمدير)',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900)),
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
                                          color: AppTheme.successGreen,
                                          size: 20),
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

              // Action Buttons Bottom
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إلغاء',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Obx(() {
                        int currentTotal =
                            (showLate.value ? initialLateMins : 0) +
                                (showEarly.value ? initialEarlyExitMins : 0);
                        bool hasEnoughCredit =
                            selectedType.value != AppConstants.annualLeave ||
                                (totalCreditMinutes >= currentTotal);
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
                                  final errorMsg = await controller
                                      .addVacationRequestWithReason(request,
                                          attachmentFile:
                                              selectedAttachmentFile.value);
                                  if (errorMsg == null) {
                                    Get.back();
                                    UiUtils.showSuccessDialog(
                                        'تم التغطية بنجاح',
                                        'تم تطبيق الإجازة واحتساب الدقائق المطلوبة.');
                                    controller.fetchEmployeeMonthlySummary(
                                        att.employeeId);
                                  } else {
                                    UiUtils.showErrorDialog('خطأ', errorMsg);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('اعتماد التغطية',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
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

  Widget _buildSelectableProTile(
      {required String title,
      required String subtitle,
      required IconData icon,
      required bool isSelected,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryTeal.withValues(alpha: 0.05)
              : Colors.white,
          border: Border.all(
              color: isSelected ? AppTheme.primaryTeal : AppTheme.borderLight,
              width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryTeal
                    : AppTheme.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 20,
                  color: isSelected ? Colors.white : AppTheme.textSecondary),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textPrimary)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? AppTheme.primaryTeal
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color:
                    isSelected ? AppTheme.primaryTeal : AppTheme.borderLight),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(
      IconData icon, String label, String value, Color color,
      {bool isBold = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.textSecondary),
            SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
        SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: isBold ? 12 : 11,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
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

  String _getMonthShortNameArabic(int month) {
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

  void _showRecordDetailsDialog(BuildContext context,
      AdminController controller, AttendanceModel att, EmployeeModel employee) {
    final holiday = controller.getHolidayForDate(att.date);
    final effectiveStatus = att.status;
    final effectiveLate = att.lateMinutes;
    final vacation = controller.getApprovedVacation(employee.id!, att.date);
    final hasVacation = effectiveStatus == 'vacation' || vacation != null;
    final isHoliday = holiday != null;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(
            horizontal: Responsive.isMobile(context) ? 16 : 32, vertical: 24),
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border:
                      Border(bottom: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10)
                        ],
                      ),
                      child: Icon(Icons.calendar_month_rounded,
                          color: AppTheme.primaryTeal, size: 24),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تفاصيل السجل',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: AppTheme.textPrimary)),
                          Text(att.date,
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close_rounded,
                          color: AppTheme.textSecondary),
                      style:
                          IconButton.styleFrom(backgroundColor: Colors.white),
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
                            child: Icon(Icons.person_rounded,
                                size: 18, color: AppTheme.textSecondary),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('الموظف',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.bold)),
                                Text(employee.name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: AppTheme.textPrimary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(effectiveStatus)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _getStatusColor(effectiveStatus)
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              isHoliday
                                  ? holiday.name
                                  : (hasVacation
                                      ? (vacation?.vacationType ?? 'إجازة')
                                      : _getStatusText(
                                          effectiveStatus,
                                          att.earlyExitMinutes > 0,
                                          effectiveLate > 0)),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: isHoliday || hasVacation
                                    ? (hasVacation
                                        ? Colors.teal
                                        : AppTheme.primaryTeal)
                                    : _getStatusColor(effectiveStatus),
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
                            child: _buildProTimeBox(
                                'وقت الدخول',
                                _formatTime(att.checkIn),
                                Icons.login_rounded,
                                AppTheme.successGreen),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildProTimeBox(
                                'وقت الخروج',
                                _formatTime(att.checkOut),
                                Icons.logout_rounded,
                                AppTheme.errorRed),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Financial Details
                      Builder(builder: (context) {
                        final earlyMins = att.earlyExitMinutes;
                        final minuteRate = controller.calculateMinuteDiscount(
                            att.salary, employee);
                        final lateDisc = effectiveLate * minuteRate;
                        final earlyDisc = earlyMins * minuteRate;
                        final absenceDisc = (effectiveStatus == 'absent' &&
                                !controller.hasApprovedVacation(
                                    att.employeeId, att.date))
                            ? (att.salary / controller.daysInMonth)
                            : 0.0;
                        final totalDisc = lateDisc + earlyDisc + absenceDisc;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: totalDisc > 0
                                ? AppTheme.errorRed.withValues(alpha: 0.04)
                                : AppTheme.successGreen.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: totalDisc > 0
                                    ? AppTheme.errorRed.withValues(alpha: 0.1)
                                    : AppTheme.successGreen
                                        .withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_rounded,
                                      size: 18,
                                      color: totalDisc > 0
                                          ? AppTheme.errorRed
                                          : AppTheme.successGreen),
                                  SizedBox(width: 8),
                                  Text('التفاصيل المالية',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: totalDisc > 0
                                              ? AppTheme.errorRed
                                              : AppTheme.successGreen)),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildInfoRow('إجمالي الخصم:',
                                  '${totalDisc.toStringAsFixed(2)} ر.س',
                                  isBold: true,
                                  color: totalDisc > 0
                                      ? AppTheme.errorRed
                                      : AppTheme.successGreen),
                              if (lateDisc > 0) ...[
                                SizedBox(height: 8),
                                _buildInfoRow('خصم التأخير:',
                                    '${lateDisc.toStringAsFixed(2)} ر.س',
                                    color: Colors.orange)
                              ],
                              if (earlyDisc > 0) ...[
                                SizedBox(height: 8),
                                _buildInfoRow('خصم خروج مبكر:',
                                    '${earlyDisc.toStringAsFixed(2)} ر.س',
                                    color: Colors.orange)
                              ],
                              if (absenceDisc > 0) ...[
                                SizedBox(height: 8),
                                _buildInfoRow('خصم غياب:',
                                    '${absenceDisc.toStringAsFixed(2)} ر.س',
                                    color: AppTheme.errorRed)
                              ],
                            ],
                          ),
                        );
                      }),
                      SizedBox(height: 24),

                      // Overtime Details
                      Builder(builder: (context) {
                        final approvedOvertime = controller.overtimeRequests
                            .where((req) =>
                                req.employeeId == att.employeeId &&
                                req.date == att.date &&
                                req.status == 'approved')
                            .toList();
                        if (approvedOvertime.isEmpty)
                          return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تفاصيل العمل الإضافي المعتمد:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14)),
                            SizedBox(height: 12),
                            ...approvedOvertime.map((req) {
                              final amount = req.totalMinutes *
                                  ((employee.salary) /
                                      controller.daysInMonth /
                                      controller.getWorkDayDurationInMinutes(
                                          employee));
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal
                                      .withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: AppTheme.primaryTeal
                                          .withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.more_time_rounded,
                                            size: 20,
                                            color: AppTheme.primaryTeal),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                              '${_formatTime(req.startTime)} - ${_formatTime(req.endTime)}',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppTheme.textPrimary)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.successGreen
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                              '+ ${amount.toStringAsFixed(2)} ر.س',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
                                                  color:
                                                      AppTheme.successGreen)),
                                        ),
                                      ],
                                    ),
                                    if (req.reason != null &&
                                        req.reason!.isNotEmpty) ...[
                                      SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.format_quote_rounded,
                                                size: 14,
                                                color: AppTheme.textSecondary),
                                            SizedBox(width: 8),
                                            Expanded(
                                                child: Text(req.reason!,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppTheme
                                                            .textSecondary,
                                                        height: 1.4))),
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
                        final approvedCorrections = controller
                            .correctionRequests
                            .where((c) =>
                                c.employeeId == att.employeeId &&
                                c.date == att.date &&
                                c.status == 'approved')
                            .toList();
                        if (approvedCorrections.isEmpty)
                          return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تصحيحات البصمة المعتمدة:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14)),
                            SizedBox(height: 12),
                            ...approvedCorrections.map((c) {
                              String typeText = c.type == 'check_in' ||
                                      c.type == 'missing_check_in'
                                  ? 'بصمة دخول'
                                  : 'بصمة خروج';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold
                                      .withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.primaryGold
                                          .withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_calendar_rounded,
                                        size: 18, color: AppTheme.primaryGold),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(typeText,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryGold)),
                                          if (c.reason.isNotEmpty)
                                            Text(c.reason,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme
                                                        .textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Text(_formatTime(c.requestedTime),
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.primaryGold)),
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

                        final dayVacations =
                            controller.vacationRequests.where((v) {
                          if (v.employeeId != att.employeeId) return false;
                          final start = DateTime.tryParse(v.startDate);
                          final end = DateTime.tryParse(v.endDate);
                          if (start == null || end == null) return false;

                          if (v.isHourly || start.isAtSameMomentAs(end)) {
                            return targetDate.isAtSameMomentAs(start);
                          }

                          return (targetDate.isAtSameMomentAs(start) ||
                                  targetDate.isAfter(start)) &&
                              (targetDate.isAtSameMomentAs(end) ||
                                  targetDate.isBefore(end));
                        }).toList();

                        if (dayVacations.isEmpty)
                          return const SizedBox.shrink();

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
                                  color: AppTheme.primaryTeal
                                      .withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.primaryTeal
                                          .withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.beach_access_rounded,
                                            size: 18,
                                            color: AppTheme.primaryTeal),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(v.vacationType,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppTheme
                                                          .primaryTeal)),
                                              if (v.reason != null &&
                                                  v.reason!.isNotEmpty)
                                                Text(
                                                    v.reason!
                                                        .replaceAll(
                                                            RegExp(
                                                                r'\[COVER_(LATE|EARLY|BOTH)\]'),
                                                            '')
                                                        .trim(),
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: AppTheme
                                                            .textSecondary)),
                                            ],
                                          ),
                                        ),
                                        Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: v.status == 'approved'
                                                  ? AppTheme.successGreen
                                                      .withValues(alpha: 0.1)
                                                  : v.status == 'rejected'
                                                      ? AppTheme.errorRed
                                                          .withValues(
                                                              alpha: 0.1)
                                                      : Colors.orange
                                                          .withValues(
                                                              alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                                v.status == 'approved'
                                                    ? 'مقبولة'
                                                    : v.status == 'rejected'
                                                        ? 'مرفوضة'
                                                        : 'معلقة',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: v.status == 'approved'
                                                      ? AppTheme.successGreen
                                                      : v.status == 'rejected'
                                                          ? AppTheme.errorRed
                                                          : Colors.orange,
                                                )))
                                      ],
                                    ),
                                    if (v.attachment != null &&
                                        v.attachment!.isNotEmpty) ...[
                                      SizedBox(height: 12),
                                      InkWell(
                                        onTap: () async {
                                          final url = Uri.parse(
                                              '${ApiService.baseApiUrl}/${v.attachment}');
                                          if (await launchUrl(url,
                                              mode: LaunchMode
                                                  .externalApplication)) {
                                          } else {
                                            UiUtils.showErrorDialog(
                                                'تعذر الفتح',
                                                'لا يمكن فتح المرفق حالياً');
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryTeal
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: AppTheme.primaryTeal
                                                    .withValues(alpha: 0.2)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.attach_file_rounded,
                                                  size: 14,
                                                  color: AppTheme.primaryTeal),
                                              SizedBox(width: 4),
                                              Text('عرض المرفق',
                                                  style: TextStyle(
                                                      color:
                                                          AppTheme.primaryTeal,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold)),
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
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    if (att.lateMinutes > 0 || att.earlyExitMinutes > 0) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            _showCoverWithVacationDialog(
                                context, controller, att, employee);
                          },
                          icon: Icon(Icons.beach_access_rounded, size: 18),
                          label: const Text('تغطية تأخير/خروج مبكر بإجازة',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (effectiveStatus == 'absent' &&
                        !hasVacation &&
                        !isHoliday) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            _showAddVacationOverrideDialog(
                                context, controller, att);
                          },
                          icon: Icon(Icons.beach_access_rounded, size: 18),
                          label: const Text('تحويل غياب الموظف لإجازة',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                    if (hasVacation && vacation != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.back();
                            UiUtils.showConfirmDialog(
                              title: 'تأكيد الحذف',
                              message: 'هل أنت متأكد من حذف هذه الإجازة؟',
                              confirmColor: AppTheme.errorRed,
                              confirmText: 'حذف',
                              onConfirm: () async {
                                final res = await controller.deleteVacation(vacation.id!);
                                if (res == null) {
                                  UiUtils.showSuccessDialog('تم الحذف', 'تم حذف الإجازة بنجاح.');
                                  controller.fetchEmployeeMonthlySummary(employee.id!);
                                } else {
                                  UiUtils.showErrorDialog('تعذر الحذف', res);
                                }
                              }
                            );
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('إلغاء وحذف الإجازة',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          _showAddCorrectionDialog(context, controller, att);
                        },
                        icon: Icon(Icons.edit_calendar_rounded, size: 18),
                        label: const Text('إجراء تصحيح بصمات',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '---';
    try {
      String timePart = dateTimeStr;
      if (dateTimeStr.contains(' ')) {
        timePart = dateTimeStr.split(' ')[1];
      }
      final time = DateFormat('HH:mm:ss').parse(timePart);
      return DateFormat('hh:mm a', 'en').format(time);
    } catch (e) {
      return '---';
    }
  }

  void _showPrintOptionsDialog(BuildContext context, EmployeeModel employee,
      AdminController controller, String type) {
    final RxString selectedCriteria = 'month'.obs;
    final RxInt selectedMonth = controller.selectedMonth.value.obs;
    final RxInt selectedYear = controller.selectedYear.value.obs;

    final RxList<int> multipleMonths =
        <int>[controller.selectedMonth.value].obs;
    final Rx<DateTimeRange?> dateRange = Rx<DateTimeRange?>(null);
    final RxString sortOrder = 'desc'.obs; // 'asc' or 'desc'

    String getReportTitle() {
      if (type == 'vacations') return 'سجل الإجازات';
      if (type == 'absent') return 'سجل الغياب فقط';
      if (type == 'overtime') return 'تقرير العمل الإضافي';
      return 'سجل الحضور والغياب';
    }

    Get.dialog(
      AlertDialog(
        title: Text('خيارات طباعة (${getReportTitle()})',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('اختر فترة التقرير:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 12),
                Obx(() => Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('شهر محدد'),
                          value: 'month',
                          groupValue: selectedCriteria.value,
                          onChanged: (v) => selectedCriteria.value = v!,
                        ),
                        RadioListTile<String>(
                          title: const Text('شهور متعددة'),
                          value: 'multiple_months',
                          groupValue: selectedCriteria.value,
                          onChanged: (v) => selectedCriteria.value = v!,
                        ),
                        RadioListTile<String>(
                          title: const Text('نطاق تواريخ مخصص'),
                          value: 'range',
                          groupValue: selectedCriteria.value,
                          onChanged: (v) => selectedCriteria.value = v!,
                        ),
                        RadioListTile<String>(
                          title: const Text('كل السجلات'),
                          value: 'all',
                          groupValue: selectedCriteria.value,
                          onChanged: (v) => selectedCriteria.value = v!,
                        ),
                      ],
                    )),
                SizedBox(height: 16),
                const Divider(),
                SizedBox(height: 16),
                Obx(() {
                  if (selectedCriteria.value == 'month') {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildPrintDropdown<int>(
                            value: selectedMonth.value,
                            items: List.generate(12, (i) => i + 1),
                            onChanged: (v) => selectedMonth.value = v!,
                            itemLabel: (v) => _getMonthNameArabic(v),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildPrintDropdown<int>(
                            value: selectedYear.value,
                            items: List.generate(
                                5, (i) => DateTime.now().year - 2 + i),
                            onChanged: (v) => selectedYear.value = v!,
                            itemLabel: (v) => v.toString(),
                          ),
                        ),
                      ],
                    );
                  }

                  if (selectedCriteria.value == 'multiple_months') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('اختر الشهور المطلوب تضمينها:',
                            style: TextStyle(fontSize: 13)),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(12, (i) {
                            final m = i + 1;
                            return ChoiceChip(
                              label: Text(_getMonthNameArabic(m)),
                              selected: multipleMonths.contains(m),
                              onSelected: (selected) {
                                if (selected) {
                                  multipleMonths.add(m);
                                } else {
                                  if (multipleMonths.length > 1)
                                    multipleMonths.remove(m);
                                }
                              },
                            );
                          }),
                        ),
                      ],
                    );
                  }

                  if (selectedCriteria.value == 'range') {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('اختر نطاق التواريخ:',
                            style: TextStyle(fontSize: 13)),
                        SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: Icon(Icons.date_range_rounded),
                          label: Text(dateRange.value == null
                              ? 'تحديد النطاق'
                              : '${DateFormat('yyyy-MM-dd').format(dateRange.value!.start)} ⟵ ${DateFormat('yyyy-MM-dd').format(dateRange.value!.end)}'),
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                              initialDateRange: dateRange.value,
                            );
                            if (picked != null) dateRange.value = picked;
                          },
                        ),
                      ],
                    );
                  }

                  return const Center(
                    child: Text('سيتم تصدير كامل السجلات التاريخية المتاحة.',
                        style: TextStyle(
                            fontSize: 13, fontStyle: FontStyle.italic)),
                  );
                }),
                SizedBox(height: 16),
                const Divider(),
                SizedBox(height: 12),
                const Text('ترتيب التاريخ:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 8),
                Obx(() => Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('تنازلي (الأحدث أولاً)',
                                style: TextStyle(fontSize: 12)),
                            value: 'desc',
                            groupValue: sortOrder.value,
                            onChanged: (v) => sortOrder.value = v!,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('تصاعدي (الأقدم أولاً)',
                                style: TextStyle(fontSize: 12)),
                            value: 'asc',
                            groupValue: sortOrder.value,
                            onChanged: (v) => sortOrder.value = v!,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton.icon(
            icon: Icon(Icons.print_rounded),
            label: const Text('طباعة ومشاركة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Get.back();
              _generateCustomPdf(
                context: context,
                employee: employee,
                controller: controller,
                type: type,
                criteria: selectedCriteria.value,
                month: selectedMonth.value,
                year: selectedYear.value,
                multipleMonths: multipleMonths,
                range: dateRange.value,
                sortOrder: sortOrder.value,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrintDropdown<T>({
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(itemLabel(e))))
          .toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(),
      ),
    );
  }

  void _generateCustomPdf({
    required BuildContext context,
    required EmployeeModel employee,
    required AdminController controller,
    required String type,
    required String criteria,
    required int month,
    required int year,
    required List<int> multipleMonths,
    required DateTimeRange? range,
    required String sortOrder,
  }) async {
    if (type == 'overtime') {
      List<OvertimeRequestModel> otRecords = controller.overtimeRequests
          .where((ot) => ot.employeeId == employee.id)
          .toList();

      if (criteria == 'month') {
        otRecords = otRecords.where((ot) {
          final dt = DateTime.tryParse(ot.date);
          if (dt == null) return false;
          final periodStart = DateTime(year, month - 1, 25);
          final periodEnd = DateTime(year, month, 24);
          return (dt.isAtSameMomentAs(periodStart) ||
                  dt.isAfter(periodStart)) &&
              (dt.isAtSameMomentAs(periodEnd) || dt.isBefore(periodEnd));
        }).toList();
      } else if (criteria == 'multiple_months') {
        otRecords = otRecords.where((ot) {
          final dt = DateTime.tryParse(ot.date);
          if (dt == null) return false;
          int currentYear = DateTime.now().year;
          multipleMonths.sort();
          final periodStart =
              DateTime(currentYear, multipleMonths.first - 1, 25);
          final periodEnd = DateTime(currentYear, multipleMonths.last, 24);
          return (dt.isAtSameMomentAs(periodStart) ||
                  dt.isAfter(periodStart)) &&
              (dt.isAtSameMomentAs(periodEnd) || dt.isBefore(periodEnd));
        }).toList();
      } else if (criteria == 'range') {
        if (range != null) {
          otRecords = otRecords.where((ot) {
            final dt = DateTime.tryParse(ot.date);
            if (dt == null) return false;
            return (dt.isAtSameMomentAs(range.start) ||
                    dt.isAfter(range.start)) &&
                (dt.isAtSameMomentAs(range.end) || dt.isBefore(range.end));
          }).toList();
        }
      }

      // Apply sorting
      if (sortOrder == 'asc') {
        otRecords.sort((a, b) => a.date.compareTo(b.date));
      } else {
        otRecords.sort((a, b) => b.date.compareTo(a.date));
      }

      await PdfHelper.shareOvertimePdf(
        employee: employee,
        records: otRecords,
        title: 'تقرير العمل الإضافي',
        controller: controller,
      );
      return;
    }

    DateTime start;
    DateTime end;
    String subtitle = '';

    if (criteria == 'month') {
      start = DateTime(year, month - 1, 25);
      end = DateTime(year, month, 24);
      subtitle = 'شهر $month / $year';
    } else if (criteria == 'multiple_months') {
      multipleMonths.sort();
      int minMonth = multipleMonths.first;
      int maxMonth = multipleMonths.last;
      int currentYear = DateTime.now().year;
      start = DateTime(currentYear, minMonth - 1, 25);
      end = DateTime(currentYear, maxMonth, 24);

      String monthsStr =
          multipleMonths.map((m) => _getMonthNameArabic(m)).join('، ');
      subtitle = 'الشهور: $monthsStr';
    } else if (criteria == 'range') {
      if (range == null) {
        UiUtils.showErrorDialog('خطأ', 'يرجى تحديد نطاق التواريخ أولاً');
        return;
      }
      start = range.start;
      end = range.end;
      subtitle =
          'الفترة: ${DateFormat('yyyy-MM-dd').format(start)} إلى ${DateFormat('yyyy-MM-dd').format(end)}';
    } else {
      start = DateTime(2024, 1, 1);
      end = DateTime.now();
      subtitle = 'كامل السجلات التاريخية';
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    final detailedData = await controller.fetchDetailedAttendance(
      employee.id!,
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    );
    Get.back(); // close loading dialog

    List<AttendanceModel> finalPrintRecords =
        detailedData.map((d) => AttendanceModel.fromJson(d)).toList();

    String reportTitle = 'سجل الحضور والغياب';

    if (type == 'vacations') {
      reportTitle = 'سجل الإجازات';
      finalPrintRecords =
          finalPrintRecords.where((r) => r.status == 'vacation').toList();
    } else if (type == 'absent') {
      reportTitle = 'سجل الغياب فقط';
      finalPrintRecords =
          finalPrintRecords.where((r) => r.status == 'absent').toList();
    }

    // Apply sorting
    if (sortOrder == 'asc') {
      finalPrintRecords.sort((a, b) => a.date.compareTo(b.date));
    } else {
      finalPrintRecords.sort((a, b) => b.date.compareTo(a.date));
    }

    int absentDays = 0;
    double finalLateDiscount = 0.0;
    double finalEarlyExitDiscount = 0.0;
    double finalAbsenceDiscount = 0.0;
    double finalTotalDiscount = 0.0;

    for (var r in finalPrintRecords) {
      if (r.status == 'absent') absentDays++;
      finalLateDiscount += r.lateDiscount;
      finalEarlyExitDiscount += r.earlyExitDiscount;
      double baseAbsenceDisc = r.discount - r.lateDiscount - r.earlyExitDiscount;
      if (baseAbsenceDisc > 0) {
        finalAbsenceDiscount += baseAbsenceDisc;
      }
      finalTotalDiscount += r.discount;
    }

    final periodStr = '${DateFormat('yyyy-MM-dd').format(start)}_${DateFormat('yyyy-MM-dd').format(end)}';

    await PdfHelper.shareAttendancePdf(
      employee: employee,
      records: finalPrintRecords,
      title: reportTitle,
      subtitle: subtitle,
      reportPeriod: periodStr,
      totalDiscount: finalTotalDiscount,
      totalLateDiscount: finalLateDiscount,
      totalEarlyExitDiscount: finalEarlyExitDiscount,
      totalAbsenceDiscount: finalAbsenceDiscount,
      absentDays: absentDays,
      controller: controller,
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                color: color ?? AppTheme.textPrimary,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.bold)),
      ],
    );
  }

  Widget _buildProTimeBox(
      String label, String time, IconData icon, Color color) {
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
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text(time,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary)),
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
      case 'off':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusText(String status,
      [bool hasEarlyExit = false, bool hasLate = false, VacationRequestModel? vacation]) {
    String text = '';

    if (hasLate && hasEarlyExit) {
      return 'تأخير وخروج مبكر';
    } else if (hasEarlyExit) {
      return 'خروج مبكر';
    } else if (hasLate) {
      return 'متأخر';
    }

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
        text = vacation?.vacationType ?? 'إجازة';
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
    return text;
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
              Text('تصحيح بصمة',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
              Text(att.employeeName ?? 'الموظف',
                  style:
                      TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
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
                              color: Colors.black.withValues(alpha: 0.05),
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

  void _showSplitPayrollDialog(
      BuildContext context, EmployeeModel employee, AdminController controller) {
    final endDateStr = DateTime.now().toString().split(' ')[0];
    final startDateStr = DateTime.now().subtract(const Duration(days: 30)).toString().split(' ')[0];
    
    final selectedStartDate = RxString(startDateStr);
    final selectedEndDate = RxString(endDateStr);
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_clock_rounded, color: AppTheme.primaryTeal, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('الإغلاق الشهري', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('سيتم إغلاق وحفظ الرواتب للفترة المحددة كفترة مستقلة. سيقوم النظام تلقائياً بتخطي الفترات التي تم إغلاقها مسبقاً لتجنب التكرار.', 
                      style: TextStyle(color: Colors.black87, fontSize: 12, height: 1.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('من تاريخ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Obx(() => InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(selectedStartDate.value),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      selectedStartDate.value = picked.toString().split(' ')[0];
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: AppTheme.borderLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedStartDate.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Icon(Icons.calendar_month_rounded, size: 20, color: AppTheme.primaryTeal),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            const Text('إلى تاريخ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Obx(() => InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(selectedEndDate.value),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      selectedEndDate.value = picked.toString().split(' ')[0];
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: AppTheme.borderLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedEndDate.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Icon(Icons.calendar_month_rounded, size: 20, color: AppTheme.primaryTeal),
                      ],
                    ),
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final errorMap = await controller.splitEmployeePayroll(employee.id!, selectedStartDate.value, selectedEndDate.value);
              if (errorMap == null) {
                UiUtils.showSuccessDialog('نجاح', 'تم إنهاء وحفظ الفترة بنجاح.');
              } else if (errorMap['status'] == 'success') {
                final dups = errorMap['duplicates'] as List<dynamic>? ?? [];
                final details = dups.isNotEmpty ? '\n\nتم تخطي الفترات المغلقة مسبقاً: ' + dups.join(' , ') : '';
                UiUtils.showSuccessDialog('تم الإغلاق بنجاح', 'تمت عملية الإغلاق للفترات المطلوبة.$details');
              } else {
                final msg = errorMap['message'] ?? 'خطأ غير معروف';
                UiUtils.showErrorDialog('تنبيه الإغلاق', msg);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('حفظ الإغلاق', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  void _showClosingsBottomSheet(BuildContext context) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 800, // Make it look good on web/desktop
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.history_edu_rounded, color: AppTheme.primaryTeal, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('سجل الإغلاقات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                          SizedBox(height: 4),
                          Text('أرشيف الفترات المالية المحفوظة للموظف', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: Obx(() {
                  if (controller.selectedEmployeeClosings.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_rounded, size: 64, color: AppTheme.borderLight),
                            SizedBox(height: 16),
                            Text('لا توجد إغلاقات محفوظة لهذا الموظف', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(24),
                    itemCount: controller.selectedEmployeeClosings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final closing = controller.selectedEmployeeClosings[index];
                      final totals = closing.totals;
                      
                      final deductionRaw = double.tryParse((totals['total_deduction'] ?? 0).toString()) ?? 0.0;
                      final totalDeductionStr = deductionRaw.toStringAsFixed(2);
                      
                      final netSalaryRaw = closing.salarySnapshot - deductionRaw;
                      final netSalaryStr = netSalaryRaw.toStringAsFixed(2);

                      final presentDays = (totals['present_days'] ?? 0).toString();
                      final absentDays = (totals['absent_days'] ?? 0).toString();
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_month_rounded, color: AppTheme.primaryTeal, size: 20),
                                      const SizedBox(width: 8),
                                      Text('الفترة: ${closing.startDate} إلى ${closing.endDate}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryTeal.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text('${closing.month}/${closing.year}', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Expanded(child: _buildClosingStat('أيام الحضور', presentDays, Icons.check_circle_outline)),
                                  Container(height: 30, width: 1, color: AppTheme.borderLight),
                                  Expanded(child: _buildClosingStat('أيام الغياب', absentDays, Icons.event_busy_rounded, color: Colors.orange)),
                                  Container(height: 30, width: 1, color: AppTheme.borderLight),
                                  Expanded(child: _buildClosingStat('إجمالي الخصم', '$totalDeductionStr ر.س', Icons.money_off_rounded, color: AppTheme.errorRed)),
                                  Container(height: 30, width: 1, color: AppTheme.borderLight),
                                  Expanded(child: _buildClosingStat('الراتب المعتمد', '${closing.salarySnapshot} ر.س', Icons.account_balance_wallet_outlined)),
                                  Container(height: 30, width: 1, color: AppTheme.borderLight),
                                  Expanded(child: _buildClosingStat('الصافي', '$netSalaryStr ر.س', Icons.payments_rounded, color: AppTheme.successGreen)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
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

  Widget _buildClosingStat(String title, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? AppTheme.textSecondary),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? AppTheme.textPrimary)),
      ],
    );
  }

  void _showVacationsHistoryDialog(BuildContext context, AdminController controller, EmployeeModel employee) {
    int selectedMonth = 0; // 0 = all
    String selectedType = 'الكل';
    final List<String> types = ['الكل', ...AppConstants.getVacationTypes()];

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: Responsive.isMobile(context) ? 16 : 32, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final empVacations = controller.vacationRequests.where((v) => v.employeeId == employee.id).toList();
              
              // Filter
              final filtered = empVacations.where((v) {
                bool typeMatch = selectedType == 'الكل' || v.vacationType == selectedType;
                bool monthMatch = true;
                if (selectedMonth != 0) {
                  try {
                    monthMatch = DateTime.parse(v.startDate).month == selectedMonth;
                  } catch (_) {
                    monthMatch = false;
                  }
                }
                return typeMatch && monthMatch;
              }).toList();

              return Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.beach_access_rounded, color: AppTheme.primaryTeal),
                        SizedBox(width: 12),
                        Text('سجل طلبات الإجازة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
                      ],
                    ),
                  ),
                  
                  // Filters
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedMonth,
                            decoration: InputDecoration(
                              labelText: 'الشهر',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(value: 0, child: Text('الكل')),
                              ...List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(_getMonthNameArabic(index + 1)))),
                            ],
                            onChanged: (v) => setState(() => selectedMonth = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: InputDecoration(
                              labelText: 'النوع',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) => setState(() => selectedType = v!),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // List
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('لا توجد طلبات إجازة تطابق البحث', style: TextStyle(color: AppTheme.textSecondary)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final req = filtered[index];
                              Color statusColor = req.status == 'approved' ? AppTheme.successGreen : (req.status == 'rejected' ? AppTheme.errorRed : Colors.orange);
                              String statusText = req.status == 'approved' ? 'معتمدة' : (req.status == 'rejected' ? 'مرفوضة' : 'قيد الانتظار');

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.borderLight),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(req.vacationType, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                          child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            UiUtils.showConfirmDialog(
                                              title: 'تأكيد الحذف',
                                              message: 'هل أنت متأكد من حذف هذه الإجازة؟',
                                              confirmColor: AppTheme.errorRed,
                                              confirmText: 'حذف',
                                              onConfirm: () async {
                                                final res = await controller.deleteVacation(req.id!);
                                                if (res == null) {
                                                  UiUtils.showSuccessDialog('تم الحذف', 'تم حذف الإجازة بنجاح.');
                                                  controller.fetchEmployeeMonthlySummary(employee.id!);
                                                } else {
                                                  UiUtils.showErrorDialog('تعذر الحذف', res);
                                                }
                                              }
                                            );
                                          },
                                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.errorRed),
                                          tooltip: 'حذف الإجازة',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('${req.startDate}  إلى  ${req.endDate}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                    if (req.isHourly) Text('إجازة جزئية (${req.totalMinutes} د)', style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.bold)),
                                    if (!req.isHourly) Text('${req.totalDays} يوم', style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.bold)),
                                    if (req.attachment != null && req.attachment!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      InkWell(
                                        onTap: () async {
                                          final url = Uri.parse('${ApiService.baseApiUrl}/${req.attachment}');
                                          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                            UiUtils.showErrorDialog('خطأ', 'لا يمكن فتح المرفق');
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.attachment_rounded, size: 16, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('عرض المرفق', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
