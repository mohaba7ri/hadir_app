
import "dart:io";

void main() {
  final dir = Directory("lib/views");
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith(".dart"));
  
  final regex = RegExp(r"\$\{([^}]+)\.toStringAsFixed\(2\)\}\s*?\.?");
  
  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains("toStringAsFixed(2)")) {
      // Replace ${someExpression.toStringAsFixed(2)} ?.? with ${UiUtils.formatAmount(someExpression)} ?.?
      content = content.replaceAllMapped(regex, (match) {
        String expr = match.group(1)!;
        return "\${UiUtils.formatAmount(\$expr)} ?.?";
      });
      file.writeAsStringSync(content);
    }
  }
  
  // also handle cases without {} if any, but most are inside ${}
  // also handle cases with + ${...} -> + ${UiUtils...}
}

