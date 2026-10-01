import 'app_permission.dart';
import 'permission_registry.dart';

/// Builds the native setup snippets and the documentation tables from
/// [PermissionRegistry], so they never drift from the code.
abstract final class PermissionSetup {
  /// `<uses-permission>` lines for AndroidManifest.xml. Duplicates are
  /// merged; an entry without `maxSdkVersion` wins over a limited one.
  static String androidManifest(Iterable<AppPermission> permissions) {
    final merged = <String, AndroidManifestEntry>{};
    for (final p in permissions) {
      for (final e in PermissionRegistry.of(p).androidManifest) {
        final existing = merged[e.name];
        if (existing == null) {
          merged[e.name] = e;
        } else if (existing.maxSdkVersion != null &&
            (e.maxSdkVersion == null ||
                e.maxSdkVersion! > existing.maxSdkVersion!)) {
          merged[e.name] = e;
        }
      }
    }
    return merged.values.map((e) => e.toXml()).join('\n');
  }

  /// Info.plist keys with placeholder reasons to replace.
  static String iosInfoPlist(Iterable<AppPermission> permissions) {
    final keys = <String>{
      for (final p in permissions) ...PermissionRegistry.of(p).iosPlistKeys,
    };
    return keys
        .map(
          (k) =>
              '<key>$k</key>\n<string>TODO: explain why the app needs this.</string>',
        )
        .join('\n');
  }

  /// Podfile `post_install` block for CocoaPods builds. Unlisted
  /// permissions stay compiled out.
  static String iosPodfile(Iterable<AppPermission> permissions) {
    final macros = <String>{
      for (final p in permissions) ...PermissionRegistry.of(p).iosPodMacros,
    };
    final lines = macros.map((m) => "        '$m=1',").join('\n');
    return '''
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '\$(inherited)',
$lines
      ]
    end
  end
end''';
  }

  /// Markdown reference table with one row per [AppPermission].
  static String markdownReference() {
    final b = StringBuffer()
      ..writeln(
        '| Tag | Android native | iOS native | AndroidManifest.xml | Info.plist | Podfile macro |',
      )
      ..writeln('|---|---|---|---|---|---|');

    String natives(List<Object> list) =>
        list.isEmpty ? '—' : list.map((p) => '`${_dartName(p)}`').join(', ');

    for (final spec in PermissionRegistry.specs.values) {
      final android = _androidRanges(spec)
          .map((r) {
            final label = r.from == _minSdk
                ? (r.to == _maxSdk ? '' : 'API ≤ ${r.to}: ')
                : (r.to == _maxSdk
                      ? 'API ${r.from}+: '
                      : 'API ${r.from}–${r.to}: ');
            return '$label${natives(r.natives)}';
          })
          .join('<br>');

      final manifest = spec.androidManifest.isEmpty
          ? '—'
          : spec.androidManifest
                .map(
                  (e) =>
                      '`${e.name.split('.').last}`${e.maxSdkVersion == null ? '' : ' (≤ API ${e.maxSdkVersion})'}',
                )
                .join('<br>');

      b.writeln(
        '| `${spec.permission.name}` | $android | ${natives(spec.ios)} | $manifest | '
        '${spec.iosPlistKeys.isEmpty ? '—' : spec.iosPlistKeys.map((k) => '`$k`').join('<br>')} | '
        '${spec.iosPodMacros.isEmpty ? '—' : spec.iosPodMacros.map((m) => '`$m`').join('<br>')} |',
      );
    }

    b
      ..writeln()
      ..writeln('**Notes per tag**')
      ..writeln();
    for (final spec in PermissionRegistry.specs.values) {
      for (final note in spec.notes) {
        b.writeln('- `${spec.permission.name}`: $note');
      }
    }
    return b.toString().trimRight();
  }

  /// Dart constant name of a native permission, e.g. `activityRecognition`
  /// (permission_handler's toString uses snake_case for some of them).
  static String _dartName(Object permission) {
    final raw = permission.toString().split('.').last;
    final parts = raw.split('_');
    return parts.first +
        parts
            .skip(1)
            .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
            .join();
  }

  static const int _minSdk = 21;
  static const int _maxSdk = 36;

  /// Groups consecutive API levels that resolve to the same natives.
  static List<({int from, int to, List<Object> natives})> _androidRanges(
    PermissionSpec spec,
  ) {
    final ranges = <({int from, int to, List<Object> natives})>[];
    for (var sdk = _minSdk; sdk <= _maxSdk; sdk++) {
      final current = spec.android(sdk);
      if (ranges.isNotEmpty && _same(ranges.last.natives, current)) {
        final last = ranges.removeLast();
        ranges.add((from: last.from, to: sdk, natives: last.natives));
      } else {
        ranges.add((from: sdk, to: sdk, natives: current));
      }
    }
    return ranges;
  }

  static bool _same(List<Object> a, List<Object> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);
}
