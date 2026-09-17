import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:petdate/state/profile_provider.dart';

/// Device-local bytes for pet photos so My page survives cold start even when
/// Storage is unavailable. Paths: `{docs}/pet_photos/{uid}/photo_i.jpg`.
abstract final class PetPhotoLocalCache {
  static Future<Directory?> _dir(String uid) async {
    if (kIsWeb) return null;
    try {
      final root = await getApplicationDocumentsDirectory();
      final dir = Directory('${root.path}/pet_photos/$uid');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } on Object catch (error) {
      assert(() {
        debugPrint('PetPhotoLocalCache dir failed: $error');
        return true;
      }());
      return null;
    }
  }

  static Future<void> write({
    required String uid,
    required List<MockPhoto> photos,
  }) async {
    final dir = await _dir(uid);
    if (dir == null) return;

    final keep = <String>{};
    for (var i = 0; i < photos.length; i++) {
      final bytes = photos[i].bytes;
      if (bytes == null || bytes.isEmpty) continue;
      final name = 'photo_$i.jpg';
      keep.add(name);
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
    }

    try {
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!keep.contains(name)) {
          await entity.delete();
        }
      }
    } on Object catch (error) {
      assert(() {
        debugPrint('PetPhotoLocalCache prune failed: $error');
        return true;
      }());
    }
  }

  /// Fills missing [MockPhoto.bytes] from disk when present.
  static Future<ProfileDraft> hydrate({
    required String uid,
    required ProfileDraft draft,
  }) async {
    if (draft.photos.isEmpty) return draft;
    final dir = await _dir(uid);
    if (dir == null) return draft;

    final next = <MockPhoto>[];
    for (var i = 0; i < draft.photos.length; i++) {
      final photo = draft.photos[i];
      if (photo.hasLocalImage) {
        next.add(photo);
        continue;
      }
      final file = File('${dir.path}/photo_$i.jpg');
      Uint8List? bytes;
      try {
        if (await file.exists()) {
          final raw = await file.readAsBytes();
          if (raw.isNotEmpty) bytes = raw;
        }
      } on Object catch (error) {
        assert(() {
          debugPrint('PetPhotoLocalCache read failed: $error');
          return true;
        }());
      }
      next.add(bytes == null ? photo : photo.copyWith(bytes: bytes));
    }
    return draft.copyWith(photos: next);
  }
}
