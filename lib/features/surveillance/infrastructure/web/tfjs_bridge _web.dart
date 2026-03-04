// @dart=2.19
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;
import 'detection_bridge.dart';

class TfjsBridgeWeb implements DetectionBridge {
  @override
  Future<void> ready() async {
    if (!kIsWeb) return Future.value();

    while (!_isTfjsLoaded()) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  bool _isTfjsLoaded() {
    if (!kIsWeb) return false;

    try {
      // Check if cocoSsd exists in the global window object
      // Using bracket notation to check if property exists
      final cocoSsd = (web.window as dynamic)['cocoSsd'];
      final tf = (web.window as dynamic)['tf'];
      return cocoSsd != null && tf != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Object?> loadModel() async {
    if (!kIsWeb) return null;

    try {
      // Get cocoSsd from window using bracket notation
      final cocoSsd = (web.window as dynamic)['cocoSsd'];
      if (cocoSsd == null) {
        return null;
      }

      // Call load method which returns a Promise
      final promise = cocoSsd['load']();

      // Convert Promise to Future
      return await _promiseToFuture(promise);
    } catch (e) {
      // In production, use a proper logging framework
      // For now, we'll keep print but consider replacing
      // ignore: avoid_print
      print('Error loading model: $e');
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> detect(
    Object? model,
    dynamic videoElement,
  ) async {
    if (!kIsWeb || model == null || videoElement == null) return [];

    try {
      // Call detect method which returns a Promise
      final promise = (model as dynamic)['detect'](videoElement);

      // Convert Promise to Future and process predictions
      final predictions = await _promiseToFuture(promise);
      return _convertPredictions(predictions);
    } catch (e) {
      // ignore: avoid_print
      print('Error during detection: $e');
      return [];
    }
  }

  // Helper to convert Promise to Future
  Future<T> _promiseToFuture<T>(dynamic promise) {
    final completer = Completer<T>();

    try {
      if (promise == null) {
        completer.completeError('Promise is null');
        return completer.future;
      }

      // Add then handler
      promise['then']((dynamic value) {
        if (!completer.isCompleted) {
          completer.complete(value as T);
        }
      });

      // Add catch handler
      promise['catch']((dynamic error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }

    return completer.future;
  }

  List<Map<String, dynamic>> _convertPredictions(dynamic predictions) {
    final List<Map<String, dynamic>> result = [];

    try {
      if (predictions == null) return result;

      // Check if it's an array by looking for length property
      final length = predictions['length'];
      if (length is num) {
        for (int i = 0; i < length; i++) {
          final pred = predictions[i];
          if (pred != null) {
            result.add(_extractPrediction(pred));
          }
        }
      }
    } catch (e) {
      // If conversion fails, return empty list
    }

    return result;
  }

  Map<String, dynamic> _extractPrediction(dynamic pred) {
    return {
      'bbox': _getArrayProperty(pred, 'bbox', [0, 0, 0, 0]),
      'class': _getStringProperty(pred, 'class', ''),
      'score': _getNumberProperty(pred, 'score', 0.0),
    };
  }

  List<dynamic> _getArrayProperty(
      dynamic obj, String prop, List<dynamic> defaultValue) {
    try {
      final value = obj[prop];
      if (value == null) return defaultValue;

      final List<dynamic> list = [];
      final length = value['length'];
      if (length is num) {
        for (int i = 0; i < length; i++) {
          list.add(value[i]);
        }
      }
      return list;
    } catch (_) {
      return defaultValue;
    }
  }

  String _getStringProperty(dynamic obj, String prop, String defaultValue) {
    try {
      final value = obj[prop];
      return value?.toString() ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  double _getNumberProperty(dynamic obj, String prop, double defaultValue) {
    try {
      final value = obj[prop];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }
}
