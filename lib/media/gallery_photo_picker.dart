import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Result of a gallery pick.
class PickedGalleryPhoto {
  const PickedGalleryPhoto({
    required this.path,
    required this.bytes,
  });

  final String path;
  final Uint8List bytes;
}

/// Opens the device photo library. Tests override [galleryPhotoPickerProvider].
abstract class GalleryPhotoPicker {
  Future<PickedGalleryPhoto?> pickFromGallery();
}

class ImagePickerGalleryPhotoPicker implements GalleryPhotoPicker {
  ImagePickerGalleryPhotoPicker({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedGalleryPhoto?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) return null;
    return PickedGalleryPhoto(path: file.path, bytes: bytes);
  }
}

/// Widget tests: add a slot without opening the system picker.
class FakeGalleryPhotoPicker implements GalleryPhotoPicker {
  @override
  Future<PickedGalleryPhoto?> pickFromGallery() async {
    return PickedGalleryPhoto(
      path: '',
      bytes: Uint8List(0),
    );
  }
}

final galleryPhotoPickerProvider = Provider<GalleryPhotoPicker>(
  (ref) => ImagePickerGalleryPhotoPicker(),
);
