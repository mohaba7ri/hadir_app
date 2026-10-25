import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class AppConstants {
  static const String annualLeave = 'إجازة سنوية';
  static const String businessMission = 'مهمة عمل';
  static const String exemption = 'إعفاء';
  static const String sickLeave = 'إجازة مرضية';
  static const String officialHoliday = 'إجازة رسمية';
  static const String marriage = 'زواج';
  static const String bereavement = 'وفاة';
  static const String otherVacation = 'أخرى';

  static String resolveVacationType(String selectedType, String customType) =>
      selectedType == otherVacation ? customType.trim() : selectedType;

  static List<String> getVacationTypes() {
    final authController = Get.find<AuthController>();

    final allTypes = [
      annualLeave,
      businessMission,
      sickLeave,
      marriage,
      bereavement,
      exemption,
      officialHoliday,
      otherVacation,
    ];

    // Exemption requests are available to admin roles only.
    if (!authController.isAdmin.value && !authController.isSuperAdmin.value) {
      allTypes.remove(exemption);
    }

    return allTypes;
  }
}
