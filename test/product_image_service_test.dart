import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner/core/services/product_image_service.dart';

void main() {
  test('recognises permanent vs temporary paths', () {
    expect(
      ProductImageService.isPersisted('/data/user/0/app/app_flutter/product_images/a.jpg'),
      isTrue,
    );
    expect(
      ProductImageService.isPersisted(r'C:\app\documents\product_images\a.jpg'),
      isTrue,
    );
    // The image_picker cache path that used to be stored in the database.
    expect(
      ProductImageService.isPersisted('/data/user/0/app/cache/image_picker_123.jpg'),
      isFalse,
    );
  });

  test('isMissing only flags recorded paths whose file is gone', () {
    expect(ProductImageService.isMissing(null), isFalse);
    expect(ProductImageService.isMissing('   '), isFalse);
    expect(ProductImageService.isMissing('/no/such/file.jpg'), isTrue);
  });

  test('repairIfNeeded is a no-op for already-persisted and vanished files',
      () async {
    expect(
      await ProductImageService.repairIfNeeded('/app/product_images/a.jpg'),
      isNull,
    );
    expect(await ProductImageService.repairIfNeeded('/cache/gone.jpg'), isNull);
    expect(await ProductImageService.repairIfNeeded(null), isNull);
  });
}
