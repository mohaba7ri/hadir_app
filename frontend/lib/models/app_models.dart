export 'attendance_correction_model.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';

class EmployeeModel {
  int? id;
  String name;
  double salary;
  String? specialStartTime;
  String? specialEndTime;
  int vacationCredit;
  int workDaysPerWeek;
  String status;
  String password;
  bool isFlexible;
  double requiredHours;
  int? departmentId;
  String? departmentName;
  int monthlyAnnualLeaveLimitMinutes;

  EmployeeModel({
    this.id,
    required this.name,
    this.salary = 0.0,
    this.specialStartTime,
    this.specialEndTime,
    this.vacationCredit = 30,
    this.workDaysPerWeek = 6,
    this.status = 'active',
    this.password = '123',
    this.isFlexible = false,
    this.requiredHours = 8.0,
    this.departmentId,
    this.departmentName,
    this.monthlyAnnualLeaveLimitMinutes = 750,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] ?? 'موظف جديد',
      salary: json['salary'] != null
          ? double.tryParse(json['salary'].toString()) ?? 0.0
          : 0.0,
      specialStartTime: json['special_start_time'],
      specialEndTime: json['special_end_time'],
      vacationCredit: json['vacation_credit'] != null
          ? () {
              final val = int.tryParse(json['vacation_credit'].toString()) ?? 0;
              if (val > 1000000) {
                return val ~/ 60000;
              }
              return val;
            }()
          : 0,
      workDaysPerWeek: json['work_days_per_week'] != null
          ? int.tryParse(json['work_days_per_week'].toString()) ?? 6
          : 6,
      status: json['status'] ?? 'active',
      password: json['password'] ?? '123',
      isFlexible: json['is_flexible'] == 1 || json['is_flexible'] == true,
      requiredHours: json['required_hours'] != null
          ? double.tryParse(json['required_hours'].toString()) ?? 8.0
          : 8.0,
      departmentId: json['department_id'] != null
          ? int.tryParse(json['department_id'].toString())
          : null,
      departmentName: json['department_name'],
      monthlyAnnualLeaveLimitMinutes: json['monthly_annual_leave_limit_minutes'] != null
          ? int.tryParse(json['monthly_annual_leave_limit_minutes'].toString()) ?? 750
          : 750,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'salary': salary,
      'special_start_time': specialStartTime,
      'special_end_time': specialEndTime,
      'vacation_credit': vacationCredit,
      'work_days_per_week': workDaysPerWeek,
      'status': status,
      'password': password,
      'is_flexible': isFlexible ? 1 : 0,
      'required_hours': requiredHours,
      'department_id': departmentId,
      'monthly_annual_leave_limit_minutes': monthlyAnnualLeaveLimitMinutes,
    };
  }
}

class AttendanceModel {
  int? id;
  int employeeId;
  String? employeeName;
  String date;
  String? checkIn;
  String? checkOut;
  int lateMinutes;
  int earlyExitMinutes;
  String status;
  String source;
  double salary;
  double discount;
  double lateDiscount;
  double earlyExitDiscount;
  int overtimeMinutes;
  String? notes;
  bool isCorrected;
  bool isCheckInCorrected;
  bool isCheckOutCorrected;
  bool isPendingCorrection;

  AttendanceModel({
    this.id,
    required this.employeeId,
    this.employeeName,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.lateMinutes = 0,
    this.earlyExitMinutes = 0,
    required this.status,
    this.source = 'json_import',
    this.salary = 0.0,
    this.discount = 0.0,
    this.lateDiscount = 0.0,
    this.earlyExitDiscount = 0.0,
    this.overtimeMinutes = 0,
    this.notes,
    this.isCorrected = false,
    this.isCheckInCorrected = false,
    this.isCheckOutCorrected = false,
    this.isPendingCorrection = false,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      employeeId: json['employee_id'] != null
          ? int.tryParse(json['employee_id'].toString()) ?? 0
          : 0,
      employeeName: json['employee_name'],
      date: json['date'] ?? '',
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      lateMinutes: json['late_minutes'] != null
          ? int.tryParse(json['late_minutes'].toString()) ?? 0
          : 0,
      earlyExitMinutes: json['early_exit_minutes'] != null
          ? int.tryParse(json['early_exit_minutes'].toString()) ?? 0
          : 0,
      status: json['status'] ?? 'pending',
      source: json['source'] ?? 'json_import',
      salary: json['salary'] != null
          ? double.tryParse(json['salary'].toString()) ?? 0.0
          : 0.0,
      discount: json['discount'] != null
          ? double.tryParse(json['discount'].toString()) ?? 0.0
          : 0.0,
      lateDiscount: json['late_discount'] != null
          ? double.tryParse(json['late_discount'].toString()) ?? 0.0
          : 0.0,
      earlyExitDiscount: json['early_exit_discount'] != null
          ? double.tryParse(json['early_exit_discount'].toString()) ?? 0.0
          : 0.0,
      overtimeMinutes: json['approved_overtime'] != null
          ? int.tryParse(json['approved_overtime'].toString()) ?? 0
          : 0,
      notes: json['notes'],
      isCorrected:
          json['source'] == 'corrected' || json['source'] == 'correction',
      isCheckInCorrected:
          json['source'] == 'corrected' || json['source'] == 'correction',
      isCheckOutCorrected:
          json['source'] == 'corrected' || json['source'] == 'correction',
    );
  }
}

class VacationRequestModel {
  int? id;
  int employeeId;
  String? employeeName;
  String startDate;
  String endDate;
  int totalDays;
  String status;
  String vacationType;
  String? attachment;
  String? reason;
  bool isHourly;
  String? startTime;
  String? endTime;
  int totalMinutes;
  String? createdAt;
  String? notes;

  VacationRequestModel({
    this.id,
    required this.employeeId,
    this.employeeName,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    this.status = 'pending',
    this.vacationType = AppConstants.annualLeave,
    this.attachment,
    this.reason,
    this.isHourly = false,
    this.startTime,
    this.endTime,
    this.totalMinutes = 0,
    this.createdAt,
    this.notes,
  });

  factory VacationRequestModel.fromJson(Map<String, dynamic> json) {
    return VacationRequestModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      employeeId: json['employee_id'] != null
          ? int.tryParse(json['employee_id'].toString()) ?? 0
          : 0,
      employeeName: json['employee_name'],
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      totalDays: json['total_days'] != null
          ? int.tryParse(json['total_days'].toString()) ?? 0
          : 0,
      status: json['status'] ?? 'pending',
      vacationType: json['vacation_type'] ?? AppConstants.annualLeave,
      attachment: json['attachment'],
      reason: json['reason'],
      isHourly: json['is_hourly'] == 1 || json['is_hourly'] == true,
      startTime: json['start_time'],
      endTime: json['end_time'],
      totalMinutes: json['total_minutes'] != null
          ? int.tryParse(json['total_minutes'].toString()) ?? 0
          : 0,
      createdAt: json['created_at'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'start_date': startDate,
      'end_date': endDate,
      'total_days': totalDays,
      'status': status,
      'vacation_type': vacationType,
      'attachment': attachment,
      'reason': reason,
      'notes': notes,
      'is_hourly': isHourly ? 1 : 0,
      'start_time': startTime,
      'end_time': endTime,
      'total_minutes': totalMinutes,
      'created_at': createdAt,
    };
  }
}

class SettingsModel {
  String defaultStartTime;
  int allowedLateMinutes;
  String ramadanStartTime;
  String ramadanEndTime;
  bool ramadanMode;
  String defaultEndTime;
  int lastRenewalYear;
  int minVersion;
  String? forceUpdateUrl;

  SettingsModel({
    required this.defaultStartTime,
    required this.allowedLateMinutes,
    required this.ramadanStartTime,
    required this.ramadanEndTime,
    required this.ramadanMode,
    required this.defaultEndTime,
    required this.lastRenewalYear,
    this.minVersion = 1,
    this.forceUpdateUrl,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      defaultStartTime: json['default_start_time'] ?? '08:00:00',
      allowedLateMinutes: json['allowed_late_minutes'] != null
          ? int.tryParse(json['allowed_late_minutes'].toString()) ?? 15
          : 15,
      ramadanStartTime: json['ramadan_start_time'] ?? '10:00:00',
      ramadanEndTime: json['ramadan_end_time'] ?? '15:00:00',
      ramadanMode: json['ramadan_mode'] == "1" ||
          json['ramadan_mode'] == 1 ||
          json['ramadan_mode'] == true,
      defaultEndTime: json['default_end_time'] ?? '16:00:00',
      lastRenewalYear: json['last_renewal_year'] != null
          ? int.tryParse(json['last_renewal_year'].toString()) ?? 2026
          : 2026,
      minVersion: json['min_version'] != null
          ? int.tryParse(json['min_version'].toString()) ?? 1
          : 1,
      forceUpdateUrl: json['force_update_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default_start_time': defaultStartTime,
      'allowed_late_minutes': allowedLateMinutes,
      'ramadan_start_time': ramadanStartTime,
      'ramadan_end_time': ramadanEndTime,
      'ramadan_mode': ramadanMode ? 1 : 0,
      'default_end_time': defaultEndTime,
      'last_renewal_year': lastRenewalYear,
      'min_version': minVersion,
      'force_update_url': forceUpdateUrl,
    };
  }
}

class HolidayModel {
  int? id;
  String name;
  String date;
  String? endDate;
  bool isRecurring;

  HolidayModel({
    this.id,
    required this.name,
    required this.date,
    this.endDate,
    this.isRecurring = false,
  });

  factory HolidayModel.fromJson(Map<String, dynamic> json) {
    return HolidayModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      endDate: json['end_date'],
      isRecurring: json['is_recurring'] == 1 || json['is_recurring'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'end_date': endDate ?? date,
      'is_recurring': isRecurring ? 1 : 0,
    };
  }
}

class DepartmentModel {
  final int? id;
  final String name;

  DepartmentModel({this.id, required this.name});

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class OvertimeRequestModel {
  int? id;
  int employeeId;
  String? employeeName;
  String date;
  String startTime;
  String endTime;
  int totalMinutes;
  String status;
  String? reason;
  String? adminNote;
  String? createdAt;

  OvertimeRequestModel({
    this.id,
    required this.employeeId,
    this.employeeName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.totalMinutes = 0,
    this.status = 'pending',
    this.reason,
    this.adminNote,
    this.createdAt,
  });

  factory OvertimeRequestModel.fromJson(Map<String, dynamic> json) {
    return OvertimeRequestModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      employeeId: json['employee_id'] != null
          ? int.tryParse(json['employee_id'].toString()) ?? 0
          : 0,
      employeeName: json['employee_name'],
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      totalMinutes: json['total_minutes'] != null
          ? int.tryParse(json['total_minutes'].toString()) ?? 0
          : 0,
      status: json['status'] ?? 'pending',
      reason: json['reason'],
      adminNote: json['admin_note'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'reason': reason,
      'status': status,
      'admin_note': adminNote,
    };
  }
}

class EmployeeClosingModel {
  int? id;
  int month;
  int year;
  String startDate;
  String endDate;
  double salarySnapshot;
  int workDaysPerWeekSnapshot;
  Map<String, dynamic> totals;
  String? createdAt;

  EmployeeClosingModel({
    this.id,
    required this.month,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.salarySnapshot,
    required this.workDaysPerWeekSnapshot,
    required this.totals,
    this.createdAt,
  });

  factory EmployeeClosingModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedTotals = {};
    if (json['totals_json'] != null) {
      if (json['totals_json'] is String) {
        try {
          parsedTotals = jsonDecode(json['totals_json']);
        } catch (_) {}
      } else if (json['totals_json'] is Map) {
        parsedTotals = Map<String, dynamic>.from(json['totals_json']);
      }
    }

    return EmployeeClosingModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      month: int.tryParse(json['month'].toString()) ?? 1,
      year: int.tryParse(json['year'].toString()) ?? 2026,
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      salarySnapshot: double.tryParse(json['salary_snapshot']?.toString() ?? '0') ?? 0.0,
      workDaysPerWeekSnapshot: int.tryParse(json['work_days_per_week_snapshot']?.toString() ?? '6') ?? 6,
      totals: parsedTotals,
      createdAt: json['created_at']?.toString(),
    );
  }
}
