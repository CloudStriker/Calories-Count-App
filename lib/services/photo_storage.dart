import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract class PhotoStore {
  Future<String> saveMealPhoto(Uint8List bytes, String mealId);
  Future<void> deleteMealPhoto(String? path);
}

class LocalPhotoStore implements PhotoStore {
  @override
  Future<String> saveMealPhoto(Uint8List bytes, String mealId) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docsDir.path, 'meal_photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final targetPath = p.join(photosDir.path, '$mealId.jpg');
    await File(targetPath).writeAsBytes(bytes, flush: true);
    return targetPath;
  }

  @override
  Future<void> deleteMealPhoto(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort cleanup; ignore missing or locked files.
    }
  }
}
