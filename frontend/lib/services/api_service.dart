import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class ApiService extends GetConnect {
  static const bool debugMode =
      false; // Set to true for local, false for production

  static const String baseApiUrl = debugMode
      ? 'http://localhost/attendace/backend' // Note: Use 10.0.2.2 for Android Emulator
      : 'https://hadir.gheta-alrahmah.com/backend';
  @override
  void onInit() {
    httpClient.baseUrl = baseApiUrl;
    httpClient.timeout = const Duration(seconds: 120);
    super.onInit();
  }

  Future<dynamic> getData(String endpoint) async {
    final response = await get('/$endpoint');
    if (response.status.hasError) {
      if (kDebugMode) {
        print('Error GET $endpoint: ${response.statusText}');
        print('Error Body: ${response.bodyString}');
      }
      return null;
    } else {
      try {
        if (response.body is String) {
          return jsonDecode(response.body);
        }
        return response.body;
      } catch (e) {
        if (kDebugMode) {
          print('JSON Decode Error on $endpoint');
          print('Raw Body: ${response.bodyString}');
        }
        return null;
      }
    }
  }

  Future<dynamic> postData(String endpoint, Map<String, dynamic> data) async {
    final response = await post('/$endpoint', data);
    if (response.status.hasError) {
      if (response.bodyString != null && response.bodyString!.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.bodyString!);
          if (decoded is Map) {
            decoded['status'] = 'error';
            return decoded;
          }
        } catch (_) {}
      }
      return {
        "status": "error",
        "message":
            "خطأ في الشبكة (${response.statusCode}): ${response.statusText}.\n${response.bodyString ?? ''}"
      };
    }
    try {
      if (response.body == null) return null;
      if (response.body is String) return jsonDecode(response.body);
      return response.body;
    } catch (e) {
      return {
        "status": "error",
        "message": "فشل فك التشفير.\nالرد: ${response.bodyString ?? 'فارغ'}"
      };
    }
  }

  Future<dynamic> putData(String endpoint, Map<String, dynamic> data) async {
    final response = await put('/$endpoint', data);
    if (response.status.hasError) {
      if (response.body != null && response.body is Map) {
        final decoded = Map<String, dynamic>.from(response.body);
        decoded['status'] = 'error';
        return decoded;
      }
      return {
        "status": "error",
        "message": response.statusText ?? 'خطأ في الاتصال بالخادم'
      };
    }
    try {
      if (response.body == null) return null;
      if (response.body is Map) return response.body;
      if (response.body is String) return jsonDecode(response.body);
      return response.body;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> deleteData(String endpoint) async {
    final response = await delete('/$endpoint');
    if (response.status.hasError) {
      if (kDebugMode) print('Error DELETE $endpoint: ${response.statusText}');
      return null;
    } else {
      return jsonDecode(response.bodyString ?? '{}');
    }
  }

  Future<dynamic> deleteVacation(int id) async {
    final response = await delete('/vacations/$id');
    if (response.status.hasError) {
      if (response.bodyString != null && response.bodyString!.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.bodyString!);
          if (decoded is Map && decoded.containsKey('message')) {
            return {"status": "error", "message": decoded['message']};
          }
        } catch (_) {}
      }
      return {"status": "error", "message": response.statusText};
    }
    return jsonDecode(response.bodyString ?? '{}');
  }

  Future<dynamic> uploadJson(String endpoint, String filePath) async {
    final formData = FormData({
      'file': MultipartFile(filePath, filename: 'attendance.json'),
    });
    final response = await post('/$endpoint', formData);
    if (response.status.hasError) {
      return null;
    } else {
      return jsonDecode(response.bodyString ?? '{}');
    }
  }

  Future<dynamic> syncDatabaseFromFile() async {
    final response = await post('/attendance/sync_file', {});
    if (response.status.hasError) {
      return {
        "message":
            "خطأ في الشبكة (${response.statusCode}): ${response.statusText}.\n${response.bodyString ?? ''}"
      };
    } else {
      try {
        return jsonDecode(response.bodyString ?? '{}');
      } catch (e) {
        return {
          "message": "فشل فك التشفير.\nالرد: ${response.bodyString ?? 'فارغ'}"
        };
      }
    }
  }

  Future<dynamic> requestVacationWithFile(
      Map<String, String> data, PlatformFile? attachmentFile) async {
    final formData = FormData(data);
    if (attachmentFile != null) {
      if (kIsWeb) {
        formData.files.add(MapEntry(
          'attachment',
          MultipartFile(attachmentFile.bytes!, filename: attachmentFile.name),
        ));
      } else {
        formData.files.add(MapEntry(
          'attachment',
          MultipartFile(attachmentFile.path, filename: attachmentFile.name),
        ));
      }
    }

    final response = await post('/vacations', formData);
    if (response.status.hasError) {
      if (response.bodyString != null && response.bodyString!.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.bodyString!);
          if (decoded is Map) {
            decoded['status'] = 'error';
            return decoded;
          }
        } catch (_) {}
      }
      return {"status": "error", "message": response.statusText};
    } else {
      return jsonDecode(response.bodyString ?? '{}');
    }
  }

  Future<dynamic> submitObjectionWithFile(
      Map<String, String> data, String? attachmentPath) async {
    final formData = FormData(data);
    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      formData.files.add(MapEntry(
        'attachment',
        MultipartFile(attachmentPath,
            filename: 'attachment.${attachmentPath.split('.').last}'),
      ));
    }

    final response = await post('/objections', formData);
    if (response.status.hasError) {
      try {
        return jsonDecode(response.bodyString ?? '{"message": "Error"}');
      } catch (e) {
        return {"message": response.statusText};
      }
    } else {
      return jsonDecode(response.bodyString ?? '{}');
    }
  }

  Future<dynamic> splitPayroll(String employeeId, int month, int year,
      String startDate, String endDate) async {
    final response = await post('/reports/split-payroll', {
      'employee_id': employeeId,
      'month': month,
      'year': year,
      'start_date': startDate,
      'end_date': endDate,
    });

    if (response.status.hasError) {
      if (response.body != null && response.body is Map) {
        final decoded = Map<String, dynamic>.from(response.body);
        decoded['status'] = 'error';
        return decoded;
      }
      if (response.bodyString != null && response.bodyString!.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.bodyString!);
          if (decoded is Map) {
            decoded['status'] = 'error';
            return decoded;
          }
        } catch (_) {}
      }
      return {
        "status": "error",
        "message": response.statusText ?? 'خطأ في الاتصال بالخادم'
      };
    } else {
      if (response.body != null && response.body is Map) {
        return response.body;
      }
      return jsonDecode(response.bodyString ?? '{}');
    }
  }
}
