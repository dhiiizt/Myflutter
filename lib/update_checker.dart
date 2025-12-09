import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static Future<void> checkForUpdate(
    BuildContext context,
    VoidCallback onDone, // callback setelah selesai cek update
  ) async {
    const jsonUrl =
        "https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Json/app_update.json";

    final response = await http.get(Uri.parse(jsonUrl));
    if (response.statusCode != 200) {
      onDone(); // lanjut meskipun gagal fetch
      return;
    }

    final data = jsonDecode(response.body);

    final latestVersion = data["latest_version"];
    final forceUpdate = data["force_update"];
    final updateUrl = data["update_url"];

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    if (_isNewVersionAvailable(currentVersion, latestVersion)) {
      _showUpdateDialog(context, updateUrl, forceUpdate, onDone);
    } else {
      onDone(); // tidak ada update → lanjut
    }
  }

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
    BuildContext context,
    String url,
    bool force,
    VoidCallback onDone,
  ) {
    showDialog(
      barrierDismissible: !force,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Available"),
          content: const Text(
            "A new version of the app is available. Please update to continue.",
          ),
          actions: [
            if (!force)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDone(); // lanjut cek permission setelah dialog ditutup
                },
                child: const Text("Later"),
              ),
            TextButton(
              onPressed: () async {
                if (await canLaunchUrl(Uri.parse(url))) {
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
                // NOTE: untuk force update, onDone TIDAK dipanggil
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}