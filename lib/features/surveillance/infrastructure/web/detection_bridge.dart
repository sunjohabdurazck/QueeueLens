abstract class DetectionBridge {
  Future<void> ready();
  Future<Object?> loadModel();
  Future<List<Map<String, dynamic>>> detect(
    Object? model,
    dynamic videoElement,
  );
}
