import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/src/core/logging/app_logger.dart';
import 'package:image_picker/image_picker.dart';

/// Where an image came from.
enum ImageOrigin { camera, gallery }

/// Picks and prepares an image for upload.
///
/// An interface because `image_picker` reaches a platform channel and cannot run
/// in a widget test, and because "the user cancelled" must be a first-class
/// result rather than an exception — cancelling a picker is normal, not a
/// failure.
//
// One member today, but the seam is the point: a fork will add
// `pickMultiple` or `pickVideo` here, and a top-level function cannot be
// swapped out by a provider override.
// ignore: one_member_abstracts
abstract interface class ImageSourceService {
  /// Returns compressed JPEG bytes, or null if the user cancelled.
  Future<Uint8List?> pickImage(ImageOrigin origin);
}

class PlatformImageSourceService implements ImageSourceService {
  const PlatformImageSourceService(this._picker);

  final ImagePicker _picker;

  /// Avatars are displayed at 80dp; 512px covers a 4x display with headroom.
  ///
  /// Downscaling *before* compression is what actually saves bandwidth — a 12MP
  /// phone photo is ~4MB even at high JPEG compression.
  static const maxDimension = 512;

  /// 85 is the usual sweet spot: visually indistinguishable from 100 at this
  /// size, roughly a third of the bytes.
  static const jpegQuality = 85;

  @override
  Future<Uint8List?> pickImage(ImageOrigin origin) async {
    final file = await _picker.pickImage(
      source: switch (origin) {
        ImageOrigin.camera => ImageSource.camera,
        ImageOrigin.gallery => ImageSource.gallery,
      },
      maxWidth: maxDimension.toDouble(),
      maxHeight: maxDimension.toDouble(),
      imageQuality: jpegQuality,
      requestFullMetadata: false,
    );

    // Null means cancelled, which is not an error.
    if (file == null) return null;

    final raw = await file.readAsBytes();
    return compress(raw);
  }

  /// Re-encodes to JPEG at [jpegQuality].
  ///
  /// `image_picker`'s own `imageQuality` is ignored on some platforms, so this
  /// runs unconditionally rather than trusting it. A compression failure returns
  /// the original bytes: a larger upload beats no upload.
  @visibleForTesting
  static Future<Uint8List> compress(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: jpegQuality,
      );
      return result.isEmpty ? bytes : result;
    } catch (error) {
      AppLogger.instance.w('Image compression failed; uploading raw: $error');
      return bytes;
    }
  }
}

/// Returns scripted bytes. Used by tests and by the placeholder avatar flow.
@visibleForTesting
class FakeImageSourceService implements ImageSourceService {
  FakeImageSourceService({this.result, this.throwOnPick = false});

  /// Bytes to return. Null models the user cancelling.
  Uint8List? result;

  bool throwOnPick;

  final picked = <ImageOrigin>[];

  @override
  Future<Uint8List?> pickImage(ImageOrigin origin) async {
    picked.add(origin);
    if (throwOnPick) throw const ImagePickFailure('injected');
    return result;
  }
}

/// A picker that could not read the chosen image.
class ImagePickFailure implements Exception {
  const ImagePickFailure(this.message);

  final String message;

  @override
  String toString() => 'ImagePickFailure: $message';
}

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final imageSourceServiceProvider = Provider<ImageSourceService>(
  (ref) => PlatformImageSourceService(ref.watch(imagePickerProvider)),
);
