import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
<<<<<<< HEAD
import 'helpers/storage_helper.dart';
import 'helpers/shizuku_helper.dart';
=======
import '/helpers/storage_helper.dart';
import '/helpers/shizuku_helper.dart';
>>>>>>> 6d3a480 (Initial commit)
import 'drone_page.dart';
import 'skins_page.dart';
import 'emote_page.dart';
import 'recall_page.dart';
import 'config_page.dart';
import '/helpers/download_manager_helper.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

    return MaterialApp(
      title: 'Neru Injector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Jost',
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.background,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onBackground,
          elevation: 0,
          titleTextStyle: const TextStyle(
            fontFamily: 'Jost',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        cardColor: colorScheme.surface,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            elevation: 4,
            textStyle: const TextStyle(
              fontFamily: 'Jost',
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Jost',
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Jost',
            color: Color(0xFF555555),
          ),
        ),
        useMaterial3: true,
      ),
      home: const CollapsiblePage(),
    );
  }
}

class CollapsiblePage extends StatefulWidget {
  const CollapsiblePage({super.key});

  @override
  State<CollapsiblePage> createState() => _CollapsiblePageState();
}

class _CollapsiblePageState extends State<CollapsiblePage> {
  String output = '';

  static const MethodChannel _channel = MethodChannel('com.example.getapp/native');
  
  String _output = '';
 
 Future<void> _createFolder() async {
    // Pastikan Shizuku aktif dan izin sudah diberikan
    final ok = await ShizukuHelper.ensurePermission();
    if (!ok) {
      setState(() {
        _output = 'Shizuku belum aktif atau izin belum diberikan';
      });
      return;
    }

    // Contoh: membuat folder di /sdcard/TestShizuku
    final res = await ShizukuHelper.exec('cp -r /storage/emulated/0/TestShizuku /storage/emulated/0/Android/data/com.mobile.legends/');

    setState(() {
      _output = res.isEmpty
          ? 'Folder berhasil dibuat!'
          : 'Output: $res';
    });
  }

  Future<void> _runTest() async {
    final ok = await ShizukuHelper.ensurePermission();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shizuku tidak aktif ❌')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shizuku sudah aktif ✅')),
    );
  }

  void _handleDefaultPermission(
      BuildContext dialogContext, ColorScheme colorScheme) async {
    try {
      final mlPackages = ['com.mobile.legends', 'com.mobile.legends.hwag'];

      String? validPkg;
      for (final p in mlPackages) {
        if (await StorageHelper.isAppInstalled(p)) {
          validPkg = p;
          break;
        }
      }

      final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);

      if (validPkg == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Mobile Legends tidak ditemukan ❌')),
        );
        return;
      }

      final saved = await StorageHelper.getSavedTreeUri();
      if (saved != null && saved.isNotEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Izin default diset ✅')),
        );
        return;
      }

      final pickedUri = await StorageHelper.pickTreeAndSave(packageName: validPkg);

      if (pickedUri == null || pickedUri.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Permission denied ❌')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Izin default diset ✅')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }
  
  Future<String?> showPermissionDialog(BuildContext context) {
  return showCupertinoDialog<String>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('Permission'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('Please select first'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, 'saf'),
            child: const Text('Default Permission'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, 'shizuku'),
            child: const Text('Shizuku Permission'),
          ),
          CupertinoDialogAction(
            // ⬇️ tidak destruktif
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ],
      );
    },
  );
}

  final List<String> ToolbarImages = [
    'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Julian_(Megumi_Fushiguro).jpg',
    'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Alpha_(Revenant_of_Roses).jpg',
  ];

  final List<Map<String, String>> features = [
    {
      'title': 'Unlock All Skins',
      'subtitle': 'All skin role unlock',
      'icon':
          'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg'
    },
    {
      'title': 'Unlock Emotes',
      'subtitle': '33 Available Emotes',
      'icon':
          'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg'
    },
    {
      'title': 'Unlock Recalls',
      'subtitle': '25 Available Recalls',
      'icon':
          'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg'
    },
    {
      'title': 'Drone View',
      'subtitle': 'Vertical/Horizontal Available',
      'icon':
          'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg'
    },
    {
      'title': 'Configuration',
      'subtitle': 'Games mode api',
      'icon':
          'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg'
    },
  ];

  Future<List<dynamic>> fetchHeroData() async {
    const String jsonUrl =
        'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Json/skin_update.json';
    final response = await http.get(Uri.parse(jsonUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memuat data hero');
    }
  }
  
<<<<<<< HEAD
   // 🔹 Fungsi untuk menampilkan dialog loading bulat
  Future<void> _showProgressDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false, // tidak bisa ditutup manual
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SizedBox(
            height: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Sedang mengunduh...',
                  style: TextStyle(fontFamily: 'Jost'),
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
=======
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
>>>>>>> 6d3a480 (Initial commit)

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: buildDrawer(context, colorScheme),
      body: CustomScrollView(
        slivers: [
          // 🔹 AppBar (kembali dengan icon More & fungsinya)
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            backgroundColor: colorScheme.primaryContainer,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: colorScheme.onBackground),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
  icon: Icon(Icons.monetization_on_outlined, color: colorScheme.primary),
  onPressed: () async {
    final result = await showPermissionDialog(context);

    if (result == 'saf') {
      // 🔹 Jalankan logika SAF di sini
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SAF permission dipilih')),
      );
      // contoh: await handleSAFPermission();

    } else if (result == 'shizuku') {
      // 🔹 Jalankan logika Shizuku di sini
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shizuku permission dipilih')),
      );
      // contoh: await handleShizukuPermission();

    } else {
      // 🔹 Dibatalkan
     /* ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dialog dibatalkan')),
      ); */
    }
  },
),

              // <-- POPUP "More" ICON + MENU (dipulihkan)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colorScheme.onBackground),
                onSelected: (value) async {
                  if (value == 'permission') {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (context) => CupertinoActionSheet(
                        title: Text(
                          'Permission',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                            fontFamily: 'Jost',
                          ),
                        ),
                        message: const Text(
                          'Pilih satu izin yang ingin digunakan',
                          style: TextStyle(fontSize: 14),
                        ),
                        actions: [
                          CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: Text(
                                    'Default Permission?',
                                    style: TextStyle(
                                      fontFamily: 'Jost',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to use Default Permission?',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
                                    ),
                                    CupertinoDialogAction(
                                      isDefaultAction: true,
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        final rootContext = Navigator.of(context, rootNavigator: true).context;
                                        _handleDefaultPermission(rootContext, colorScheme);
                                      },
                                      child: Text('Use Default', style: TextStyle(color: colorScheme.primary)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Default Permission', style: TextStyle(fontSize: 16)),
                          ),
                          CupertinoActionSheetAction(
                            onPressed: () {
                              Navigator.pop(context);
                              showCupertinoDialog(
                                context: context,
                                builder: (context) => CupertinoAlertDialog(
                                  title: Text(
                                    'Shizuku Permission?',
                                    style: TextStyle(
                                      fontFamily: 'Jost',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to use Shizuku Permission?',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
                                    ),
                                    CupertinoDialogAction(
                                      isDefaultAction: true,
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _runTest();
                                      },
                                      child: const Text('Use Shizuku'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Shizuku Permission', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              fontFamily: 'Jost',
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else if (value == 'about') {
                    showAboutDialog(
                      context: context,
                      applicationName: 'MLX Tools - App Injector',
                      applicationVersion: 'August 2025',
                      applicationLegalese: '© 2025 EsaNeru',
                      applicationIcon: const FlutterLogo(size: 40),
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          'MLX Tools adalah aplikasi yang dirancang untuk membantu pengguna '
                          'mengoptimalkan dan mengelola konfigurasi sistem Mobile Legends dengan aman. '
                          'Aplikasi ini memanfaatkan Shizuku API untuk menjalankan perintah tingkat sistem '
                          'tanpa perlu root, memberikan kontrol penuh dengan antarmuka yang mudah digunakan.',
                          style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                        ),
                      ],
                    );
                  } else if (value == 'exit') {
                    SystemNavigator.pop();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'permission', child: Text('Permission')),
                  PopupMenuItem(value: 'about', child: Text('About')),
                  PopupMenuItem(value: 'exit', child: Text('Exit')),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'MLX Injector',
                style: TextStyle(
                  fontFamily: 'Jost',
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: CachedNetworkImage(
                imageUrl: ToolbarImages[0],
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🔹 Judul Section “New Skin” di kanan + Divider full
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'New Skin',
                        style: TextStyle(
                          fontFamily: 'Jost',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(thickness: 1),
              ],
            ),
          ),

          // 🔹 List Hero dari JSON
          SliverToBoxAdapter(
            child: FutureBuilder<List<dynamic>>(
              future: fetchHeroData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
  return const Padding(
    padding: EdgeInsets.all(16.0),
    child: Center(child: CircularProgressIndicator()),
  );
}

if (snapshot.hasError) {
  // Cek apakah error karena koneksi internet (SocketException)
  if (snapshot.error.toString().contains('SocketException')) {
    // Kalau offline, tampilkan loading saja
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  // Kalau error lain, tampilkan teks error
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Center(child: Text('Error: ${snapshot.error}')),
  );
}

                final heroes = snapshot.data ?? [];

                return SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: heroes.length,
                    itemBuilder: (context, index) {
                      final hero = heroes[index];
                      return GestureDetector(
                        onTap: () async {
  final url = hero['download_url'];
  final heroName = hero['hero_name'] ?? 'Unknown Hero';
  final skinName = hero['skin_name'] ?? 'Unknown Skin';

  // 🔹 Jika URL kosong, langsung hentikan
  if (url == null || url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL tidak ditemukan di data JSON!')),
    );
    return;
  }

  // 🔹 Tampilkan dialog konfirmasi bergaya iOS
  final confirm = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text(
        'Notice!',
        style: TextStyle(
          fontFamily: 'Jost',
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Apakah kamu ingin mengunduh dan memasang "$skinName" dari "$heroName"?',
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

  // 🔹 Jika user batal, hentikan
  if (confirm != true) return;

  // 🔹 tampilkan dialog loading
  await _showProgressDialog();

  // 🔹 jalankan proses download & install
  final ok = await DownloadManagerHelper.handleDownloadAndInstall(url);

  // 🔹 tutup dialog
  _hideProgressDialog();

  // 🔹 tampilkan hasil download
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? '✅ Berhasil mengunduh dan memasang $skinName dari $heroName!'
            : '❌ Gagal mengunduh $skinName dari $heroName!',
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
},
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius:
                                    const BorderRadius.vertical(top: Radius.circular(16)),
                                child: CachedNetworkImage(
                                  imageUrl: hero['image'],
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(height: 140, color: Colors.grey[300]),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (hero['role_icon'] != null)
                                          Image.network(hero['role_icon'], width: 18, height: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          hero['hero_name'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      hero['skin_name'] ?? '',
                                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hero['role'] ?? '',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // 🔹 Text “More Feature” di kanan + Divider full bawah
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'More Feature',
                        style: TextStyle(
                          fontFamily: 'Jost',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(thickness: 1),
              ],
            ),
          ),

          // 🔹 List fitur bawah
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final feature = features[index];
                final gradients = [
  const LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
  const LinearGradient(colors: [Colors.purple, Colors.pinkAccent]),
  const LinearGradient(colors: [Colors.red, Colors.orange]),
  const LinearGradient(colors: [Colors.orange, Colors.yellow]),
  const LinearGradient(colors: [Colors.green, Colors.lightGreenAccent]),
  const LinearGradient(colors: [Colors.teal, Colors.cyan]),
];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: colorScheme.surface,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            CachedNetworkImageProvider(feature['icon']!),
                        radius: 26,
                      ),
                      title: Text(
                        feature['title']!,
                        style: TextStyle(
                          fontFamily: 'Jost',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        feature['subtitle']!,
                        style: TextStyle(
                          fontFamily: 'Jost',
                          fontSize: 14,
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      trailing: Material(
  color: Colors.transparent,
  shape: const CircleBorder(),
  child: InkWell(
    customBorder: const CircleBorder(),
    onTap: () {
      final title = feature['title'];

      if (title == 'Unlock All Skins') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SkinsPage()),
        );
      } else if (title == 'Unlock Emotes') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EmotePage()),
        );
      } else if (title == 'Unlock Recalls') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RecallPage()),
        );
      } else if (title == 'Drone View') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DronePage()),
        );
      } else if (title == 'Configuration') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ConfigPage()),
        );
      }
    },
    child: Ink(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: gradients[index % gradients.length], // 🔹 gradient berganti tiap item
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white,
        size: 18,
      ),
    ),
  ),
),
                    ),
                  ),
                );
              },
              childCount: features.length,
            ),
          ),
        ],
      ),
    );
  }
  // 🔹 Fungsi drawer diletakkan di luar class
Drawer buildDrawer(BuildContext context, ColorScheme colorScheme) {
  return Drawer(
    child: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 🔹 Header fleksibel (bukan DrawerHeader lagi)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2196F3), // 💙 Biru utama
                  Color(0xFF64B5F6), // 💙 Biru muda lembut
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // biar tinggi menyesuaikan isi
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto profil bundar
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Icon/Hero1281-icon.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.black12, width: 70, height: 70),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'MLX Tools',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Jost',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'by Esa Neru',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Jost',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Menu drawer
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF2196F3)),
            title: const Text('Home', style: TextStyle(fontFamily: 'Jost')),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.telegram, color: Color(0xFF2196F3)),
            title: const Text('Telegram', style: TextStyle(fontFamily: 'Jost')),
            onTap: () async {
              final url = Uri.parse('https://t.me/EsaNeruChannel');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_fill, color: Color(0xFF2196F3)),
            title: const Text('YouTube', style: TextStyle(fontFamily: 'Jost')),
            onTap: () async {
              final url = Uri.parse(
                  'https://youtu.be/b97UwCGFOiM?si=9EhEtlblDHBlm_VR');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.privacy_tip_outlined, color: Color(0xFF2196F3)),
            title: const Text('Privacy Policy', style: TextStyle(fontFamily: 'Jost')),
            onTap: () async {
              final url = Uri.parse('https://yourwebsite.com/privacy');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    ),
  );
}
} 