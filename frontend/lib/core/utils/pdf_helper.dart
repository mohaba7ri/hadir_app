import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:collection/collection.dart';
import '../../models/app_models.dart';
import '../../controllers/admin_controller.dart';

class PdfHelper {
  static Future<void> shareAttendancePdf({
    required EmployeeModel employee,
    required List<AttendanceModel> records,
    String title = 'سجل الحضور والغياب',
    String subtitle = '',
    String reportPeriod = '',
    required double totalDiscount,
    required double totalLateDiscount,
    required double totalEarlyExitDiscount,
    required double totalAbsenceDiscount,
    required int absentDays,
    required AdminController controller,
  }) async {
    final pdf = pw.Document();

    // Load Font
    final fontData = await rootBundle.load("assets/fonts/janat.ttf");
    final ttf = pw.Font.ttf(fontData);

    // Load Logo
    final logoData = await rootBundle.load("assets/logo.png");
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: ttf),
        textDirection: pw.TextDirection.rtl,
        header: (context) =>
            _buildHeader(employee, title, subtitle, ttf, logoImage),
        build: (context) => [
          _buildSummarySection(
              employee, records, totalDiscount, totalLateDiscount, totalEarlyExitDiscount, totalAbsenceDiscount, absentDays, controller, ttf),
          pw.SizedBox(height: 20),
          _buildAttendanceTable(records, employee, controller, ttf),
        ],
        footer: (context) => _buildFooter(context, ttf),
      ),
    );

    final periodSuffix = reportPeriod.isNotEmpty ? '_$reportPeriod' : '';
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${title}_${employee.name}$periodSuffix.pdf',
    );
  }

  static pw.Widget _buildHeader(EmployeeModel emp, String title,
      String subtitle, pw.Font font, pw.ImageProvider logo) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Image(logo, width: 45, height: 45),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(title,
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text(subtitle,
                        style: pw.TextStyle(font: font, fontSize: 11)),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(emp.name,
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text('الرقم الوظيفي: #${emp.id}',
                    style: pw.TextStyle(font: font, fontSize: 10)),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.blueGrey),
        pw.SizedBox(height: 10),
      ],
    );
  }

  static pw.Widget _buildSummarySection(
      EmployeeModel emp,
      List<AttendanceModel> records,
      double totalDiscount,
      double totalLateDiscount,
      double totalEarlyExitDiscount,
      double totalAbsenceDiscount,
      int absentDays,
      AdminController controller,
      pw.Font font) {
    final Map<String, int> fullDays = {};
    final Map<String, int> hourlyMins = {};

    for (var r in records) {
      final effectiveStatus = r.status;
      if (effectiveStatus == 'vacation') {
        final vac = controller.getApprovedVacation(emp.id ?? 0, r.date);
        if (vac != null) {
          final typeStr = vac.vacationType;
          fullDays[typeStr] = (fullDays[typeStr] ?? 0) + 1;
        }
      }

      final hourlyVac =
          controller.getHourlyVacationRequest(emp.id ?? 0, r.date);
      if (hourlyVac != null) {
        final typeStr = hourlyVac.vacationType;
        hourlyMins[typeStr] =
            (hourlyMins[typeStr] ?? 0) + hourlyVac.totalMinutes;
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Wrap(
        spacing: 24,
        runSpacing: 12,
        alignment: pw.WrapAlignment.spaceAround,
        children: [
          _buildStat('الراتب الأساسي', '${emp.salary} ر.س', font),
          if (absentDays > 0)
            _buildStat('أيام الغياب', '$absentDays يوم', font, isError: true),
          if (totalLateDiscount > 0)
            _buildStat('خصم التأخير',
                '${totalLateDiscount.toStringAsFixed(2)} ر.س', font,
                isError: true),
          if (totalEarlyExitDiscount > 0)
            _buildStat('خصم خروج مبكر',
                '${totalEarlyExitDiscount.toStringAsFixed(2)} ر.س', font,
                isError: true),
          if (totalAbsenceDiscount > 0)
            _buildStat('خصم الغياب',
                '${totalAbsenceDiscount.toStringAsFixed(2)} ر.س', font,
                isError: true),
          ...(() {
            final Set<String> allVacTypes = {
              ...fullDays.keys,
              ...hourlyMins.keys
            };
            final List<pw.Widget> vacStats = [];

            for (var type in allVacTypes) {
              int days = fullDays[type] ?? 0;
              int mins = hourlyMins[type] ?? 0;

              int hours = mins ~/ 60;
              int remMins = mins % 60;

              List<String> parts = [];
              if (days > 0) parts.add('$days يوم');
              if (hours > 0) parts.add('$hours ساعات');
              if (remMins > 0) parts.add('$remMins دقيقة');

              if (parts.isNotEmpty) {
                vacStats.add(_buildStat(type, parts.join(' و'), font));
              }
            }
            return vacStats;
          })(),
          _buildStat(
              'إجمالي الخصم', '${totalDiscount.toStringAsFixed(2)} ر.س', font,
              isError: totalDiscount > 0),
          _buildStat('صافي المستحق',
              '${(emp.salary - totalDiscount).toStringAsFixed(2)} ر.س', font),
        ],
      ),
    );
  }

  static Future<void> shareOvertimePdf({
    required EmployeeModel employee,
    required List<OvertimeRequestModel> records,
    String title = 'تقرير العمل الإضافي',
    String reportPeriod = '',
    required AdminController controller,
  }) async {
    final pdf = pw.Document();

    // Load Font
    final fontData = await rootBundle.load("assets/fonts/janat.ttf");
    final ttf = pw.Font.ttf(fontData);

    // Load Logo
    final logoData = await rootBundle.load("assets/logo.png");
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(base: ttf),
        textDirection: pw.TextDirection.rtl,
        header: (context) => _buildHeader(employee, title, '', ttf, logoImage),
        build: (context) => [
          _buildOvertimeSummary(employee, records, controller, ttf),
          pw.SizedBox(height: 20),
          _buildOvertimeTable(records, employee, ttf),
        ],
        footer: (context) => _buildFooter(context, ttf),
      ),
    );

    final periodSuffix = reportPeriod.isNotEmpty ? '_$reportPeriod' : '';
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${title}_${employee.name}$periodSuffix.pdf',
    );
  }

  static pw.Widget _buildOvertimeSummary(
      EmployeeModel emp,
      List<OvertimeRequestModel> records,
      AdminController controller,
      pw.Font font) {
    final approved = records.where((r) => r.status == 'approved').toList();
    int totalMins = approved.fold(0, (sum, r) => sum + r.totalMinutes);
    int hours = totalMins ~/ 60;
    int mins = totalMins % 60;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _buildStat('الموظف', emp.name, font),
          _buildStat('القسم', emp.departmentName ?? 'غير محدد', font),
          _buildStat('الطلبات المعتمدة', approved.length.toString(), font),
          _buildStat('إجمالي الساعات', '$hours ساعة و$mins دقيقة', font),
        ],
      ),
    );
  }

  static pw.Widget _buildOvertimeTable(List<OvertimeRequestModel> records,
      EmployeeModel employee, pw.Font font) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5), // ملاحظات الإدارة
        1: const pw.FlexColumnWidth(2.5), // السبب
        2: const pw.FlexColumnWidth(1.5), // الحالة
        3: const pw.FlexColumnWidth(1.5), // المدة
        4: const pw.FlexColumnWidth(1.5), // النهاية
        5: const pw.FlexColumnWidth(1.5), // البداية
        6: const pw.FlexColumnWidth(2.0), // التاريخ
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          children: [
            _cell('ملاحظات الإدارة', font, isHeader: true),
            _cell('السبب', font, isHeader: true),
            _cell('الحالة', font, isHeader: true),
            _cell('المدة', font, isHeader: true),
            _cell('نهاية', font, isHeader: true),
            _cell('بداية', font, isHeader: true),
            _cell('التاريخ', font, isHeader: true),
          ],
        ),
        ...records.map((r) {
          int hours = r.totalMinutes ~/ 60;
          int remMins = r.totalMinutes % 60;
          String durationText = '$hours س';
          if (remMins > 0) durationText += ' و$remMins د';

          String statusText = r.status == 'approved'
              ? 'معتمد'
              : (r.status == 'rejected' ? 'مرفوض' : 'معلق');
          PdfColor statusColor = r.status == 'approved'
              ? PdfColors.green
              : (r.status == 'rejected' ? PdfColors.red : PdfColors.orange);

          return pw.TableRow(
            children: [
              _cell(r.adminNote ?? '-', font),
              _cell(r.reason ?? '-', font),
              _cell(statusText, font,
                  backgroundColor: statusColor == PdfColors.green
                      ? PdfColors.green100
                      : (statusColor == PdfColors.red
                          ? PdfColors.red100
                          : PdfColors.orange100)),
              _cell(durationText, font),
              _cell(r.endTime, font),
              _cell(r.startTime, font),
              _cell(r.date, font),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildStat(String label, String value, pw.Font font,
      {bool isError = false}) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: font, fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(
                font: font,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: isError ? PdfColors.red : PdfColors.black)),
      ],
    );
  }

  static pw.Widget _buildAttendanceTable(List<AttendanceModel> records,
      EmployeeModel employee, AdminController controller, pw.Font font) {
    final filtered = records
        .where((r) => r.status != 'pending')
        .toList();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3.5), // ملاحظات
        1: const pw.FlexColumnWidth(1.5), // الخصم
        2: const pw.FlexColumnWidth(2.0), // الحالة
        3: const pw.FlexColumnWidth(1.0), // خروج
        4: const pw.FlexColumnWidth(1.0), // دخول
        5: const pw.FlexColumnWidth(2.0), // التاريخ / اليوم
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          children: [
            _cell('ملاحظات', font, isHeader: true),
            _cell('الخصم', font, isHeader: true),
            _cell('الحالة', font, isHeader: true),
            _cell('خروج', font, isHeader: true),
            _cell('دخول', font, isHeader: true),
            _cell('التاريخ / اليوم', font, isHeader: true),
          ],
        ),
        // Data Rows
        ...filtered.map((r) {
          final statusStr = r.status;
          final date = DateTime.tryParse(r.date) ?? DateTime.now();
          final dayName = _getDayNameArabic(date);

          String statusText = _getStatusArabic(statusStr, r.earlyExitMinutes > 0);

          final recordDate = DateTime.tryParse(r.date) ?? DateTime.now();
          int m = recordDate.month;
          int y = recordDate.year;
          if (recordDate.day >= 25) {
            m++;
            if (m > 12) {
              m = 1;
              y++;
            }
          }
          int recordDivisor = DateTime(y, m + 1, 0).day;

          final effectiveLate = r.lateMinutes;
          final isEarly = r.earlyExitMinutes > 0;

          final lateDisc = r.lateDiscount;
          final earlyDisc = r.earlyExitDiscount;
          final earlyMins = r.earlyExitMinutes;

          if (effectiveLate > 0 || earlyMins > 0) {
            List<String> parts = [];
            if (effectiveLate > 0) {
              String discText = lateDisc > 0 ? ' (${lateDisc.toStringAsFixed(2)})' : '';
              parts.add('تأخير $effectiveLateد$discText');
            }
            if (earlyMins > 0) {
              String discText = earlyDisc > 0 ? ' (${earlyDisc.toStringAsFixed(2)})' : '';
              parts.add('خروج مبكر $earlyMinsد$discText');
            }
            statusText = parts.join(' | ');
          } else if (statusStr == 'vacation') {
            final vac =
                controller.getApprovedVacation(employee.id ?? 0, r.date);
            if (vac != null) statusText = vac.vacationType;
          }

          final hourlyVac =
              controller.getHourlyVacationRequest(employee.id ?? 0, r.date);
          if (hourlyVac != null) {
            String hourlyText =
                'تم طلب (${hourlyVac.totalMinutes}د) من (${hourlyVac.vacationType})';
            if (statusText.isNotEmpty && statusText != 'حاضر') {
              statusText += ' | $hourlyText';
            } else {
              statusText = hourlyText;
            }
          }

          final approvedCheckInCorr = controller.correctionRequests
              .firstWhereOrNull((c) =>
                  c.date == r.date &&
                  c.employeeId == r.employeeId &&
                  c.status == 'approved' &&
                  (c.type == 'check_in' || c.type == 'missing_check_in'));

          final approvedCheckOutCorr = controller.correctionRequests
              .firstWhereOrNull((c) =>
                  c.date == r.date &&
                  c.employeeId == r.employeeId &&
                  c.status == 'approved' &&
                  (c.type == 'check_out' || c.type == 'missing_check_out'));

          // Format check-in/check-out to be time only
          String checkIn = _formatTime(approvedCheckInCorr != null
              ? approvedCheckInCorr.requestedTime
              : r.checkIn);
          String checkOut = _formatTime(approvedCheckOutCorr != null
              ? approvedCheckOutCorr.requestedTime
              : r.checkOut);

          final discount = r.discount;

          // Build notes string
          List<String> notesParts = [];
          final approvedVac =
              controller.getApprovedVacation(employee.id ?? 0, r.date);
          if (approvedVac != null &&
              approvedVac.reason != null &&
              approvedVac.reason!.trim().isNotEmpty) {
            notesParts.add('إجازة: ${approvedVac.reason!}');
          }
          if (hourlyVac != null &&
              hourlyVac.reason != null &&
              hourlyVac.reason!.trim().isNotEmpty) {
            notesParts.add('طلب إجازة: ${hourlyVac.reason!}');
          }
          if (approvedCheckInCorr != null &&
              approvedCheckInCorr.reason.trim().isNotEmpty) {
            notesParts.add('تصحيح دخول: ${approvedCheckInCorr.reason}');
          }
          if (approvedCheckOutCorr != null &&
              approvedCheckOutCorr.reason.trim().isNotEmpty) {
            notesParts.add('تصحيح خروج: ${approvedCheckOutCorr.reason}');
          }
          if (r.notes != null && r.notes!.trim().isNotEmpty) {
            notesParts.add('سجل: ${r.notes!}');
          }
          String notesText = notesParts.join('\n');

          PdfColor? rowColor;
          if (statusStr == 'absent') {
            rowColor = PdfColors.red100;
          } else if (statusStr == 'vacation') {
            rowColor = PdfColors.blue100;
          } else if (statusStr == 'holiday') {
            rowColor = PdfColors.green100;
          } else if (statusStr == 'off') {
            rowColor = PdfColors.grey100;
          }

          return pw.TableRow(
            decoration:
                rowColor != null ? pw.BoxDecoration(color: rowColor) : null,
            children: [
              _cell(notesText, font),
              _cell(discount > 0 ? '${discount.toStringAsFixed(2)} ر.س' : '-',
                  font,
                  isError: discount > 0),
              _cell(statusText, font),
              _cell(checkOut, font,
                  backgroundColor: approvedCheckOutCorr != null
                      ? PdfColors.orange100
                      : null),
              _cell(checkIn, font,
                  backgroundColor:
                      approvedCheckInCorr != null ? PdfColors.orange100 : null),
              _cell(
                pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(dayName,
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text(r.date,
                        style: pw.TextStyle(
                            font: font, fontSize: 7, color: PdfColors.grey700)),
                  ],
                ),
                font,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(dynamic content, pw.Font font,
      {bool isHeader = false,
      bool isError = false,
      PdfColor? backgroundColor}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      alignment: pw.Alignment.center,
      color: backgroundColor,
      child: content is String
          ? pw.Text(
              content,
              style: pw.TextStyle(
                font: font,
                fontSize: isHeader ? 9 : 8,
                fontWeight:
                    isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isHeader
                    ? PdfColors.white
                    : (isError ? PdfColors.red : PdfColors.black),
              ),
            )
          : content as pw.Widget,
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
      child: pw.Text(
        'صفحة ${context.pageNumber} من ${context.pagesCount}',
        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  static String _getDayNameArabic(DateTime date) {
    final days = {
      1: 'الاثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };
    return days[date.weekday] ?? '';
  }

  static String _getStatusArabic(String status, [bool hasEarlyExit = false]) {
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

  static String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty || timeStr == '--:--')
      return '--:--';
    try {
      String timePart =
          timeStr.contains(' ') ? timeStr.split(' ').last : timeStr;
      final parts = timePart.split(':');
      if (parts.length < 2) return timePart;

      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      String period = hour >= 12 ? 'م' : 'ص';
      int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

      String minuteStr = minute.toString().padLeft(2, '0');
      return '$displayHour:$minuteStr $period';
    } catch (e) {
      return timeStr;
    }
  }
}
