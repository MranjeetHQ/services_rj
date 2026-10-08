import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every extension in lib/src/core must be documented in
/// docs/extensions.md. The form controller extension is documented in
/// docs/forms.md instead.
List<String> _sources() =>
    Directory('lib/src/core')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.path)
        .toList()
      ..sort();

final _extension = RegExp(r'^extension (\w+) on ');
final _getter = RegExp(r'^  [^\s/].* get ([a-z]\w*)\b');
final _method = RegExp(r'^  [\w<>?][\w<>?, ]* ([a-z]\w*)\(');

void main() {
  test('every public extension member is in docs/extensions.md', () {
    final docs = File('docs/extensions.md').readAsStringSync();
    final missing = <String>[];
    var members = 0;

    for (final path in _sources()) {
      String? current;
      for (final line in File(path).readAsLinesSync()) {
        final ext = _extension.firstMatch(line);
        if (ext != null) {
          current = ext[1];
          if (!docs.contains('`$current`')) missing.add(current!);
          continue;
        }
        if (line == '}') current = null;
        if (current == null) continue;

        final name = (_getter.firstMatch(line) ?? _method.firstMatch(line))
            ?.group(1);
        if (name == null) continue;
        members++;
        if (!docs.contains('`$name`') && !docs.contains('`$name(')) {
          missing.add('$current.$name');
        }
      }
    }

    // Guards against the patterns silently matching nothing.
    expect(members, greaterThan(40));
    expect(missing, isEmpty, reason: 'Document these in docs/extensions.md');
  });
}
