import 'package:gallery_saver/gallery_saver.dart';

class SaveToGallery {
  Future<void> saveImage(String img) async {
    GallerySaver.saveImage(img);
  }
}
