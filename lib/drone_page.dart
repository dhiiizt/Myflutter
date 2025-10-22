import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'helpers/download_manager_helper.dart';
import 'package:flutter/cupertino.dart';

class DronePage extends StatefulWidget {
  const DronePage({super.key});

  @override
  State<DronePage> createState() => _DronePageState();
}

class _DronePageState extends State<DronePage> {
  List<dynamic> droneItems = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    fetchDroneData();
  }

  Future<void> fetchDroneData() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
        'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Json/drone_data.json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          droneItems = json.decode(response.body);
        });
      } else {
        throw Exception('Gagal memuat data JSON (${response.statusCode})');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

// 🔹 Fungsi untuk menampilkan dialog loading modern (Cupertino style)
Future<void> _showProgressDialog() async {
  showCupertinoDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text(
          'Mohon tunggu...',
          style: TextStyle(
            fontFamily: 'Jost',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: const [
              CupertinoActivityIndicator(radius: 12),
              SizedBox(height: 16),
              Text(
                'Sedang mengunduh dan memproses file...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Jost',
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// 🔹 Fungsi untuk menutup dialog progress
void _hideProgressDialog() {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: const Color(0xFF2196F3), // 💙 Biru utama (Blue 500)
  onPrimary: Colors.white,
  secondary: const Color(0xFF64B5F6), // 💙 Biru muda (Blue 300)
  onSecondary: Colors.white,
  surface: Colors.white,
  onSurface: const Color(0xFF1A1A1A),
  surfaceContainerHighest: const Color(0xFFFFFFFF),
  background: const Color(0xFFF3F8FF), // 💙 Latar belakang biru lembut
  onBackground: const Color(0xFF333333),
  error: Colors.red.shade400,
  onError: Colors.white,
  primaryContainer: const Color(0xFFE3F2FD), // 💙 Biru pastel (soft background)
  onPrimaryContainer: const Color(0xFF0D47A1), // 💙 Biru tua untuk teks kontras
);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'List Drone',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'Jost',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : droneItems.isEmpty
              ? const Center(child: Text('Tidak ada data drone.'))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    itemCount: droneItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final item = droneItems[index];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 🔹 Gambar drone dengan fade + shimmer
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: item['image'] ?? '',
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  fadeInDuration:
                                      const Duration(milliseconds: 500),
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.broken_image, size: 50),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),                     
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                item['title'] ?? 'Tanpa judul',
                                style: const TextStyle(
                                  fontFamily: 'Jost',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Text(
                                item['description'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
  onPressed: () async {
    final url = item['downloadUrl'];
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL tidak ditemukan di data JSON!'),
        ),
      );
      return;
    }

    // 🔹 Tampilkan dialog konfirmasi bergaya iOS
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text(
          'Notice!',
          style: TextStyle(fontFamily: 'Jost', fontWeight: FontWeight.bold),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Apakah kamu ingin mengunduh dan memasang "${item['title']}"?',
            style: const TextStyle(fontFamily: 'Jost'),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Download',
              style: TextStyle(color: CupertinoColors.systemBlue),
            ),
          ),
        ],
      ),
    );

    // 🔹 Jika user tidak menekan "Ya", hentikan proses
    if (confirm != true) return;

    // 🔹 Tampilkan dialog loading
    await _showProgressDialog();

    final ok = await DownloadManagerHelper.handleDownloadAndInstall(url);

    // 🔹 Tutup dialog setelah selesai
    _hideProgressDialog();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '✅ Download & pasang berhasil!'
              : '❌ Gagal download atau pasang!',
        ),
      ),
    );
  },
  icon: const Icon(Icons.download),
  label: const Text('Download'),
),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}