
import "dart:io";

void main() {
  final file = File("lib/views/employee/my_attendance_view.dart");
  String content = file.readAsStringSync();
  
  final exprs = [
    "controller.totalDiscount",
    "controller.totalAbsentDiscount",
    "controller.totalLateDiscount",
    "controller.totalEarlyExitDiscount",
    "controller.totalOvertimeGained",
    "controller.totalDiscount",
    "controller.totalAbsentDiscount",
    "controller.totalLateDiscount",
    "controller.totalEarlyExitDiscount",
    "controller.totalOvertimeGained",
    "controller.getEffectiveEarlyExitDiscount(att)",
    "controller.getEffectiveLateDiscount(att)",
    "controller.getEffectiveDiscount(att)",
    "controller.getEffectiveLateDiscount(att)",
    "controller.getEffectiveEarlyExitDiscount(att)",
    "controller.getEffectiveDiscount(att)",
    "controller.getEffectiveDiscount(att)",
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

