import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/ui_utils.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Consolidated Login Card
              Container(
                width: 500,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 50,
                      offset: const Offset(0, 15),
                    ),
                  ],
                  border: Border.all(color: AppTheme.borderLight, width: 0.8),
                ),
                child: Column(
                  children: [
                    // Brand Identity inside the card
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Image.asset(
                        'assets/ic_launcher.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 20),
                    const Text(
                      'حاضر',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 40),

                    // Unified Header for inputs
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 12),
                        const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),

                    // Unified ID field
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        labelText: 'اسم المستخدم أو الرقم',
                        prefixIcon:
                            Icon(Icons.person_outline_rounded, size: 22),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FB),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Color(0xFFE9E9EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: AppTheme.primaryTeal, width: 1.5),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Password field
                    TextField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: Icon(Icons.lock_outline_rounded, size: 22),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _isObscure = !_isObscure),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FB),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Color(0xFFE9E9EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: AppTheme.primaryTeal, width: 1.5),
                        ),
                      ),
                    ),
                    Obx(() => CheckboxListTile(
                          value: authController.rememberMe.value,
                          onChanged: (val) =>
                              authController.rememberMe.value = val ?? true,
                          title: const Text('تذكرني في المرة القادمة',
                              style: TextStyle(fontSize: 14)),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.primaryTeal,
                          dense: true,
                        )),
                    SizedBox(height: 24),

                    // Actions Row (Login + Fingerprint)
                    Obx(() => Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: authController.isLoading.value
                                      ? null
                                      : () {
                                          if (_idController.text.isEmpty ||
                                              _passwordController
                                                  .text.isEmpty) {
                                            UiUtils.showErrorDialog('تنبيه',
                                                'يرجى إدخال اسم المستخدم وكلمة المرور');
                                          } else {
                                            authController.login(
                                                _idController.text,
                                                _passwordController.text);
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryTeal,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                  ),
                                  child: authController.isLoading.value
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3))
                                      : const Text(
                                          'دخول',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ),
                            if (authController.canCheckBiometrics.value &&
                                authController.isBiometricEnabled.value) ...[
                              SizedBox(width: 12),
                              Container(
                                height: 56,
                                width: 64,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.fingerprint_rounded,
                                      size: 32, color: AppTheme.primaryTeal),
                                  onPressed: () =>
                                      authController.loginWithBiometrics(),
                                  tooltip: 'البصمة',
                                ),
                              ),
                            ],
                          ],
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
