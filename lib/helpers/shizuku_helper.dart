import 'package:flutter/services.dart';

class ShizukuHelper {
static const MethodChannel _channel =
MethodChannel('com.example.getapp/native');

/// Mengecek apakah Shizuku tersedia di perangkat
static Future<bool> isAvailable() async {
try {
final result = await _channel.invokeMethod('isShizukuAvailable');
return result == true;
} catch (e) {
return false;
}
}

/// Mengecek apakah izin Shizuku sudah diberikan
static Future<bool> hasPermission() async {
try {
final result = await _channel.invokeMethod('hasShizukuPermission');
return result == true;
} catch (e) {
return false;
}
}

/// Meminta izin Shizuku (akan menampilkan dialog izin dari Shizuku)
static Future<bool> requestPermission() async {
try {
final result = await _channel.invokeMethod('requestShizukuPermission');
return result == true;
} catch (e) {
return false;
}
}

/// Menjalankan perintah shell melalui Shizuku
static Future<String> exec(String cmd) async {
try {
final result = await _channel.invokeMethod(
'execShizukuCommand',
{'cmd': cmd},
);
return result?.toString() ?? '';
} catch (e) {
return 'Error: $e';
}
}

/// Shortcut untuk memastikan Shizuku aktif + izin granted
static Future<bool> ensurePermission() async {
if (!await isAvailable()) {
return false;
}

if (await hasPermission()) {  
  return true;  
}  

return await requestPermission();

}
}


