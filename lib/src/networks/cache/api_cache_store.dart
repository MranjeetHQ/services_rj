import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_logger.dart';
import '../../core/security/app_encryption.dart';
import 'cache_entry.dart';

/// Two-level store: an in-memory LRU map for instant reads, backed by one
/// file per entry on disk so data survives restarts.
///
/// File names are SHA-256 hashes of the cache key, so URLs and query
/// parameters are not visible on disk. When encryption is active the
/// contents are AES-GCM encrypted (`.enc`), otherwise plain JSON (`.json`).
class ApiCacheStore {
  ApiCacheStore({
    required this.maxMemoryEntries,
    required this.maxDiskBytes,
    required this.directoryName,
    this.directoryOverride,
  });

  final int maxMemoryEntries;
  final int maxDiskBytes;
  final String directoryName;

  /// Used by tests instead of the platform app support directory.
  final Directory? directoryOverride;

  static const String _encExt = '.enc';
  static const String _jsonExt = '.json';

  final LinkedHashMap<String, CacheEntry> _memory = LinkedHashMap();

  /// file base name (hash) -> size and last write time.
  final Map<String, _DiskMeta> _disk = {};

  Directory? _dir;

  Future<void> _writeQueue = Future.value();

  AppEncryption get _crypto => AppEncryption.instance;

  bool get hasDisk => _dir != null;

  int get memoryCount => _memory.length;

  int get diskBytes => _disk.values.fold(0, (sum, m) => sum + m.size);

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  Future<void> initialize({required bool preload}) async {
    if (kIsWeb) {
      AppLogger.warning(
        'ApiCache: disk cache is not available on web, using memory only.',
      );
      return;
    }

    final base = directoryOverride ?? await getApplicationSupportDirectory();
    final dir = Directory(
      '${base.path}${Platform.pathSeparator}$directoryName',
    );
    await dir.create(recursive: true);
    _dir = dir;

    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = _baseName(entity.path);
      if (name == null) {
        // Leftover temp file from an interrupted write.
        await _safeDelete(entity);
        continue;
      }
      final stat = await entity.stat();
      _disk[name.hash] = _DiskMeta(stat.size, stat.modified, name.ext);
      files.add(entity);
    }

    if (!preload || files.isEmpty) return;

    // Newest first, up to the memory limit.
    final newest = _disk.entries.toList()
      ..sort((a, b) => b.value.modified.compareTo(a.value.modified));

    final loaded = await Future.wait(
      newest.take(maxMemoryEntries).map((e) => _readFile(e.key)),
    );

    // Insert oldest first so LRU order matches recency.
    for (final entry in loaded.reversed) {
      if (entry != null) _memory[entry.key] = entry;
    }
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Memory-only lookup. Synchronous, so it can feed a widget's first frame.
  CacheEntry? peek(String key) {
    final entry = _memory.remove(key);
    if (entry != null) _memory[key] = entry;
    return entry;
  }

  Future<CacheEntry?> get(String key) async {
    final hit = peek(key);
    if (hit != null) return hit;

    final entry = await _readFile(AppEncryption.sha256Hex(key));
    if (entry != null && entry.key == key) {
      _remember(entry);
      return entry;
    }
    return null;
  }

  /// All entries in memory plus any that exist only on disk.
  Future<List<CacheEntry>> all() async {
    final result = <String, CacheEntry>{
      for (final e in _memory.values) e.key: e,
    };
    final memoryHashes = result.keys.map(AppEncryption.sha256Hex).toSet();

    for (final hash in _disk.keys.toList()) {
      if (memoryHashes.contains(hash)) continue;
      final entry = await _readFile(hash);
      if (entry != null) result[entry.key] = entry;
    }
    return result.values.toList();
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Stores [entry] in memory right away and on disk in the background.
  /// Returns a future that completes once the disk write is done.
  Future<void> put(CacheEntry entry) {
    _remember(entry);
    if (_dir == null) return Future.value();

    final hash = AppEncryption.sha256Hex(entry.key);
    return _enqueue(() => _writeFile(hash, entry));
  }

  Future<void> remove(String key) {
    _memory.remove(key);
    if (_dir == null) return Future.value();

    final hash = AppEncryption.sha256Hex(key);
    return _enqueue(() => _deleteHash(hash));
  }

  Future<void> clear() {
    _memory.clear();
    if (_dir == null) return Future.value();

    return _enqueue(() async {
      for (final hash in _disk.keys.toList()) {
        await _deleteHash(hash);
      }
    });
  }

  /// Waits for all pending disk writes.
  Future<void> flush() => _writeQueue;

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  void _remember(CacheEntry entry) {
    _memory.remove(entry.key);
    _memory[entry.key] = entry;
    while (_memory.length > maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  Future<void> _enqueue(Future<void> Function() task) {
    final next = _writeQueue.then((_) => task()).catchError((
      Object e,
      StackTrace st,
    ) {
      AppLogger.error('ApiCache disk error: $e', stackTrace: st);
    });
    _writeQueue = next;
    return next;
  }

  Future<void> _writeFile(String hash, CacheEntry entry) async {
    final dir = _dir!;
    final encrypt = _crypto.isActive;
    final ext = encrypt ? _encExt : _jsonExt;

    final Uint8List bytes;
    final json = utf8.encode(jsonEncode(entry.toJson()));
    bytes = encrypt ? _crypto.encryptBytes(json) : Uint8List.fromList(json);

    // Write to a temp file then rename, so a crash never leaves half a file.
    final target = File(_path(dir, hash, ext));
    final temp = File('${target.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(target.path);

    // Remove a copy with the other extension (encryption was toggled).
    final old = _disk[hash];
    if (old != null && old.ext != ext) {
      await _safeDelete(File(_path(dir, hash, old.ext)));
    }

    _disk[hash] = _DiskMeta(bytes.length, DateTime.now(), ext);
    await _enforceDiskLimit();
  }

  Future<CacheEntry?> _readFile(String hash) async {
    final dir = _dir;
    final meta = _disk[hash];
    if (dir == null || meta == null) return null;

    final file = File(_path(dir, hash, meta.ext));
    try {
      final bytes = await file.readAsBytes();
      final List<int> json;
      if (meta.ext == _encExt) {
        if (!_crypto.isInitialized) return null;
        json = _crypto.decryptBytes(bytes);
      } else {
        json = bytes;
      }
      return CacheEntry.fromJson(
        jsonDecode(utf8.decode(json)) as Map<String, dynamic>,
      );
    } catch (e) {
      // Corrupt, tampered, or encrypted with a lost key. Drop it, but only
      // if no newer write replaced the file while it was being read.
      AppLogger.warning('ApiCache: discarding unreadable entry ($e)');
      await _enqueue(() async {
        if (identical(_disk[hash], meta)) await _deleteHash(hash);
      });
      return null;
    }
  }

  Future<void> _deleteHash(String hash) async {
    final dir = _dir;
    final meta = _disk.remove(hash);
    if (dir == null || meta == null) return;
    await _safeDelete(File(_path(dir, hash, meta.ext)));
  }

  Future<void> _enforceDiskLimit() async {
    if (diskBytes <= maxDiskBytes) return;

    final oldest = _disk.entries.toList()
      ..sort((a, b) => a.value.modified.compareTo(b.value.modified));

    for (final e in oldest) {
      if (diskBytes <= maxDiskBytes) break;
      await _deleteHash(e.key);
    }
  }

  Future<void> _safeDelete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  String _path(Directory dir, String hash, String ext) =>
      '${dir.path}${Platform.pathSeparator}$hash$ext';

  ({String hash, String ext})? _baseName(String path) {
    final name = path.split(Platform.pathSeparator).last;
    for (final ext in const [_encExt, _jsonExt]) {
      if (name.endsWith(ext)) {
        return (hash: name.substring(0, name.length - ext.length), ext: ext);
      }
    }
    return null;
  }
}

class _DiskMeta {
  _DiskMeta(this.size, this.modified, this.ext);

  final int size;
  final DateTime modified;
  final String ext;
}
