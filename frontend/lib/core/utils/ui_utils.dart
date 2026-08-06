import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/responsive.dart';

class UiUtils {
  static double getPadding(BuildContext context) {
    return Responsive.isMobile(context) ? 16.0 : 40.0;
  }

  static bool isSmallScreen(BuildContext context) {
    return Responsive.isMobile(context);
  }

  static String formatDaysApproximate(double days) {
    if (days == 0) return '0 يوم';
    
    // Format to 1 decimal place and remove trailing .0
    String formatted = days.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    
    // Simple pluralization for Arabic
    if (formatted == '1') return 'يوم واحد';
    if (formatted == '2') return 'يومان';
    
    // For numbers 3-10, we usually say "أيام". For others "يوم".
    // But since it's an approximate decimal (e.g. 3.5), it's safe to just say "يوم" for decimals
    // For simplicity, we can append 'أيام' if it's an integer between 3 and 10, otherwise 'يوم'.
    int? parsedInt = int.tryParse(formatted);
    if (parsedInt != null && parsedInt >= 3 && parsedInt <= 10) {
      return '$formatted أيام';
    }
    
    return 'حوالي $formatted يوم';
  }

  static String formatDuration(int totalMinutes) {
    if (totalMinutes == 0) return '0 دقيقة';

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours ساعة و $minutes دقيقة';
    } else if (hours > 0) {
      return '$hours ساعة';
    } else {
      return '$minutes دقيقة';
    }
  }

  static void showSuccessDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  static void showErrorDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  static void showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    Color confirmColor = Colors.blue,
  }) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(cancelText),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  minimumSize: const Size(80, 40),
                ),
                child: Text(confirmText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
