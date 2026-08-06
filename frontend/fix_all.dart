
import "dart:io";

void main() {
  String c1 = File("lib/views/admin/attendance_view.dart").readAsStringSync();
  c1 = c1.replaceFirst(r"(${UiUtils.formatAmount($expr)} ?.? ?.?)", r"(${UiUtils.formatAmount(controller.getEarlyExitMinutes(att, emp) * controller.calculateMinuteDiscount(att.salary > 0 ? att.salary : emp.salary, emp))} ?.?)"); // 373
  c1 = c1.replaceFirst(r"(${UiUtils.formatAmount($expr)} ?.? ?.?)", r"(${UiUtils.formatAmount(effectiveLate * controller.calculateMinuteDiscount(att.salary > 0 ? att.salary : emp.salary, emp))} ?.?)"); // 378
  c1 = c1.replaceFirst(r"(${UiUtils.formatAmount($expr)} ?.? ?.?)", r"(${UiUtils.formatAmount((att.salary > 0 ? att.salary : emp.salary) / controller.daysInMonth)} ?.?)"); // 385
  c1 = c1.replaceFirst(r"- ${UiUtils.formatAmount($expr)} ?.? ?.?", r"- ${UiUtils.formatAmount((emp.salary) / controller.daysInMonth)} ?.?"); // 561
  c1 = c1.replaceFirst(r"- ${UiUtils.formatAmount($expr)} ?.? ?.?", r"- ${UiUtils.formatAmount(controller.getEarlyExitDiscount(att, emp))} ?.?"); // 594
  c1 = c1.replaceFirst(r"- ${UiUtils.formatAmount($expr)} ?.? ?.?", r"- ${UiUtils.formatAmount(controller.getLateDiscount(att, emp))} ?.?"); // 617
  c1 = c1.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(totalDisc)} ?.?"); // 1624
  c1 = c1.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(lateDisc)} ?.?"); // 1625
  c1 = c1.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(earlyDisc)} ?.?"); // 1626
  c1 = c1.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(absenceDisc)} ?.?"); // 1627
  c1 = c1.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(amount)} ?.?"); // 1669
  File("lib/views/admin/attendance_view.dart").writeAsStringSync(c1);

  String c2 = File("lib/views/admin/employee_details_view.dart").readAsStringSync();
  c2 = c2.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(absenceDiscountTotal)} ?.?"); // 379
  c2 = c2.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(lateDiscountTotal)} ?.?"); // 384
  c2 = c2.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(earlyExitDiscountTotal)} ?.?"); // 389
  c2 = c2.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(totalDiscount)} ?.?"); // 394
  c2 = c2.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(totalDiscount)} ?.?"); // 413
  c2 = c2.replaceFirst(r"(${UiUtils.formatAmount($expr)} ?.? ?.?)", r"(${UiUtils.formatAmount(controller.getEarlyExitMinutes(att, employee) * controller.calculateMinuteDiscount(att.salary > 0 ? att.salary : employee.salary, employee))} ?.?)"); // 630
  c2 = c2.replaceFirst(r"(${UiUtils.formatAmount($expr)} ?.? ?.?)", r"(${UiUtils.formatAmount(effectiveLate * controller.calculateMinuteDiscount(att.salary > 0 ? att.salary : employee.salary, employee))} ?.?)"); // 639
  c2 = c2.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount((att.salary > 0 ? att.salary : employee.salary) / controller.daysInMonth)} ?.?"); // 650
  c2 = c2.replaceFirst(r"- ${UiUtils.formatAmount($expr)} ?.? ?.?", r"- ${UiUtils.formatAmount(employee.salary / controller.daysInMonth)} ?.?"); // 907
  c2 = c2.replaceFirst(r"- ${UiUtils.formatAmount($expr)} ?.? ?.?", r"- ${UiUtils.formatAmount(controller.getEarlyExitDiscount(att, employee))} ?.?"); // 939
  c2 = c2.replaceFirst(r"- ${UiUtils.formatAmount($expr)} ?.? ?.?", r"- ${UiUtils.formatAmount(controller.getLateDiscount(att, employee))} ?.?"); // 964
  c2 = c2.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(totalDisc)} ?.?"); // 1966
  c2 = c2.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(lateDisc)} ?.?"); // 1974
  c2 = c2.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(earlyDisc)} ?.?"); // 1980
  c2 = c2.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(absenceDisc)} ?.?"); // 1986
  c2 = c2.replaceFirst(r"${UiUtils.formatAmount($expr)} ?.? ?.?", r"${UiUtils.formatAmount(amount)} ?.?"); // 2056
  File("lib/views/admin/employee_details_view.dart").writeAsStringSync(c2);
}

