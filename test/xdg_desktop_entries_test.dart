import 'package:flutter_test/flutter_test.dart';

import 'package:xdg_desktop_entries/xdg_desktop_entries.dart';

void main() {
  test('adds one to input values', () {
    final entry = DesktopEntry.fromContent('''
[Desktop Entry]
Name=Hoshi Launcher
Exec=hoshi-launcher
Icon=org.hoshi.launcher
Comment=An example launcher
Terminal=false
Type=Application
Categories=Utility;
''');

    expect(entry, isNotNull);
    expect(entry?.name, 'Hoshi Launcher');
    expect(entry?.exec, 'hoshi-launcher');
    expect(entry?.icon, 'org.hoshi.launcher');
  });
}
