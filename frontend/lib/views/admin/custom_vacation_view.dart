import 'package:attendance_management/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/admin_controller.dart';
import '../../models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/constants/app_constants.dart';

class CustomVacationView extends StatefulWidget {
  const CustomVacationView({super.key});

  @override
  State<CustomVacationView> createState() => _CustomVacationViewState();
}

class _CustomVacationViewState extends State<CustomVacationView> {
  final controller = Get.find<AdminController>();

  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _detailsController = TextEditingController();

  String _selectedType = AppConstants.annualLeave;
  final List<String> _vacationTypes = AppConstants.getVacationTypes();

  final RxList<int> _selectedEmployeeIds = <int>[].obs;
  final Rx<PlatformFile?> _attachmentFile = Rx<PlatformFile?>(null);
  final RxBool _selectAll = false.obs;

  @override
  void initState() {
    super.initState();
    _startDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _endDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  void _toggleSelectAll(bool? value) {
    _selectAll.value = value ?? false;
    if (_selectAll.value) {
      _selectedEmployeeIds.value = controller.employees
          .where((e) => e.status == 'active')
          .map((e) => e.id!)
          .toList();
    } else {
      _selectedEmployeeIds.clear();
    }
  }

  void _toggleEmployee(int id) {
    if (_selectedEmployeeIds.contains(id)) {
      _selectedEmployeeIds.remove(id);
      _selectAll.value = false;
    } else {
      _selectedEmployeeIds.add(id);
      if (_selectedEmployeeIds.length ==
          controller.employees.where((e) => e.status == 'active').length) {
        _selectAll.value = true;
      }
    }
  }

  int get _calculatedTotalDays {
    try {
      final start = DateTime.parse(_startDateController.text);
      final end = DateTime.parse(_endDateController.text);
      if (end.isBefore(start)) return 0;
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _submit() async {
    if (_selectedEmployeeIds.isEmpty) {
      UiUtils.showErrorDialog('تنبيه', 'يرجى اختيار موظف واحد على الأقل');
      return;
    }

    final start = DateTime.parse(_startDateController.text);
    final end = DateTime.parse(_endDateController.text);

    if (end.isBefore(start)) {
      UiUtils.showErrorDialog(
          'خطأ', 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية');
      return;
    }

    final totalDays = end.difference(start).inDays + 1;

    // Show confirmation
    bool? confirm = await Get.dialog<bool>(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.help_outline_rounded,
              color: AppTheme.primaryTeal, size: 28),
          SizedBox(width: 12),
          Text('تأكيد الإجازة المخصصة'),
        ],
      ),
      content: Text(
          'سيتم إضافة إجازة لـ ${_selectedEmployeeIds.length} موظف بمسمى (${_selectedType}).\n\nهل أنت متأكد من المتابعة؟',
          style: TextStyle(fontSize: 14)),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('إلغاء',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('تأكيد الإسناد'),
        ),
      ],
    ));

    if (confirm != true) return;

    int successCount = 0;
    int failCount = 0;
    List<String> failedDetails = [];
    int total = _selectedEmployeeIds.length;
    RxInt currentProgress = 0.obs;

    Get.dialog(
      barrierDismissible: false,
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: EdgeInsets.all(Responsive.isMobile(context) ? 24 : 32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryTeal,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.isMobile(context) ? 16 : 24),
                  Text('جاري إسناد الإجازات...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: Responsive.isMobile(context) ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Obx(() => Text('تم معالجة ${currentProgress.value} من $total موظف',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: Responsive.isMobile(context) ? 13 : 14, 
                          color: AppTheme.textSecondary))),
                  SizedBox(height: Responsive.isMobile(context) ? 16 : 24),
                  Obx(() => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: total > 0 ? currentProgress.value / total : 0,
                          backgroundColor: AppTheme.borderLight,
                          color: AppTheme.primaryTeal,
                          minHeight: Responsive.isMobile(context) ? 6 : 8,
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    for (var empId in _selectedEmployeeIds) {
      final emp = controller.getEmployeeById(empId);
      if (emp == null) {
        failCount++;
        failedDetails.add('• مجهول: لم يتم العثور على بيانات الموظف');
        currentProgress.value++;
        continue;
      }

      // Credit check for Annual Leave
      final workMins = controller.getWorkDayDurationInMinutes(emp);
      final totalCreditDays = emp.vacationCredit / workMins;
      if (_selectedType == AppConstants.annualLeave &&
          totalCreditDays < totalDays) {
        // Skip silently, it's better UX than showing 50 stacked error dialogs
        failCount++;
        failedDetails.add('• ${emp.name}: رصيد الإجازات السنوية غير كافٍ (المتاح: ${UiUtils.formatDaysApproximate(totalCreditDays)})');
        currentProgress.value++;
        continue;
      }

      final request = VacationRequestModel(
        employeeId: empId,
        startDate: _startDateController.text,
        endDate: _endDateController.text,
        totalDays: totalDays,
        vacationType: _selectedType,
        status: 'approved', // Custom admin vacation is pre-approved
        reason: _detailsController.text,
        employeeName: emp.name,
      );

      dynamic errorReason = await controller.addVacationRequestWithReason(request,
          attachmentFile: _attachmentFile.value);
      
      if (errorReason == null) {
        successCount++;
      } else {
        failCount++;
        String msg = errorReason is Map ? (errorReason['message']?.toString() ?? 'خطأ') : errorReason.toString();
        failedDetails.add('• ${emp.name}: $msg');
      }
        
      currentProgress.value++;
    }

    // Close progress dialog
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    if (successCount > 0) {
      String msg = 'تمت إضافة الإجازة لـ $successCount موظف بنجاح.';
      if (failCount > 0) {
        msg += '\n\nملاحظة: تعذر الإسناد لـ $failCount موظفين للأسباب التالية:\n' + failedDetails.join('\n');
      }
      UiUtils.showSuccessDialog('اكتملت العملية', msg);
    } else if (failCount > 0) {
      UiUtils.showErrorDialog(
          'فشل العملية', 'تعذر إضافة الإجازة لـ $failCount موظفين للأسباب التالية:\n\n' + failedDetails.join('\n'));
    }

    if (successCount > 0) {
      // Clear selection
      _selectedEmployeeIds.clear();
      _selectAll.value = false;
      _detailsController.clear();
      _attachmentFile.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(UiUtils.getPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إجازة مخصصة',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const Text('إسناد إجازات لمجموعة من الموظفين بشكل مباشر',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form Section
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: _buildFormCard(),
                    ),
                  ),
                  if (!Responsive.isMobile(context)) SizedBox(width: 24),
                  // Employee Selection Section
                  if (!Responsive.isMobile(context))
                    Expanded(
                      flex: 2,
                      child: _buildEmployeeSelector(),
                    ),
                ],
              ),
            ),
            if (Responsive.isMobile(context)) ...[
              SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: _buildEmployeeSelector(),
              ),
              SizedBox(height: 16),
            ],
            SizedBox(height: 16),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('نوع الإجازة'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Obx(() {
              final auth = Get.find<AuthController>();
              final isSuper = auth.isSuperAdmin.value;
              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: _vacationTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedType = v);
                  },
                ),
              );
            }),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('من تاريخ'),
                    _buildDatePicker(_startDateController),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('إلى تاريخ'),
                    _buildDatePicker(_endDateController),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppTheme.primaryTeal),
                SizedBox(width: 8),
                Text('مدة الإجازة: $_calculatedTotalDays يوم',
                    style: TextStyle(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
          ),
          SizedBox(height: 20),
          _buildFieldLabel('تفاصيل الإجازة'),
          TextField(
            controller: _detailsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'أدخل تفاصيل إضافية هنا...',
              filled: true,
              fillColor: AppTheme.backgroundLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.borderLight),
              ),
            ),
          ),
          SizedBox(height: 20),
          _buildFieldLabel('المرفقات (اختياري)'),
          _buildAttachmentPicker(),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, right: 4),
      child: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.textPrimary)),
    );
  }

  Widget _buildDatePicker(TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.parse(controller.text),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(date);
        }
      },
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
        filled: true,
        fillColor: AppTheme.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderLight),
        ),
      ),
    );
  }

  Widget _buildAttachmentPicker() {
    return Obx(() {
      final hasFile = _attachmentFile.value != null;
      return InkWell(
        onTap: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
            withData: kIsWeb,
          );
          if (result != null) {
            _attachmentFile.value = result.files.single;
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasFile
                ? AppTheme.successGreen.withValues(alpha: 0.05)
                : AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: hasFile ? AppTheme.successGreen : AppTheme.borderLight,
                style: hasFile ? BorderStyle.solid : BorderStyle.none),
          ),
          child: Row(
            children: [
              Icon(
                  hasFile
                      ? Icons.check_circle_rounded
                      : Icons.cloud_upload_rounded,
                  color:
                      hasFile ? AppTheme.successGreen : AppTheme.textSecondary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasFile
                      ? _attachmentFile.value!.name
                      : 'اختيار ملف (صور أو PDF)',
                  style: TextStyle(
                      color: hasFile
                          ? AppTheme.successGreen
                          : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight:
                          hasFile ? FontWeight.bold : FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasFile)
                IconButton(
                  onPressed: () => _attachmentFile.value = null,
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: AppTheme.errorRed),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmployeeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('اختيار الموظفين',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Obx(() => Row(
                    children: [
                      const Text('الكل', style: TextStyle(fontSize: 13)),
                      Checkbox(
                        value: _selectAll.value,
                        onChanged: _toggleSelectAll,
                        activeColor: AppTheme.primaryTeal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  )),
            ],
          ),
          const Divider(),
          Expanded(
            child: Obx(() {
              final activeEmployees = controller.employees
                  .where((e) => e.status == 'active')
                  .toList();
              if (activeEmployees.isEmpty) {
                return const Center(
                    child: Text('لا يوجد موظفين نشطين',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)));
              }
              return ListView.builder(
                itemCount: activeEmployees.length,
                itemBuilder: (context, index) {
                  final emp = activeEmployees[index];
                  return Obx(() {
                    final isSelected = _selectedEmployeeIds.contains(emp.id);
                    return CheckboxListTile(
                      title:
                          Text(emp.name, style: TextStyle(fontSize: 14)),
                      subtitle: Text('ID: ${emp.id}',
                          style: TextStyle(fontSize: 11)),
                      value: isSelected,
                      onChanged: (_) => _toggleEmployee(emp.id!),
                      activeColor: AppTheme.primaryTeal,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.platform,
                    );
                  });
                },
              );
            }),
          ),
          const Divider(),
          Obx(() => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('تم اختيار ${_selectedEmployeeIds.length} موظف',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryTeal,
                        fontSize: 12)),
              )),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => ElevatedButton(
          onPressed: controller.isLoading.value ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryTeal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 54),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: controller.isLoading.value
              ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('إسناد الإجازة للمختارين',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ));
  }
}
