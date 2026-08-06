
import "dart:io";

void main() {
  final file = File("lib/views/admin/employee_details_view.dart");
  if (!file.existsSync()) return;
  String content = file.readAsStringSync();
  
  final exprs = [
    "absenceDiscountTotal",
    "lateDiscountTotal",
    "earlyExitDiscountTotal",
    "totalDiscount",
    "totalDiscount",
    "(controller.getEarlyExitMinutes(att, employee) * controller.calculateMinuteDiscount(att.salary > 0 ? att.salary : employee.salary, employee))",
    "(effectiveLate * controller.calculateMinuteDiscount(att.salary > 0 ? att.salary : employee.salary, employee))",
    "((att.salary > 0 ? att.salary : employee.salary) / controller.daysInMonth)",
    "(employee.salary / controller.daysInMonth)",
    "controller.getEarlyExitDiscount(att, employee)",
    "controller.getLateDiscount(att, employee)",
    "totalDisc",
    "lateDisc",
    "earlyDisc",
    "absenceDisc",
    "amount"
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

