import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/dynamic_form_controller.dart';
import '../models/field_config.dart';
import '../models/field_type.dart';
import 'decoration_helper.dart';

/// One picked image / video / document.
///
/// [path] is what gets stored in the form data (a file path on mobile and
/// desktop, a blob URL on web). [name] is the display file name and [bytes]
/// holds preview bytes for images (kept in an in-memory cache so thumbnails
/// work on every platform, including web).
class PickedMediaFile {
  /// Creates a picked-file description.
  const PickedMediaFile({required this.path, required this.name, this.bytes});

  /// Platform path (or blob URL on web) — this is the stored form value.
  final String path;

  /// Original file name, for display.
  final String name;

  /// Optional preview bytes (images only).
  final Uint8List? bytes;
}

/// Native picking service used by the built-in `image`, `camera` and `file`
/// fields. Wraps the official `image_picker` and `file_selector` plugins.
///
/// Swap [instance] to change how picking works everywhere (custom cropper,
/// permission flow, test fake…) without re-implementing the field UI:
///
/// ```dart
/// MediaPickerAdapter.instance = MyCroppingPickerAdapter();
/// ```
class MediaPickerAdapter {
  /// Creates the default adapter.
  MediaPickerAdapter();

  /// Active adapter — replace to customize picking globally.
  static MediaPickerAdapter instance = MediaPickerAdapter();

  final ImagePicker _picker = ImagePicker();

  /// Picks one or more images from [camera] or the gallery.
  Future<List<PickedMediaFile>> pickImages({
    bool camera = false,
    bool multiple = false,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
    int? limit,
    bool frontCamera = false,
  }) async {
    if (camera) {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: frontCamera
            ? CameraDevice.front
            : CameraDevice.rear,
      );
      return [if (shot != null) await _withBytes(shot)];
    }
    if (multiple) {
      final picked = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        limit: limit != null && limit >= 2 ? limit : null,
      );
      return [for (final x in picked) await _withBytes(x)];
    }
    final one = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    return [if (one != null) await _withBytes(one)];
  }

  /// Records or picks a single video.
  Future<List<PickedMediaFile>> pickVideo({
    bool camera = false,
    Duration? maxDuration,
    bool frontCamera = false,
  }) async {
    final video = await _picker.pickVideo(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: maxDuration,
      preferredCameraDevice: frontCamera
          ? CameraDevice.front
          : CameraDevice.rear,
    );
    return [
      if (video != null) PickedMediaFile(path: video.path, name: video.name),
    ];
  }

  /// Picks one or more arbitrary files, optionally filtered by
  /// [extensions] (e.g. `['pdf', 'docx']`) and/or [mimeTypes].
  Future<List<PickedMediaFile>> pickFiles({
    bool multiple = false,
    List<String>? extensions,
    List<String>? mimeTypes,
  }) async {
    final groups = <file_selector.XTypeGroup>[
      if ((extensions?.isNotEmpty ?? false) || (mimeTypes?.isNotEmpty ?? false))
        file_selector.XTypeGroup(extensions: extensions, mimeTypes: mimeTypes),
    ];
    if (multiple) {
      final files = await file_selector.openFiles(acceptedTypeGroups: groups);
      return [
        for (final f in files) PickedMediaFile(path: f.path, name: f.name),
      ];
    }
    final file = await file_selector.openFile(acceptedTypeGroups: groups);
    return [
      if (file != null) PickedMediaFile(path: file.path, name: file.name),
    ];
  }

  Future<PickedMediaFile> _withBytes(XFile x) async =>
      PickedMediaFile(path: x.path, name: x.name, bytes: await x.readAsBytes());
}

/// Session cache: path → preview bytes / display name. Lets thumbnails and
/// file names render on every platform without touching dart:io.
class _MediaCache {
  static final Map<String, Uint8List> bytes = {};
  static final Map<String, String> names = {};

  static void remember(PickedMediaFile f) {
    names[f.path] = f.name;
    final b = f.bytes;
    if (b != null) bytes[f.path] = b;
  }

  static String nameFor(String path) =>
      names[path] ?? Uri.tryParse(path)?.pathSegments.lastOrNull ?? path;
}

/// Rebuild-scoped listener over a media field's value + error + enabled.
class _MediaScope extends StatelessWidget {
  const _MediaScope({required this.state, required this.builder});

  final dynamic state; // FieldRuntimeState
  final Widget Function(BuildContext, Object?, String?, bool) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Object?>(
      valueListenable: state.value as ValueNotifier<Object?>,
      builder: (context, value, _) => ValueListenableBuilder<String?>(
        valueListenable: state.error as ValueNotifier<String?>,
        builder: (context, error, _) => ValueListenableBuilder<bool>(
          valueListenable: state.enabled as ValueNotifier<bool>,
          builder: (context, enabled, _) =>
              builder(context, value, error, enabled),
        ),
      ),
    );
  }
}

List<String> _asPathList(Object? value) => switch (value) {
  null => const [],
  List<dynamic> l => [for (final e in l) e.toString()],
  _ => [value.toString()],
};

/// Built-in renderer for the `image` and `camera` field types: gallery
/// and/or camera picking with thumbnail previews, multi-image support and
/// full validation/theming integration — all driven from JSON.
///
/// Stored value: single image → `String` path; `"multiple": true` →
/// `List<String>` of paths.
///
/// Supported JSON `extra` keys:
/// - `source`: `"gallery"`, `"camera"` or `"both"` (default `"both"`;
///   the `camera` field type forces `"camera"`)
/// - `multiple`: pick several images (gallery)
/// - `maxImages`: cap for `multiple`
/// - `imageQuality`: 0–100 compression
/// - `maxWidth` / `maxHeight`: downscale bounds
/// - `preferredCamera`: `"front"` or `"rear"`
/// - `video`: pick/record a video instead of an image
/// - `previewSize`: thumbnail side in logical pixels (default 72)
class DynamicImageField extends StatelessWidget {
  /// Creates an image/camera field.
  const DynamicImageField({
    super.key,
    required this.field,
    required this.controller,
  });

  /// Field configuration.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  bool get _multiple => field.ex<bool>('multiple') ?? false;

  bool get _video => field.ex<bool>('video') ?? false;

  String get _source => field.type == FieldType.camera
      ? 'camera'
      : (field.ex<String>('source') ?? 'both').toLowerCase();

  Future<void> _pick(BuildContext context, List<String> current) async {
    var camera = _source == 'camera';
    if (_source == 'both') {
      final l10n = controller.l10n;
      final choice = await showModalBottomSheet<bool>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.message('gallery')),
                onTap: () => Navigator.pop(context, false),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.message('camera')),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      );
      if (choice == null) return;
      camera = choice;
    }

    final maxImages = field.ex<int>('maxImages');
    final frontCamera =
        (field.ex<String>('preferredCamera') ?? '').toLowerCase() == 'front';
    final List<PickedMediaFile> picked;
    try {
      picked = _video
          ? await MediaPickerAdapter.instance.pickVideo(
              camera: camera,
              frontCamera: frontCamera,
              maxDuration: field.ex<int>('maxDurationSeconds') != null
                  ? Duration(seconds: field.ex<int>('maxDurationSeconds')!)
                  : null,
            )
          : await MediaPickerAdapter.instance.pickImages(
              camera: camera,
              multiple: _multiple && !camera,
              imageQuality: field.ex<int>('imageQuality'),
              maxWidth: field.ex<double>('maxWidth'),
              maxHeight: field.ex<double>('maxHeight'),
              limit: maxImages == null ? null : maxImages - current.length,
              frontCamera: frontCamera,
            );
    } on Exception catch (e) {
      debugPrint('json_form_engine: media pick failed: $e');
      return;
    }
    if (picked.isEmpty) return;
    picked.forEach(_MediaCache.remember);

    if (_multiple) {
      var paths = [...current, for (final f in picked) f.path];
      if (maxImages != null && paths.length > maxImages) {
        paths = paths.sublist(0, maxImages);
      }
      controller.setValue(field.id, paths);
    } else {
      controller.setValue(field.id, picked.first.path);
    }
  }

  void _remove(String path, List<String> current) {
    if (_multiple) {
      controller.setValue(
        field.id,
        [...current]..removeWhere((p) => p == path),
      );
    } else {
      controller.setValue(field.id, null);
    }
  }

  Widget _thumb(
    BuildContext context,
    String path,
    double size,
    bool enabled,
    List<String> current,
  ) {
    final radius = BorderRadius.circular(8);
    Widget preview;
    if (_video) {
      preview = Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.videocam_outlined),
      );
    } else {
      final cached = _MediaCache.bytes[path];
      if (cached != null) {
        preview = Image.memory(
          cached,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      } else if (path.startsWith('http')) {
        preview = Image.network(
          path,
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) =>
              const Icon(Icons.broken_image_outlined),
        );
      } else {
        preview = FutureBuilder<Uint8List>(
          future: XFile(path).readAsBytes(),
          builder: (context, snap) => snap.hasData
              ? Image.memory(snap.data!, fit: BoxFit.cover)
              : Icon(
                  snap.hasError
                      ? Icons.broken_image_outlined
                      : Icons.image_outlined,
                  color: Theme.of(context).colorScheme.outline,
                ),
        );
      }
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: radius,
          child: SizedBox(width: size, height: size, child: preview),
        ),
        if (enabled)
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: () => _remove(path, current),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Semantics(
                  label: controller.l10n.message('remove'),
                  button: true,
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state(field.id);
    final size = field.ex<double>('previewSize') ?? 72;
    return _MediaScope(
      state: state,
      builder: (context, value, error, enabled) {
        final paths = _asPathList(value);
        final interactive = enabled && !field.readOnly;
        final maxImages = field.ex<int>('maxImages');
        final canAdd =
            interactive &&
            (paths.isEmpty ||
                (_multiple && (maxImages == null || paths.length < maxImages)));

        return InkWell(
          onTap: canAdd ? () => _pick(context, paths) : null,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: buildFieldDecoration(
              context,
              field,
              controller,
              errorText: error,
              suffix: Icon(
                _source == 'camera'
                    ? Icons.photo_camera_outlined
                    : Icons.add_photo_alternate_outlined,
              ),
            ),
            isEmpty: paths.isEmpty,
            child: paths.isEmpty
                ? const Text('')
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in paths)
                          _thumb(context, p, size, interactive, paths),
                        if (canAdd)
                          InkWell(
                            onTap: () => _pick(context, paths),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// Built-in renderer for the `file` field type: document picking with
/// extension/MIME filters, file-name rows and remove buttons.
///
/// Stored value: single file → `String` path; `"multiple": true` →
/// `List<String>` of paths.
///
/// Supported JSON `extra` keys:
/// - `multiple`: allow several files
/// - `maxFiles`: cap for `multiple`
/// - `extensions`: allowed extensions, e.g. `["pdf", "docx"]`
/// - `mimeTypes`: allowed MIME types, e.g. `["application/pdf"]`
class DynamicFileField extends StatelessWidget {
  /// Creates a file field.
  const DynamicFileField({
    super.key,
    required this.field,
    required this.controller,
  });

  /// Field configuration.
  final FieldConfig field;

  /// Owning form controller.
  final DynamicFormController controller;

  bool get _multiple => field.ex<bool>('multiple') ?? false;

  List<String>? _stringList(String key) {
    final raw = field.ex<List<dynamic>>(key);
    if (raw == null || raw.isEmpty) return null;
    return [for (final e in raw) e.toString().replaceFirst('.', '')];
  }

  Future<void> _pick(List<String> current) async {
    final List<PickedMediaFile> picked;
    try {
      picked = await MediaPickerAdapter.instance.pickFiles(
        multiple: _multiple,
        extensions: _stringList('extensions'),
        mimeTypes: field.ex<List<dynamic>>('mimeTypes') == null
            ? null
            : [
                for (final m in field.ex<List<dynamic>>('mimeTypes')!)
                  m.toString(),
              ],
      );
    } on Exception catch (e) {
      debugPrint('json_form_engine: file pick failed: $e');
      return;
    }
    if (picked.isEmpty) return;
    picked.forEach(_MediaCache.remember);

    if (_multiple) {
      var paths = [...current, for (final f in picked) f.path];
      final maxFiles = field.ex<int>('maxFiles');
      if (maxFiles != null && paths.length > maxFiles) {
        paths = paths.sublist(0, maxFiles);
      }
      controller.setValue(field.id, paths);
    } else {
      controller.setValue(field.id, picked.first.path);
    }
  }

  void _remove(String path, List<String> current) {
    if (_multiple) {
      controller.setValue(
        field.id,
        [...current]..removeWhere((p) => p == path),
      );
    } else {
      controller.setValue(field.id, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state(field.id);
    return _MediaScope(
      state: state,
      builder: (context, value, error, enabled) {
        final paths = _asPathList(value);
        final interactive = enabled && !field.readOnly;
        final maxFiles = field.ex<int>('maxFiles');
        final canAdd =
            interactive &&
            (paths.isEmpty ||
                (_multiple && (maxFiles == null || paths.length < maxFiles)));

        return InkWell(
          onTap: canAdd ? () => _pick(paths) : null,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: buildFieldDecoration(
              context,
              field,
              controller,
              errorText: error,
              suffix: const Icon(Icons.attach_file),
            ),
            isEmpty: paths.isEmpty,
            child: paths.isEmpty
                ? const Text('')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final p in paths)
                        Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file_outlined,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _MediaCache.nameFor(p),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (interactive)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                visualDensity: VisualDensity.compact,
                                tooltip: controller.l10n.message('remove'),
                                onPressed: () => _remove(p, paths),
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
