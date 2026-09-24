// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final iconFile = File('assets/icons/app_icon.png');
  if (!iconFile.existsSync()) {
    print('Source icon not found at ${iconFile.path}');
    exit(1);
  }

  final imageBytes = iconFile.readAsBytesSync();
  final image = img.decodeImage(imageBytes);

  if (image == null) {
    print('Failed to decode image');
    exit(1);
  }

  final sizes = {
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };

  for (final entry in sizes.entries) {
    final targetPath = entry.key;
    final size = entry.value;
    final resized = img.copyResize(image, width: size, height: size, interpolation: img.Interpolation.cubic);
    final targetFile = File(targetPath);
    targetFile.parent.createSync(recursive: true);
    targetFile.writeAsBytesSync(img.encodePng(resized));
    print('Generated $targetPath ($size x $size)');
  }

  print('Successfully generated all Android app launcher icons!');
}
