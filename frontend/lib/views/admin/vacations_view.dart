import 'package:attendance_management/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class VacationsView extends StatefulWidget {
  const VacationsView({Key? key}) : super(key: key);

  @override
  State<VacationsView> createState() => _VacationsViewState();
}

class _VacationsViewState extends State<VacationsView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.text =
        Get.find<AdminController>().vacationSearchQuery.value;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              // Search
              SizedBox(
                width: Responsive.isMobile(context) ? double.infinity : 300,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => controller.vacationSearchQuery.value = v,
                  decoration: InputDecoration(
                    hintText: 'البحث باسم الموظف...',
                    prefixIcon: Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryTeal),
                    ),
                  ),
                ),
              ),

              // Status Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Obx(() => DropdownButton<String>(
                      value: controller.vacationStatusFilter.value,
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('كل الحالات')),
                        DropdownMenuItem(
                            value: 'pending', child: Text('قيد الانتظار')),
                        DropdownMenuItem(
                            value: 'approved', child: Text('مقبولة')),
                        DropdownMenuItem(
                            value: 'rejected', child: Text('مرفوضة')),
                      ],
                      onChanged: (v) =>
                          controller.vacationStatusFilter.value = v!,
                      underline: SizedBox(),
                      icon: Icon(Icons.keyboard_arrow_down_rounded),
                    )),
              ),

              // Date Filters
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => Checkbox(
                        value: !controller.isVacationDateFilterEnabled.value,
                        onChanged: (v) =>
                            controller.isVacationDateFilterEnabled.value = !v!,
                      )),
                  const Text('بدون تحديد الفترة',
                      style: TextStyle(fontSize: 13)),
                  SizedBox(width: 12),
                  _buildDateFilters(controller),
                ],
              ),
              // Refresh for Web/Desktop
              if (!Responsive.isMobile(context))
                IconButton(
                  onPressed: () => controller.fetchVacationRequests(),
                  icon: Icon(Icons.refresh_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.borderLight),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                border: Border.all(color: AppTheme.borderLight, width: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: RefreshIndicator(
                onRefresh: () async => await controller.fetchVacationRequests(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Obx(() {
                    if (controller.filteredVacationRequests.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.25),
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.beach_access_rounded,
                                    size: 64, color: AppTheme.textSecondary),
                                SizedBox(height: 16),
                                Text('لا توجد طلبات إجازة معلقة',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.all(
                          UiUtils.isSmallScreen(context) ? 12 : 24),
                      itemCount: controller.filteredVacationRequests.length,
                      separatorBuilder: (context, i) =>
                          const Divider(height: 1, color: AppTheme.borderLight),
                      itemBuilder: (context, i) {
                        final req = controller.filteredVacationRequests[i];
                        return ListTile(
                          onTap: () => _showVacationDetailsDialog(context, req),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  _getStatusColor(req.status).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.calendar_today_rounded,
                                color: _getStatusColor(req.status), size: 20),
                          ),
                          title: Text(req.employeeName ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(req.vacationType,
                                  style: TextStyle(
                                      color: AppTheme.primaryTeal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                              Text(
                                  req.isHourly
                                      ? 'تاريخ: ${req.startDate} (${req.totalMinutes} دقيقة)'
                                      : 'تاريخ: ${req.startDate} ⟵ ${req.endDate} (${req.totalDays} أيام)',
                                  style: TextStyle(fontSize: 12)),
                              if (req.reason != null &&
                                  req.reason!.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Text('السبب: ${req.reason!.replaceAll(RegExp(r'\[COVER_(LATE|EARLY|BOTH)\]'), '').trim()}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        fontStyle: FontStyle.italic)),
                              ],
                              if (req.attachment != null &&
                                  req.attachment!.isNotEmpty) ...[
                                SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final url = Uri.parse(
                                        '${ApiService.baseApiUrl}/${req.attachment}');
                                    if (await launchUrl(url,
                                        mode: LaunchMode.externalApplication)) {
                                    } else {
                                      UiUtils.showErrorDialog('تعذر الفتح',
                                          'لا يمكن فتح المرفق حالياً');
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.primaryTeal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
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
                                                color: AppTheme.primaryTeal,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Obx(() {
                            final isLoading = controller.isLoading.value;
                            if (req.status == 'pending') {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (Responsive.isMobile(context)) ...[
                                    _buildStatusButton_Compact(
                                        isLoading ? null : Icons.close_rounded,
                                        AppTheme.errorRed,
                                        isLoading
                                            ? null
                                            : () => _handleStatusUpdate(
                                                req.id!, 'rejected')),
                                    SizedBox(width: 8),
                                    _buildStatusButton_Compact(
                                        isLoading ? null : Icons.check_rounded,
                                        AppTheme.successGreen,
                                        isLoading
                                            ? null
                                            : () => _handleStatusUpdate(
                                                req.id!, 'approved')),
                                  ] else ...[
                                    TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : () => _handleStatusUpdate(
                                              req.id!, 'rejected'),
                                      style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.errorRed),
                                      child: isLoading &&
                                              controller.isLoading.value
                                          ? SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppTheme.errorRed))
                                          : const Text('رفض'),
                                    ),
                                    SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () => _handleStatusUpdate(
                                              req.id!, 'approved'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.successGreen,
                                        minimumSize: const Size(100, 40),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      child: isLoading &&
                                              controller.isLoading.value
                                          ? SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white))
                                          : const Text('موافقة'),
                                    ),
                                  ],
                                ],
                              );
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(req.status)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                req.status == 'approved' ? 'مقبولة' : 'مرفوضة',
                                style: TextStyle(
                                  color: _getStatusColor(req.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.successGreen;
      case 'rejected':
        return AppTheme.errorRed;
      default:
        return AppTheme.primaryTeal;
    }
  }

  Widget _buildStatusButton_Compact(
      IconData? icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: icon == null
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color))
            : Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _handleStatusUpdate(int id, String status) {
    final controller = Get.find<AdminController>();
    final noteController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text(
          status == 'approved' ? 'موافقة على الإجازة' : 'رفض الطلب',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status == 'approved'
                    ? 'هل أنت متأكد من الموافقة على طلب الإجازة؟ سيتم خصم الأيام من رصيد الموظف.'
                    : 'هل أنت متأكد من رغبتك في رفض هذا الطلب؟',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
              ),
              SizedBox(height: 16),
              const Text(
                'ملاحظات الإدارة (اختياري):',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'أدخل أي ملاحظات هنا...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              bool success = await controller.updateVacationStatus(
                id,
                status,
                note:
                    noteController.text.isNotEmpty ? noteController.text : null,
              );
              if (success) {
                UiUtils.showSuccessDialog(
                    'تم التحديث', 'تمت عملية التحديث بنجاح');
              } else {
                UiUtils.showErrorDialog('خطأ', 'تعذر تحديث حالة الطلب');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved'
                  ? AppTheme.successGreen
                  : AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text(status == 'approved' ? 'موافقة' : 'تأكيد الرفض'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilters(AdminController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Obx(() => IgnorePointer(
            ignoring: !controller.isVacationDateFilterEnabled.value,
            child: Opacity(
              opacity: controller.isVacationDateFilterEnabled.value ? 1.0 : 0.4,
              child: Row(
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
              ),
            ),
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

  void _showVacationDetailsDialog(
      BuildContext context, VacationRequestModel req) {
    final controller = Get.find<AdminController>();
    final noteController = TextEditingController(text: req.notes ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text('تفاصيل طلب الإجازة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الموظف: ${req.employeeName ?? ""}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('نوع الإجازة: ${req.vacationType}',
                  style: TextStyle(
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                req.isHourly
                    ? 'التاريخ: ${req.startDate} (${req.totalMinutes} دقيقة)'
                    : 'الفترة: ${req.startDate} ⟵ ${req.endDate} (${req.totalDays} أيام)',
                style: TextStyle(fontSize: 14),
              ),
              if (req.reason != null && req.reason!.isNotEmpty) ...[
                SizedBox(height: 12),
                Text('سبب الطلب: ${req.reason!.replaceAll(RegExp(r'\[COVER_(LATE|EARLY|BOTH)\]'), '').trim()}',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ],
              if (req.attachment != null && req.attachment!.isNotEmpty) ...[
                SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final url =
                        Uri.parse('${ApiService.baseApiUrl}/${req.attachment}');
                    if (await launchUrl(url,
                        mode: LaunchMode.externalApplication)) {
                    } else {
                      UiUtils.showErrorDialog(
                          'تعذر الفتح', 'لا يمكن فتح المرفق حالياً');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file_rounded,
                            size: 16, color: AppTheme.primaryTeal),
                        SizedBox(width: 6),
                        Text('عرض المرفق',
                            style: TextStyle(
                                color: AppTheme.primaryTeal,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16),
              const Divider(),
              SizedBox(height: 12),
              const Text('ملاحظات الإدارة:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'أدخل أي ملاحظة حول الإجازة هنا...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              bool success = await controller.updateVacationStatus(
                req.id!,
                req.status,
                note: noteController.text,
              );
              if (success) {
                UiUtils.showSuccessDialog('تم بنجاح', 'تم حفظ الملاحظة');
              } else {
                UiUtils.showErrorDialog('فشل', 'تعذر حفظ الملاحظة');
              }
            },
            icon: Icon(Icons.save_rounded),
            label: const Text('حفظ الملاحظة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
