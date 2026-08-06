
import "dart:io";

void main() {
  final dir = Directory("lib");
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith(".dart"));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains(r"\$expr")) {
      content = content.replaceAll(r"\$expr", "amount"); // wait, no! I lost the original expression!
    }
  }
}

