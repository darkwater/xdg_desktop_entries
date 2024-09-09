import 'package:xdg_desktop_entries/xdg_desktop_entries.dart';

void main() async {
  final entries =
      await DesktopEntry.fromDirectories(DesktopEntry.standardDirectories);

  for (final entry in entries) {
    if (entry.actions.isNotEmpty) {
      print("${entry.name} (+${entry.actions.length} actions)");
    } else {
      print(entry.name);
    }
  }
}
