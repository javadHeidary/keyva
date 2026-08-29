import 'package:flutter_test/flutter_test.dart';
import 'package:keyva/feature/type/image/service/image_gallery_export_service.dart';
import 'package:keyva/feature/type/image/util/image_gallery_export_ui.dart';

void main() {
  test('builds progress copy with latin digits for FaNum', () {
    expect(
      galleryExportProgressMessage(3, 10),
      'در حال ذخیره تصاویر... 3 از 10',
    );
  });

  test('summarizes all, partial, and zero saves', () {
    expect(
      folderGalleryExportSummary(
        const ImageGalleryFolderExportResult(saved: 10, total: 10),
      ),
      '10 تصویر با موفقیت در گالری ذخیره شد.',
    );
    expect(
      folderGalleryExportSummary(
        const ImageGalleryFolderExportResult(saved: 8, total: 10),
      ),
      '8 تصویر از 10 تصویر در گالری ذخیره شدند.',
    );
    expect(
      folderGalleryExportSummary(
        const ImageGalleryFolderExportResult(saved: 0, total: 10),
      ),
      'ذخیره تصاویر در گالری انجام نشد.',
    );
  });
}
