import 'package:flutter/services.dart';

class IntegrityService {
  static const _channel = MethodChannel('com.yarzo.zeno/integrity');
  
  static Future<bool> verifyApp() async {
    try {
      final result = await _channel.invokeMethod<bool>('verify');
      return result ?? false;
    } catch (_) {
      return true; // fail open in debug
    }
  }
}
