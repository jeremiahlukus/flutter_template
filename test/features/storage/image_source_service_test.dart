// The image-preparation contract: downscale, re-encode, and never lose the
// upload to a compression failure.
//
// 0019-R4/R5/R6 previously cited the constants by name, which proved they
// existed but not that anything used them. A recording picker closes that gap.
import 'dart:typed_data';

import 'package:flutter_template/src/features/storage/image_source_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

/// Captures the constraints `pickImage` asks the platform for.
class _RecordingPicker extends ImagePicker {
  double? maxWidth;
  double? maxHeight;
  int? imageQuality;
  ImageSource? source;

  /// Bytes the picker "returns". Null models the user cancelling.
  Uint8List? bytes = Uint8List.fromList(const [1, 2, 3, 4]);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;
    this.imageQuality = imageQuality;
    if (bytes == null) return null;
    return XFile.fromData(bytes!, name: 'avatar.jpg');
  }
}

void main() {
  group('downscaling before upload', () {
    test('asks the picker for at most maxDimension on both edges', () async {
      final picker = _RecordingPicker();
      await PlatformImageSourceService(picker).pickImage(ImageOrigin.gallery);

      expect(picker.maxWidth, PlatformImageSourceService.maxDimension);
      expect(picker.maxHeight, PlatformImageSourceService.maxDimension);
    });

    test('maxDimension covers a 4x display without being wasteful', () {
      // Avatars render at 80dp. Below 320 they blur on a 4x screen; far above
      // it, the bytes are spent on pixels nobody sees.
      expect(
        PlatformImageSourceService.maxDimension,
        inInclusiveRange(320, 1024),
      );
    });
  });

  group('re-encoding as JPEG', () {
    test('asks the picker for the fixed JPEG quality', () async {
      final picker = _RecordingPicker();
      await PlatformImageSourceService(picker).pickImage(ImageOrigin.camera);

      expect(picker.imageQuality, PlatformImageSourceService.jpegQuality);
    });

    test(
      'the quality is lossy enough to save bytes, high enough to look right',
      () {
        expect(
          PlatformImageSourceService.jpegQuality,
          inInclusiveRange(70, 95),
        );
      },
    );
  });

  group('a compression failure never costs the upload', () {
    test('falls back to the original bytes', () async {
      // `FlutterImageCompress` reaches a platform channel, so in a unit test it
      // throws `MissingPluginException` — which is exactly the failure this
      // requirement is about. The bytes must survive it.
      final original = Uint8List.fromList(const [9, 8, 7, 6, 5]);

      expect(await PlatformImageSourceService.compress(original), original);
    });

    test('a cancelled pick returns null rather than empty bytes', () async {
      final picker = _RecordingPicker()..bytes = null;

      expect(
        await PlatformImageSourceService(picker).pickImage(ImageOrigin.gallery),
        isNull,
      );
    });

    test('the origin selects the matching platform source', () async {
      final picker = _RecordingPicker();
      final service = PlatformImageSourceService(picker);

      await service.pickImage(ImageOrigin.camera);
      expect(picker.source, ImageSource.camera);

      await service.pickImage(ImageOrigin.gallery);
      expect(picker.source, ImageSource.gallery);
    });
  });
}
