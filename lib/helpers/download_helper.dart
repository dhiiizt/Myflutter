import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '/helpers/storage_helper.dart';

class DownloadHelper {
  static const _channel = MethodChannel('com.example.getapp/native');

  /// ===============================
  /// DOWNLOAD FILE DENGAN PROGRESS
  /// ===============================
  static Future<File?> downloadFile(
    String url, {
    String filename = 'download.zip',
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return null;

      final file = File('${dir.path}/$filename');
      if (await file.exists()) await file.delete();

      final request = await http.Client().send(http.Request('GET', Uri.parse(url)));
      final total = request.contentLength ?? 0;
      int received = 0;

      final sink = file.openWrite();
      await for (final chunk in request.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (onProgress != null && total > 0) {
          onProgress(received / total);
        }
      }
      await sink.close();
      return file;
    } catch (e) {
      debugPrint('❌ Download error: $e');
      return null;
    }
  }

  /// ===============================
  /// EKSTRAK ZIP
  /// ===============================
  static Future<Directory?> extractZip(String zipPath) async {
    try {
      final file = File(zipPath);
      final outputDir = Directory(zipPath.replaceAll('.zip', ''));
      if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final entry in archive) {
        final outPath = '${outputDir.path}/${entry.name}';
        if (entry.isFile) {
          final outFile = File(outPath);
          outFile.createSync(recursive: true);
          await outFile.writeAsBytes(entry.content as List<int>);
        } else {
          Directory(outPath).createSync(recursive: true);
        }
      }

      return outputDir;
    } catch (e) {
      debugPrint('❌ Extract error: $e');
      return null;
    }
  }

  /// ===============================
  /// DAPATKAN VERSI ANDROID
  /// ===============================
  static Future<int> _getAndroidVersion() async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt ?? 30;
  }

  /// ===============================
  /// CEK PACKAGE ML TERINSTALL
  /// ===============================
  static Future<String?> _getInstalledMLPackage() async {
    try {
      final ml = await _channel.invokeMethod<bool>('isAppInstalled', {'package': 'com.mobile.legends'});
      if (ml == true) return 'com.mobile.legends';

      final hwag = await _channel.invokeMethod<bool>('isAppInstalled', {'package': 'com.mobile.legends.hwag'});
      if (hwag == true) return 'com.mobile.legends.hwag';

      return null;
    } catch (_) {
      return null;
    }
  }

  /// ===============================
  /// SALIN KE MOBILE LEGENDS (Normal → SAF → Shizuku)
  /// ===============================
  static Future<bool> smartCopyToML(Directory sourceDir) async {
    final androidVer = await _getAndroidVersion();
    final pkg = await _getInstalledMLPackage();
    if (pkg == null) {
      debugPrint('⚠️ Tidak ada package ML terinstal');
      return false;
    }

    final targetPath = '/storage/emulated/0/Android/data/$pkg/files/';
    debugPrint('🎯 Target: $targetPath (SDK: $androidVer)');

    // 1️⃣ Android ≤ 10 → normal copy
    if (androidVer <= 29) {
      try {
        await _copyDirNormal(sourceDir, Directory(targetPath));
        debugPrint('✅ Normal copy berhasil');
        return true;
      } catch (e) {
        debugPrint('❌ Normal copy gagal: $e');
      }
    }

    // 2️⃣ Android ≥ 11 → SAF
    try {
      final treeUri = await StorageHelper.getSavedTreeUri();
if (treeUri != null) {
  debugPrint('🔐 Menyalin via SAF...');
  final ok = await StorageHelper.copyDirectoryToSAF(sourceDir.path, treeUri);
  if (ok) {
    debugPrint('✅ SAF copy berhasil');
    return true;
  } else {
    debugPrint('❌ SAF copy gagal');
  }
} else {
  debugPrint('⚠️ Tidak ada SAF URI tersimpan, lanjut ke Shizuku...');
}
    } catch (e) {
      debugPrint('❌ SAF error: $e');
    }

    // 3️⃣ Shizuku fallback
    try {
  final available = await _channel.invokeMethod<bool>('isShizukuAvailable') ?? false;
  if (available) {
    var granted = await _channel.invokeMethod<bool>('hasShizukuPermission') ?? false;
    if (!granted) {
      await _channel.invokeMethod('requestShizukuPermission');
      granted = await _channel.invokeMethod<bool>('hasShizukuPermission') ?? false;
    }

    if (granted) {
      // Target langsung ke Android/data/<package>/ tanpa masuk ke 'files/'
      final targetPath = '/storage/emulated/0/Android/data/$pkg/'; 
      final cmd = 'cp -r "${sourceDir.path}/." "$targetPath"';
      final output = await _channel.invokeMethod<String>(
        'execShizukuCommand', 
        {'cmd': cmd}
      );
      debugPrint('🚀 Shizuku output: $output');
      return true;
    } else {
      debugPrint('❌ Izin Shizuku ditolak');
    }
  } else {
    debugPrint('❌ Shizuku tidak tersedia');
  }
} catch (e) {
  debugPrint('❌ Shizuku error: $e');
}

debugPrint('⚠️ Semua metode gagal');
return false;
  }

  /// ===============================
  /// COPY NORMAL TANPA SAF
  /// ===============================
  static Future<void> _copyDirNormal(Directory source, Directory target) async {
    if (!target.existsSync()) target.createSync(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        await _copyDirNormal(
          entity,
          Directory('${target.path}/${entity.uri.pathSegments.last}'),
        );
      } else if (entity is File) {
        final newFile = File('${target.path}/${entity.uri.pathSegments.last}');
        newFile.createSync(recursive: true);
        await newFile.writeAsBytes(await entity.readAsBytes());
      }
    }
  }
}