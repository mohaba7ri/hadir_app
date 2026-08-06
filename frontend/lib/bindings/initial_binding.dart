import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../controllers/employee_controller.dart';
import '../services/api_service.dart';
import '../controllers/notification_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ApiService());
    Get.put(AuthController());
    Get.put(NotificationController());
    Get.lazyPut(() => AdminController(), fenix: true);
    Get.lazyPut(() => EmployeeController(), fenix: true);
  }
}
