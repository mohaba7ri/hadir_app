import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/employee_controller.dart';
import 'my_attendance_view.dart';
import 'my_vacations_view.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../profile_view.dart';
import 'my_overtime_view.dart';
import 'my_corrections_view.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final RxInt selectedIndex = 0.obs;

  void _showMoreBottomSheet(BuildContext context) {
    final auth = Get.find<AuthController>();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            const Text('المزيد من الخيارات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMoreItem(
                  icon: Icons.more_time_rounded,
                  label: 'عمل إضافي',
                  color: AppTheme.primaryTeal,
                  onTap: () {
                    selectedIndex.value = 3;
                    Get.back();
                  },
                ),
                _buildMoreItem(
                  icon: Icons.fingerprint_rounded,
                  label: 'تصحيح بصمة',
                  color: Colors.orange,
                  onTap: () {
                    selectedIndex.value = 4;
                    Get.back();
                  },
                ),
                _buildMoreItem(
                  icon: Icons.logout_rounded,
                  label: 'خروج',
                  color: AppTheme.errorRed,
                  onTap: () {
                    Get.back();
                    auth.logout();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildMoreItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      const EmployeeOverview(),
      const MyAttendanceView(),
      const MyVacationsView(),
      const MyOvertimeView(),
      const MyCorrectionsView(),
      const ProfileView(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
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
                    return const Text('سجل حضوري');
                  case 2:
                    return const Text('طلبات الإجازة');
                  case 3:
                    return const Text('عمل إضافي');
                  case 4:
                    return const Text('تصحيح بصمة');
                  case 5:
                    return const Text('الملف الشخصي');
                  default:
                    return const Text('بوابة الموظف');
                }
              }),
            ),
      bottomNavigationBar: Responsive.isDesktop(context)
          ? null
          : Obx(() {
              int current = selectedIndex.value;
              int mappedIndex = current;
              if (current == 3 || current == 4) {
                mappedIndex = 4;
              } else if (current == 5) {
                mappedIndex = 3;
              }

              return BottomNavigationBar(
                currentIndex: mappedIndex > 4 ? 4 : mappedIndex,
                onTap: (index) {
                  if (index == 4) {
                    _showMoreBottomSheet(context);
                  } else if (index == 3) {
                    selectedIndex.value = 5;
                  } else {
                    selectedIndex.value = index;
                  }
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppTheme.surfaceLight,
                selectedItemColor: AppTheme.primaryTeal,
                unselectedItemColor: AppTheme.textSecondary,
                showUnselectedLabels: true,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.grid_view_rounded), label: 'الرئيسية'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.fact_check_rounded), label: 'حضوري'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.beach_access_rounded), label: 'إجازاتي'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded), label: 'حسابي'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.more_horiz_rounded), label: 'المزيد'),
                ],
              );
            }),
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
              child: _EmployeeSidebarContent(
                  selectedIndex: selectedIndex, auth: auth),
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

class _EmployeeSidebarContent extends StatelessWidget {
  final RxInt selectedIndex;
  final AuthController auth;

  const _EmployeeSidebarContent({
    Key? key,
    required this.selectedIndex,
    required this.auth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 50),
        SizedBox(height: 16),
        Obx(() => Text(auth.currentEmployeeName.value,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppTheme.textPrimary))),
        const Text('بوابة الموظف',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildNavItem(0, 'الرئيسية', Icons.grid_view_rounded),
              _buildNavItem(1, 'سجل حضوري', Icons.fact_check_rounded),
              _buildNavItem(2, 'طلبات الإجازة', Icons.beach_access_rounded),
              _buildNavItem(3, 'العمل الإضافي', Icons.more_time_rounded),
              _buildNavItem(4, 'تصحيح البصمات', Icons.fingerprint_rounded),
              _buildNavItem(5, 'الملف الشخصي', Icons.person_rounded),
            ],
          ),
        ),
        if (Responsive.isDesktop(context))
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading:
                  Icon(Icons.logout_rounded, color: AppTheme.errorRed),
              title: const Text('خروج',
                  style: TextStyle(
                      color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
              onTap: () => auth.logout(),
            ),
          ),
      ],
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
              ],
            ),
          ),
        ),
      );
    });
  }
}

class EmployeeOverview extends StatelessWidget {
  const EmployeeOverview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final controller = Get.find<EmployeeController>();
    final padding = Responsive.isMobile(context) ? 16.0 : 40.0;

    return RefreshIndicator(
      onRefresh: () async {
        controller.fetchMyData();
        return Future.value();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => Text('مرحباً بك، ${auth.currentEmployeeName.value}',
                    style: TextStyle(
                        fontSize: 16, color: AppTheme.textSecondary))),
                if (!Responsive.isMobile(context))
                  IconButton(
                    onPressed: () => controller.fetchMyData(),
                    icon: Icon(Icons.refresh_rounded),
                    tooltip: 'تحديث البيانات',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: AppTheme.borderLight),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),

            SizedBox(height: 10),

            Obx(() {
              final month = controller.selectedMonth.value;
              final year = controller.selectedYear.value;
              final months = [
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
              final prevMonth = month == 1 ? 12 : month - 1;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppTheme.primaryTeal),
                    SizedBox(width: 8),
                    Text(
                      'إحصائيات فترة: 25 ${months[prevMonth]} - 24 ${months[month]} $year',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryTeal),
                    ),
                  ],
                ),
              );
            }),

            // Stats Grid 2-column
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final leaves = controller.filteredAttendance
                  .where((a) => controller.isDayApprovedVacation(a.date))
                  .length;

              return GridView.count(
                crossAxisCount: Responsive.isMobile(context) ? 2 : 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  _buildStatCard('إجازاتي', leaves.toString(),
                      Icons.beach_access_rounded, AppTheme.primaryTeal),
                  _buildStatCard(
                      'خصم التأخير',
                      '${controller.totalLateDiscount.toStringAsFixed(2)} ر.س',
                      Icons.timer_rounded,
                      Colors.orange),
                  _buildStatCard(
                      'خصم الخروج المبكر',
                      '${controller.totalEarlyExitDiscount.toStringAsFixed(2)} ر.س',
                      Icons.logout_rounded,
                      Colors.orange),
                  _buildStatCard(
                      'خصم الغياب',
                      '${controller.totalAbsentDiscount.toStringAsFixed(2)} ر.س',
                      Icons.person_off_rounded,
                      AppTheme.errorRed),
                  _buildStatCard(
                      'إجمالي الخصم',
                      '${controller.totalDiscount.toStringAsFixed(2)} ر.س',
                      Icons.money_off_csred_rounded,
                      AppTheme.errorRed),
                ],
              );
            }),

            SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderLight, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.primaryTeal),
                      SizedBox(width: 12),
                      Text('إرشادات سريعة',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                      '• يمكنك الاطلاع على كامل سجل حضورك وانصرافك من خلال تبويب "سجل حضوري".',
                      style: TextStyle(fontSize: 15, height: 1.6)),
                  Text(
                      '• لطلب إجازة جديدة، توجه إلى تبويب "طلبات الإجازة" وقم بتعبئة النموذج.',
                      style: TextStyle(fontSize: 15, height: 1.6)),
                  Text(
                      '• رصيد إجازاتك السنوي يتم تحديثه تلقائياً عند الموافقة على طلباتك.',
                      style: TextStyle(fontSize: 15, height: 1.6)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
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
