import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import '/helpers/shizuku_helper.dart';
import '/helpers/storage_helper.dart';
import 'package:flutter/foundation.dart';

class DownloadManagerHelper {
  static Future<bool> handleDownloadAndInstall(String url) async {
    Directory? tempDir;
    File? downloadedFile;

    try {
      // === 0️⃣ Tentukan package Mobile Legends yang benar-benar terinstal ===
      String? realPackage;
      if (await StorageHelper.isAppInstalled('com.mobile.legends')) {
        realPackage = 'com.mobile.legends';
      } else if (await StorageHelper.isAppInstalled('com.mobile.legends.hwag')) {
        realPackage = 'com.mobile.legends.hwag';
      }

      if (realPackage == null) {
        debugPrint('❌ Tidak ada Mobile Legends terinstal!');
        return false;
      }

      debugPrint('🎯 Package target terdeteksi: $realPackage');

      // === 1️⃣ Direktori sementara di external storage milik app sendiri ===
      tempDir = await getExternalStorageDirectory();
      if (tempDir == null) {
        debugPrint('❌ Tidak bisa dapatkan external storage dir');
        return false;
      }

      final tmpFolder = Directory('${tempDir.path}/tmp');
      if (!await tmpFolder.exists()) {
        await tmpFolder.create(recursive: true);
      }

      final tmpPath = '${tmpFolder.path}/tmp_download.zip';
      downloadedFile = File(tmpPath);
      if (await downloadedFile.exists()) await downloadedFile.delete();

      // === 2️⃣ Download file zip ===
      debugPrint('⬇️ Mulai download dari: $url');
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 60));

      debugPrint('Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('❌ Gagal download: ${response.statusCode}');
        return false;
      }

      await downloadedFile.writeAsBytes(response.bodyBytes);
      debugPrint('✅ File tersimpan di: ${downloadedFile.path}');

      // === 3️⃣ Ekstrak zip ke folder extracted ===
      final extractDir = Directory('${tmpFolder.path}/extracted');
      if (await extractDir.exists()) await extractDir.delete(recursive: true);
      await extractDir.create(recursive: true);

      debugPrint('📦 Ekstraksi...');
      final inputStream = InputFileStream(downloadedFile.path);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      for (final file in archive) {
        final filename = '${extractDir.path}/${file.name}';
        if (file.isFile) {
          final outFile = File(filename);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filename).create(recursive: true);
        }
      }
      debugPrint('✅ Ekstrak selesai di: ${extractDir.path}');

      // === 4️⃣ Pindahkan hasil ke folder package yang terdeteksi ===
      final targetPath = '/storage/emulated/0/Android/data/$realPackage';
      bool moved = false;

      try {
        final targetDir = Directory(targetPath);
        if (await targetDir.exists()) {
          await _copyDirectory(extractDir, targetDir);
          debugPrint('✅ Move langsung berhasil ke $targetPath');
          moved = true;
        } else {
          debugPrint('⚠️ Target folder tidak ditemukan: $targetPath');
        }
      } catch (e) {
        debugPrint('❌ Move langsung gagal: $e');
      }

      // === 4b. SAF fallback ===
      if (!moved) {
        final uri = await StorageHelper.getSavedTreeUri();
        if (uri != null) {
          debugPrint('Coba move via SAF: $uri');
          final success = await StorageHelper.copyDirectoryToSAF(extractDir.path, uri);
          if (success) {
            debugPrint('✅ Move via SAF berhasil');
            moved = true;
          } else {
            debugPrint('❌ Move via SAF gagal');
          }
        }
      }

      // === 4c. Shizuku fallback ===
      if (!moved) {
        debugPrint('Coba move via Shizuku...');
        final shizukuOk = await ShizukuHelper.ensurePermission();
        if (shizukuOk) {
          final cmd = 'cp -r "${extractDir.path}/." "$targetPath/"';
          final res = await ShizukuHelper.exec(cmd);
          debugPrint('Hasil Shizuku exec: $res');
          moved = true;
        } else {
          debugPrint('❌ Shizuku tidak aktif / izin ditolak');
        }
      }

      // === 5️⃣ Bersihkan temporary files ===
      await _cleanupTemp(tmpFolder);
      debugPrint('🧹 Bersihkan file sementara selesai');

      return moved;
    } catch (e) {
      debugPrint('❌ Error di handleDownloadAndInstall: $e');
      try {
        if (tempDir != null) await _cleanupTemp(tempDir);
      } catch (_) {}
      return false;
    }
  }

  // Rekursif copy directory
  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDir = Directory('${destination.path}/${entity.uri.pathSegments.last}');
        await newDir.create(recursive: true);
        await _copyDirectory(entity.absolute, newDir);
      } else if (entity is File) {
        final newFile = File('${destination.path}/${entity.uri.pathSegments.last}');
        await newFile.writeAsBytes(await entity.readAsBytes());
      }
    }
  }

  // Bersihkan folder sementara
  static Future<void> _cleanupTemp(Directory tempDir) async {
    try {
      if (await tempDir.exists()) {
        for (final file in tempDir.listSync()) {
          try {
            if (file is File) await file.delete();
            else if (file is Directory) await file.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}