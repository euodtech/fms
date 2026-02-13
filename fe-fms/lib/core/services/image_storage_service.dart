import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageStorageService {
  static Future<List<String>> saveImages({
    required int jobId,
    required List<XFile> images,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final jobDir = Directory(p.join(appDir.path, 'offline_images', '$jobId'));
    if (!await jobDir.exists()) {
      await jobDir.create(recursive: true);
    }

    final savedPaths = <String>[];
    for (int i = 0; i < images.length; i++) {
      final ext = p.extension(images[i].path).isNotEmpty
          ? p.extension(images[i].path)
          : '.jpg';
      final destPath = p.join(jobDir.path, 'img_${i}_${DateTime.now().millisecondsSinceEpoch}$ext');
      final bytes = await images[i].readAsBytes();
      await File(destPath).writeAsBytes(bytes);
      savedPaths.add(destPath);
    }
    return savedPaths;
  }

  static Future<List<String>> loadImagesAsBase64(List<String> paths) async {
    final base64List = <String>[];
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        base64List.add(base64Encode(bytes));
      }
    }
    return base64List;
  }

  static Future<void> deleteImages(List<String> paths) async {
    for (final path in paths) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    // Clean up empty parent directory
    if (paths.isNotEmpty) {
      final parent = File(paths.first).parent;
      if (await parent.exists()) {
        final remaining = await parent.list().length;
        if (remaining == 0) {
          await parent.delete();
        }
      }
    }
  }
}
