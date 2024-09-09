import 'dart:developer';
import 'dart:io';

class DesktopEntry {
  // A map to store all key-value pairs from the .desktop file
  final Map<String, String> _entries = {};
  final Map<String, DesktopAction> actions = {};

  // Getters for common desktop entry fields
  String? get name => _entries['Name'];
  String? get exec => _entries['Exec'];
  String? get comment => _entries['Comment'];
  String? get icon => _entries['Icon'];
  bool get terminal => _entries['Terminal']?.toLowerCase() == 'true';
  String? get type => _entries['Type'];
  List<String>? get categories =>
      _entries['Categories']?.split(';').where((e) => e.isNotEmpty).toList();
  List<String>? get keywords =>
      _entries['Keywords']?.split(';').where((e) => e.isNotEmpty).toList();
  List<String>? get mimeTypes =>
      _entries['MimeType']?.split(';').where((e) => e.isNotEmpty).toList();
  List<String>? get actionNames =>
      _entries['Actions']?.split(';').where((e) => e.isNotEmpty).toList();

  /// Parses the content of a .desktop file and returns a DesktopEntry object
  static DesktopEntry? fromContent(String content) {
    final lines = content.split('\n');
    DesktopEntry? desktopEntry;
    DesktopAction? currentAction;
    bool unknownSection = false;

    for (var line in lines) {
      // Skip comments and empty lines
      if (line.startsWith('#') || line.trim().isEmpty) continue;

      // Detect the start of a new section
      if (line.startsWith('[')) {
        // End the current action section (if any)
        if (currentAction != null) {
          desktopEntry?.actions[currentAction.name!] = currentAction;
          currentAction = null;
        }

        // Start the Desktop Entry or an Action section
        if (line.startsWith('[Desktop Entry]')) {
          desktopEntry = DesktopEntry();
        } else if (line.startsWith('[Desktop Action ')) {
          final actionName = line.substring(16, line.length - 1).trim();
          currentAction = DesktopAction(name: actionName);
        } else {
          unknownSection = true;
        }

        continue;
      }

      // Skip unknown sections
      if (unknownSection) continue;

      // Parse key-value pairs within the current section
      final parts = line.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();

        if (currentAction != null) {
          if (currentAction.entries[key] != null) {
            log('Duplicate key in action section: $key');
          }

          // Handle Action-specific key-value pairs
          currentAction.entries[key] = value;
        } else if (desktopEntry != null) {
          if (desktopEntry._entries[key] != null) {
            log('Duplicate key in desktop entry: $key');
          }

          // Handle Desktop Entry-specific key-value pairs
          desktopEntry._entries[key] = value;
        }
      }
    }

    // Add the last action if still active
    if (currentAction != null) {
      desktopEntry?.actions[currentAction.name!] = currentAction;
    }

    // Ensure at least a Name and Exec are present to validate this as an entry
    if (desktopEntry?.name != null && desktopEntry?.exec != null) {
      return desktopEntry;
    }
    return null;
  }

  /// Reads a .desktop file asynchronously and returns a DesktopEntry object
  static Future<DesktopEntry?> fromFile(File file) async {
    if (!await file.exists()) return null;

    final content = await file.readAsString();
    return fromContent(content);
  }

  /// Finds all .desktop entries in a directory asynchronously
  /// If multiple directories are given, entries from later directories with the same filename will
  /// override entries from earlier directories
  static Future<List<DesktopEntry>> fromDirectories(
    List<Directory> dirs,
  ) async {
    final files = <String, File>{};

    for (final dir in dirs) {
      if (await dir.exists()) {
        final entries = await dir
            .list(recursive: false)
            .where((e) => e.path.endsWith('.desktop'))
            .toList();

        for (final entry in entries) {
          final name = entry.path.split('/').last;
          files[name] = File(entry.path);
        }
      }
    }

    final entries = <DesktopEntry>[];

    for (final file in files.values) {
      final entry = await fromFile(file);
      if (entry != null) {
        entries.add(entry);
      }
    }

    return entries;
  }

  static List<Directory> get standardDirectories => [
        Directory('/usr/share/applications'),
        Directory('/usr/local/share/applications'),
        if (Platform.environment['HOME'] != null)
          Directory(
              '${Platform.environment['HOME']}/.local/share/applications'),
      ];

  /// Access any custom key-value pair
  String? operator [](String key) => _entries[key];

  @override
  String toString() {
    return 'DesktopEntry(name: $name, exec: $exec, comment: $comment, icon: $icon, terminal: $terminal, type: $type, categories: $categories, actions: $actions)';
  }
}

/// Class representing a single desktop action
class DesktopAction {
  final String? name;
  final Map<String, String> entries = {};

  DesktopAction({this.name});

  String? get exec => entries['Exec'];
  String? get actionName => entries['Name'];
  String? get icon => entries['Icon'];

  @override
  String toString() {
    return 'DesktopAction(name: $name, exec: $exec, actionName: $actionName, icon: $icon)';
  }
}
