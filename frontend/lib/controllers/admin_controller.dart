import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../models/app_models.dart';
import 'auth_controller.dart';
import '../core/utils/ui_utils.dart';
import 'package:file_picker/file_picker.dart';

class AdminController extends GetxController {
  ApiService get _api => Get.find<ApiService>();

  var employees = <EmployeeModel>[].obs;
  var searchQuery = ''.obs;
  var filteredEmployees = <EmployeeModel>[].obs;
  var selectedDepartmentFilter = RxnInt(); // null = all

  var attendance = <AttendanceModel>[].obs;
  var vacationRequests = <VacationRequestModel>[].obs;
  var overtimeRequests = <OvertimeRequestModel>[].obs;
  var correctionRequests = <AttendanceCorrectionModel>[].obs;
  var holidays = <HolidayModel>[].obs;
  var departments = <DepartmentModel>[].obs;
  var settings = Rxn<SettingsModel>();
  var isLoading = false.obs;

  // Filters for Attendance
  final selectedYear = 2026.obs;
  final selectedMonth = 1.obs;
  var filteredAttendance = <AttendanceModel>[].obs;

  int get daysInMonth =>
      DateTime(selectedYear.value, selectedMonth.value + 1, 0).day;

  // Filters for Vacations
  var vacationSearchQuery = ''.obs;
  var vacationStatusFilter = 'all'.obs; // all, pending, approved, rejected
  var isVacationDateFilterEnabled = true.obs;
  var filteredVacationRequests = <VacationRequestModel>[].obs;

  // Filters for Overtime
  var overtimeSearchQuery = ''.obs;
  var overtimeStatusFilter = 'all'.obs;
  var filteredOvertimeRequests = <OvertimeRequestModel>[].obs;

  @override
  void onInit() {
    super.onInit();

    // Set initial custom month based on today's date
    final now = DateTime.now();
    int m = now.month;
    int y = now.year;
    if (now.day >= 25) {
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }
    selectedMonth.value = m;
    selectedYear.value = y;

    fetchInitialData();

    // Setup search listener
    ever(searchQuery, (_) => _filterEmployees());
    ever(employees, (_) => _filterEmployees());
    ever(selectedDepartmentFilter, (val) => fetchEmployees(departmentId: val));

    // Setup attendance filters
    ever(attendance, (_) => _applyAttendanceFilter());
    ever(selectedMonth, (_) => _applyAttendanceFilter());
    ever(selectedYear, (_) => _applyAttendanceFilter());
    ever(employees, (_) => _applyAttendanceFilter());
    ever(correctionRequests, (_) => _applyAttendanceFilter());

    // Setup vacation filters
    ever(vacationRequests, (_) => _filterVacations());
    ever(vacationSearchQuery, (_) => _filterVacations());
    ever(vacationStatusFilter, (_) => _filterVacations());
    ever(isVacationDateFilterEnabled, (_) => _filterVacations());
    ever(selectedMonth, (_) => _filterVacations());
    ever(selectedYear, (_) => _filterVacations());

    // Setup overtime filters
    ever(overtimeRequests, (_) => _filterOvertime());
    ever(overtimeSearchQuery, (_) => _filterOvertime());
    ever(overtimeStatusFilter, (_) => _filterOvertime());
    ever(selectedMonth, (_) => _filterOvertime());
    ever(selectedYear, (_) => _filterOvertime());
  }

  Future<void> fetchInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchEmployees(),
        fetchAttendance(),
        fetchVacationRequests(),
        fetchOvertimeRequests(),
        fetchCorrectionRequests(),
        fetchHolidays(),
        fetchDepartments(),
        fetchSettings(),
      ]);
    } catch (e) {
      print('Refresh error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncBiometricData() async {
    isLoading.value = true;
    try {
      final response = await _api.postData('attendance/sync_file', {});
      if (response != null) {
        UiUtils.showSuccessDialog(
            'تمت المزامنة', 'تمت مزامنة ملف الحضور بنجاح مع السيرفر.');
        fetchInitialData();
      } else {
        UiUtils.showErrorDialog(
            'خطأ', 'فشلت المزامنة. تحقق من الاتصال بالخادم.');
      }
    } catch (e) {
      UiUtils.showErrorDialog('خطأ', 'حدث خطأ أثناء المزامنة: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyAttendanceFilter() {
    // Collect all valid combinations of active employee and date
    List<AttendanceModel> result = [];

    // First, process all raw attendance records matching the date filter
    final rawMatches = attendance.where((a) {
      final date = DateTime.parse(a.date);

      int displayMonth = date.month;
      int displayYear = date.year;

      // Custom Month Logic: If day >= 25, it belongs to the NEXT month
      if (date.day >= 25) {
        displayMonth++;
        if (displayMonth > 12) {
          displayMonth = 1;
          displayYear++;
        }
      }

      bool isDateMatch = displayYear == selectedYear.value &&
          displayMonth == selectedMonth.value;

      // Filter only active employees
      final emp = getEmployeeById(a.employeeId);
      bool isActive = emp?.status == 'active';

      return isDateMatch && isActive;
    }).toList();

    // Apply corrections to each matching record
    for (var a in rawMatches) {
      result.add(_applyCorrections(a, a.date, a.employeeId)!);
    }

    // Now, handle synthetic records for missing punches
    // Loop over approved corrections that don't have a matching raw record
    final syntheticCorrections = correctionRequests.where((c) {
      if (c.status != 'approved') return false;
      final date = DateTime.parse(c.date);
      int dMonth = date.month;
      int dYear = date.year;
      if (date.day >= 25) {
        dMonth++;
        if (dMonth > 12) {
          dMonth = 1;
          dYear++;
        }
      }
      if (dYear != selectedYear.value || dMonth != selectedMonth.value)
        return false;

      return !rawMatches
          .any((a) => a.date == c.date && a.employeeId == c.employeeId);
    });

    for (var c in syntheticCorrections) {
      if (!result
          .any((r) => r.date == c.date && r.employeeId == c.employeeId)) {
        final synth = _applyCorrections(null, c.date, c.employeeId);
        if (synth != null) result.add(synth);
      }
    }

    filteredAttendance.value = result..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<bool> updateAttendanceNote(int attendanceId, String note) async {
    isLoading.value = true;
    try {
      final response = await _api.postData('attendance/update_note', {
        'id': attendanceId,
        'notes': note,
      });
      if (response != null) {
        // Find local instance and update notes immediately for quick UI reactivity
        final attIndex = attendance.indexWhere((a) => a.id == attendanceId);
        if (attIndex != -1) {
          attendance[attIndex].notes = note;
          _applyAttendanceFilter();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating note: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _filterEmployees() {
    List<EmployeeModel> results = employees;

    // 1. Department Filter
    if (selectedDepartmentFilter.value != null) {
      results = results
          .where((emp) => emp.departmentId == selectedDepartmentFilter.value)
          .toList();
    }

    // 2. Search Query
    if (searchQuery.isNotEmpty) {
      results = results
          .where((emp) =>
              emp.name
                  .toLowerCase()
                  .contains(searchQuery.value.toLowerCase()) ||
              emp.id.toString().contains(searchQuery.value))
          .toList();
    }

    filteredEmployees.value = results;
  }

  void _filterVacations() {
    filteredVacationRequests.value = vacationRequests.where((v) {
      // 1. Search Query (Employee Name)
      bool matchesSearch = vacationSearchQuery.isEmpty ||
          (v.employeeName
                  ?.toLowerCase()
                  .contains(vacationSearchQuery.value.toLowerCase()) ??
              false);

      // 2. Status Filter
      bool matchesStatus = vacationStatusFilter.value == 'all' ||
          v.status == vacationStatusFilter.value;

      // 3. Date Filter (using selected month/year)
      bool matchesMonth = true;
      if (isVacationDateFilterEnabled.value) {
        final date = DateTime.parse(v.startDate);
        matchesMonth = date.month == selectedMonth.value &&
            date.year == selectedYear.value;
      }

      return matchesSearch && matchesStatus && matchesMonth;
    }).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  void _filterOvertime() {
    filteredOvertimeRequests.value = overtimeRequests.where((r) {
      // 1. Search Query (Employee Name)
      bool matchesSearch = overtimeSearchQuery.isEmpty ||
          (r.employeeName
                  ?.toLowerCase()
                  .contains(overtimeSearchQuery.value.toLowerCase()) ??
              false) ||
          r.employeeId.toString().contains(overtimeSearchQuery.value);

      // 2. Status Filter
      bool matchesStatus = overtimeStatusFilter.value == 'all' ||
          r.status == overtimeStatusFilter.value;

      // 3. Date Filter (using selected month/year)
      final date = DateTime.parse(r.date);
      int displayMonth = date.month;
      int displayYear = date.year;

      if (date.day >= 25) {
        displayMonth++;
        if (displayMonth > 12) {
          displayMonth = 1;
          displayYear++;
        }
      }
      bool matchesMonth = displayMonth == selectedMonth.value &&
          displayYear == selectedYear.value;

      return matchesSearch && matchesStatus && matchesMonth;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  int getWorkDayDurationInMinutes(EmployeeModel? emp) {
    return getSystemWorkDayDurationInMinutes();
  }

  int getSystemWorkDayDurationInMinutes() {
    if (settings.value == null) return 8 * 60; // 8 hours fallback
    String startStr = settings.value!.ramadanMode
        ? settings.value!.ramadanStartTime
        : settings.value!.defaultStartTime;
    String endStr = settings.value!.ramadanMode
        ? settings.value!.ramadanEndTime
        : settings.value!.defaultEndTime;
    try {
      final start = _parseTime(startStr);
      final end = _parseTime(endStr);
      int diff = end.difference(start).inMinutes;
      if (diff < 0) diff += 24 * 60;
      return diff > 0 ? diff : (8 * 60);
    } catch (e) {
      return 8 * 60;
    }
  }

  // Employee Specific Monthly Summary
  var selectedEmployeeSummaryDays = <AttendanceModel>[].obs;
  var selectedEmployeeSummaryTotals = <String, dynamic>{}.obs;
  var selectedEmployeeClosings = <EmployeeClosingModel>[].obs;

  Future<void> fetchEmployeeClosings(int employeeId) async {
    try {
      final res = await _api.getData('reports/employee-closings?employee_id=$employeeId');
      if (res != null && res is List) {
        selectedEmployeeClosings.value = res.map((e) => EmployeeClosingModel.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching closings: $e");
    }
  }

  Future<void> fetchEmployeeMonthlySummary(int employeeId) async {
    isLoading.value = true;
    try {
      final res = await _api.getData(
          'attendance/monthly-summary?employee_id=$employeeId&month=${selectedMonth.value}&year=${selectedYear.value}');
      if (res != null && res is Map) {
        if (res['days'] != null) {
          selectedEmployeeSummaryDays.value = (res['days'] as List)
              .map((e) => AttendanceModel.fromJson(e))
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
        }
        if (res['totals'] != null) {
          selectedEmployeeSummaryTotals.value =
              Map<String, dynamic>.from(res['totals']);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> splitEmployeePayroll(int employeeId, String startDate, String endDate) async {
    isLoading.value = true;
    try {
      final res = await _api.splitPayroll(
          employeeId.toString(), selectedMonth.value, selectedYear.value, startDate, endDate);
      if (res != null && res is Map) {
        if (res['status'] == 'success') {
          // Refresh summary
          await fetchEmployeeMonthlySummary(employeeId);
          // Return the success data which might contain skipped duplicates
          if (res['data'] != null && res['data']['duplicates'] != null && (res['data']['duplicates'] as List).isNotEmpty) {
             return {'status': 'success', 'duplicates': res['data']['duplicates']};
          }
          return null;
        } else {
          return Map<String, dynamic>.from(res);
        }
      }
      return {'message': 'فشل الإغلاق أو لا توجد استجابة صحيحة'};
    } catch (e) {
      print('Error splitting payroll: $e');
      return {'message': e.toString().replaceAll('Exception: ', '')};
    } finally {
      isLoading.value = false;
    }
  }

  bool hasApprovedVacation(int employeeId, String date) =>
      getApprovedVacation(employeeId, date) != null;

  VacationRequestModel? getApprovedVacation(int employeeId, String date) {
    try {
      final d = DateTime.parse(date);
      return vacationRequests.firstWhereOrNull((v) {
        if (v.employeeId != employeeId || v.status != 'approved' || v.isHourly)
          return false;
        final start = DateTime.parse(v.startDate);
        final end = DateTime.parse(v.endDate);
        return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
            (d.isAtSameMomentAs(end) || d.isBefore(end));
      });
    } catch (e) {
      return null;
    }
  }

  bool hasPendingVacation(int employeeId, String date) =>
      getPendingVacation(employeeId, date) != null;

  VacationRequestModel? getPendingVacation(int employeeId, String date) {
    try {
      final d = DateTime.parse(date);
      return vacationRequests.firstWhereOrNull((v) {
        if (v.employeeId != employeeId || v.status != 'pending')
          return false;
        final start = DateTime.parse(v.startDate);
        final end = DateTime.parse(v.endDate);
        return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
            (d.isAtSameMomentAs(end) || d.isBefore(end));
      });
    } catch (e) {
      return null;
    }
  }

  VacationRequestModel? getHourlyVacationRequest(int employeeId, String date) {
    try {
      final d = DateTime.parse(date);
      return vacationRequests.firstWhereOrNull((v) {
        if (v.employeeId != employeeId || !v.isHourly) return false;
        final start = DateTime.parse(v.startDate);
        final end = DateTime.parse(v.endDate);
        return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
            (d.isAtSameMomentAs(end) || d.isBefore(end));
      });
    } catch (e) {
      return null;
    }
  }

  EmployeeModel? getEmployeeById(int id) {
    return employees.firstWhereOrNull((e) => e.id == id);
  }

  double calculateMinuteDiscount(double salary, EmployeeModel? emp,
      {int? customDaysInMonth}) {
    double effectiveSalary = salary;
    if (effectiveSalary <= 0 && emp != null) {
      effectiveSalary = emp.salary;
      if (effectiveSalary <= 0) {
        final latest = getEmployeeById(emp.id ?? 0);
        if (latest != null) effectiveSalary = latest.salary;
      }
    }

    int workMinutes = getWorkDayDurationInMinutes(emp);
    if (workMinutes <= 0) workMinutes = 480;

    int divisor = customDaysInMonth ?? daysInMonth;
    if (divisor <= 0) divisor = 30;

    return effectiveSalary / divisor / workMinutes;
  }

  // Employees
  Future<void> fetchEmployees({int? departmentId}) async {
    isLoading.value = true;
    String url = 'employees';
    if (departmentId != null) {
      url += '?department_id=$departmentId';
    }
    final data = await _api.getData(url);
    if (data != null && data is List) {
      employees.value = data.map((e) => EmployeeModel.fromJson(e)).toList();
    }
    isLoading.value = false;
  }

  Future<String?> addEmployee(EmployeeModel employee) async {
    isLoading.value = true;
    try {
      final res = await _api.postData('employees', employee.toJson());
      if (res != null && res is Map) {
        if (res['status'] == 'error') {
          return res['message'] ?? 'تعذر إضافة الموظف';
        }
      }
      fetchEmployees();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> updateEmployee(EmployeeModel employee) async {
    isLoading.value = true;
    try {
      final res =
          await _api.putData('employees/${employee.id}', employee.toJson());
      if (res != null && res is Map) {
        if (res['status'] == 'error') {
          return res['message'] ?? 'تعذر تحديث بيانات الموظف';
        }
      }
      fetchEmployees();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  int _calculateCreditMinutes(EmployeeModel emp) {
    // Treat the current vacationCredit value as 'Days' for calculation purposes
    // since the UI inputs days.
    int days = emp.vacationCredit;
    int dailyMinutes = getSystemWorkDayDurationInMinutes();

    return days * dailyMinutes;
  }

  Future<bool> deleteEmployee(int id) async {
    isLoading.value = true;
    try {
      final res = await _api.deleteData('employees/$id');
      if (res != null) {
        fetchEmployees();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Attendance
  Future<void> fetchAttendance() async {
    final data = await _api.getData('attendance');
    if (data != null && data is List) {
      attendance.value = data.map((e) => AttendanceModel.fromJson(e)).toList();
    }
  }

  Future<bool> importAttendance(String jsonPath) async {
    isLoading.value = true;
    final res = await _api.uploadJson('attendance/import', jsonPath);
    isLoading.value = false;
    if (res != null) {
      fetchAttendance();
      return true;
    }
    return false;
  }

  // Vacations
  Future<void> fetchVacationRequests() async {
    final data = await _api.getData('vacations');
    if (data != null && data is List) {
      vacationRequests.value =
          data.map((e) => VacationRequestModel.fromJson(e)).toList();
    }
  }

  Future<bool> updateVacationStatus(int id, String status,
      {String? note}) async {
    isLoading.value = true;
    try {
      final res = await _api.putData('vacations/$id', {
        'status': status,
        if (note != null) 'notes': note,
      });
      if (res != null) {
        fetchVacationRequests();
        fetchEmployees(); // Credit might have changed
        fetchAttendance();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> deleteVacation(int id) async {
    isLoading.value = true;
    try {
      final res = await _api.deleteVacation(id);
      if (res != null && res is Map) {
        if (res['status'] == 'error') {
          return res['message']?.toString() ?? 'تعذر حذف الإجازة';
        }
        fetchVacationRequests();
        fetchEmployees();
        fetchAttendance();
        return null; // Success
      }
      return 'فشل الاتصال بالخادم';
    } catch (e) {
      return 'حدث خطأ: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchDetailedAttendance(
      int employeeId, String startDate, String endDate) async {
    try {
      final res = await _api.postData('reports/detailed-attendance', {
        'employee_id': employeeId,
        'start_date': startDate,
        'end_date': endDate,
      });
      if (res != null && res['status'] == 'success' && res['days'] != null) {
        return List<Map<String, dynamic>>.from(res['days']);
      }
      return [];
    } catch (e) {
      if (kDebugMode) print('fetchDetailedAttendance error: $e');
      return [];
    }
  }

  Future<bool> addVacationRequest(VacationRequestModel request,
      {PlatformFile? attachmentFile}) async {
    isLoading.value = true;
    try {
      dynamic res;
      if (attachmentFile != null) {
        final data = {
          'employee_id': request.employeeId.toString(),
          'start_date': request.startDate,
          'end_date': request.endDate,
          'total_days': request.totalDays.toString(),
          'vacation_type': request.vacationType,
          'status': request.status,
          'reason': request.reason ?? '',
          'is_hourly': request.isHourly ? '1' : '0',
          'start_time': request.startTime ?? '',
          'end_time': request.endTime ?? '',
          'total_minutes': request.totalMinutes.toString(),
          'notes': request.notes ?? '',
          'is_admin': 'true',
        };
        res = await _api.requestVacationWithFile(data, attachmentFile);
      } else {
        final payload = request.toJson();
        payload['is_admin'] = true;
        res = await _api.postData('vacations', payload);
      }

      if (res != null) {
        if (res is Map && res['status'] == 'error') {
          return false;
        }
        fetchVacationRequests();
        fetchEmployees();
        fetchAttendance();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> addVacationRequestWithReason(VacationRequestModel request,
      {PlatformFile? attachmentFile}) async {
    isLoading.value = true;
    try {
      dynamic res;
      if (attachmentFile != null) {
        final data = {
          'employee_id': request.employeeId.toString(),
          'start_date': request.startDate,
          'end_date': request.endDate,
          'total_days': request.totalDays.toString(),
          'vacation_type': request.vacationType,
          'status': request.status,
          'reason': request.reason ?? '',
          'is_hourly': request.isHourly ? '1' : '0',
          'start_time': request.startTime ?? '',
          'end_time': request.endTime ?? '',
          'total_minutes': request.totalMinutes.toString(),
          'notes': request.notes ?? '',
          'is_admin': 'true',
        };
        res = await _api.requestVacationWithFile(data, attachmentFile);
      } else {
        final payload = request.toJson();
        payload['is_admin'] = true;
        res = await _api.postData('vacations', payload);
      }

      if (res != null) {
        if (res is Map && res['status'] == 'error') {
          return res['message']?.toString() ?? 'خطأ غير معروف من الخادم';
        }
        fetchVacationRequests();
        fetchEmployees();
        fetchAttendance();
        return null; // Success
      }
      return 'فشل الاتصال بالخادم';
    } catch (e) {
      return 'حدث خطأ: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Settings
  Future<void> fetchSettings() async {
    final data = await _api.getData('settings');
    if (data != null) {
      settings.value = SettingsModel.fromJson(data);
    }
  }

  Future<bool> updateSettings(SettingsModel newSettings) async {
    isLoading.value = true;
    try {
      final res = await _api.putData('settings', newSettings.toJson());
      if (res != null) {
        settings.value = newSettings;
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Reports
  Future<List<dynamic>> getReport(String type) async {
    final data = await _api.getData('reports/$type');
    return data ?? [];
  }

  // General Holidays Management
  Future<void> fetchHolidays() async {
    final data = await _api.getData('holidays');
    if (data != null && data is List) {
      holidays.value = data.map((e) => HolidayModel.fromJson(e)).toList();
    }
  }

  // Departments
  Future<void> fetchDepartments() async {
    final data = await _api.getData('departments');
    if (data != null && data is List) {
      departments.value = data.map((e) => DepartmentModel.fromJson(e)).toList();
    }
  }

  Future<bool> addDepartment(String name) async {
    isLoading.value = true;
    try {
      final res = await _api.postData('departments', {'name': name});
      if (res != null) {
        fetchDepartments();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateDepartment(int id, String name) async {
    isLoading.value = true;
    try {
      final res = await _api.putData('departments', {'id': id, 'name': name});
      if (res != null) {
        fetchDepartments();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteDepartment(int id) async {
    isLoading.value = true;
    try {
      final res = await _api.deleteData('departments/$id');
      if (res != null) {
        fetchDepartments();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Overtime
  Future<void> fetchOvertimeRequests() async {
    final data = await _api.getData('overtime');
    if (data != null && data is List) {
      overtimeRequests.value =
          data.map((e) => OvertimeRequestModel.fromJson(e)).toList();
    }
  }

  Future<bool> updateOvertimeStatus(int id, String status,
      {String? adminNote}) async {
    isLoading.value = true;
    try {
      final res = await _api.putData('overtime/$id', {
        'status': status,
        'admin_note': adminNote ?? '',
      });
      if (res != null) {
        fetchOvertimeRequests();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addHoliday(HolidayModel holiday) async {
    isLoading.value = true;
    try {
      final res = await _api.postData('holidays', holiday.toJson());
      if (res != null) {
        fetchHolidays();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteHoliday(int id) async {
    isLoading.value = true;
    try {
      final res = await _api.deleteData('holidays/$id');
      if (res != null) {
        fetchHolidays();
        return true;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Holiday Helpers
  HolidayModel? getHolidayForDate(String dateStr) {
    if (holidays.isEmpty) return null;
    final date = DateTime.parse(dateStr);
    return holidays.firstWhereOrNull((h) {
      final start = DateTime.parse(h.date);
      final end = h.endDate != null ? DateTime.parse(h.endDate!) : start;

      if (h.isRecurring) {
        if (h.endDate == null || h.endDate == h.date) {
          return date.month == start.month && date.day == start.day;
        } else {
          final normStart = DateTime(date.year, start.month, start.day);
          var normEnd = DateTime(date.year, end.month, end.day);

          if (normEnd.isBefore(normStart)) {
            return (date.isAtSameMomentAs(normStart) ||
                    date.isAfter(normStart)) ||
                (date.isAtSameMomentAs(normEnd) || date.isBefore(normEnd));
          }
          return (date.isAtSameMomentAs(normStart) ||
                  date.isAfter(normStart)) &&
              (date.isAtSameMomentAs(normEnd) || date.isBefore(normEnd));
        }
      }

      return (date.isAtSameMomentAs(start) || date.isAfter(start)) &&
          (date.isAtSameMomentAs(end) || date.isBefore(end));
    });
  }

  bool isHoliday(String dateStr) => getHolidayForDate(dateStr) != null;

  bool isEarlyExit(AttendanceModel att, [EmployeeModel? emp]) {
    String? effectiveCheckOut = att.checkOut;
    final approvedCorr = correctionRequests.firstWhereOrNull((c) =>
        c.date == att.date &&
        c.employeeId == att.employeeId &&
        c.status == 'approved' &&
        (c.type == 'check_out' || c.type == 'missing_check_out'));
    if (approvedCorr != null) {
      effectiveCheckOut = approvedCorr.requestedTime;
    }

    if (effectiveCheckOut == null ||
        effectiveCheckOut.isEmpty ||
        settings.value == null) {
      return false;
    }

    try {
      final checkOutTime = _parseTime(effectiveCheckOut);
      final e = emp ?? getEmployeeById(att.employeeId);
      bool useDefault = _prefersDefaultShift(att, e);

      String endStr = (useDefault ||
              e?.specialEndTime == null ||
              e!.specialEndTime!.isEmpty)
          ? (settings.value!.ramadanMode
              ? settings.value!.ramadanEndTime
              : settings.value!.defaultEndTime)
          : e.specialEndTime!;

      final endTime = _parseTime(endStr);
      final diff = endTime.difference(checkOutTime).inMinutes;

      int calculatedEarly = diff;
      final vac = getHourlyVacationRequest(att.employeeId, att.date);
      if (vac != null) {
        int rawLate = 0;
        String? effectiveCheckIn = att.checkIn;
        final approvedCorr = correctionRequests.firstWhereOrNull((c) =>
            c.date == att.date &&
            c.employeeId == att.employeeId &&
            c.status == 'approved' &&
            (c.type == 'check_in' || c.type == 'missing_check_in'));
        if (approvedCorr != null) {
          effectiveCheckIn = approvedCorr.requestedTime;
        }
        if (effectiveCheckIn != null && effectiveCheckIn.isNotEmpty) {
          try {
            final checkInTime = _parseTime(effectiveCheckIn);
            final employee = emp ?? getEmployeeById(att.employeeId);
            bool useDefault = _prefersDefaultShift(att, employee);
            String baselineStr = (useDefault ||
                    employee?.specialStartTime == null ||
                    employee!.specialStartTime!.isEmpty)
                ? (settings.value!.ramadanMode
                    ? settings.value!.ramadanStartTime
                    : settings.value!.defaultStartTime)
                : employee.specialStartTime!;
            final baselineTime = _parseTime(baselineStr);
            int diffLate = checkInTime.difference(baselineTime).inMinutes;
            rawLate = diffLate - settings.value!.allowedLateMinutes;
            if (rawLate < 0) rawLate = 0;
          } catch (_) {}
        }

        int vacMinutes = vac.totalMinutes;
        int coveredLate = vacMinutes < rawLate ? vacMinutes : rawLate;
        vacMinutes -= coveredLate;

        int rawEarly = calculatedEarly > 0 ? calculatedEarly : 0;
        int coveredEarly = vacMinutes < rawEarly ? vacMinutes : rawEarly;
        calculatedEarly = rawEarly - coveredEarly;
      }

      return calculatedEarly > 0;
    } catch (e) {
      return false;
    }
  }

  int getEffectiveLateMinutes(AttendanceModel att, EmployeeModel? emp) {
    String? effectiveCheckIn = att.checkIn;
    final approvedCorr = correctionRequests.firstWhereOrNull((c) =>
        c.date == att.date &&
        c.employeeId == att.employeeId &&
        c.status == 'approved' &&
        (c.type == 'check_in' || c.type == 'missing_check_in'));
    if (approvedCorr != null) {
      effectiveCheckIn = approvedCorr.requestedTime;
    }

    if (effectiveCheckIn == null || effectiveCheckIn.isEmpty) return 0;
    if (settings.value == null) return att.lateMinutes;

    final e = emp ?? getEmployeeById(att.employeeId);
    if (e != null && e.isFlexible) return 0;

    try {
      final checkInTime = _parseTime(effectiveCheckIn);
      bool useDefault = _prefersDefaultShift(att, emp);

      String baselineStr = (useDefault ||
              emp?.specialStartTime == null ||
              emp!.specialStartTime!.isEmpty)
          ? (settings.value!.ramadanMode
              ? settings.value!.ramadanStartTime
              : settings.value!.defaultStartTime)
          : emp.specialStartTime!;

      final baselineTime = _parseTime(baselineStr);
      final diff = checkInTime.difference(baselineTime).inMinutes;
      int calculatedLate = diff - settings.value!.allowedLateMinutes;

      final vac = getHourlyVacationRequest(att.employeeId, att.date);
      if (vac != null) {
        int vacMinutes = vac.totalMinutes;
        int rawLate = calculatedLate > 0 ? calculatedLate : 0;
        int coveredLate = vacMinutes < rawLate ? vacMinutes : rawLate;
        calculatedLate = rawLate - coveredLate;
      }

      return calculatedLate > 0 ? calculatedLate : 0;
    } catch (e) {
      return att.lateMinutes;
    }
  }

  double getEffectiveDiscount(AttendanceModel att, EmployeeModel? emp) {
    if (emp == null) return 0.0;
    return att.discount;
  }

  int getEarlyExitMinutes(AttendanceModel att, [EmployeeModel? emp]) {
    String? effectiveCheckOut = att.checkOut;
    final approvedCorr = correctionRequests.firstWhereOrNull((c) =>
        c.date == att.date &&
        c.employeeId == att.employeeId &&
        c.status == 'approved' &&
        (c.type == 'check_out' || c.type == 'missing_check_out'));
    if (approvedCorr != null) {
      effectiveCheckOut = approvedCorr.requestedTime;
    }

    if (effectiveCheckOut == null ||
        effectiveCheckOut.isEmpty ||
        settings.value == null) {
      return 0;
    }
    try {
      final checkOutTime = _parseTime(effectiveCheckOut);
      final e = emp ?? getEmployeeById(att.employeeId);

      int calculatedEarly = 0;
      if (e != null && e.isFlexible) {
        String? effectiveCheckIn = att.checkIn;
        final approvedInCorr = correctionRequests.firstWhereOrNull((c) =>
            c.date == att.date &&
            c.employeeId == att.employeeId &&
            c.status == 'approved' &&
            (c.type == 'check_in' || c.type == 'missing_check_in'));
        if (approvedInCorr != null) {
          effectiveCheckIn = approvedInCorr.requestedTime;
        }
        if (effectiveCheckIn != null && effectiveCheckIn.isNotEmpty) {
          final checkInTime = _parseTime(effectiveCheckIn);
          final duration = checkOutTime.difference(checkInTime).inMinutes;
          final reqMins = (e.requiredHours * 60).round();
          if (duration < reqMins) {
            calculatedEarly = reqMins - duration;
          }
        }
      } else {
        bool useDefault = _prefersDefaultShift(att, e);
        String endStr = (useDefault ||
                e?.specialEndTime == null ||
                e!.specialEndTime!.isEmpty)
            ? (settings.value!.ramadanMode
                ? settings.value!.ramadanEndTime
                : settings.value!.defaultEndTime)
            : e!.specialEndTime!;
        final endTime = _parseTime(endStr);
        calculatedEarly = endTime.difference(checkOutTime).inMinutes;
      }
      final vac = getHourlyVacationRequest(att.employeeId, att.date);
      if (vac != null) {
        int rawLate = 0;
        String? effectiveCheckIn = att.checkIn;
        final approvedCorr = correctionRequests.firstWhereOrNull((c) =>
            c.date == att.date &&
            c.employeeId == att.employeeId &&
            c.status == 'approved' &&
            (c.type == 'check_in' || c.type == 'missing_check_in'));
        if (approvedCorr != null) {
          effectiveCheckIn = approvedCorr.requestedTime;
        }
        if (effectiveCheckIn != null && effectiveCheckIn.isNotEmpty) {
          try {
            final checkInTime = _parseTime(effectiveCheckIn);
            final employee = emp ?? getEmployeeById(att.employeeId);
            bool useDefault = _prefersDefaultShift(att, employee);
            String baselineStr = (useDefault ||
                    employee?.specialStartTime == null ||
                    employee!.specialStartTime!.isEmpty)
                ? (settings.value!.ramadanMode
                    ? settings.value!.ramadanStartTime
                    : settings.value!.defaultStartTime)
                : employee.specialStartTime!;
            final baselineTime = _parseTime(baselineStr);
            int diffLate = checkInTime.difference(baselineTime).inMinutes;
            rawLate = diffLate - settings.value!.allowedLateMinutes;
            if (rawLate < 0) rawLate = 0;
          } catch (_) {}
        }

        int vacMinutes = vac.totalMinutes;
        int coveredLate = vacMinutes < rawLate ? vacMinutes : rawLate;
        vacMinutes -= coveredLate;

        int rawEarly = calculatedEarly > 0 ? calculatedEarly : 0;
        int coveredEarly = vacMinutes < rawEarly ? vacMinutes : rawEarly;
        calculatedEarly = rawEarly - coveredEarly;
      }

      return calculatedEarly > 0 ? calculatedEarly : 0;
    } catch (e) {
      return 0;
    }
  }

  bool _prefersDefaultShift(AttendanceModel att, EmployeeModel? emp) {
    if (emp == null || settings.value == null) return true;
    if (emp.specialStartTime == null || emp.specialStartTime!.isEmpty)
      return true;

    // Determine effective times (with corrections)
    String? effectiveIn = att.checkIn;
    final approvedInCorr = correctionRequests.firstWhereOrNull((c) =>
        c.date == att.date &&
        c.employeeId == att.employeeId &&
        c.status == 'approved' &&
        (c.type == 'check_in' || c.type == 'missing_check_in'));
    if (approvedInCorr != null) effectiveIn = approvedInCorr.requestedTime;

    String? effectiveOut = att.checkOut;
    final approvedOutCorr = correctionRequests.firstWhereOrNull((c) =>
        c.date == att.date &&
        c.employeeId == att.employeeId &&
        c.status == 'approved' &&
        (c.type == 'check_out' || c.type == 'missing_check_out'));
    if (approvedOutCorr != null) effectiveOut = approvedOutCorr.requestedTime;

    if (effectiveIn == null || effectiveIn.isEmpty) return false;

    try {
      final checkInTime = _parseTime(effectiveIn);

      // Default baseline times
      String defaultStartStr = settings.value!.ramadanMode
          ? settings.value!.ramadanStartTime
          : settings.value!.defaultStartTime;
      String defaultEndStr = settings.value!.ramadanMode
          ? settings.value!.ramadanEndTime
          : settings.value!.defaultEndTime;

      final baselineDefault = _parseTime(defaultStartStr);
      final endDefault = _parseTime(defaultEndStr);

      // Check if employee is within default shift limits
      bool withinDefaultIn = checkInTime.isAtSameMomentAs(baselineDefault) ||
          checkInTime.isBefore(baselineDefault
              .add(Duration(minutes: settings.value!.allowedLateMinutes)));

      bool withinDefaultOut = false;
      if (effectiveOut != null && effectiveOut.isNotEmpty) {
        final checkOutTime = _parseTime(effectiveOut);
        withinDefaultOut = checkOutTime.isAtSameMomentAs(endDefault) ||
            checkOutTime.isAfter(endDefault);
      }

      // If they met the default shift requirements exactly, prefer default regardless of special shift
      if (withinDefaultIn && withinDefaultOut) return true;

      // Option A: Special
      int lateSpecial = 0;
      final baselineSpecial = _parseTime(emp.specialStartTime!);
      final diffSpec = checkInTime.difference(baselineSpecial).inMinutes;
      lateSpecial = diffSpec - settings.value!.allowedLateMinutes;
      if (lateSpecial < 0) lateSpecial = 0;

      int earlySpecial = 0;
      if (effectiveOut != null &&
          effectiveOut.isNotEmpty &&
          emp.specialEndTime != null &&
          emp.specialEndTime!.isNotEmpty) {
        final endSpecial = _parseTime(emp.specialEndTime!);
        final diffSpecOut =
            endSpecial.difference(_parseTime(effectiveOut)).inMinutes;
        earlySpecial = diffSpecOut > 0 ? diffSpecOut : 0;
      }

      // Option B: Default
      final diffDef = checkInTime.difference(baselineDefault).inMinutes;
      int lateDefault = diffDef - settings.value!.allowedLateMinutes;
      if (lateDefault < 0) lateDefault = 0;

      int earlyDefault = 0;
      if (effectiveOut != null && effectiveOut.isNotEmpty) {
        final diffDefOut =
            endDefault.difference(_parseTime(effectiveOut)).inMinutes;
        earlyDefault = diffDefOut > 0 ? diffDefOut : 0;
      }

      return (lateDefault + earlyDefault) <= (lateSpecial + earlySpecial);
    } catch (e) {
      return true;
    }
  }

  DateTime _parseTime(String timeStr) {
    String timePart = timeStr.contains(' ') ? timeStr.split(' ')[1] : timeStr;
    final parts = timePart.split(':');
    return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  Future<void> syncDatabase() async {
    isLoading.value = true;
    // Show a persistent loading dialog for progress
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري مزامنة البيانات...',
                    style: TextStyle(
                        fontFamily: 'Janat', fontWeight: FontWeight.bold)),
                Text('يرجى عدم إغلاق التطبيق',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey, fontFamily: 'Janat')),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final res = await _api.syncDatabaseFromFile();

    // Close loading dialog
    Get.back();
    isLoading.value = false;

    if (res != null &&
        (res['message'] == 'Success' || res['message'] == 'نجاح')) {
      fetchAttendance(); // Refresh the list
      Get.defaultDialog(
        title: 'اكتملت المزامنة',
        middleText: 'تمت معالجة ${res['blocks']} حزمة بيانات.\n'
            'جديد: ${res['imported']} | تحديث: ${res['updated']}\n'
            'موجود مسبقاً: ${res['skipped']} | غير مسجل: ${res['unregistered']}',
        confirm:
            TextButton(onPressed: () => Get.back(), child: const Text('تم')),
      );
    } else {
      UiUtils.showErrorDialog(
          'خطأ', 'فشلت عملية المزامنة: ${res?['message'] ?? 'فشل الاتصال'}');
    }
  }

  Future<void> fetchCorrectionRequests() async {
    final data = await _api.getData('attendance-corrections');
    if (data != null && data is List) {
      correctionRequests.value =
          data.map((e) => AttendanceCorrectionModel.fromJson(e)).toList();
    }
  }

  Future<dynamic> updateCorrectionStatus(
      int id, String status, String adminNote) async {
    isLoading.value = true;
    try {
      final res = await _api.putData('attendance-corrections/$id', {
        'status': status,
        'admin_note': adminNote,
        'admin_id': Get.find<AuthController>().currentEmployeeId.value,
      });

      if (res != null) {
        fetchCorrectionRequests();
        return true;
      }
      return 'تعذر تحديث طلب التصحيح';
    } finally {
      isLoading.value = false;
    }
  }

  AttendanceModel? _applyCorrections(
      AttendanceModel? raw, String dateStr, int empId) {
    final corrections = correctionRequests
        .where((c) =>
            c.date == dateStr &&
            c.employeeId == empId &&
            c.status == 'approved')
        .toList();

    if (corrections.isEmpty) return raw;

    String? checkIn = raw?.checkIn;
    String? checkOut = raw?.checkOut;

    for (var c in corrections) {
      if (c.type == 'missing_check_in' ||
          (c.type == 'edit_time' &&
              (c.originalTime == checkIn || checkIn == null))) {
        checkIn = '${c.date} ${c.requestedTime}';
      } else if (c.type == 'missing_check_out' ||
          (c.type == 'edit_time' &&
              (c.originalTime == checkOut || checkOut == null))) {
        checkOut = '${c.date} ${c.requestedTime}';
      } else if (c.type == 'delete_record') {
        if (c.originalTime == checkIn) checkIn = null;
        if (c.originalTime == checkOut) checkOut = null;
      }
    }

    if (checkIn == null && checkOut == null) return null;

    return AttendanceModel(
      employeeId: empId,
      date: dateStr,
      checkIn: checkIn,
      checkOut: checkOut,
      status: (checkIn != null && checkOut != null)
          ? 'present'
          : (checkIn != null ? 'incomplete' : 'absent'),
      source: 'corrected',
      salary: raw?.salary ?? getEmployeeById(empId)?.salary ?? 0.0,
      discount: raw?.discount ?? 0.0,
      lateMinutes: raw?.lateMinutes ?? 0,
      earlyExitMinutes: raw?.earlyExitMinutes ?? 0,
    );
  }

  Future<bool> sendBroadcastNotification(
      String title, String message, String url) async {
    if (kDebugMode) {
      UiUtils.showSuccessDialog('وضع المطور',
          'تم إيقاف إرسال الإشعارات للمستخدمين في وضع التصحيح (Debug Mode).');
      return true;
    }
    isLoading.value = true;
    try {
      final res = await _api.getData(
          'reports/send_broadcast?title=$title&message=$message&url=$url');
      isLoading.value = false;
      return res != null;
    } catch (e) {
      isLoading.value = false;
      return false;
    }
  }
}
