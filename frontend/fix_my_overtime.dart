
import "dart:io";

void main() {
  final file = File("lib/views/employee/my_overtime_view.dart");
  if (!file.existsSync()) return;
  String content = file.readAsStringSync();
  
  final exprs = [
    "((req.totalMinutes * (controller.employeeData.value?.salary ?? 0.0)) / (controller.daysInMonth * controller.getWorkDayDurationInMinutes()))"
  ];
  
  int i = 0;
  content = content.replaceAllMapped(RegExp(r"\$\{UiUtils\.formatAmount\(\$expr\)\}\s*\?\.\?\s*?\.?"), (match) {
    if (i < exprs.length) {
      String expr = exprs[i++];
      return "\${UiUtils.formatAmount(\$expr)} ?.?";
    }
    return match.group(0)!;
  });
  
  file.writeAsStringSync(content);
}

