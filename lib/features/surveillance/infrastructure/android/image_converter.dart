import 'dart:typed_data';

/// Convert YUV420 image to RGB for model input
Uint8List yuv420ToRgb(Uint8List yuvData, int width, int height) {
  final rgbData = Uint8List(width * height * 3);

  int yIndex = 0;
  int uIndex = width * height;
  int vIndex = uIndex + (width * height ~/ 4);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final yPixel = yuvData[yIndex];

      // Calculate UV indices (4:2:0 subsampling)
      final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);
      final u = yuvData[uIndex + uvIndex];
      final v = yuvData[vIndex + uvIndex];

      // Convert YUV to RGB
      final r = (yPixel + 1.402 * (v - 128)).clamp(0, 255).toInt();
      final g = (yPixel - 0.344136 * (u - 128) - 0.714136 * (v - 128))
          .clamp(0, 255)
          .toInt();
      final b = (yPixel + 1.772 * (u - 128)).clamp(0, 255).toInt();

      final rgbIndex = (y * width + x) * 3;
      rgbData[rgbIndex] = r;
      rgbData[rgbIndex + 1] = g;
      rgbData[rgbIndex + 2] = b;

      yIndex++;
    }
  }

  return rgbData;
}
