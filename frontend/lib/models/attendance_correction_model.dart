class AttendanceCorrectionModel {
  final int id;
  final int employeeId;
  final String date;
  final String type;
  final String? originalTime;
  final String requestedTime;
  final String reason;
  final String status;
  final String? adminNote;
  final String? employeeName;

  AttendanceCorrectionModel({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.type,
    this.originalTime,
    required this.requestedTime,
    required this.reason,
    required this.status,
    this.adminNote,
    this.employeeName,
  });

  factory AttendanceCorrectionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceCorrectionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      employeeId: json['employee_id'] is int ? json['employee_id'] : int.tryParse(json['employee_id'].toString()) ?? 0,
      date: json['date'] ?? '',
      type: json['type'] ?? '',
      originalTime: json['original_time'],
      requestedTime: json['requested_time'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      adminNote: json['admin_note'],
      employeeName: json['employee_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date,
      'type': type,
      'original_time': originalTime,
      'requested_time': requestedTime,
      'reason': reason,
      'status': status,
      'admin_note': adminNote,
    };
  }
}
