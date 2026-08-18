import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ImageExportService {
  static Future<void> shareFile(File file, {String? text}) async {
    final xFile = XFile(file.path);
    // ignore: deprecated_member_use
    await Share.shareXFiles([xFile], text: text ?? 'Check out our catalog!');
  }
}
