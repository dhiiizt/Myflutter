import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'helpers/storage_helper.dart';
import 'helpers/shizuku_helper.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFFFF4E4E),
      onPrimary: Colors.white,
      secondary: const Color(0xFFFF7373),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF222222),
      surfaceContainerHighest: const Color(0xFFFFFFFF),
      background: const Color(0xFFFFF5F5),
      onBackground: const Color(0xFF444444),
      error: Colors.red.shade400,
      onError: Colors.white,
      primaryContainer: const Color(0xFFFFE9E9),
      onPrimaryContainer: const Color(0xFF222222),
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
  
  static const MethodChannel _channel = MethodChannel('com.example.my_app/native');

  // 🔹 Shizuku Test
  Future<void> _runTest() async {
  final ok = await ShizukuHelper.ensurePermission();
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shizuku tidak aktif ❌')),
    );
    return;
  }

  // Kalau berhasil granted
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Shizuku sudah aktif ✅')),
  );
}   

  // 🔹 SAF Handler
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
          SnackBar(content: Text('Izin default diset ✅')),
        );
        return;
      }

      // Buka picker SAF
      final pickedUri = await StorageHelper.pickTreeAndSave(packageName: validPkg);

      if (pickedUri == null || pickedUri.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Permission denied ❌')),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Izin default diset ✅')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final List<String> sliderImages = [
      'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Aldous_(Mistbender_Aldous).jpg',
      'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Alpha_(Revenant_of_Roses).jpg',
      'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Fighter/Alucard_(Obsidian_Blade).jpg',
    ];

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

    return Scaffold(
      backgroundColor: colorScheme.background,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colorScheme.primary),
              child: const Text(
                'MLX Tools Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Jost',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
            ),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('About'),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
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
                icon: Icon(Icons.shopping_bag_outlined,
                    color: colorScheme.primary),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cart opened')),
                ),
              ),
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
                            color: colorScheme.primary,
                            fontFamily: 'Jost',
                          ),
                        ),
                        message: const Text(
                          'Pilih satu izin yang ingin digunakan',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontFamily: 'Jost',
                          ),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to use Default Permission?',
                                    style: TextStyle(
                                      fontFamily: 'Jost',
                                      fontSize: 14,
                                    ),
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: Text('Cancel',
                                          style: TextStyle(
                                              color: colorScheme.primary)),
                                    ),
                                    CupertinoDialogAction(
                                      isDefaultAction: true,
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        final rootContext =
                                            Navigator.of(context,
                                                    rootNavigator: true)
                                                .context;
                                        _handleDefaultPermission(
                                            rootContext, colorScheme);
                                      },
                                      child: Text('Use Default',
                                          style: TextStyle(
                                              color: colorScheme.primary)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Default Permission',
                                style: TextStyle(fontSize: 16)),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to use Shizuku Permission?',
                                    style: TextStyle(
                                      fontFamily: 'Jost',
                                      fontSize: 14,
                                    ),
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: Text('Cancel',
                                          style: TextStyle(
                                              color: colorScheme.primary)),
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
                            child: const Text('Shizuku Permission',
                                style: TextStyle(fontSize: 16)),
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
                          style: TextStyle(
                              fontSize: 14, color: Colors.black54, height: 1.4),
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
              background: Image.network(
                ToolbarImages[0],
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 180.0,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  aspectRatio: 16 / 9,
                  autoPlayInterval: const Duration(seconds: 4),
                ),
                items: sliderImages.map((item) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      item,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final feature = features[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: colorScheme.surface,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(feature['icon']!),
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
                          color:
                              colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: colorScheme.primary,
                              content: Text(
                                'Opening ${feature['title']}...',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontFamily: 'Jost',
                                ),
                              ),
                            ),
                          );
                        },
                        child: const Text('OPEN'),
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
}