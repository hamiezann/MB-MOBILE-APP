import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  PermissionStatus status;

  if (await Permission.storage.isGranted) {
    return; // already granted
  }

  if (await Permission.photos.isDenied ||
      await Permission.photos.isPermanentlyDenied) {
    status = await Permission.photos.request();
  } else {
    status = await Permission.storage.request();
  }

  if (status.isGranted) {
    print("Permission granted.");
  } else {
    print("Permission denied.");
  }
}
