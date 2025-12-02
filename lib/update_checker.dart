import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static Future<void> checkForUpdate(BuildContext context) async {
    const jsonUrl = "https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Json/app_update.json"; // Ganti URL JSON kamu

    /// Fetch JSON
    final response = await http.get(Uri.parse(jsonUrl));
    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body);

    final latestVersion = data["latest_version"];
    final forceUpdate = data["force_update"];
    final updateUrl = data["update_url"];

    /// Ambil versi aplikasi saat ini
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    /// Bandingkan versi
    if (_isNewVersionAvailable(currentVersion, latestVersion)) {
      _showUpdateDialog(context, updateUrl, forceUpdate);
    }
  }

  /// Bandingkan versi: 1.0.1 < 1.0.2
  static bool _isNewVersionAvailable(String current, String latest) {
    final c = current.split('.').map(int.parse).toList();
    final l = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < l.length; i++) {
      if (c[i] < l[i]) return true;
      if (c[i] > l[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
      BuildContext context, String url, bool force) {
    showDialog(
      barrierDismissible: !force, // Tidak bisa ditutup kalau force update
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Tersedia"),
          content: const Text("Versi terbaru aplikasi sudah tersedia. Silakan update untuk melanjutkan."),
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Nanti"),
              ),
            TextButton(
              onPressed: () async {
                if (await canLaunchUrl(Uri.parse(url))) {
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}