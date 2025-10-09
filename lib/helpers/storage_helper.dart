import 'package:flutter/services.dart';

class StorageHelper {
  static const _channel = MethodChannel('com.example.my_app/native');

  static Future<bool> isAppInstalled(String packageName) async {
    try {
      final bool installed = await _channel.invokeMethod('isAppInstalled', {'package': packageName});
      return installed;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> pickTreeAndSave({String? packageName}) async {
    try {
      final uri = await _channel.invokeMethod('openDocumentTreeForPackage', {'package': packageName});
      if (uri is String && uri.isNotEmpty) return uri;
      return null; // cancel atau URI invalid
    } on PlatformException {
      return null;
    }
  }

  static Future<String?> getSavedTreeUri() async {
    try {
      final uri = await _channel.invokeMethod('getSavedTreeUri');
      if (uri is String && uri.isNotEmpty) return uri;
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearSavedTreeUri() async {
    try {
      await _channel.invokeMethod('clearSavedTreeUri');
    } catch (e) {}
  }
}