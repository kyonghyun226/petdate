import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:petdate/firebase/firestore_ids.dart';
import 'package:petdate/firebase/identity_remote.dart';
import 'package:petdate/firebase/pet_photo_local_cache.dart';
import 'package:petdate/state/profile_provider.dart';

/// Upload / resolve pet photos at Storage paths `pets/{uid}/{file}`.
abstract final class PetPhotoStorage {
  static bool get _ready {
    try {
      return Firebase.apps.isNotEmpty && IdentityRemote.isLiveAuthReady;
    } on Object {
      return false;
    }
  }

  /// Primary first, then the rest — Firestore photo[0] is the cover.
  static List<MockPhoto> orderedPhotos(ProfileDraft draft) {
    final primary = draft.primaryPhoto;
    if (primary == null) return List<MockPhoto>.from(draft.photos);
    return [
      primary,
      ...draft.photos.where((p) => p.id != primary.id),
    ];
  }

  /// Upload local bytes (and keep existing remote objects). Returns a draft
  /// whose photos have [MockPhoto.storagePath] / [MockPhoto.remoteUrl] set.
  /// Always writes a device-local cache so My page survives cold start.
  static Future<ProfileDraft> syncDraftPhotos({
    required String uid,
    required ProfileDraft draft,
  }) async {
    final ordered = orderedPhotos(draft);
    if (ordered.isEmpty) {
      await PetPhotoLocalCache.write(uid: uid, photos: const []);
      return draft;
    }

    final next = <MockPhoto>[];
    for (var i = 0; i < ordered.length; i++) {
      final photo = ordered[i];
      final fileName = 'photo_$i.jpg';
      final path = FirestoreIds.photoPath(petId: uid, fileName: fileName);

      if (!_ready) {
        next.add(
          photo.copyWith(id: 'photo_$i', seed: i, storagePath: path),
        );
        continue;
      }

      var remoteUrl = photo.remoteUrl;
      final bytes = photo.bytes;

      if (bytes != null && bytes.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.ref(path);
          await ref.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          remoteUrl = await ref.getDownloadURL();
        } on Object catch (error) {
          // Storage may not be provisioned yet — local cache still persists.
          assert(() {
            debugPrint('PetPhotoStorage upload failed for $path: $error');
            return true;
          }());
        }
      } else if (photo.storagePath != null && photo.storagePath != path) {
        remoteUrl ??= await _tryDownloadUrl(photo.storagePath!);
      } else if (remoteUrl == null || remoteUrl.isEmpty) {
        remoteUrl = await _tryDownloadUrl(path);
      }

      next.add(
        photo.copyWith(
          id: 'photo_$i',
          seed: i,
          storagePath: path,
          remoteUrl: remoteUrl,
        ),
      );
    }

    final synced = draft.copyWith(
      photos: next,
      primaryPhotoId: next.isEmpty ? null : next.first.id,
      clearPrimaryPhotoId: next.isEmpty,
    );
    await PetPhotoLocalCache.write(uid: uid, photos: next);
    return synced;
  }

  /// Restore local bytes + attach download URLs (cold start / re-login).
  static Future<ProfileDraft> resolveRemoteUrls(
    ProfileDraft draft, {
    String? uid,
  }) async {
    var nextDraft = draft;
    final owner = uid ?? IdentityRemote.authUid;
    if (owner != null) {
      nextDraft = await PetPhotoLocalCache.hydrate(uid: owner, draft: nextDraft);
    }
    if (!_ready || nextDraft.photos.isEmpty) return nextDraft;
    final next = <MockPhoto>[];
    for (final photo in nextDraft.photos) {
      if (photo.hasRemoteImage || photo.hasLocalImage) {
        next.add(photo);
        continue;
      }
      final path = photo.storagePath;
      if (path == null || path.isEmpty) {
        next.add(photo);
        continue;
      }
      final url = await _tryDownloadUrl(path);
      next.add(photo.copyWith(remoteUrl: url));
    }
    return nextDraft.copyWith(photos: next);
  }

  static Future<String?> _tryDownloadUrl(String path) async {
    try {
      return await FirebaseStorage.instance.ref(path).getDownloadURL();
    } on Object catch (error) {
      assert(() {
        debugPrint('PetPhotoStorage download URL failed for $path: $error');
        return true;
      }());
      return null;
    }
  }
}
