import 'package:flutter_test/flutter_test.dart';
import 'package:xdg_desktop_entries/src/exec_line.dart';
import 'package:xdg_desktop_entries/xdg_desktop_entries.dart';

void main() {
  final entry = DesktopEntry.fromContent("""
# comment

[Desktop Entry]
#[Desktop Entry]
Name=Hoshi Launcher
#Exec=commented out
Exec=hoshi-launcher
#Exec=also commented out
Icon=org.hoshi.launcher
Comment=An example launcher
Terminal=false
Type=Application
Categories=Utility;
""");

  test("parses desktop entries", () {
    expect(entry, isNotNull);
    expect(entry?.name, "Hoshi Launcher");
    expect(entry?.exec, "hoshi-launcher");
    expect(entry?.icon, "org.hoshi.launcher");
    expect(entry?.parseExec().expand(null), ["hoshi-launcher"]);
  });

  test("parses exec line", () {
    expect(ExecLine.parse("foo").args, [LiteralArgument("foo")]);
    expect(ExecLine.parse("foo bar").args,
        [LiteralArgument("foo"), LiteralArgument("bar")]);
    expect(ExecLine.parse("foo %f").args,
        [LiteralArgument("foo"), ParameterArgument(FieldType.file)]);

    expect(ExecLine.parse("foo %%").args,
        [LiteralArgument("foo"), LiteralArgument("%")]);

    expect(() => ExecLine.parse("foo %f %f"), throwsException);
    expect(() => ExecLine.parse("foo %f %U"), throwsException);

    expect(ExecLine.parse("foo %f %i").args, [
      LiteralArgument("foo"),
      ParameterArgument(FieldType.file),
      SpecialArgument(FieldType.icon),
    ]);

    expect(ExecLine.parse("foo %i %f bar").args, [
      LiteralArgument("foo"),
      SpecialArgument(FieldType.icon),
      ParameterArgument(FieldType.file),
      LiteralArgument("bar"),
    ]);

    expect(ExecLine.parse('foo "hello world"').args, [
      LiteralArgument("foo"),
      LiteralArgument("hello world"),
    ]);

    expect(ExecLine.parse('foo "hello %f"').args, [
      LiteralArgument("foo"),
      LiteralArgument("hello %f"),
    ]);

    expect(ExecLine.parse('foo "hello \\"world\\""').args, [
      LiteralArgument("foo"),
      LiteralArgument("hello \"world\""),
    ]);
  });

  test("expands exec line", () {
    expect(ExecLine.parse("foo").expand(null), ["foo"]);
    expect(ExecLine.parse("foo bar").expand(null), ["foo", "bar"]);
    expect(ExecLine.parse("foo %f").expand(null), ["foo"]);
    expect(ExecLine.parse("foo %%").expand(null), ["foo", "%"]);
    expect(ExecLine.parse("foo %f %i").expand(null), ["foo"]);
    expect(ExecLine.parse("foo %i %f bar").expand(null), ["foo", "bar"]);

    expect(ExecLine.parse("foo %i %f bar").expand(entry),
        ["foo", "--icon", "org.hoshi.launcher", "bar"]);

    expect(ExecLine.parse('foo "hello world"').expand(null),
        ["foo", "hello world"]);

    expect(ExecLine.parse('foo "hello %f"').expand(null), ["foo", "hello %f"]);

    expect(ExecLine.parse('foo "hello \\"world\\""').expand(null),
        ["foo", "hello \"world\""]);
  });
}
