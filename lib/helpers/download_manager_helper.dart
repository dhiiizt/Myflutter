import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import '/helpers/shizuku_helper.dart';
import '/helpers/storage_helper.dart';

class DownloadManagerHelper {
  /// Unduh ZIP, ekstrak, dan pasang otomatis ke folder Mobile Legends.
  /// 
  /// [onProgress] memberikan update (stage, progress):
  /// - stage = "download" / "extract" / "move"
  /// - progress = 0.0–1.0
  static Future<bool> handleDownloadAndInstall(
    String url, {
    void Function(String stage, double progress)? onProgress,
  }) async {
    Directory? tempDir;
    File? downloadedFile;

    try {
      // === 0️⃣ Tentukan package Mobile Legends yang benar-benar terinstal ===
String? realPackage;

// Daftar lengkap MLBB
final mlPackages = [
  // Resmi Global
  'com.mobile.legends',

  // Huawei AppGallery
  'com.mobile.legends.hwag',

  // Vietnam (VNG)
  'com.vng.mlbbvn',

  // USA Region
  'com.mobile.legends.usa',

  // India/Alternatif Global (mobiin)
  'com.mobiin.gp',

  // Xiaomi GetApps (OEM)
  'com.mobilelegends.mi',

];

for (final pkg in mlPackages) {
  if (await StorageHelper.isAppInstalled(pkg)) {
    realPackage = pkg;
    break;
  }
}

if (realPackage == null) {
  debugPrint('❌ Tidak ada Mobile Legends terinstal!');
  return false;
}

debugPrint("✅ Mobile Legends ditemukan: $realPackage");

      // === 1️⃣ Siapkan direktori sementara ===
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

      // === 2️⃣ Download file ZIP dengan progress ===
      debugPrint('⬇️ Mulai download dari: $url');
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      final total = response.contentLength ?? 0;
      int received = 0;

      final sink = downloadedFile.openWrite();
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (onProgress != null && total > 0) {
          onProgress('download', received / total);
        }
      }
      await sink.close();
      debugPrint('✅ File tersimpan di: ${downloadedFile.path}');

      // === 3️⃣ Ekstrak ZIP dengan progress ===
      final extractDir = Directory('${tmpFolder.path}/extracted');
      if (await extractDir.exists()) await extractDir.delete(recursive: true);
      await extractDir.create(recursive: true);

      debugPrint('📦 Ekstraksi...');
      final inputStream = InputFileStream(downloadedFile.path);
      final archive = ZipDecoder().decodeStream(inputStream);

      int extracted = 0;
      for (final file in archive) {
        final filename = '${extractDir.path}/${file.name}';
        if (file.isFile) {
          final outFile = File(filename);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filename).create(recursive: true);
        }

        extracted++;
        if (onProgress != null) {
          onProgress('extract', extracted / archive.length);
        }
      }
      debugPrint('✅ Ekstrak selesai di: ${extractDir.path}');

      // === 4️⃣ Pindahkan hasil ke folder package ===
      final targetPath = '/storage/emulated/0/Android/data/$realPackage/files/dragon2017/assets';
      bool moved = false;

      // 4a. Normal copy (Android 10 kebawah)
      try {
        final targetDir = Directory(targetPath);
        if (await targetDir.exists()) {
          if (onProgress != null) onProgress('move', 0.0);
          await _copyDirectoryWithProgress(extractDir, targetDir,
              (p) => onProgress?.call('move', p));
          if (onProgress != null) onProgress('move', 1.0);
          debugPrint('✅ Move langsung berhasil ke $targetPath');
          moved = true;
        } else {
          debugPrint('⚠️ Target folder tidak ditemukan: $targetPath');
        }
      } catch (e) {
        debugPrint('❌ Move langsung gagal: $e');
      }
      
      // 4c. Shizuku fallback (shizuku permission)
      if (!moved) {
        debugPrint('Coba move via Shizuku...');
        final shizukuOk = await ShizukuHelper.ensurePermission();
        if (shizukuOk) {
          onProgress?.call('move', 0.0);
          final cmd = 'cp -r "${extractDir.path}/." "$targetPath/"';
          final res = await ShizukuHelper.exec(cmd);
          debugPrint('Hasil Shizuku exec: $res');
          onProgress?.call('move', 1.0);
          moved = true;
        } else {
          debugPrint('❌ Shizuku tidak aktif / izin ditolak');
        }
      }

      // 4b. SAF fallback (Android 11+)
        if (!moved) {
          final uri = await StorageHelper.getSavedTreeUri();
          if (uri != null) {
            debugPrint('Coba move via SAF: $uri');
        
            // hubungkan event SAF ke callback utama
            StorageHelper.setMoveProgressListener((progress) {
              onProgress?.call('move', progress);
            });
        
            onProgress?.call('move', 0.0);
            final success =
                await StorageHelper.copyDirectoryToSAF(extractDir.path, uri);
        
            // hapus listener biar gak nyangkut
            StorageHelper.setMoveProgressListener(null);
        
            if (success) {
              onProgress?.call('move', 1.0);
              debugPrint('✅ Move via SAF berhasil');
              moved = true;
            } else {
              debugPrint('❌ Move via SAF gagal');
            }
          }
        }

      // === 5️⃣ Bersihkan file sementara ===
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

  /// Rekursif copy directory dengan callback progress
  static Future<void> _copyDirectoryWithProgress(
  Directory source,
  Directory destination,
  void Function(double progress)? onProgress,
) async {
  final entities = source.listSync(recursive: true);
  int copied = 0;

  for (final entity in entities) {
    final relativePath = entity.path.substring(source.path.length + 1);
    final newPath = '${destination.path}/$relativePath';

    if (entity is Directory) {
      await Directory(newPath).create(recursive: true);
    } else if (entity is File) {
      final newFile = File(newPath);
      await newFile.create(recursive: true);

      // 🧠 Pindahkan operasi tulis ke isolate
      await compute(_copyFileCompute, {
        'source': entity.path,
        'dest': newFile.path,
      });
    }

    copied++;
    if (onProgress != null) {
      onProgress(copied / entities.length);
    }

    // beri jeda kecil supaya UI bisa update
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

/// Fungsi helper untuk dijalankan di isolate
static Future<void> _copyFileCompute(Map<String, String> paths) async {
  final src = File(paths['source']!);
  final dst = File(paths['dest']!);
  await dst.writeAsBytes(await src.readAsBytes());
}

  /// Bersihkan folder sementara
  static Future<void> _cleanupTemp(Directory tempDir) async {
    try {
      if (await tempDir.exists()) {
        for (final file in tempDir.listSync()) {
          try {
            if (file is File) {
              await file.delete();
            } else if (file is Directory) {
              await file.delete(recursive: true);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}