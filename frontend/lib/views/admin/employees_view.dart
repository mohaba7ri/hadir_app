import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../models/app_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_utils.dart';

class EmployeesView extends StatelessWidget {
  const EmployeesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return Padding(
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
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: Responsive.isMobile(context) ? double.infinity : 300,
                    child: TextField(
                      onChanged: (v) => controller.searchQuery.value = v,
                      decoration: InputDecoration(
                        hintText: 'بحث عن موظف...',
                        prefixIcon: Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppTheme.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                    ),
                  ),
                  // Department Filter
                  Container(
                    width: Responsive.isMobile(context) ? double.infinity : 200,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Obx(() => DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: controller.selectedDepartmentFilter.value,
                            hint: const Text('الإدارة: الكل'),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('الكل'),
                              ),
                              ...controller.departments
                                  .map((d) => DropdownMenuItem<int?>(
                                        value: d.id,
                                        child: Text(d.name),
                                      ))
                                  .toList(),
                            ],
                            onChanged: (v) =>
                                controller.selectedDepartmentFilter.value = v,
                          ),
                        )),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showEmployeeDialog(context, null),
                    icon: Icon(Icons.add_rounded, size: 20),
                    label: const Text('إضافة موظف'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Responsive.isMobile(context)
                          ? const Size(double.infinity, 48)
                          : const Size(160, 48),
                    ),
                  ),
                  if (!Responsive.isMobile(context))
                    IconButton(
                      onPressed: () => controller.fetchEmployees(),
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
          ),
          SizedBox(height: 32),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => await controller.fetchEmployees(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.filteredEmployees.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25),
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline_rounded,
                                  size: 64, color: AppTheme.textSecondary),
                              SizedBox(height: 16),
                              Text('لا يوجد موظفين حالياً',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    itemCount: controller.filteredEmployees.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final emp = controller.filteredEmployees[index];
                      final isActive = emp.status == 'active';

                      return ListTile(
                          onTap: () => Get.toNamed('/admin/employee-details',
                              arguments: emp),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (isActive
                                      ? AppTheme.primaryTeal
                                      : AppTheme.textSecondary)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(Icons.person_rounded,
                                  color: isActive
                                      ? AppTheme.primaryTeal
                                      : AppTheme.textSecondary),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(emp.name,
                                  style: TextStyle(
                                    color: isActive
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                    decoration: isActive
                                        ? null
                                        : TextDecoration.lineThrough,
                                  )),
                              if (emp.departmentName != null) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryTeal
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    emp.departmentName!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primaryTeal,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                              '${emp.salary} ر.س | رصيد إجازات: ${UiUtils.formatDaysApproximate(emp.vacationCredit / controller.getSystemWorkDayDurationInMinutes())} (${UiUtils.formatDuration(emp.vacationCredit)})'
                              '${emp.specialStartTime != null ? ' | بدء: ${emp.specialStartTime}' : ''}'
                              '${emp.specialEndTime != null ? ' | انتهاء: ${emp.specialEndTime}' : ''}'),
                          trailing: SizedBox(
                            width: Responsive.isDesktop(context) ? 180 : 48,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (Responsive.isDesktop(context)) ...[
                                  // Activation Toggle
                                  Switch(
                                    value: isActive,
                                    onChanged: (value) async {
                                      emp.status =
                                          value ? 'active' : 'inactive';
                                      await controller.updateEmployee(emp);
                                    },
                                    activeColor: AppTheme.successGreen,
                                  ),
                                  SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.edit_rounded,
                                        color: AppTheme.primaryTeal, size: 20),
                                    onPressed: () =>
                                        _showEmployeeDialog(context, emp),
                                    style: IconButton.styleFrom(
                                        backgroundColor: AppTheme.primaryTeal
                                            .withValues(alpha: 0.05)),
                                  ),
                                  SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded,
                                        color: AppTheme.errorRed, size: 20),
                                    onPressed: () =>
                                        _confirmDelete(context, emp.id!),
                                    style: IconButton.styleFrom(
                                        backgroundColor: AppTheme.errorRed
                                            .withValues(alpha: 0.05)),
                                  ),
                                ] else
                                  PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'edit') {
                                        _showEmployeeDialog(context, emp);
                                      } else if (v == 'delete') {
                                        _confirmDelete(context, emp.id!);
                                      } else if (v == 'toggle') {
                                        emp.status =
                                            isActive ? 'inactive' : 'active';
                                        controller.updateEmployee(emp);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'toggle',
                                        child: ListTile(
                                          leading: Icon(
                                              isActive
                                                  ? Icons.close_rounded
                                                  : Icons.check_circle_rounded,
                                              color: isActive
                                                  ? AppTheme.errorRed
                                                  : AppTheme.successGreen),
                                          title: Text(isActive
                                              ? 'تعطيل الحساب'
                                              : 'تفعيل الحساب'),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                          leading: Icon(Icons.edit_rounded,
                                              color: AppTheme.primaryTeal),
                                          title: Text('تعديل'),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(Icons.delete_rounded,
                                              color: AppTheme.errorRed),
                                          title: Text('حذف'),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ));
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

  void _showEmployeeDialog(BuildContext context, EmployeeModel? employee) {
    final controller = Get.find<AdminController>();
    final idController =
        TextEditingController(text: employee?.id?.toString() ?? '');
    final nameController = TextEditingController(text: employee?.name ?? '');
    final salaryController =
        TextEditingController(text: employee?.salary.toString() ?? '0');
    final specialStartTimeController =
        TextEditingController(text: employee?.specialStartTime ?? '');
    final specialEndTimeController =
        TextEditingController(text: employee?.specialEndTime ?? '');
    final workDaysController = TextEditingController(
        text: employee?.workDaysPerWeek.toString() ?? '6');

    final workMins = controller.settings.value == null
        ? 480
        : controller.getWorkDayDurationInMinutes(employee);

    final initialMinutes = employee?.vacationCredit ?? (30 * workMins);
    final initialDays = initialMinutes / workMins;

    final vacationCreditController =
        TextEditingController(text: initialDays.toStringAsFixed(2));
    final vacationCreditMinutesController =
        TextEditingController(text: initialMinutes.toString());
    final vacationCreditHoursController =
        TextEditingController(text: (initialMinutes / 60).toStringAsFixed(2));
    final int initialMonthlyLimitMins = employee?.monthlyAnnualLeaveLimitMinutes ?? 750;
    final monthlyAnnualLeaveLimitHoursController =
        TextEditingController(text: (initialMonthlyLimitMins ~/ 60).toString());
    final monthlyAnnualLeaveLimitMinutesController =
        TextEditingController(text: (initialMonthlyLimitMins % 60).toString());

    // Sync listeners
    vacationCreditController.addListener(() {
      if (vacationCreditController.selection.baseOffset < 0) return;
      double days = double.tryParse(vacationCreditController.text) ?? 0;
      int mins = (days * workMins).toInt();
      if (vacationCreditMinutesController.text != mins.toString()) {
        vacationCreditMinutesController.text = mins.toString();
      }
      String hrs = (mins / 60).toStringAsFixed(2);
      if (vacationCreditHoursController.text != hrs) {
        vacationCreditHoursController.text = hrs;
      }
    });

    vacationCreditMinutesController.addListener(() {
      if (vacationCreditMinutesController.selection.baseOffset < 0) return;
      int mins = int.tryParse(vacationCreditMinutesController.text) ?? 0;
      double days = mins / workMins;
      if (vacationCreditController.text != days.toStringAsFixed(2)) {
        vacationCreditController.text = days.toStringAsFixed(2);
      }
      String hrs = (mins / 60).toStringAsFixed(2);
      if (vacationCreditHoursController.text != hrs) {
        vacationCreditHoursController.text = hrs;
      }
    });

    vacationCreditHoursController.addListener(() {
      if (vacationCreditHoursController.selection.baseOffset < 0) return;
      double hrs = double.tryParse(vacationCreditHoursController.text) ?? 0;
      int mins = (hrs * 60).toInt();
      if (vacationCreditMinutesController.text != mins.toString()) {
        vacationCreditMinutesController.text = mins.toString();
      }
      double days = mins / workMins;
      if (vacationCreditController.text != days.toStringAsFixed(2)) {
        vacationCreditController.text = days.toStringAsFixed(2);
      }
    });

    final passwordController =
        TextEditingController(text: employee?.password ?? '123');
    final isFlexible = (employee?.isFlexible ?? false).obs;
    final initialReqHrs = employee?.requiredHours ?? 8.0;
    final int initialReqHrsInt = initialReqHrs.floor();
    final int initialReqMins =
        ((initialReqHrs - initialReqHrsInt) * 60).round();
    final requiredHoursTextController =
        TextEditingController(text: initialReqHrsInt.toString());
    final requiredMinutesTextController =
        TextEditingController(text: initialReqMins.toString());
    final selectedDeptId = (employee?.departmentId).obs;

    Get.dialog(
      AlertDialog(
        title: Text(employee == null ? 'إضافة موظف جديد' : 'تعديل موظف'),
        contentPadding: EdgeInsets.zero,
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Container(
          width: Responsive.isDesktop(context) ? 950 : 400,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                          'المعلومات الأساسية', Icons.person_outline_rounded),
                      SizedBox(height: 16),
                      if (Responsive.isDesktop(context))
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                  controller: idController,
                                  enabled: employee == null,
                                  decoration: const InputDecoration(
                                    labelText: 'الرقم الوظيفي',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                    hintText: 'من جهاز البصمة',
                                  ),
                                  keyboardType: TextInputType.number),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'الاسم الكامل',
                                    prefixIcon: Icon(Icons.person_outline),
                                  )),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                  controller: salaryController,
                                  decoration: const InputDecoration(
                                    labelText: 'الراتب الأساسي',
                                    prefixIcon: Icon(Icons.payments_outlined),
                                    suffixText: 'ر.س',
                                  ),
                                  keyboardType: TextInputType.number),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: Obx(() => DropdownButtonFormField<int?>(
                                    value: selectedDeptId.value,
                                    decoration: const InputDecoration(
                                      labelText: 'الإدارة',
                                      prefixIcon: Icon(Icons.business_rounded),
                                    ),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('بدون إدارة'),
                                      ),
                                      ...controller.departments
                                          .map((d) => DropdownMenuItem<int?>(
                                                value: d.id,
                                                child: Text(d.name),
                                              ))
                                          .toList(),
                                    ],
                                    onChanged: (v) => selectedDeptId.value = v,
                                  )),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            TextField(
                                controller: idController,
                                enabled: employee == null,
                                decoration: const InputDecoration(
                                  labelText: 'الرقم الوظيفي',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                  hintText: 'من جهاز البصمة',
                                ),
                                keyboardType: TextInputType.number),
                            SizedBox(height: 16),
                            TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'الاسم الكامل',
                                  prefixIcon: Icon(Icons.person_outline),
                                )),
                            SizedBox(height: 16),
                            TextField(
                                controller: salaryController,
                                decoration: const InputDecoration(
                                  labelText: 'الراتب الأساسي',
                                  prefixIcon: Icon(Icons.payments_outlined),
                                  suffixText: 'ر.س',
                                ),
                                keyboardType: TextInputType.number),
                            SizedBox(height: 16),
                            Obx(() => DropdownButtonFormField<int?>(
                                  value: selectedDeptId.value,
                                  decoration: const InputDecoration(
                                    labelText: 'الإدارة',
                                    prefixIcon: Icon(Icons.business_rounded),
                                  ),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('بدون إدارة'),
                                    ),
                                    ...controller.departments
                                        .map((d) => DropdownMenuItem<int?>(
                                              value: d.id,
                                              child: Text(d.name),
                                            ))
                                        .toList(),
                                  ],
                                  onChanged: (v) => selectedDeptId.value = v,
                                )),
                          ],
                        ),
                      SizedBox(height: 32),
                      _buildSectionHeader(
                          'الدوام والأمان', Icons.security_rounded),
                      SizedBox(height: 16),
                      if (Responsive.isDesktop(context))
                        Column(
                          children: [
                            Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                  hintText: 'الافتراضية 123',
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value:
                                    int.tryParse(workDaysController.text) ?? 6,
                                items: List.generate(6, (index) => index + 1)
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text('$e أيام'),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null)
                                    workDaysController.text = v.toString();
                                },
                                decoration: const InputDecoration(
                                  labelText: 'أيام العمل في الأسبوع',
                                  prefixIcon:
                                      Icon(Icons.calendar_month_rounded),
                                ),
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: vacationCreditController,
                                decoration: const InputDecoration(
                                  labelText: 'الإجازات (أيام)',
                                  prefixIcon: Icon(Icons.beach_access_rounded),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: vacationCreditHoursController,
                                decoration: const InputDecoration(
                                  labelText: 'الإجازات (ساعات)',
                                  prefixIcon:
                                      Icon(Icons.history_toggle_off_rounded),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: vacationCreditMinutesController,
                                decoration: const InputDecoration(
                                  labelText: 'الإجازات (دقائق)',
                                  prefixIcon: Icon(Icons.timer_rounded),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: monthlyAnnualLeaveLimitHoursController,
                                decoration: const InputDecoration(
                                  labelText: 'الحد الشهري للإجازة السنوية (ساعات)',
                                  prefixIcon: Icon(Icons.av_timer_rounded),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: monthlyAnnualLeaveLimitMinutesController,
                                decoration: const InputDecoration(
                                  labelText: 'الحد الشهري (دقائق)',
                                  prefixIcon: Icon(Icons.timer_outlined),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const Spacer(flex: 3),
                          ],
                        ),
                      ],
                    )
                  else
                        Column(
                          children: [
                            TextField(
                              controller: passwordController,
                              decoration: const InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                                hintText: 'الافتراضية 123',
                              ),
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<int>(
                              value: int.tryParse(workDaysController.text) ?? 6,
                              items: List.generate(6, (index) => index + 1)
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text('$e أيام'),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null)
                                  workDaysController.text = v.toString();
                              },
                              decoration: const InputDecoration(
                                labelText: 'أيام العمل في الأسبوع',
                                prefixIcon: Icon(Icons.calendar_month_rounded),
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: vacationCreditController,
                                    decoration: const InputDecoration(
                                      labelText: 'الإجازات (أيام)',
                                      prefixIcon:
                                          Icon(Icons.beach_access_rounded),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: vacationCreditHoursController,
                                    decoration: const InputDecoration(
                                      labelText: 'الإجازات (ساعات)',
                                      prefixIcon: Icon(
                                          Icons.history_toggle_off_rounded),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: vacationCreditMinutesController,
                                    decoration: const InputDecoration(
                                      labelText: 'الإجازات (دقائق)',
                                      prefixIcon: Icon(Icons.timer_rounded),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: monthlyAnnualLeaveLimitHoursController,
                                    decoration: const InputDecoration(
                                      labelText: 'الحد الشهري للإجازة السنوية (ساعات)',
                                      prefixIcon: Icon(Icons.av_timer_rounded),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: monthlyAnnualLeaveLimitMinutesController,
                                    decoration: const InputDecoration(
                                      labelText: 'الحد الشهري (دقائق)',
                                      prefixIcon: Icon(Icons.timer_outlined),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      SizedBox(height: 32),
                      _buildSectionHeader(
                          'نظام الدوام المخصص', Icons.access_time_rounded),
                      SizedBox(height: 8),
                      Obx(() => CheckboxListTile(
                            title: const Text('ليس له وقت محدد (دوام مرن)',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text(
                                'يتم احتساب الدوام بناءً على عدد الساعات المنجزة فقط'),
                            value: isFlexible.value,
                            onChanged: (v) => isFlexible.value = v ?? false,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppTheme.primaryTeal,
                          )),
                      SizedBox(height: 12),
                      Obx(() {
                        if (isFlexible.value) {
                          return SizedBox(
                            width: Responsive.isDesktop(context)
                                ? 400
                                : double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                      controller: requiredHoursTextController,
                                      decoration: const InputDecoration(
                                          labelText: 'عدد الساعات',
                                          suffixText: 'ساعة',
                                          prefixIcon:
                                              Icon(Icons.timer_rounded)),
                                      keyboardType: TextInputType.number),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                      controller: requiredMinutesTextController,
                                      decoration: const InputDecoration(
                                          labelText: 'الدقائق',
                                          suffixText: 'دقيقة',
                                          prefixIcon:
                                              Icon(Icons.timer_outlined)),
                                      keyboardType: TextInputType.number),
                                ),
                              ],
                            ),
                          );
                        }
                        return Responsive.isDesktop(context)
                            ? Row(
                                children: [
                                  Expanded(
                                      child: _buildTimePickerField(
                                          context,
                                          'وقت بدء العمل',
                                          specialStartTimeController)),
                                  SizedBox(width: 20),
                                  Expanded(
                                      child: _buildTimePickerField(
                                          context,
                                          'وقت انتهاء العمل',
                                          specialEndTimeController)),
                                  SizedBox(width: 20),
                                  const Spacer(),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildTimePickerField(
                                      context,
                                      'وقت بدء العمل',
                                      specialStartTimeController),
                                  SizedBox(height: 16),
                                  _buildTimePickerField(
                                      context,
                                      'وقت انتهاء العمل',
                                      specialEndTimeController),
                                ],
                              );
                      }),
                    ],
                  ),
                ),
              ),
            ],
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
                            if (idController.text.isEmpty) {
                              UiUtils.showErrorDialog(
                                  'خطأ', 'يرجى إدخال الرقم الوظيفي');
                              return;
                            }
                            if (nameController.text.isEmpty) {
                              UiUtils.showErrorDialog(
                                  'خطأ', 'يرجى إدخال اسم الموظف');
                              return;
                            }
                            final emp = EmployeeModel(
                              id: int.tryParse(idController.text),
                              name: nameController.text,
                              salary:
                                  double.tryParse(salaryController.text) ?? 0,
                              specialStartTime: isFlexible.value ||
                                      specialStartTimeController.text.isEmpty
                                  ? null
                                  : specialStartTimeController.text,
                              specialEndTime: isFlexible.value ||
                                      specialEndTimeController.text.isEmpty
                                  ? null
                                  : specialEndTimeController.text,
                              vacationCredit: int.tryParse(
                                      vacationCreditMinutesController.text) ??
                                  0,
                              workDaysPerWeek:
                                  int.tryParse(workDaysController.text) ?? 6,
                              status: employee?.status ?? 'active',
                              password: passwordController.text,
                              isFlexible: isFlexible.value,
                              requiredHours: (double.tryParse(
                                          requiredHoursTextController.text) ??
                                      8.0) +
                                  ((double.tryParse(
                                              requiredMinutesTextController
                                                  .text) ??
                                          0.0) /
                                      60.0),
                              departmentId: selectedDeptId.value,
                              monthlyAnnualLeaveLimitMinutes: ((int.tryParse(monthlyAnnualLeaveLimitHoursController.text) ?? 12) * 60) + (int.tryParse(monthlyAnnualLeaveLimitMinutesController.text) ?? 30),
                            );
                            String? errorMsg;
                            if (employee == null) {
                              errorMsg = await controller.addEmployee(emp);
                            } else {
                              errorMsg = await controller.updateEmployee(emp);
                            }
                            if (errorMsg == null) {
                              Get.back();
                              UiUtils.showSuccessDialog(
                                  'نجاح',
                                  employee == null
                                      ? 'تم إضافة الموظف بنجاح'
                                      : 'تم تحديث بيانات الموظف');
                            } else {
                              UiUtils.showErrorDialog('خطأ', errorMsg);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 40)),
                    child: controller.isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('حفظ'),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryTeal),
        SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.primaryTeal)),
        SizedBox(width: 12),
        const Expanded(child: Divider(thickness: 0.5)),
      ],
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
        suffixIcon: Icon(Icons.access_time_rounded, size: 20),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    UiUtils.showConfirmDialog(
      title: 'تأكيد الحذف',
      message:
          'هل أنت متأكد من رغبتك في حذف هذا الموظف؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'حذف الموظف',
      confirmColor: AppTheme.errorRed,
      onConfirm: () async {
        bool success = await Get.find<AdminController>().deleteEmployee(id);
        if (success) {
          UiUtils.showSuccessDialog(
              'تم الحذف', 'تم حذف الموظف من النظام بنجاح');
        } else {
          UiUtils.showErrorDialog('خطأ', 'تعذر حذف الموظف');
        }
      },
    );
  }
}
