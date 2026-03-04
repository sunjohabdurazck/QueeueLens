// lib/core/utils/device_utils.dart (NEW)
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceUtils {
  static const _keyDeviceId = 'temp_user_key';

  /// Get or create a persistent device-based user key
  static Future<String> getTempUserKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_keyDeviceId);

    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }

    // Generate new device ID
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = 'ios_${iosInfo.identifierForVendor ?? const Uuid().v4()}';
      } else {
        deviceId = 'device_${const Uuid().v4()}';
      }
    } catch (e) {
      // Fallback to UUID
      deviceId = 'device_${const Uuid().v4()}';
    }

    await prefs.setString(_keyDeviceId, deviceId);
    return deviceId;
  }

  /// Clear device ID (useful for testing)
  static Future<void> clearTempUserKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeviceId);
  }
}
