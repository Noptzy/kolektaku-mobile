import 'dart:io';
import 'dart:typed_data';

import 'package:kolektaku/platform/picture_source.dart';

const sample = 'https://images.plurk.com/32B15UXxymfSMwKGTObY5e.jpg';

class SamplePictures implements PictureSource {
  SamplePictures(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List?> fromGallery() async => bytes;

  @override
  Future<Uint8List?> fromCamera() async => bytes;
}

Future<Uint8List> download(String url) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(Uri.parse(url))).close();
    final builder = BytesBuilder();
    await for (final chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  } finally {
    client.close();
  }
}
