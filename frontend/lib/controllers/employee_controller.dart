import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../models/app_models.dart';
import 'auth_controller.dart';
import '../core/utils/ui_utils.dart';

class EmployeeController extends GetxController {
  ApiService get _api => Get.find<ApiService>();
  AuthController get _auth => Get.find<AuthController>();

  var myAttendance = <AttendanceModel>[].obs;
  var myVacationRequests = <VacationRequestModel>[].obs;
  var myOvertimeRequests = <OvertimeRequestModel>[].obs;
  var myCorrectionRequests = <AttendanceCorrectionModel>[].obs;
  var employeeData = Rxn<EmployeeModel>();
  var settings = Rxn<SettingsModel>();
  var isLoading = false.obs;
  var preFilledVacationDate = ''.obs;
  var selectedAttachmentFile = Rx<PlatformFile?>(null);

  // New Filters for Employee
  final selectedYear = 2026.obs;
  final selectedMonth = 1.obs;
  var filteredAttendance = <AttendanceModel>[].obs;
  int get daysInMonth =>
      DateTime(selectedYear.value, selectedMonth.value + 1, 0).day;
  // Monthly Summary Totals
  var monthlyTotals = <String, dynamic>{}.obs;

  double get totalDiscount => (monthlyTotals['total_deduction'] ?? 0.0).toDouble();
  double get totalEarlyExitDiscount => (monthlyTotals['early_exit_deduction'] ?? 0.0).toDouble();
  double get totalLateDiscount => (monthlyTotals['late_deduction'] ?? 0.0).toDouble();
  double get totalAbsentDiscount => (monthlyTotals['absence_deduction'] ?? 0.0).toDouble();
  double get totalOvertimeGained => (monthlyTotals['overtime_bonus'] ?? 0.0).toDouble();

  int getApprovedOvertimeMinutes(String date) {
    return myOvertimeRequests
        .where((req) => req.date == date && req.status == 'approved')
        .fold(0, (sum, req) => sum + req.totalMinutes);
  }

  int get totalApprovedOvertimeMinutes => (monthlyTotals['total_overtime_minutes'] ?? 0).toInt();

  @override
  void onInit() {
    super.onInit();

    // Initial custom month calculation
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

    if (_auth.currentEmployeeId.value != 0) {
      fetchMyData();
    }

    // IMPORTANT: Listen for employee ID changes (e.g., when login finishes or storage is ready)
    ever(_auth.currentEmployeeId, (int id) {
      if (id != 0) {
        fetchMyData();
      }
    });

    // Listeners for filters
    // Listeners for filters
    ever(selectedMonth, (_) => fetchMonthlySummary());
    ever(selectedYear, (_) => fetchMonthlySummary());
  }

  Future<void> fetchMonthlySummary() async {
    if (_auth.currentEmployeeId.value == 0) return;
    isLoading.value = true;
    try {
      final res = await _api.getData(
          'attendance/monthly-summary?employee_id=${_auth.currentEmployeeId.value}&month=${selectedMonth.value}&year=${selectedYear.value}');
      if (res != null && res is Map) {
        if (res['days'] != null) {
          var list = (res['days'] as List)
              .map((e) => AttendanceModel.fromJson(e))
              .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          filteredAttendance.value = list;
        }
        if (res['totals'] != null) {
          monthlyTotals.value = Map<String, dynamic>.from(res['totals']);
        }
      }
    } catch (e) {
      // Error fetching monthly summary: $e
    } finally {
      isLoading.value = false;
    }
  }



  bool isDayPendingCorrection(String date) {
    return myCorrectionRequests
        .any((c) => c.date == date && c.status == 'pending');
  }

  bool isDayApprovedVacation(String date) {
    final d = DateTime.parse(date);
    return myVacationRequests.any((v) {
      if (v.status != 'approved') return false;
      final start = DateTime.parse(v.startDate);
      final end = DateTime.parse(v.endDate);
      return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
          (d.isAtSameMomentAs(end) || d.isBefore(end));
    });
  }

  bool isDayPendingVacation(String date) {
    final d = DateTime.parse(date);
    return myVacationRequests.any((v) {
      if (v.status != 'pending') return false;
      final start = DateTime.parse(v.startDate);
      final end = DateTime.parse(v.endDate);
      return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
          (d.isAtSameMomentAs(end) || d.isBefore(end));
    });
  }

  Future<void> fetchMyData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchMonthlySummary(),
        fetchMyAttendance(),
        fetchMyVacations(),
        fetchMyOvertime(),
        fetchMyCorrectionRequests(),
        fetchEmployeeDetails(),
        fetchSettings(),
      ]);
    } catch (e) {
      // print('Error overall fetch: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSettings() async {
    final data = await _api.getData('settings');
    if (data != null) {
      settings.value = SettingsModel.fromJson(data);
    }
  }

  Future<void> fetchEmployeeDetails() async {
    final data = await _api.getData('employees');
    if (data != null && data is List) {
      final emp = data.firstWhereOrNull((e) =>
          int.parse(e['id'].toString()) == _auth.currentEmployeeId.value);
      if (emp != null) {
        employeeData.value = EmployeeModel.fromJson(emp);
      }
    }
  }

  Future<void> fetchMyAttendance() async {
    final data = await _api.getData('attendance');
    if (data != null && data is List) {
      myAttendance.value = data
          .map((e) => AttendanceModel.fromJson(e))
          .where((e) => e.employeeId == _auth.currentEmployeeId.value)
          .toList();
    }
  }

  Future<void> fetchMyVacations() async {
    final data = await _api.getData('vacations');
    if (data != null && data is List) {
      myVacationRequests.value = data
          .map((e) => VacationRequestModel.fromJson(e))
          .where((e) => e.employeeId == _auth.currentEmployeeId.value)
          .toList();
    }
  }

  Future<void> fetchMyOvertime() async {
    final data = await _api.getData('overtime');
    if (data != null && data is List) {
      myOvertimeRequests.value = data
          .map((e) => OvertimeRequestModel.fromJson(e))
          .where((e) => e.employeeId == _auth.currentEmployeeId.value)
          .toList();
    }
  }

  Future<void> fetchMyCorrectionRequests() async {
    final data = await _api.getData('attendance-corrections');
    if (data != null && data is List) {
      myCorrectionRequests.value = data
          .map((e) => AttendanceCorrectionModel.fromJson(e))
          .where((e) => e.employeeId == _auth.currentEmployeeId.value)
          .toList();
    }
  }

  Future<dynamic> submitCorrectionRequest({
    required String date,
    required String type,
    String? originalTime,
    required String requestedTime,
    required String reason,
  }) async {
    isLoading.value = true;
    try {
      final res = await _api.postData('attendance-corrections', {
        'employee_id': _auth.currentEmployeeId.value,
        'date': date,
        'type': type,
        'original_time': originalTime,
        'requested_time': requestedTime,
        'reason': reason,
      });

      if (res != null) {
        if (res['status'] == 'error') {
          return res['message'] ?? 'حدث خطأ في تقديم الطلب';
        }
        fetchMyCorrectionRequests();
        return true;
      }
      return 'تعذر الاتصال بالخادم';
    } finally {
      isLoading.value = false;
    }
  }


  Future<dynamic> submitOvertimeRequest(
      {required String date,
      required String startTime,
      required String endTime,
      String? reason}) async {
    isLoading.value = true;
    try {
      final res = await _api.postData('overtime', {
        'employee_id': _auth.currentEmployeeId.value,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'reason': reason ?? '',
      });

      if (res != null) {
        if (res['status'] == 'error') {
          return res['message'] ?? 'حدث خطأ في تقديم الطلب';
        }
        fetchMyOvertime();
        return true;
      }
      return 'تعذر الاتصال بالخادم';
    } finally {
      isLoading.value = false;
    }
  }

  int getSystemWorkDayDurationInMinutes() {
    if (settings.value == null) return 8 * 60; // 8 hours fallback

    String startStr = settings.value!.ramadanMode ? settings.value!.ramadanStartTime : settings.value!.defaultStartTime;
    String endStr = settings.value!.ramadanMode ? settings.value!.ramadanEndTime : settings.value!.defaultEndTime;

    try {
      final partsSt = startStr.split(':');
      final partsEt = endStr.split(':');
      if (partsSt.length >= 2 && partsEt.length >= 2) {
        final h1 = int.parse(partsSt[0]);
        final m1 = int.parse(partsSt[1]);
        final h2 = int.parse(partsEt[0]);
        final m2 = int.parse(partsEt[1]);
        int diff = ((h2 * 60) + m2) - ((h1 * 60) + m1);
        if (diff < 0) diff += 24 * 60;
        if (diff > 0) return diff;
      }
    } catch (_) {}
    
    return 480;
  }

  Future<dynamic> requestVacation(
      String start, String end, int days, String type,
      {PlatformFile? attachmentFile,
      bool isHourly = false,
      String? startTime,
      String? endTime,
      int totalMinutes = 0,
      String? reason}) async {
    isLoading.value = true;
    try {
      final res = await _api.requestVacationWithFile({
        'employee_id': _auth.currentEmployeeId.value.toString(),
        'start_date': start,
        'end_date': end,
        'total_days': days.toString(),
        'vacation_type': type,
        'is_hourly': isHourly ? '1' : '0',
        'start_time': startTime ?? '',
        'end_time': endTime ?? '',
        'total_minutes': totalMinutes.toString(),
        'reason': reason ?? '',
      }, attachmentFile);

      if (res != null) {
        if (res['status'] == 'error' ||
            (res['message'] != null &&
                res['message'].toString().toLowerCase().contains('error'))) {
          return res['message'] ?? 'حدث خطأ في الخادم';
        }

        fetchMyVacations();
        return true;
      }
      return 'تعذر الاتصال بالخادم أو البيانات غير صالحة';
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
        fetchMyVacations();
        fetchMyAttendance();
        fetchEmployeeDetails();
        return null; // Success
      }
      return 'فشل الاتصال بالخادم';
    } catch (e) {
      return 'حدث خطأ: $e';
    } finally {
      isLoading.value = false;
    }
  }


}
