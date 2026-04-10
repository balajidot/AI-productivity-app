import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

enum DevicePerformanceClass {
  low,
  mid,
  high,
}

class PerformanceService {
  static final DevicePerformanceClass deviceClass = _calculateDeviceClass();

  static DevicePerformanceClass _calculateDeviceClass() {
    // Default to mid for safety
    if (kIsWeb) return DevicePerformanceClass.mid;

    try {
      if (Platform.isAndroid) {
        // Simple logic for Android: 
        // In a real app, we'd check system memory (RAM), but Flutter doesn't expose it directly without a plugin.
        // For this demo, we can proxy it by OS version or specific model flags if needed.
        // However, we'll use a conservative default and allow the provider to refine it.
        return DevicePerformanceClass.mid; 
      }
      
      if (Platform.isIOS) {
        // Modern iPhones are generally high-performance
        return DevicePerformanceClass.high;
      }
    } catch (_) {}

    return DevicePerformanceClass.mid;
  }

  /// Estimates if the device should use 'Ultra Performance' mode.
  /// This can be refined by checking specific hardware identifiers.
  static Future<DevicePerformanceClass> getDetailedDeviceClass() async {
    final deviceInfo = DeviceInfoPlugin();
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // On Android, we can check the 'lowRamDevice' flag if available or SDK version
        final isLowRam = androidInfo.systemFeatures.contains('android.hardware.ram.low');
        final sdkInt = androidInfo.version.sdkInt;
        
        if (isLowRam || sdkInt < 29) { // Android 10 is our threshold for 'modern'
          return DevicePerformanceClass.low;
        }
        
        // Check for high-end chips (approximate)
        final hardware = androidInfo.hardware.toLowerCase();
        if (hardware.contains('snapdragon') || hardware.contains('exynos') || hardware.contains('tensor')) {
          return DevicePerformanceClass.high;
        }
      }
      
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final model = iosInfo.utsname.machine.toLowerCase();
        // iPhone 11 and above (iPhone12,1+) are high-end
        if (model.contains('iphone')) {
          final versionStr = model.replaceAll(RegExp(r'[^0-9,]'), '');
          final version = int.tryParse(versionStr.split(',')[0]) ?? 0;
          if (version >= 12) return DevicePerformanceClass.high;
          if (version < 10) return DevicePerformanceClass.low; // iPhone 8 and below
        }
      }
    } catch (e) {
      debugPrint('Performance detection error: $e');
    }

    return DevicePerformanceClass.mid;
  }
}
