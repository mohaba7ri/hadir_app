import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/employee_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';

class MyVacationsView extends StatelessWidget {
  const MyVacationsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<EmployeeController>();

    return Padding(
      padding: EdgeInsets.all(UiUtils.getPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showRequestDialog(context),
                  icon: Icon(Icons.add_rounded, size: 20),
                  label: const Text('طلب إجازة جديدة'),
                ),
              ),
              if (!Responsive.isMobile(context)) ...[
                SizedBox(width: 12),
                IconButton(
                  onPressed: () => controller.fetchMyVacations(),
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
            ],
          ),
          SizedBox(height: 32),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => await controller.fetchMyVacations(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Obx(() {
                  if (controller.myVacationRequests.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25),
                        const Center(
                            child: Text('لا توجد طلبات إجازة سابقة',
                                style:
                                    TextStyle(color: AppTheme.textSecondary))),
                      ],
                    );
                  }
                  return ListView.separated(
                    itemCount: controller.myVacationRequests.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final req = controller.myVacationRequests[index];
                      return ListTile(
                        onTap: () {},
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _getStatusColor(req.status)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.beach_access_rounded,
                              color: _getStatusColor(req.status), size: 20),
                        ),
                        title: Text(
                          '${req.startDate} ⟵ ${req.endDate}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppTheme.textPrimary),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              _buildMiniBadge(
                                  req.vacationType, AppTheme.primaryTeal),
                              SizedBox(width: 8),
                              if (req.isHourly)
                                _buildMiniBadge(
                                    'المدة: ${req.totalMinutes} دقيقة',
                                    AppTheme.textSecondary)
                              else
                                _buildMiniBadge('المدة: ${req.totalDays} أيام',
                                    AppTheme.textSecondary),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (req.attachment != null &&
                                req.attachment!.isNotEmpty)
                              IconButton(
                                onPressed: () async {
                                  final url = Uri.parse(
                                      '${ApiService.baseApiUrl}/${req.attachment}');
                                  if (await launchUrl(url,
                                      mode: LaunchMode.externalApplication)) {
                                  } else {
                                    UiUtils.showErrorDialog('تعذر الفتح',
                                        'لا يمكن فتح المرفق حالياً');
                                  }
                                },
                                icon: Icon(Icons.attach_file_rounded,
                                    size: 18, color: AppTheme.primaryTeal),
                                tooltip: 'عرض المرفق',
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(req.status)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getStatusText(req.status),
                                style: TextStyle(
                                  color: _getStatusColor(req.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
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
                                    } else {
                                      UiUtils.showErrorDialog('تعذر الحذف', res);
                                    }
                                  }
                                );
                              },
                              icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.errorRed),
                              tooltip: 'حذف الإجازة',
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
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

  String _getStatusText(String status) {
    if (status == 'pending') return 'قيد الانتظار';
    if (status == 'approved') return 'مقبولة';
    return 'مرفوضة';
  }

  Color _getStatusColor(String status) {
    if (status == 'pending') return Colors.orange;
    if (status == 'approved') return AppTheme.successGreen;
    return AppTheme.errorRed;
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showRequestDialog(BuildContext context) {
    final controller = Get.find<EmployeeController>();
    controller.fetchMyData(); // Fetch latest credit and requests
    final startController =
        TextEditingController(text: controller.preFilledVacationDate.value);
    final endController =
        TextEditingController(text: controller.preFilledVacationDate.value);
    final daysController = TextEditingController();
    final timeStartController = TextEditingController();
    final timeEndController = TextEditingController();
    final reasonController = TextEditingController();

    final RxString selectedType = AppConstants.annualLeave.obs;
    final RxBool isHourly = false.obs;
    final RxInt calculatedMinutes = 0.obs;
    final RxInt calculatedDays = 0.obs;
    final RxBool hasEnoughBalance = true.obs;
    final RxBool hasEnoughMonthlyBalance = true.obs;

    final types = AppConstants.getVacationTypes();

    int getRemainingBalance() {
      final int creditMinutes =
          controller.employeeData.value?.vacationCredit ?? 0;
      final int usedMinutes = controller.myVacationRequests
          .where((v) =>
              v.vacationType == AppConstants.annualLeave &&
              v.status == 'pending')
          .fold(0, (sum, v) => sum + v.totalMinutes);
      return creditMinutes - usedMinutes;
    }

    int getMonthlyRemainingBalance(DateTime requestMonth) {
      final int monthlyLimit =
          controller.employeeData.value?.monthlyAnnualLeaveLimitMinutes ?? 750;

      int reqMonth = requestMonth.month;
      int reqYear = requestMonth.year;
      if (requestMonth.day >= 25) {
        reqMonth++;
        if (reqMonth > 12) {
          reqMonth = 1;
          reqYear++;
        }
      }

      int baselineYear = 2026;
      int baselineMonth = 8;
      DateTime baselineCycleStart = DateTime(2026, 7, 25);

      if (reqYear < baselineYear || (reqYear == baselineYear && reqMonth < baselineMonth)) {
        int startMonth = reqMonth == 1 ? 12 : reqMonth - 1;
        int startYear = reqMonth == 1 ? reqYear - 1 : reqYear;
        DateTime cycleStart = DateTime(startYear, startMonth, 25);
        DateTime cycleEnd = DateTime(reqYear, reqMonth, 24, 23, 59, 59);

        final int usedMinutesThisMonth = controller.myVacationRequests.where((v) {
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

        return monthlyLimit - usedMinutesThisMonth;
      } else {
        int monthsElapsed = (reqYear - baselineYear) * 12 + (reqMonth - baselineMonth) + 1;
        int effectiveLimit = monthsElapsed * monthlyLimit;

        final int usedMinutesCumulative = controller.myVacationRequests.where((v) {
          if (v.vacationType != AppConstants.annualLeave) return false;
          if (v.status != 'pending' && v.status != 'approved') return false;
          try {
            final reqStart = DateTime.parse(v.startDate);
            return reqStart.isAfter(baselineCycleStart) || reqStart.isAtSameMomentAs(baselineCycleStart);
          } catch (_) {
            return false;
          }
        }).fold(0, (sum, v) => sum + v.totalMinutes);

        return effectiveLimit - usedMinutesCumulative;
      }
    }

    String formatMinutes(int total) {
      int h = total ~/ 60;
      int m = total % 60;
      if (h == 0) return '$m دقيقة';
      if (m == 0) return '$h ساعة';
      return '$h ساعة و $m دقيقة';
    }

    void calculateTotal() {
      if (isHourly.value) {
        if (timeStartController.text.isNotEmpty &&
            timeEndController.text.isNotEmpty) {
          try {
            final s = DateFormat('HH:mm').parse(timeStartController.text);
            final e = DateFormat('HH:mm').parse(timeEndController.text);
            int diff = e.difference(s).inMinutes;
            if (diff < 0) diff += 24 * 60;
            calculatedMinutes.value = diff;
            hasEnoughBalance.value =
                selectedType.value != AppConstants.annualLeave ||
                    getRemainingBalance() >= diff;
            final reqMonth =
                DateTime.tryParse(startController.text) ?? DateTime.now();
            hasEnoughMonthlyBalance.value =
                selectedType.value != AppConstants.annualLeave ||
                    getMonthlyRemainingBalance(reqMonth) >= diff;
          } catch (e) {
            calculatedMinutes.value = 0;
          }
        }
      } else {
        if (startController.text.isNotEmpty && endController.text.isNotEmpty) {
          try {
            final start = DateTime.parse(startController.text);
            final end = DateTime.parse(endController.text);
            final diff = end.difference(start).inDays + 1;
            if (diff > 0) {
              calculatedDays.value = diff;
              daysController.text = diff.toString();

              int dailyMins = controller.getSystemWorkDayDurationInMinutes();
              int totalMins = diff * dailyMins;
              calculatedMinutes.value = totalMins;
              hasEnoughBalance.value =
                  selectedType.value != AppConstants.annualLeave ||
                      getRemainingBalance() >= totalMins;
              final reqMonth =
                  DateTime.tryParse(startController.text) ?? DateTime.now();
              hasEnoughMonthlyBalance.value =
                  selectedType.value != AppConstants.annualLeave ||
                      getMonthlyRemainingBalance(reqMonth) >= totalMins;
            }
          } catch (e) {
            calculatedDays.value = 0;
          }
        }
      }
    }

    Get.dialog(
      AlertDialog(
        title: const Text('طلب إجازة جديدة'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => DropdownButtonFormField<String>(
                      value: selectedType.value,
                      decoration: const InputDecoration(labelText: 'نوع الطلب'),
                      items: types
                          .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) {
                        selectedType.value = v!;
                        calculateTotal();
                      },
                    )),
                SizedBox(height: 12),
                Obx(() => SwitchListTile(
                      title: const Text('إجازة (جزئية)',
                          style: TextStyle(fontSize: 13)),
                      value: isHourly.value,
                      onChanged: (v) {
                        isHourly.value = v;
                        calculateTotal();
                      },
                      contentPadding: EdgeInsets.zero,
                    )),
                SizedBox(height: 12),
                TextField(
                  controller: startController,
                  readOnly: true,
                  decoration: const InputDecoration(
                      labelText: 'التاريخ',
                      suffixIcon: Icon(Icons.calendar_month_rounded, size: 20)),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030));
                    if (picked != null) {
                      startController.text =
                          DateFormat('yyyy-MM-dd').format(picked);
                      if (!isHourly.value)
                        endController.text = startController.text;
                      calculateTotal();
                    }
                  },
                ),
                Obx(() {
                  if (!isHourly.value) {
                    return Column(
                      children: [
                        SizedBox(height: 12),
                        TextField(
                          controller: endController,
                          readOnly: true,
                          decoration: const InputDecoration(
                              labelText: 'تاريخ الانتهاء',
                              suffixIcon:
                                  Icon(Icons.calendar_month_rounded, size: 20)),
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2030));
                            if (picked != null) {
                              endController.text =
                                  DateFormat('yyyy-MM-dd').format(picked);
                              calculateTotal();
                            }
                          },
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: timeStartController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                    labelText: 'من الساعة'),
                                onTap: () async {
                                  TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          const TimeOfDay(hour: 8, minute: 0));
                                  if (picked != null) {
                                    timeStartController.text =
                                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                    calculateTotal();
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: timeEndController,
                                readOnly: true,
                                decoration: const InputDecoration(
                                    labelText: 'إلى الساعة'),
                                onTap: () async {
                                  TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime:
                                          const TimeOfDay(hour: 16, minute: 0));
                                  if (picked != null) {
                                    timeEndController.text =
                                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                    calculateTotal();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                }),
                SizedBox(height: 16),
                Obx(() => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('الرصيد المتاح:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                              Text(
                                  '${UiUtils.formatDaysApproximate(getRemainingBalance() / controller.getSystemWorkDayDurationInMinutes())} (${UiUtils.formatDuration(getRemainingBalance())})',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                          const Divider(),
                          if (selectedType.value != AppConstants.annualLeave)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 14, color: AppTheme.successGreen),
                                  SizedBox(width: 4),
                                  const Text('لن يتم الخصم من رصيد الإجازات',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.successGreen,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('المدة المطلوبة:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary)),
                              Text(formatMinutes(calculatedMinutes.value),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: hasEnoughBalance.value
                                          ? AppTheme.primaryTeal
                                          : AppTheme.errorRed,
                                      fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    )),
                SizedBox(height: 16),
                Obx(() {
                  if (selectedType.value != AppConstants.annualLeave ||
                      (hasEnoughBalance.value && hasEnoughMonthlyBalance.value))
                    return const SizedBox.shrink();

                  String errorMsg = '';
                  if (!hasEnoughBalance.value) {
                    errorMsg = 'رصيد الإجازات السنوية غير كافٍ.';
                  } else if (!hasEnoughMonthlyBalance.value) {
                    errorMsg =
                        'لقد تجاوزت الحد الشهري المسموح للإجازة السنوية.';
                  }

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppTheme.errorRed, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(errorMsg,
                                style: TextStyle(
                                    color: AppTheme.errorRed,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'سبب الإجازة / ملاحظات (اختياري)',
                    hintText: 'اكتب سبب الإجازة أو أي ملاحظات هنا...',
                  ),
                ),
                SizedBox(height: 16),
                const Divider(),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Obx(() => Text(
                      selectedType.value == AppConstants.annualLeave
                          ? 'المرفقات (اختياري)'
                          : 'المرفقات (مطلوب)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selectedType.value == AppConstants.annualLeave
                              ? AppTheme.textSecondary
                              : AppTheme.errorRed))),
                ),
                SizedBox(height: 8),
                Obx(() => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderLight)),
                      child: Column(
                        children: [
                          if (controller.selectedAttachmentFile.value == null)
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
                                    ]);
                                if (result != null)
                                  controller.selectedAttachmentFile.value =
                                      result.files.single;
                              },
                              icon: Icon(Icons.upload_file_rounded, size: 18),
                              label: const Text('اختيار ملف',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primaryTeal,
                                  elevation: 0,
                                  side:
                                      BorderSide(color: AppTheme.primaryTeal)),
                            )
                          else
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: AppTheme.successGreen, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                        controller
                                            .selectedAttachmentFile.value!.name,
                                        style: TextStyle(
                                            fontSize: 11,
                                            overflow: TextOverflow.ellipsis))),
                                IconButton(
                                    onPressed: () => controller
                                        .selectedAttachmentFile.value = null,
                                    icon: Icon(Icons.cancel_outlined,
                                        color: AppTheme.errorRed, size: 18)),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('إلغاء', style: TextStyle(fontSize: 12)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Obx(() => ElevatedButton(
                        onPressed: (selectedType.value ==
                                        AppConstants.annualLeave &&
                                    (!hasEnoughBalance.value ||
                                        !hasEnoughMonthlyBalance.value)) ||
                                calculatedMinutes.value == 0 ||
                                (selectedType.value !=
                                        AppConstants.annualLeave &&
                                    controller.selectedAttachmentFile.value ==
                                        null)
                            ? null
                            : () async {
                                // Validate if any day in range has both check-in and check-out
                                final startD =
                                    DateTime.parse(startController.text);
                                final endD = isHourly.value
                                    ? startD
                                    : DateTime.parse(endController.text);

                                bool hasWorkedDay = false;
                                for (int i = 0;
                                    i <= endD.difference(startD).inDays;
                                    i++) {
                                  final date = startD.add(Duration(days: i));
                                  final dateStr =
                                      DateFormat('yyyy-MM-dd').format(date);
                                  final att = controller.myAttendance
                                      .firstWhereOrNull(
                                          (a) => a.date == dateStr);
                                  if (att != null &&
                                      (att.checkIn ?? '').isNotEmpty &&
                                      (att.checkOut ?? '').isNotEmpty) {
                                    hasWorkedDay = true;
                                    break;
                                  }
                                }

                                if (hasWorkedDay) {
                                  UiUtils.showErrorDialog('تنبيه',
                                      'لا يمكنك طلب إجازة في يوم قمت بالبصمة فيه (دخول وخروج).');
                                  return;
                                }

                                final res = await controller.requestVacation(
                                  startController.text,
                                  isHourly.value
                                      ? startController.text
                                      : endController.text,
                                  calculatedDays.value,
                                  selectedType.value,
                                  attachmentFile:
                                      controller.selectedAttachmentFile.value,
                                  isHourly: isHourly.value,
                                  startTime: isHourly.value
                                      ? timeStartController.text
                                      : null,
                                  endTime: isHourly.value
                                      ? timeEndController.text
                                      : null,
                                  totalMinutes: calculatedMinutes.value,
                                  reason: reasonController.text.isNotEmpty
                                      ? reasonController.text
                                      : null,
                                );
                                if (res == true) {
                                  Get.back();
                                  UiUtils.showSuccessDialog('تم بنجاح',
                                      'تم تقديم طلب الإجازة بنجاح وهو الآن قيد الانتظار لمراجعة الإدارة.');
                                } else {
                                  UiUtils.showErrorDialog(
                                      'خطأ', res.toString());
                                }
                              },
                        child: controller.isLoading.value
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('إرسال الطلب',
                                style: TextStyle(fontSize: 12)),
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
