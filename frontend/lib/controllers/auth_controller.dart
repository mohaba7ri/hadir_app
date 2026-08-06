import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_routes.dart';
import '../services/api_service.dart';
import '../core/utils/ui_utils.dart';
import '../models/app_models.dart';
import 'notification_controller.dart';
import 'package:local_auth/local_auth.dart';

class AuthController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final LocalAuthentication _localAuth = LocalAuthentication();

  var isAdmin = false.obs;
  var isSuperAdmin = false.obs;
  var currentEmployeeId = 0.obs;
  var currentEmployeeName = ''.obs;
  var userIdentifier = ''.obs;
  var isLoggedIn = false.obs;
  var isLoading = false.obs;

  var canCheckBiometrics = false.obs;
  var isBiometricEnabled = false.obs;
  var rememberMe = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    if (GetPlatform.isWeb || !GetPlatform.isAndroid) return;

    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      canCheckBiometrics.value = canAuthenticate;

      final prefs = await SharedPreferences.getInstance();
      isBiometricEnabled.value = prefs.getBool('biometricEnabled') ?? false;
    } catch (e) {
      canCheckBiometrics.value = false;
    }
  }

  void checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn.value) {
      isAdmin.value = prefs.getBool('isAdmin') ?? false;
      isSuperAdmin.value = prefs.getBool('isSuperAdmin') ?? false;
      currentEmployeeId.value = prefs.getInt('employeeId') ?? 0;
      currentEmployeeName.value = prefs.getString('employeeName') ?? '';
      userIdentifier.value = prefs.getString('userIdentifier') ?? '';

      if (isAdmin.value && currentEmployeeName.value.isEmpty) {
        currentEmployeeName.value = 'المدير';
      }

      // Re-subscribe on restart
      final notificationController = Get.find<NotificationController>();
      if (isAdmin.value) {
        notificationController.subscribeToAdmin();
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else {
        notificationController.subscribeToEmployee(currentEmployeeId.value);
        Get.offAllNamed(AppRoutes.employeeDashboard);
      }
    }
  }

  Future<void> login(String identifier, String password) async {
    isLoading.value = true;
    final res = await _api.postData('auth', {
      'identifier': identifier,
      'password': password,
    });
    isLoading.value = false;

    if (res != null && res['status'] == 'success') {
      final prefs = await SharedPreferences.getInstance();

      // ONLY SAVE PERSISTENT LOGIN IF REMEMBER ME IS TRUE
      if (rememberMe.value) {
        await prefs.setBool('isLoggedIn', true);
      }

      final bool is_admin = res['isAdmin'] ?? false;
      final bool is_super = res['isSuperAdmin'] ?? false;
      await prefs.setBool('isAdmin', is_admin);
      await prefs.setBool('isSuperAdmin', is_super);
      isAdmin.value = is_admin;
      isSuperAdmin.value = is_super;
      isLoggedIn.value = true;

      if (!is_admin) {
        await prefs.setInt('employeeId', res['employee']['id']);
        await prefs.setString('employeeName', res['employee']['name']);
        currentEmployeeId.value = res['employee']['id'];
        currentEmployeeName.value = res['employee']['name'];
      } else {
        String adminName =
            res['name'] ?? (is_super ? 'المدير العام (Super Admin)' : 'المدير');
        currentEmployeeName.value = adminName;
        await prefs.setString('employeeName', adminName);
      }

      final String finalIdentifier = res['identifier'] ?? identifier;
      await prefs.setString('userIdentifier', finalIdentifier);
      userIdentifier.value = finalIdentifier;

      // Save credentials for biometric login if on Android (not Web)
      if (!GetPlatform.isWeb && GetPlatform.isAndroid) {
        await prefs.setString('savedIdentifier', identifier);
        await prefs.setString('savedPassword', password);

        // Only set to true if never set before, otherwise respect user's choice from Profile
        if (prefs.getBool('biometricEnabled') == null) {
          await prefs.setBool('biometricEnabled', true);
          isBiometricEnabled.value = true;
        }
      }

      final notificationController = Get.find<NotificationController>();
      if (is_admin) {
        notificationController.subscribeToAdmin();
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else {
        notificationController.subscribeToEmployee(currentEmployeeId.value);
        Get.offAllNamed(AppRoutes.employeeDashboard);
      }
    } else {
      String errorMessage = 'معلومات الدخول غير صحيحة';
      if (res != null && res['message'] != null) {
        errorMessage = res['message'];
      }
      UiUtils.showErrorDialog('فشل الدخول', errorMessage);
    }
  }

  Future<void> loginWithBiometrics() async {
    if (GetPlatform.isWeb || !GetPlatform.isAndroid) return;

    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'يرجى تأكيد الهوية لتسجيل الدخول',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        final id = prefs.getString('savedIdentifier');
        final pass = prefs.getString('savedPassword');

        if (id != null && pass != null) {
          await login(id, pass);
        } else {
          UiUtils.showErrorDialog('خطأ',
              'لم يتم العثور على بيانات محفوظة. يرجى تسجيل الدخول يدوياً أول مرة.');
        }
      }
    } catch (e) {
      UiUtils.showErrorDialog('فشل التحقق', 'حدث خطأ أثناء التحقق من البصمة');
    }
  }

  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final String identifier = prefs.getString('savedIdentifier') ??
        (isAdmin.value ? 'admin' : currentEmployeeId.value.toString());

    if (identifier.isEmpty) return false;

    isLoading.value = true;
    final res = await _api.putData('auth', {
      'identifier': identifier,
      'old_password': oldPassword,
      'new_password': newPassword,
    });
    isLoading.value = false;

    if (res != null && res['status'] == 'success') {
      await prefs.setString('savedPassword', newPassword);
      return true;
    }
    return false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometricEnabled', enabled);
    isBiometricEnabled.value = enabled;
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    isLoggedIn.value = false;
    isAdmin.value = false;
    isSuperAdmin.value = false;
    currentEmployeeId.value = 0;
    currentEmployeeName.value = '';

    Get.offAllNamed(AppRoutes.login);
  }
}
