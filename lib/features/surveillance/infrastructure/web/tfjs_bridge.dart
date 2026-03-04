// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

// Use conditional exports for web-specific code
// This file should only be imported in web context

class TfjsBridge {
  static Future<void> ready() async {
    if (!kIsWeb) return Future.value();

    // Wait for TFJS to be loaded
    while (!_isTfjsLoaded()) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static bool _isTfjsLoaded() {
    if (!kIsWeb) return false;

    try {
      // Use js_util only in web context
      // This requires dart:js_util import which is only available on web
      // We'll handle this with a separate web-only file
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<Object> loadCocoSsd() async {
    throw UnsupportedError('loadCocoSsd is only supported on web');
  }

  static Future<List<dynamic>> detect(Object model, dynamic video) async {
    throw UnsupportedError('detect is only supported on web');
  }
}
