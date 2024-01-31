import 'dart:io';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

Future<ui.Image?> imageFromFile(XFile xFile) async {
  final bytes = await File(xFile.path).readAsBytes();

  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();

  return frame.image;
}
