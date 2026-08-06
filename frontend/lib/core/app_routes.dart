import 'package:get/get.dart';
import '../views/login_view.dart';
import '../views/admin/admin_dashboard.dart';
import '../views/employee/employee_dashboard.dart';
import '../views/admin/employee_details_view.dart';
import '../views/profile_view.dart';

import 'auth_middleware.dart';

class AppRoutes {
  static const login = '/login';
  static const adminDashboard = '/admin/dashboard';
  static const employeeDashboard = '/employee/dashboard';
  static const profile = '/profile';

  static final pages = [
    GetPage(
      name: login,
      page: () => const LoginView(),
    ),
    GetPage(
      name: adminDashboard,
      page: () => AdminDashboard(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: employeeDashboard,
      page: () => EmployeeDashboard(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: profile,
      page: () => const ProfileView(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/admin/employee-details',
      page: () => const EmployeeDetailsView(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
