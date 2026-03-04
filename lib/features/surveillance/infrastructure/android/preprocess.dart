import 'dart:typed_data';
import 'image_converter.dart';
import '../../domain/person_detector.dart';

/// Preprocess image for TFLite model input
Float32List preprocessImage(
  Uint8List imageData,
  int originalWidth,
  int originalHeight,
  int targetWidth,
  int targetHeight,
  ImageFormat format,
) {
  Uint8List rgbData;

  // Convert to RGB if needed
  if (format == ImageFormat.yuv420) {
    rgbData = yuv420ToRgb(imageData, originalWidth, originalHeight);
  } else {
    rgbData = imageData;
  }

  // Resize image
  final resizedData = resizeImage(
    rgbData,
    originalWidth,
    originalHeight,
    targetWidth,
    targetHeight,
  );

  // Normalize to [0,1] and convert to float32
  final floatData = Float32List(targetWidth * targetHeight * 3);
  for (int i = 0; i < resizedData.length; i++) {
    floatData[i] = resizedData[i] / 255.0;
  }

  // Return as a flat Float32List
  // The interpreter expects input as a List<List<...>> or directly
  return floatData;
}

Uint8List resizeImage(
  Uint8List input,
  int inWidth,
  int inHeight,
  int outWidth,
  int outHeight,
) {
  final output = Uint8List(outWidth * outHeight * 3);

  final xScale = inWidth / outWidth;
  final yScale = inHeight / outHeight;

  for (int y = 0; y < outHeight; y++) {
    for (int x = 0; x < outWidth; x++) {
      final srcX = (x * xScale).toInt().clamp(0, inWidth - 1);
      final srcY = (y * yScale).toInt().clamp(0, inHeight - 1);
      final srcIndex = (srcY * inWidth + srcX) * 3;
      final dstIndex = (y * outWidth + x) * 3;

      if (srcIndex + 2 < input.length && dstIndex + 2 < output.length) {
        output[dstIndex] = input[srcIndex];
        output[dstIndex + 1] = input[srcIndex + 1];
        output[dstIndex + 2] = input[srcIndex + 2];
      }
    }
  }

  return output;
}
