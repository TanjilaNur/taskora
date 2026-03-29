import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';

class ImageService {
  final ImagePicker _picker;
  final Uuid _uuid;

  ImageService({ImagePicker? picker, Uuid? uuid})
      : _picker = picker ?? ImagePicker(),
        _uuid = uuid ?? const Uuid();

  Future<Result<String>> pickFromGallery() async {
    try {
      final xfile = await _picker.pickImage(source: ImageSource.gallery);
      if (xfile == null) return Err(Exception('No image selected'));
      return _compressAndSave(xfile.path);
    } catch (e) {
      return Err(Exception('Gallery pick failed: $e'));
    }
  }

  Future<Result<String>> pickFromCamera() async {
    try {
      final xfile = await _picker.pickImage(source: ImageSource.camera);
      if (xfile == null) return Err(Exception('No image captured'));
      return _compressAndSave(xfile.path);
    } catch (e) {
      return Err(Exception('Camera pick failed: $e'));
    }
  }

  Future<Result<String>> _compressAndSave(String sourcePath) async {
    try {
      final dir      = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(dir.path, 'task_images'));
      if (!imagesDir.existsSync()) await imagesDir.create(recursive: true);

      final destPath = p.join(imagesDir.path, '${_uuid.v4()}.jpg');

      final compressed = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        destPath,
        minWidth:  AppConstants.thumbnailSize,
        minHeight: AppConstants.thumbnailSize,
        quality:   AppConstants.imageQuality,
        format:    CompressFormat.jpeg,
      );

      if (compressed == null) return Err(Exception('Compression failed'));
      return Ok(compressed.path);
    } catch (e) {
      return Err(Exception('Image save failed: $e'));
    }
  }

  Future<void> deleteImage(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Returns true if the URL responds with a 2xx/3xx status — false otherwise.
  /// Used by the form sheet to validate URLs before saving.
  Future<bool> validateUrl(String url) async {
    try {
      final client  = HttpClient();
      final request = await client.headUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      final response = await request.close();
      client.close();
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  Future<Result<String>> downloadAndCacheUrl(String url) async {
    try {
      final client   = HttpClient();
      final request  = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        return Err(Exception('Failed to download image: ${response.statusCode}'));
      }

      // Consolidate chunked response into a single byte list
      final bytes = await _consolidateBytes(response);

      final dir      = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(dir.path, 'task_images'));
      if (!imagesDir.existsSync()) await imagesDir.create(recursive: true);

      final destPath = p.join(imagesDir.path, '${_uuid.v4()}.jpg');

      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth:  AppConstants.thumbnailSize,
        minHeight: AppConstants.thumbnailSize,
        quality:   AppConstants.imageQuality,
        format:    CompressFormat.jpeg,
      );

      await File(destPath).writeAsBytes(compressed);
      return Ok(destPath);
    } catch (e) {
      return Err(Exception('URL image download failed: $e'));
    }
  }

  /// Collects all chunks from an [HttpClientResponse] into a single [Uint8List].
  Future<Uint8List> _consolidateBytes(HttpClientResponse response) async {
    final chunks = <List<int>>[];
    await for (final chunk in response) {
      chunks.add(chunk);
    }
    return Uint8List.fromList(chunks.expand((x) => x).toList());
  }
}