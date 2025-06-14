import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class AudioCacheHelper {
  static Future<String> getLocalFilePath(String audioUrl) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = Uri.parse(audioUrl).pathSegments.last;
    return "${dir.path}/$fileName";
  }

  static Future<File> downloadAndCacheAudio(String audioUrl) async {
    final filePath = await getLocalFilePath(audioUrl);
    final file = File(filePath);

    if (!await file.exists()) {
      final dio = Dio();
      await dio.download(audioUrl, filePath);
    }

    return file;
  }

  static Future<void> clearAllCachedAudio() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = Directory(dir.path).listSync();
    for (var file in files) {
      if (file.path.endsWith(".mp3") || file.path.endsWith(".m4a")) {
        await File(file.path).delete();
      }
    }
  }
}
