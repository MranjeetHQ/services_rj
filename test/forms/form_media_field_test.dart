import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:services_rj/services_rj.dart';

/// 1x1 transparent PNG so Image.memory decodes in tests.
final Uint8List kTinyPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class _FakePickerAdapter extends MediaPickerAdapter {
  _FakePickerAdapter(this.queue);

  /// Each pick call pops one batch off the queue.
  final List<List<PickedMediaFile>> queue;
  final List<String> calls = [];

  List<PickedMediaFile> _next() => queue.isEmpty ? [] : queue.removeAt(0);

  @override
  Future<List<PickedMediaFile>> pickImages({
    bool camera = false,
    bool multiple = false,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
    int? limit,
    bool frontCamera = false,
  }) async {
    calls.add(
      'images(camera:$camera,multiple:$multiple,quality:$imageQuality)',
    );
    return _next();
  }

  @override
  Future<List<PickedMediaFile>> pickVideo({
    bool camera = false,
    Duration? maxDuration,
    bool frontCamera = false,
  }) async {
    calls.add('video(camera:$camera)');
    return _next();
  }

  @override
  Future<List<PickedMediaFile>> pickFiles({
    bool multiple = false,
    List<String>? extensions,
    List<String>? mimeTypes,
  }) async {
    calls.add('files(multiple:$multiple,ext:${extensions?.join('|')})');
    return _next();
  }
}

PickedMediaFile _img(String path) =>
    PickedMediaFile(path: path, name: path.split('/').last, bytes: kTinyPng);

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late DynamicFormController controller;
  late _FakePickerAdapter fake;
  final defaultAdapter = MediaPickerAdapter.instance;

  setUp(() {
    controller = DynamicFormController();
    fake = _FakePickerAdapter([]);
    MediaPickerAdapter.instance = fake;
  });

  tearDown(() {
    controller.dispose();
    MediaPickerAdapter.instance = defaultAdapter;
  });

  group('image field', () {
    testWidgets('source both shows gallery/camera sheet and stores the pick', (
      tester,
    ) async {
      fake.queue.add([_img('/tmp/photo1.png')]);
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {'type': 'image', 'id': 'avatar', 'label': 'Avatar'},
              ],
            },
          ),
        ),
      );

      await tester.tap(find.byType(DynamicImageField));
      await tester.pumpAndSettle();
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);

      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      expect(controller.getValue('avatar'), '/tmp/photo1.png');
      expect(fake.calls.single, contains('camera:false'));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('camera type picks directly from the camera', (tester) async {
      fake.queue.add([_img('/tmp/shot.jpg')]);
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {'type': 'camera', 'id': 'selfie', 'label': 'Selfie'},
              ],
            },
          ),
        ),
      );

      await tester.tap(find.byType(DynamicImageField));
      await tester.pumpAndSettle();

      expect(find.text('Gallery'), findsNothing); // no source sheet
      expect(controller.getValue('selfie'), '/tmp/shot.jpg');
      expect(fake.calls.single, contains('camera:true'));
    });

    testWidgets('multiple appends, respects maxImages and removes', (
      tester,
    ) async {
      fake.queue.add([_img('/a.png'), _img('/b.png')]);
      fake.queue.add([_img('/c.png'), _img('/d.png')]);
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {
                  'type': 'image',
                  'id': 'photos',
                  'label': 'Photos',
                  'source': 'gallery',
                  'multiple': true,
                  'maxImages': 3,
                },
              ],
            },
          ),
        ),
      );

      await tester.tap(find.byType(DynamicImageField));
      await tester.pumpAndSettle();
      expect(controller.getValue('photos'), ['/a.png', '/b.png']);

      // Second pick would exceed maxImages → capped at 3.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(controller.getValue('photos'), ['/a.png', '/b.png', '/c.png']);

      // Remove the first thumbnail.
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();
      expect(controller.getValue('photos'), ['/b.png', '/c.png']);
    });

    testWidgets('imageQuality and source gallery pass through', (tester) async {
      fake.queue.add([_img('/q.png')]);
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {
                  'type': 'image',
                  'id': 'pic',
                  'label': 'Pic',
                  'source': 'gallery',
                  'imageQuality': 60,
                },
              ],
            },
          ),
        ),
      );

      await tester.tap(find.byType(DynamicImageField));
      await tester.pumpAndSettle();
      expect(fake.calls.single, contains('quality:60'));
    });

    testWidgets('required image blocks submit and shows error', (tester) async {
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {
                  'type': 'image',
                  'id': 'doc',
                  'label': 'Doc',
                  'required': true,
                },
              ],
            },
          ),
        ),
      );

      expect(controller.validate(), isFalse);
      await tester.pump();
      expect(find.text('This field is required'), findsOneWidget);
    });
  });

  group('file field', () {
    testWidgets('picks a file, shows its name, remove clears', (tester) async {
      fake.queue.add([
        const PickedMediaFile(path: '/docs/resume.pdf', name: 'resume.pdf'),
      ]);
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {
                  'type': 'file',
                  'id': 'resume',
                  'label': 'Resume',
                  'extensions': ['pdf'],
                },
              ],
            },
          ),
        ),
      );

      await tester.tap(find.byType(DynamicFileField));
      await tester.pumpAndSettle();

      expect(controller.getValue('resume'), '/docs/resume.pdf');
      expect(fake.calls.single, contains('ext:pdf'));
      expect(find.text('resume.pdf'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(controller.getValue('resume'), isNull);
    });

    testWidgets('multiple files accumulate into a list', (tester) async {
      fake.queue.add([
        const PickedMediaFile(path: '/x/a.pdf', name: 'a.pdf'),
        const PickedMediaFile(path: '/x/b.pdf', name: 'b.pdf'),
      ]);
      await tester.pumpWidget(
        _app(
          DynamicForm(
            controller: controller,
            json: const {
              'fields': [
                {
                  'type': 'file',
                  'id': 'attachments',
                  'label': 'Attachments',
                  'multiple': true,
                },
              ],
            },
          ),
        ),
      );

      await tester.tap(find.byType(DynamicFileField));
      await tester.pumpAndSettle();
      expect(controller.getValue('attachments'), ['/x/a.pdf', '/x/b.pdf']);
      expect(find.text('a.pdf'), findsOneWidget);
      expect(find.text('b.pdf'), findsOneWidget);
    });
  });
}
