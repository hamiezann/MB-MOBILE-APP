import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

Future<String> downloadAudioIfNeeded(String url, String filename) async {
  if (url.isEmpty) return '';

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');

  if (await file.exists()) return file.path;

  try {
    final ref = FirebaseStorage.instance.refFromURL(url);
    final data = await ref.getData();
    await file.writeAsBytes(data!);
    print("downloading ${file.path}");
    return file.path;
  } catch (e) {
    print('Failed to download $url: $e');
    return '';
  }
}
