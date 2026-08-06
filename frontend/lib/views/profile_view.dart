import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/utils/responsive.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthController auth = Get.find<AuthController>();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    if (_newPassController.text != _confirmPassController.text) {
      UiUtils.showErrorDialog('خطأ', 'كلمتا المرور الجديدتان غير متطابقتين');
      return;
    }
    if (_newPassController.text.length < 3) {
      UiUtils.showErrorDialog('خطأ', 'كلمة المرور قصيرة جداً');
      return;
    }

    final success = await auth.updatePassword(
        _oldPassController.text, _newPassController.text);
    if (success) {
      _oldPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
      UiUtils.showSuccessDialog('تم بنجاح', 'تم تحديث كلمة المرور بنجاح');
    } else {
      UiUtils.showErrorDialog('فشل العملية', 'تأكد من صحة كلمة المرور القديمة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(UiUtils.getPadding(context)),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: [
                // Security Card
                _buildSettingsCard(
                  title: 'تغيير كلمة المرور',
                  icon: Icons.security_rounded,
                  child: Column(
                    children: [
                      _buildTextField(
                          'كلمة المرور الحالية', _oldPassController, true),
                      SizedBox(height: 16),
                      _buildTextField(
                          'كلمة المرور الجديدة', _newPassController, true),
                      SizedBox(height: 16),
                      _buildTextField('تأكيد كلمة المرور الجديدة',
                          _confirmPassController, true),
                      SizedBox(height: 32),
                      Obx(() => SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: auth.isLoading.value
                                  ? null
                                  : _handleChangePassword,
                              child: auth.isLoading.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('تحديث كلمة المرور'),
                            ),
                          )),
                    ],
                  ),
                ),

                // Biometrics Card
                if (auth.canCheckBiometrics.value)
                  _buildSettingsCard(
                    title: 'إعدادات البصمة',
                    icon: Icons.fingerprint_rounded,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('دخول سريع بالبصمة',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      'استخدم بصمة الإصبع لتسجيل الدخول بدلاً من كلمة المرور',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                            Obx(() => Switch.adaptive(
                                  value: auth.isBiometricEnabled.value,
                                  onChanged: (v) => auth.setBiometricEnabled(v),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 32),

          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryTeal, size: 20),
              SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
