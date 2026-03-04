import 'package:flutter/foundation.dart' show kIsWeb;
import '../domain/person_detector.dart';

// Conditional imports
import 'web/person_detector_web.dart'
    if (dart.library.html) 'web/person_detector_web.dart'
    if (dart.library.io) 'android/person_detector_tflite.dart';

class PersonDetectorFactory {
  static PersonDetector create() {
    if (kIsWeb) {
      return PersonDetectorWeb();
    } else {
      // For mobile, you'll need to create this file
      throw UnimplementedError('Mobile detector not implemented yet');
    }
  }
}
