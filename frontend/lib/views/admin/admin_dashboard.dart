import 'package:attendance_management/core/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';
import '../../models/app_models.dart';
import 'employees_view.dart';
import 'attendance_view.dart';
import 'vacations_view.dart';
import 'settings_view.dart';
import 'public_holidays_view.dart';
import 'custom_vacation_view.dart';
import 'department_management_view.dart';
import 'overtime_management_view.dart';
import 'corrections_management_view.dart';
import 'monthly_closings_view.dart';
import '../profile_view.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RxInt selectedIndex = 0.obs;

  late final List<Widget> screens;

  bool _hasShownMonthlyCloseDialog = false;

  @override
  void initState() {
    super.initState();
    screens = [
      const AdminOverview(),
      const EmployeesView(),
      const AttendanceView(),
      const VacationsView(),
      const CustomVacationView(),
      const PublicHolidaysView(),
      const OvertimeManagementView(),
      const CorrectionsManagementView(),
      const MonthlyClosingsView(),
      const SettingsView(),
      DepartmentManagementView(),
      const ProfileView(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMonthlyClosing();
    });
  }

  void _checkMonthlyClosing() {
    if (DateTime.now().day == 24 && !_hasShownMonthlyCloseDialog) {
      _hasShownMonthlyCloseDialog = true;
      _showMonthlyCloseSuggestionDialog();
    }
  }

  void _showMonthlyCloseSuggestionDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.event_available_rounded, color: AppTheme.primaryTeal),
            SizedBox(width: 8),
            const Text('إغلاق شهري لسجلات الحضور',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
            'اليوم هو 24 من الشهر. هل ترغب في إجراء إغلاق شهري لسجلات الحضور للموظفين؟',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('لاحقاً',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _showEmployeesSelectionDialog();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                minimumSize: Size.zero),
            child: const Text('نعم، إجراء الإغلاق',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEmployeesSelectionDialog() {
    final controller = Get.find<AdminController>();
    final selectedIds = <int>{}.obs;
    final isSelectAll = false.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('اختيار الموظفين للإغلاق الشهري',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SizedBox(
          width: 500,
          height: 400,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الموظفين المتاحين',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Obx(() => Row(
                        children: [
                          Checkbox(
                            value: isSelectAll.value,
                            activeColor: AppTheme.primaryTeal,
                            onChanged: (val) {
                              isSelectAll.value = val ?? false;
                              if (isSelectAll.value) {
                                selectedIds.addAll(
                                    controller.employees.map((e) => e.id!));
                              } else {
                                selectedIds.clear();
                              }
                            },
                          ),
                          const Text('تحديد الكل'),
                        ],
                      )),
                ],
              ),
              const Divider(),
              Expanded(
                child: Obx(() {
                  if (controller.employees.isEmpty) {
                    return const Center(child: Text('لا يوجد موظفين'));
                  }
                  return ListView.builder(
                    itemCount: controller.employees.length,
                    itemBuilder: (context, index) {
                      final emp = controller.employees[index];
                      return Obx(() => CheckboxListTile(
                            title: Text(emp.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text('الرقم الوظيفي: ${emp.id}',
                                style: const TextStyle(fontSize: 12)),
                            value: selectedIds.contains(emp.id),
                            activeColor: AppTheme.primaryTeal,
                            onChanged: (val) {
                              if (val == true) {
                                selectedIds.add(emp.id!);
                              } else {
                                selectedIds.remove(emp.id);
                                isSelectAll.value = false;
                              }
                              if (selectedIds.length ==
                                  controller.employees.length) {
                                isSelectAll.value = true;
                              }
                            },
                          ));
                    },
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold)),
          ),
          Obx(() => ElevatedButton(
                onPressed: selectedIds.isEmpty
                    ? null
                    : () async {
                        Get.back();
                        _processBatchClosing(selectedIds.toList());
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero),
                child: Text('بدء الإغلاق (${selectedIds.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
        ],
      ),
    );
  }

  void _processBatchClosing(List<int> empIds) async {
    final controller = Get.find<AdminController>();
    final endDateStr = DateTime.now().toString().split(' ')[0];
    final startDateStr = DateTime.now()
        .subtract(const Duration(days: 30))
        .toString()
        .split(' ')[0];

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: AppTheme.primaryTeal),
            const SizedBox(height: 24),
            const Text('جاري معالجة الإغلاق الشهري...',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('يرجى الانتظار، قد تستغرق هذه العملية بعض الوقت.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
          ],
        ),
      ),
      barrierDismissible: false,
    );

    int successCount = 0;
    List<Map<String, dynamic>> errorList = [];
    for (int id in empIds) {
      final emp = controller.employees.firstWhere((e) => e.id == id);
      final errorMap =
          await controller.splitEmployeePayroll(id, startDateStr, endDateStr);
      if (errorMap == null || errorMap['status'] == 'success') {
        successCount++;
      } else {
        errorList.add({
          'emp': emp.name,
          'message': errorMap['message'] ?? 'خطأ غير معروف',
          'duplicates': errorMap['duplicates'] ?? [],
        });
      }
    }

    Get.back(); // close loading dialog

    if (errorList.isEmpty) {
      if (successCount > 0) {
        UiUtils.showSuccessDialog('اكتمل الإغلاق',
            'تم إغلاق $successCount موظف بنجاح من أصل ${empIds.length}.');
      } else {
        UiUtils.showErrorDialog('تنبيه', 'لا يوجد بيانات لإغلاقها.');
      }
    } else {
      Get.dialog(
        AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.primaryGold),
              SizedBox(width: 8),
              Text('نتيجة الإغلاق',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (successCount > 0)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: AppTheme.successGreen),
                        SizedBox(width: 8),
                        Text('تم إغلاق $successCount موظف بنجاح.',
                            style: TextStyle(
                                color: AppTheme.successGreen,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                if (successCount > 0) SizedBox(height: 16),
                Text('يوجد تنبيهات للموظفين التاليين:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: errorList.length,
                    itemBuilder: (context, index) {
                      final item = errorList[index];
                      final List<dynamic> dups =
                          item['duplicates'] as List<dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppTheme.borderLight),
                        ),
                        color: AppTheme.backgroundLight,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 16, color: AppTheme.textSecondary),
                                  SizedBox(width: 6),
                                  Text(item['emp'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(item['message'],
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.errorRed,
                                      height: 1.5)),
                              if (dups.isNotEmpty) ...[
                                SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: dups.map((d) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryTeal
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        d.toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryTeal,
                                        ),
                                        textDirection: TextDirection.ltr,
                                      ),
                                    );
                                  }).toList(),
                                )
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child:
                  Text('حسناً', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundLight,
      appBar: Responsive.isDesktop(context)
          ? null
          : AppBar(
              title: Obx(() {
                switch (selectedIndex.value) {
                  case 0:
                    return const Text('الرئيسية');
                  case 1:
                    return const Text('الموظفين');
                  case 2:
                    return const Text('سجل الحضور');
                  case 3:
                    return const Text('طلبات الإجازة');
                  case 4:
                    return const Text('إجازة مخصصة');
                  case 5:
                    return const Text('أعياد وإجازات');
                  case 6:
                    return const Text('إدارة الإضافي');
                  case 7:
                    return const Text('تصحيح البصمات');
                  case 8:
                    return const Text('الإغلاقات الشهرية');
                  case 9:
                    return const Text('إعدادات النظام');
                  case 10:
                    return const Text('إدارة الإدارات');
                  case 11:
                    return const Text('الملف الشخصي');
                  default:
                    return const Text('لوحة التحكم');
                }
              }),
            ),
      drawer: Responsive.isDesktop(context)
          ? null
          : Drawer(
              width: 280,
              backgroundColor: AppTheme.surfaceLight,
              child: _AdminSidebarContent(
                  selectedIndex: selectedIndex,
                  onItemSelected: () => Get.back()),
            ),
      body: Row(
        children: [
          // Desktop Sidebar
          if (Responsive.isDesktop(context))
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                border: Border(
                    left: BorderSide(color: AppTheme.borderLight, width: 0.5)),
              ),
              child: _AdminSidebarContent(selectedIndex: selectedIndex),
            ),
          // Main Content
          Expanded(
            child: Obx(() => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: screens[selectedIndex.value],
                )),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebarContent extends StatelessWidget {
  final RxInt selectedIndex;
  final VoidCallback? onItemSelected;

  const _AdminSidebarContent({
    Key? key,
    required this.selectedIndex,
    this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 50),
        const Text('حاضر',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: AppTheme.textPrimary)),
        const Text('لوحة تحكم المدير',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        SizedBox(height: 30),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildNavItem(0, 'الرئيسية', Icons.grid_view_rounded),
                _buildNavItem(1, 'الموظفين', Icons.people_alt_rounded),
                _buildNavItem(2, 'سجل الحضور', Icons.fact_check_rounded),
                _buildNavItem(3, 'طلبات الإجازة', Icons.beach_access_rounded),
                _buildNavItem(
                    4, 'إجازة مخصصة', Icons.assignment_turned_in_rounded),
                _buildNavItem(
                    5, 'أعياد وإجازات', Icons.event_available_rounded),
                _buildNavItem(6, 'إدارة الإضافي', Icons.more_time_rounded),
                _buildNavItem(7, 'تصحيح البصمات', Icons.fingerprint_rounded),
                _buildNavItem(8, 'الإغلاقات الشهرية', Icons.lock_clock_rounded),
                _buildNavItem(9, 'إعدادات النظام', Icons.settings_rounded),
                _buildNavItem(10, 'إدارة الإدارات', Icons.business_rounded),
                _buildNavItem(11, 'الملف الشخصي', Icons.person_rounded),

                // MOHA ONLY: Broadcast Notification
                Obx(() {
                  final auth = Get.find<AuthController>();
                  if (auth.userIdentifier.value == 'moha') {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildNavActionItem(
                          'إرسال تنبيه عام',
                          Icons.campaign_rounded,
                          AppTheme.primaryGold,
                          () => _showBroadcastDialog(context)),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: Icon(Icons.logout_rounded, color: AppTheme.errorRed),
                  title: const Text('خروج',
                      style: TextStyle(
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.w600)),
                  onTap: () => Get.find<AuthController>().logout(),
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = Get.find<AdminController>();
    final jsonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('استيراد بيانات الحضور'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'يرجى لصق محتوى ملف بيانات الحضور (JSON) في الحقل أدناه:',
                  style:
                      TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              SizedBox(height: 16),
              TextField(
                controller: jsonController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText:
                      'مثال: { "users": { "1": { "first": "2023-10-01 08:30:00", ... } } }',
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
                            if (jsonController.text.isEmpty) {
                              UiUtils.showErrorDialog(
                                  'تنبيه', 'يرجى لصق البيانات أولاً');
                              return;
                            }
                            final controller = Get.find<AdminController>();
                            controller.isLoading.value = true;
                            try {
                              final res = await Get.find<ApiService>().postData(
                                  'attendance/import',
                                  {'json': jsonController.text});
                              if (res != null) {
                                controller.fetchAttendance();
                                Get.back();
                                UiUtils.showSuccessDialog('تم الاستيراد',
                                    'تمت معالجة بيانات الحضور بنجاح');
                              } else {
                                UiUtils.showErrorDialog('فشل الاستيراد',
                                    'تأكد من صحة تنسيق ملف الـ JSON');
                              }
                            } finally {
                              controller.isLoading.value = false;
                            }
                          },
                    child: const Text('حفظ وتأكيد'),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    return Obx(() {
      final isSelected = selectedIndex.value == index;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: InkWell(
          onTap: () {
            selectedIndex.value = index;
            if (onItemSelected != null) onItemSelected!();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryTeal.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppTheme.primaryTeal
                      : AppTheme.textSecondary,
                  size: 22,
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryTeal
                        : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (isSelected) const Spacer(),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavActionItem(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    final titleController =
        TextEditingController(text: 'تحديث جديد لتطبيق حاضر 🚀');
    final msgController = TextEditingController(
        text:
            'يسرنا إبلاغك بتوفر نسخة جديدة ومطورة من تطبيق حاضر. يرجى التحديث الآن للحصول على أفضل تجربة.');
    final urlController = TextEditingController();
    final controller = Get.find<AdminController>();

    Get.dialog(
      AlertDialog(
        title: const Text('إرسال تنبيه عام (للكل)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'سيصل هذا التنبيه لجميع مستخدمي التطبيق وسيطالبهم بالتحديث فوراً.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            SizedBox(height: 16),
            TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'عنوان التنبيه')),
            SizedBox(height: 12),
            TextField(
                controller: msgController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'نص الرسالة')),
            SizedBox(height: 12),
            TextField(
                controller: urlController,
                decoration: const InputDecoration(
                    labelText: 'رابط التحديث (Google Drive)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (urlController.text.isEmpty) {
                UiUtils.showErrorDialog('خطأ', 'رابط التحديث مطلوب');
                return;
              }
              Get.back();
              bool success = await controller.sendBroadcastNotification(
                  titleController.text, msgController.text, urlController.text);
              if (success) {
                UiUtils.showSuccessDialog(
                    'نجاح', 'تم إرسال التنبيه لجميع المستخدمين');
              } else {
                UiUtils.showErrorDialog('فشل', 'حدث خطأ أثناء الإرسال');
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
            child: const Text('إرسال الآن'),
          ),
        ],
      ),
    );
  }
}

class AdminOverview extends StatelessWidget {
  const AdminOverview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final controller = Get.find<AdminController>();
    final padding = Responsive.isMobile(context) ? 16.0 : 40.0;
    return RefreshIndicator(
      onRefresh: () async {
        controller.fetchInitialData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!Responsive.isMobile(context))
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text('مرحباً بك، ${auth.currentEmployeeName.value}',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900))),
                  Obx(() => controller.isLoading.value
                      ? SizedBox(
                          width: 40,
                          height: 40,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.primaryTeal),
                          ),
                        )
                      : IconButton(
                          onPressed: () => controller.fetchInitialData(),
                          icon: Icon(Icons.refresh_rounded),
                          tooltip: 'تحديث البيانات',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: AppTheme.borderLight),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        )),
                ],
              ),
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
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
              child: Responsive.isMobile(context)
                  ? Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryTeal.withValues(alpha: 0.1),
                              radius: 24,
                              child: Icon(Icons.sync_rounded,
                                  color: AppTheme.primaryTeal, size: 28),
                            ),
                            SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مزامنة جهاز البصمة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'تحديث البيانات من ملف الحضور',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => controller.syncBiometricData(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(Icons.cloud_sync_rounded, size: 20),
                            label: const Text(
                              'مزامنة الآن',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryTeal.withValues(alpha: 0.1),
                          radius: 24,
                          child: Icon(Icons.sync_rounded,
                              color: AppTheme.primaryTeal, size: 28),
                        ),
                        SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مزامنة جهاز الحضور',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'تحديث البيانات محلياً من ملف الحضور المرفوع على السيرفر',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => controller.syncBiometricData(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Icon(Icons.cloud_sync_rounded, size: 20),
                          label: const Text(
                            'مزامنة الآن',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
            ),
            SizedBox(height: 10),
            Obx(() {
              final today = DateTime.now().toIso8601String().split('T')[0];
              final stats = [
                {
                  'title': 'إجمالي الموظفين',
                  'value': controller.employees.length.toString(),
                  'icon': Icons.people_rounded,
                  'color': AppTheme.primaryTeal
                },
                {
                  'title': 'الحاضرون اليوم',
                  'value': controller.attendance
                      .where((a) =>
                          a.date == today &&
                          (a.status == 'present' || a.status == 'late'))
                      .length
                      .toString(),
                  'icon': Icons.check_circle_rounded,
                  'color': AppTheme.successGreen
                },
                {
                  'title': 'إجازات اليوم',
                  'value': controller.vacationRequests
                      .where((v) {
                        if (v.status != 'approved') return false;
                        final t = DateTime.parse(today);
                        final s = DateTime.parse(v.startDate);
                        final e = DateTime.parse(v.endDate);
                        return (t.isAtSameMomentAs(s) || t.isAfter(s)) &&
                            (t.isAtSameMomentAs(e) || t.isBefore(e));
                      })
                      .length
                      .toString(),
                  'icon': Icons.beach_access_rounded,
                  'color': AppTheme.primaryGold
                },
              ];

              if (Responsive.isMobile(context)) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: stats
                      .map((s) => _buildStatCard(
                            s['title'] as String,
                            s['value'] as String,
                            s['icon'] as IconData,
                            s['color'] as Color,
                            isFullWidth: false,
                          ))
                      .toList(),
                );
              }

              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: stats
                    .map((s) => _buildStatCard(
                          s['title'] as String,
                          s['value'] as String,
                          s['icon'] as IconData,
                          s['color'] as Color,
                        ))
                    .toList(),
              );
            }),
            Obx(() {
              final requests = controller.vacationRequests
                  .where((v) => v.status == 'pending')
                  .toList()
                ..sort((a, b) => b.id!.compareTo(a.id!));
              if (requests.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  const Text('طلبات الإجازة',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: AppTheme.borderLight, width: 0.5),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: requests.length > 5 ? 5 : requests.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        final bool isMobile = Responsive.isMobile(context);

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryTeal
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.person_rounded,
                                        color: AppTheme.primaryTeal, size: 22),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                  req.employeeName ?? '',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15)),
                                            ),
                                            SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: AppTheme.primaryGold
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6)),
                                              child: Text(req.vacationType,
                                                  style: TextStyle(
                                                      fontSize: 9,
                                                      color:
                                                          AppTheme.primaryGold,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                            req.isHourly
                                                ? '${req.startDate} (${req.totalMinutes} دقيقة)'
                                                : '${req.startDate} ⟵ ${req.endDate} (${req.totalDays} أيام)',
                                            style: TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12)),
                                        if (req.reason != null &&
                                            req.reason!.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: Text('السبب: ${req.reason}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color:
                                                        AppTheme.textSecondary,
                                                    fontSize: 10,
                                                    fontStyle:
                                                        FontStyle.italic)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (!isMobile) ...[
                                    SizedBox(width: 16),
                                    Obx(() {
                                      final isLoading =
                                          controller.isLoading.value;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildStatusButton(
                                              isLoading
                                                  ? null
                                                  : Icons.close_rounded,
                                              AppTheme.errorRed,
                                              isLoading
                                                  ? null
                                                  : () => _handleStatusUpdate(
                                                      req.id!, 'rejected')),
                                          SizedBox(width: 12),
                                          _buildStatusButton(
                                              isLoading
                                                  ? null
                                                  : Icons.check_rounded,
                                              AppTheme.successGreen,
                                              isLoading
                                                  ? null
                                                  : () => _handleStatusUpdate(
                                                      req.id!, 'approved')),
                                        ],
                                      );
                                    }),
                                  ],
                                ],
                              ),
                              if (isMobile) ...[
                                SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Spacer(),
                                    Expanded(
                                      child: Obx(() => OutlinedButton.icon(
                                            onPressed:
                                                controller.isLoading.value
                                                    ? null
                                                    : () => _handleStatusUpdate(
                                                        req.id!, 'rejected'),
                                            icon: controller.isLoading.value
                                                ? SizedBox(
                                                    height: 16,
                                                    width: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: AppTheme
                                                                .errorRed))
                                                : Icon(Icons.close_rounded,
                                                    size: 16),
                                            label: const Text('رفض'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppTheme.errorRed,
                                              side: BorderSide(
                                                  color: AppTheme.errorRed),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                            ),
                                          )),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Obx(() => ElevatedButton.icon(
                                            onPressed:
                                                controller.isLoading.value
                                                    ? null
                                                    : () => _handleStatusUpdate(
                                                        req.id!, 'approved'),
                                            icon: controller.isLoading.value
                                                ? SizedBox(
                                                    height: 16,
                                                    width: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors.white))
                                                : Icon(Icons.check_rounded,
                                                    size: 16),
                                            label: const Text('قبول'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.successGreen,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                            ),
                                          )),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 48),
                ],
              );
            }),
            SizedBox(height: 24),
            const Text('تأخير وغيابات اليوم',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Obx(() {
              final today = DateTime.now().toIso8601String().split('T')[0];
              final holiday = controller.getHolidayForDate(today);

              if (holiday != null) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.celebration_rounded,
                          color: AppTheme.primaryTeal),
                      SizedBox(width: 12),
                      Text('اليوم إجازة رسمية: ${holiday.name}',
                          style: TextStyle(
                              color: AppTheme.primaryTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                );
              }

              // 1. Get those marked early or late today
              final todayAttendance =
                  controller.attendance.where((a) => a.date == today).toList();
              final lateEmps =
                  todayAttendance.where((a) => a.status == 'late').toList();

              // 2. Identify absentees
              final activeEmps = controller.employees
                  .where((e) => e.status == 'active')
                  .toList();
              final absentees = <EmployeeModel>[];
              final explicitlyAbsent = todayAttendance
                  .where((a) => a.status == 'absent')
                  .map((a) => a.employeeId)
                  .toSet();

              for (var emp in activeEmps) {
                final hasRecord =
                    todayAttendance.any((a) => a.employeeId == emp.id);
                final isExplicitlyAbsent = explicitlyAbsent.contains(emp.id);

                // If they have no record, we only consider them absent if their required days are 6 or more (standard week)
                // If they work less than 6 days, we don't know if today is an off-day, so we don't assume absence unless explicit.
                bool isAutoAbsent = !hasRecord && (emp.workDaysPerWeek >= 6);

                if (isExplicitlyAbsent || isAutoAbsent) {
                  // Do not consider as absent if they have approved vacation or holiday
                  if (!controller.hasApprovedVacation(emp.id!, today)) {
                    absentees.add(emp);
                  }
                }
              }

              if (lateEmps.isEmpty && absentees.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderLight, width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: AppTheme.successGreen),
                      SizedBox(width: 12),
                      Text(
                          'الكل ملتزم اليوم! لا توجد حالات تأخير أو غياب مرصودة.',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  if (lateEmps.isNotEmpty) ...[
                    _buildExceptionGroup(
                        'متأخرون (${lateEmps.length})',
                        lateEmps.map((a) {
                          final emp = controller.employees
                              .firstWhere((e) => e.id == a.employeeId);
                          final startTime = emp.specialStartTime ??
                              (controller.settings.value?.ramadanMode == true
                                  ? controller.settings.value?.ramadanStartTime
                                  : controller
                                      .settings.value?.defaultStartTime) ??
                              '08:00';
                          return ExceptionItem(
                            name: emp.name,
                            detail: 'خصم تأخير (${a.lateMinutes} دقيقة)',
                            icon: Icons.access_time_filled_rounded,
                            color: Colors.orange,
                          );
                        }).toList()),
                    SizedBox(height: 24),
                  ],
                  if (absentees.isNotEmpty)
                    _buildExceptionGroup(
                        'غائبون (${absentees.length})',
                        absentees.map((e) {
                          return ExceptionItem(
                            name: e.name,
                            detail: 'لم يتم تسجيل حضور اليوم',
                            icon: Icons.person_off_rounded,
                            color: AppTheme.errorRed,
                          );
                        }).toList()),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(IconData? icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: icon == null
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color))
            : Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _handleStatusUpdate(int id, String status) {
    Get.defaultDialog(
      title: status == 'approved' ? 'موافقة على الإجازة' : 'رفض الطلب',
      middleText: status == 'approved'
          ? 'هل أنت متأكد من الموافقة على طلب الإجازة؟'
          : 'هل أنت متأكد من رغبتك في رفض هذا الطلب؟',
      textConfirm: 'تأكيد',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor:
          status == 'approved' ? AppTheme.successGreen : AppTheme.errorRed,
      onConfirm: () async {
        Get.back();
        await Get.find<AdminController>().updateVacationStatus(id, status);
      },
    );
  }

  Widget _buildExceptionGroup(String title, List<Widget> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textSecondary)),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      {bool isFullWidth = true}) {
    return Container(
      width: isFullWidth ? 240 : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ExceptionItem extends StatelessWidget {
  final String name;
  final String detail;
  final IconData icon;
  final Color color;

  const ExceptionItem({
    Key? key,
    required this.name,
    required this.detail,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(name,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(detail,
          overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
    );
  }
}
