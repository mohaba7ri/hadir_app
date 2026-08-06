import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../models/app_models.dart';
import '../../core/utils/ui_utils.dart';

class DepartmentManagementView extends StatelessWidget {
  final AdminController controller = Get.find<AdminController>();
  final TextEditingController nameController = TextEditingController();

  DepartmentManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('إدارة الإدارات', style: TextStyle(fontFamily: 'Janat')),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDepartmentDialog(context),
        label: const Text('إضافة إدارة', style: TextStyle(fontFamily: 'Janat')),
        icon: Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.departments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.departments.isEmpty) {
          return const Center(
            child: Text('لا توجد إدارات مسجلة',
                style: TextStyle(fontFamily: 'Janat')),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.departments.length,
          itemBuilder: (context, index) {
            final dept = controller.departments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(dept.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontFamily: 'Janat')),
                subtitle: Text('رقم الإدارة: ${dept.id}',
                    style: TextStyle(fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showDepartmentDialog(context, dept),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, dept),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showDepartmentDialog(BuildContext context, [DepartmentModel? dept]) {
    nameController.text = dept?.name ?? '';
    Get.dialog(
      AlertDialog(
        title: Text(dept == null ? 'إضافة إدارة جديدة' : 'تعديل الإدارة',
            style: TextStyle(fontFamily: 'Janat')),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'اسم الإدارة',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              bool success;
              if (dept == null) {
                success =
                    await controller.addDepartment(nameController.text.trim());
              } else {
                success = await controller.updateDepartment(
                    dept.id!, nameController.text.trim());
              }
              if (success) {
                Get.back();
                UiUtils.showSuccessDialog('نجاح', 'تم حفظ البيانات بنجاح');
              } else {
                UiUtils.showErrorDialog('خطأ', 'فشل في حفظ البيانات');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DepartmentModel dept) {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Janat')),
        content: Text(
            'هل أنت متأكد من حذف إدارة "${dept.name}"؟\nسيتم فصل الموظفين المرتبطين بها.',
            style: TextStyle(fontFamily: 'Janat')),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              final success = await controller.deleteDepartment(dept.id!);
              Get.back();
              if (success) {
                UiUtils.showSuccessDialog('نجاح', 'تم الحذف بنجاح');
              } else {
                UiUtils.showErrorDialog('خطأ', 'فشل في عملية الحذف');
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
