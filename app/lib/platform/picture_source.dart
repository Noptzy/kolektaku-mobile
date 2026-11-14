import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

const sceneImageWidth = 640.0;
const sceneImageQuality = 85;

abstract interface class PictureSource {
  Future<Uint8List?> fromGallery();

  Future<Uint8List?> fromCamera();
}

class ImagePickerPictureSource implements PictureSource {
  const ImagePickerPictureSource();

  @override
  Future<Uint8List?> fromGallery() => _pick(ImageSource.gallery);

  @override
  Future<Uint8List?> fromCamera() => _pick(ImageSource.camera);

  Future<Uint8List?> _pick(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: sceneImageWidth,
      imageQuality: sceneImageQuality,
    );
    return file?.readAsBytes();
  }
}

final pictureSourceProvider = Provider<PictureSource>(
  (ref) => const ImagePickerPictureSource(),
);
