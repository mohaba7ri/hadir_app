
import "dart:io";

void main() {
  final file = File("lib/views/admin/attendance_view.dart");
  if (!file.existsSync()) return;
  String content = file.readAsStringSync();
  
  final exprs = [
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

