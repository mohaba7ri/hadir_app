import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../core/theme/app_theme.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تقارير النظام', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          const Text('استخرج بيانات دقيقة حول الرواتب، الحضور، والتأخير', style: TextStyle(color: AppTheme.textSecondary)),
          SizedBox(height: 32),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                   Container(
                     height: 50,
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(
                       color: const Color(0xFFE9E9EB),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: TabBar(
                      indicator: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: AppTheme.primaryTeal,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(text: 'الحضور'),
                        Tab(text: 'الرواتب'),
                        Tab(text: 'الإجازات'),
                        Tab(text: 'التأخير'),
                      ],
                    ),
                   ),
                  SizedBox(height: 32),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ReportTable(type: 'attendance'),
                        _ReportTable(type: 'salary'),
                        _ReportTable(type: 'vacation'),
                        _ReportTable(type: 'late'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTable extends StatelessWidget {
  final String type;
  const _ReportTable({required this.type});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    return FutureBuilder<List<dynamic>>(
      future: controller.getReport(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || !snapshot.hasData) return const Center(child: Text('خطأ في تحميل البيانات'));
        
        final data = snapshot.data!;
        if (data.isEmpty) return const Center(child: Text('لا توجد بيانات حالياً'));

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            border: Border.all(color: AppTheme.borderLight, width: 0.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 340),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed Header
                    DataTable(
                      headingRowColor:
                          MaterialStateProperty.all(const Color(0xFFF9F9F9)),
                      horizontalMargin: 24,
                      columnSpacing: 40,
                      columns: _getColumns(type),
                      rows: const [], // No rows in the header table
                    ),
                    // Scrollable Body
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          headingRowHeight: 0, // Hide header in the body table
                          horizontalMargin: 24,
                          columnSpacing: 40,
                          columns: _getColumns(type)
                              .map((c) => DataColumn(label: Container()))
                              .toList(),
                          rows: data
                              .map((item) => DataRow(cells: _getCells(type, item)))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<DataColumn> _getColumns(String type) {
    TextStyle headerStyle = TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary);
    switch (type) {
      case 'attendance':
        return [DataColumn(label: Text('الموظف', style: headerStyle)), DataColumn(label: Text('حاضر', style: headerStyle)), DataColumn(label: Text('متأخر', style: headerStyle)), DataColumn(label: Text('غائب', style: headerStyle))];
      case 'salary':
        return [DataColumn(label: Text('الموظف', style: headerStyle)), DataColumn(label: Text('الراتب', style: headerStyle)), DataColumn(label: Text('خصم غياب', style: headerStyle)), DataColumn(label: Text('خصم تأخير', style: headerStyle)), DataColumn(label: Text('الصافي', style: headerStyle))];
      case 'vacation':
        return [DataColumn(label: Text('الموظف', style: headerStyle)), DataColumn(label: Text('أيام مستخدمة', style: headerStyle)), DataColumn(label: Text('المتبقي', style: headerStyle))];
      case 'late':
        return [DataColumn(label: Text('الموظف', style: headerStyle)), DataColumn(label: Text('إجمالي الدقائق', style: headerStyle))];
      default:
        return [];
    }
  }

  List<DataCell> _getCells(String type, Map<String, dynamic> item) {
    switch (type) {
      case 'attendance':
        return [
          DataCell(Text(item['employee'] ?? '')),
          DataCell(Text(item['present_days']?.toString() ?? '0')),
          DataCell(Text(item['late_days']?.toString() ?? '0')),
          DataCell(Text(item['absent_days']?.toString() ?? '0')),
        ];
      case 'salary':
        return [
          DataCell(Text(item['employee'] ?? '')),
          DataCell(Text('${item['salary'] ?? '0'} ر.س')),
          DataCell(Text('${item['absence_deductions'] ?? '0'} ر.س', style: TextStyle(color: AppTheme.errorRed))),
          DataCell(Text('${item['late_deductions'] ?? '0'} ر.س', style: TextStyle(color: Colors.orange))),
          DataCell(Text('${item['final_salary'] ?? '0'} ر.س', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen))),
        ];
      case 'vacation':
        return [
          DataCell(Text(item['employee'] ?? '')),
          DataCell(Text(item['used_days']?.toString() ?? '0')),
          DataCell(Text(item['remaining_days']?.toString() ?? '0', style: TextStyle(fontWeight: FontWeight.bold))),
        ];
      case 'late':
        return [
          DataCell(Text(item['employee'] ?? '')),
          DataCell(Text('${item['total_late_minutes']?.toString() ?? '0'} دقيقة')),
        ];
      default:
        return [];
    }
  }
}
