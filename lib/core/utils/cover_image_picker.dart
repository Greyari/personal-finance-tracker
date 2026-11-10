import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Picks a cover photo from gallery/camera and copies it into the app's
/// documents directory so the path stays valid after the picker's temp
/// file is cleaned up. Returns the stored file path, or null if cancelled.
class CoverImagePicker {
  CoverImagePicker._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1400,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final docsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(docsDir.path, 'goal_covers'));
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
    final ext = p.extension(picked.path).isEmpty ? '.jpg' : p.extension(picked.path);
    final target = p.join(
      coversDir.path,
      'cover_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    await File(picked.path).copy(target);
    return target;
  }
}
