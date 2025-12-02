import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/helpers/storage_helper.dart';
import '/helpers/shizuku_helper.dart';
import 'drone_page.dart';
import 'skins_page.dart';
import 'emote_page.dart';
import 'recall_page.dart';
import 'config_page.dart';
import 'hero_rank_page.dart';
import 'update_checker.dart';
import 'app_open_ad_manager.dart';
import '/helpers/download_manager_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();    

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  if (Platform.isAndroid) {
    final androidImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final granted = await androidImpl?.areNotificationsEnabled();
    if (granted == false) {
      await androidImpl?.requestNotificationsPermission();
    }
  } else if (Platform.isIOS) {
    final iosImpl = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  StorageHelper.initChannelListener();

  // 🔹 Inisialisasi notifikasi
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await initNotifications();
  
  await Firebase.initializeApp();
  
  // Cek semua app Firebase yang terdaftar
  print("Firebase apps: ${Firebase.apps.map((e) => e.name).toList()}");
  
  // Cek apakah app default sudah aktif
  if (Firebase.apps.isNotEmpty) {
    print("✅ Firebase sudah tertaut dengan project Flutter");
  } else {
    print("❌ Firebase belum tertaut / belum diinisialisasi");
  }
  
  
await MobileAds.instance.initialize();

AppOpenAdManager.instance.loadAd();

  runApp(const MyApp());
    
  // 🔹 Jalankan cek izin setelah app tampil
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkPermissionsOnStart();
  });
}

Future<void> _checkPermissionsOnStart() async {
  final isAvailable = await ShizukuHelper.isAvailable();
  final hasPerm = await ShizukuHelper.hasPermission();
  final shizukuReady = isAvailable && hasPerm;
  final treeUri = await StorageHelper.getSavedTreeUri();

  // Jika Shizuku aktif ATAU TreeUri sudah tersimpan, jangan tampilkan apa pun
  if (shizukuReady || (treeUri != null && treeUri.isNotEmpty)) {
    return;
  }

  // Pastikan context siap
  final context = navigatorKey.currentContext;
  if (context == null) return;

  final choice = await showPermissionDialog(context);

  if (choice == 'shizuku') {
    await _runTest(context);
  } else if (choice == 'saf') {
    final colorScheme = Theme.of(context).colorScheme;
    await _handleDefaultPermission(context, colorScheme);
  }
}

Future<void> _runTest(BuildContext context) async {
  final ok = await ShizukuHelper.ensurePermission();
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  if (!ok) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('❌ Shizuku tidak aktif')),
    );
    return;
  }

  scaffoldMessenger.showSnackBar(
    const SnackBar(content: Text('✅ Shizuku sudah aktif')),
  );
}

Future<void> _handleDefaultPermission(
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
        const SnackBar(content: Text('❌ Mobile Legends tidak ditemukan')),
      );
      return;
    }

    final saved = await StorageHelper.getSavedTreeUri();
    if (saved != null && saved.isNotEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('✅ Izin default sudah diset')),
      );
      return;
    }

    final pickedUri =
        await StorageHelper.pickTreeAndSave(packageName: validPkg);

    if (pickedUri == null || pickedUri.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('❌ Izin ditolak')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('✅ Izin default diset')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan: $e')),
    );
  }
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
    navigatorKey: navigatorKey, // ✅
      title: 'MLX Injector',
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

  static const MethodChannel _channel = MethodChannel('com.esa.mlxinjector/native');
  
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
          const SnackBar(content: Text('Izin ditolak ❌')),
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
          child: Text('Membutuhkan izin akses ke storage com.mobile.legends, Pilih satu izin yang ingin digunakan'),
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
    'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/ML%20ToolKit/1000213688.jpg',
    'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/ML%20ToolKit/1000213688.jpg',
  ];

  final List<Map<String, String>> features = [
    {
      'title': 'Preview Skins',
      'subtitle': 'Preview All skin role',
      'icon':
          'https://akmweb.youngjoygame.com/web/gms/image/9ea138369ca4a37b4806ac64998df054.webp'
    },
    /*{
      'title': 'Unlock Emotes',
      'subtitle': '33 Available Emotes',
      'icon':
          'https://akmweb.youngjoygame.com/web/gms/image/10cf23ade94859fd7f6a877c828c0131.webp'
    },
    {
      'title': 'Unlock Recalls',
      'subtitle': '25 Available Recalls',
      'icon':
          'https://akmweb.youngjoygame.com/web/gms/image/3a7693b9a565b4e1d67d57ae73eb5297.webp'
    },*/
    {
      'title': 'Drone View',
      'subtitle': 'Vertical/Horizontal Available',
      'icon':
          'https://akmweb.youngjoygame.com/web/gms/image/1bea09e43f6b02845de97af863c53da5.webp'
    },
    {
      'title': 'Meta Hero Ranking',
      'subtitle': 'Hero Strength Ranking',
      'icon':
          'https://akmweb.youngjoygame.com/web/gms/image/adaf737c13d48204dc39f4b48de91ac8.webp'
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
  
// 🔹 Fungsi untuk menampilkan dialog loading modern (Cupertino style)
ValueNotifier<double> _progress = ValueNotifier(0.0);
ValueNotifier<String> _stageLabel = ValueNotifier('Menyiapkan...');

// 🔹 Dialog progress dengan bar + teks
Future<void> _showProgressDialog() async {
  _progress.value = 0.0;
  _stageLabel.value = 'Menyiapkan...';

  showCupertinoDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return ValueListenableBuilder<double>(
        valueListenable: _progress,
        builder: (context, progressValue, _) {
          return ValueListenableBuilder<String>(
            valueListenable: _stageLabel,
            builder: (context, stageText, _) {
              final percent =
                  (progressValue * 100).clamp(0, 100).toStringAsFixed(0);

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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔹 Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressValue.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            CupertinoColors.activeBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔹 Label tahap
                      Text(
                        stageText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Jost',
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 🔹 Persentase angka
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontFamily: 'Jost',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

void _hideProgressDialog() {
  if (Navigator.canPop(context)) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

InterstitialAd? _interstitialAd;

void _loadInterstitialAd() {
  InterstitialAd.load(
    adUnitId: 'ca-app-pub-1802736608698554/3551472040', // ✅ ID iklan TEST
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        _interstitialAd = ad;
        debugPrint('✅ Iklan Interstitial berhasil dimuat');
      },
      onAdFailedToLoad: (error) {
        _interstitialAd = null;
        debugPrint('❌ Gagal memuat iklan: $error');
      },
    ),
  );
}

void _showInterstitialAd(VoidCallback onAdClosed) {
  if (_interstitialAd != null) {
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd(); // 🔁 Siapkan iklan berikutnya
        onAdClosed(); // ✅ lanjut ke aksi berikutnya
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
        onAdClosed(); // tetap lanjut walau gagal tampil
        debugPrint('⚠️ Gagal menampilkan iklan: $error');
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null; // ❗ jangan tampilkan dua kali
  } else {
    debugPrint('⚠️ Iklan belum siap, lanjut saja');
    onAdClosed();
  }
}

@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    UpdateChecker.checkForUpdate(context);
  });

  // 🔹 Muat Interstitial Ad pertama kali
  _loadInterstitialAd();

  // 🔹 Muat Rewarded Ad pertama kali
  _loadRewardedAd();
  
  _loadBannerAd();
  
  Future.delayed(const Duration(milliseconds: 5000), () {
    if (AppOpenAdManager.instance.isLoaded) {
      AppOpenAdManager.instance.showAdIfAvailable();
    } else {
      print("⏳ Iklan belum siap, tunggu dulu...");
    }
  });
  
  
}

RewardedAd? _rewardedAd;

void _loadRewardedAd() {
  RewardedAd.load(
    adUnitId: 'ca-app-pub-1802736608698554/7171045052', // ✅ ID test Rewarded Ad
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (ad) {
        _rewardedAd = ad;
        debugPrint('✅ Iklan Rewarded berhasil dimuat');
      },
      onAdFailedToLoad: (error) {
        _rewardedAd = null;
        debugPrint('❌ Gagal memuat Rewarded Ad: $error');
      },
    ),
  );
}

void _showRewardedAd(VoidCallback onRewardEarned) {
  if (_rewardedAd != null) {
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd(); // 🔁 Siapkan iklan berikutnya
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
        debugPrint('⚠️ Gagal menampilkan iklan Rewarded: $error');
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('🎁 Pengguna mendapat reward: ${reward.amount} ${reward.type}');
        onRewardEarned(); // ✅ jalankan aksi reward di sini
      },
    );

    _rewardedAd = null;
  } else {
    debugPrint('⚠️ Rewarded Ad belum siap');
  }
}

BannerAd? _bannerAd;
bool _isBannerAdReady = false;

void _loadBannerAd() {
  _bannerAd = BannerAd(
    adUnitId: 'ca-app-pub-1802736608698554/9547069565', // ✅ ID test banner
    request: const AdRequest(),
    size: AdSize.banner,
    listener: BannerAdListener(
      onAdLoaded: (Ad ad) {
        debugPrint('✅ Iklan Banner berhasil dimuat');
        setState(() {
          _isBannerAdReady = true;
        });
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        debugPrint('❌ Gagal memuat Banner Ad: $error');
        _isBannerAdReady = false;
        ad.dispose();
      },
    ),
  )..load();
}

NativeAd? _nativeAd;
bool _isNativeAdReady = false;

/// 🔹 Muat Native Ad
void _loadNativeAd() {
  _nativeAd = NativeAd(
    adUnitId: 'ca-app-pub-3940256099942544/2247696110', // ✅ ID TEST Native
    factoryId: 'listTile', // wajib sama dengan yg di-registrasi di main.dart
    request: const AdRequest(),
    listener: NativeAdListener(
      onAdLoaded: (ad) {
        debugPrint('✅ Native Ad berhasil dimuat');
        _isNativeAdReady = true;
        setState(() {});
      },
      onAdFailedToLoad: (ad, error) {
        debugPrint('❌ Gagal memuat Native Ad: $error');
        ad.dispose();
        _isNativeAdReady = false;
        setState(() {});
      },
    ),
  )..load();
}

/// 🔹 Tampilkan Native Ad (dalam widget)
Widget _showNativeAd() {
  if (_isNativeAdReady && _nativeAd != null) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200],
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  } else {
    return const SizedBox.shrink(); // kosong dulu kalau belum siap
  }
}

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'download_channel',
    'Download Notifications',
    channelDescription: 'Status download dan instalasi',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // ID notifikasi
    title,
    body,
    platformChannelSpecifics,
  );
}

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
  drawer: buildDrawer(context, colorScheme),
  body: Stack(
    children: [
      CustomScrollView(
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
    const url = 'https://saweria.co/esaneru';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka link')),
      );
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
                          'Membutuhkan izin akses ke storage com.mobile.legends, Pilih satu izin yang ingin digunakan',
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
                                    'Apakah Anda yakin ingin menggunakan Izin Default??',
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
                                    'Apakah Anda yakin ingin menggunakan Izin Shizuku??',
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
                      applicationIcon: Image.asset(
                          'assets/images/logo.png',
                          width: 48,
                          height: 48,
                        ),
                      children: [
                        const SizedBox(height: 10),
                        const Text(
  '''MLX INJECTOR adalah aplikasi pengelola skin dan kustomisasi visual yang dirancang untuk pengguna yang ingin mencoba tampilan kustom secara lokal. Aplikasi ini hanya menyediakan file aset visual untuk penggunaan pribadi dan tidak memengaruhi sistem inti maupun mekanisme resmi game.

Beberapa aset yang tersedia dapat berasal dari pihak ketiga dan digunakan semata-mata untuk keperluan hiburan. MLX INJECTOR tidak memiliki afiliasi, tidak didukung, dan tidak disetujui oleh pengembang atau penerbit game resmi mana pun. Seluruh merek dagang dan aset visual sepenuhnya menjadi milik pemilik aslinya.

Penggunaan aplikasi ini sepenuhnya merupakan tanggung jawab pengguna.''',
  style: TextStyle(
    fontSize: 11,
    color: Colors.black54,
    height: 1.4,
  ),
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
                  //color: colorScheme.onSurface,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: CachedNetworkImage(
                imageUrl: ToolbarImages[0],
                fit: BoxFit.cover,
              ),
            ),
          ),

      /*    // 🔹 Judul Section “New Skin” di kanan + Divider full
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
          ), */

    /*      // 🔹 List Hero dari JSON
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

  // ✅ gunakan (stage, progress)
  final ok = await DownloadManagerHelper.handleDownloadAndInstall(
  url,
  onProgress: (stage, progress) {
    switch (stage) {
      case 'download':
        _stageLabel.value = 'Mengunduh file...';
        break;
      case 'extract':
        _stageLabel.value = 'Menganalisa file...';
        break;
      case 'move':
        _stageLabel.value = 'Mengekstrak file...';
        break;
      default:
        _stageLabel.value = 'Memproses...';
        break;
    }

    // update progress UI
    _progress.value = progress;
  },
);

_hideProgressDialog();

  // 🔹 tampilkan hasil download
  if (ok) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('✅ Download & pasang berhasil!')),
  );
  await showNotification('Berhasil 🎉', '"$skinName" dari "$heroName" telah dipasang!');
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('❌ Gagal download atau pasang!')),
  );
  await showNotification('Gagal ❌', 'Download atau pemasangan "$skinName" dari "$heroName" gagal.');
}
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
    Stack(
  children: [
    // 🔹 Gambar utama hero
    ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: CachedNetworkImage(
        imageUrl: hero['image'],
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            Container(height: 140, color: Colors.grey[300]),
      ),
    ),

    // 🔹 Gradient overlay di atas gambar
    Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    ),

    // 🔹 Overlay icon di kanan atas (jika ada)
    if (hero['overlay_icon'] != null && hero['overlay_icon'].isNotEmpty)
      Positioned(
        top: 0,
        right: 2,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Image.network(
            hero['overlay_icon'],
            fit: BoxFit.contain,
          ),
        ),
      ),
  ],
),

    // 🔹 Info hero di bawah gambar
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hero['role_icon'] != null)
                Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1A3E6E), // Navy tua
                        Color(0xFFE6ECF3), // Putih lembut
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(1, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.network(
                    hero['role_icon'],
                    fit: BoxFit.contain,
                  ),
                ),
              const SizedBox(width: 6),
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
          
*/
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
                        'Feature',
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
                      leading: ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: CachedNetworkImage(
    imageUrl: feature['icon']!,
    width: 52,
    height: 52,
    fit: BoxFit.cover,
    placeholder: (context, url) => Container(color: Colors.transparent),
    errorWidget: (context, url, error) => const Icon(Icons.error),
  ),
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

      // 🔹 Langsung navigasi tanpa iklan
      if (title == 'Preview Skins') {
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
      } else if (title == 'Meta Hero Ranking') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HeroRankPage()),
        );
      }
    },
    child: Ink(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: gradients[index % gradients.length],
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
SliverToBoxAdapter(
            child: SizedBox(height: 80), // jarak supaya konten tidak tertutup banner
          ),
        ],
      ),
      
      // 🔹 Banner Ad di bawah layar
      if (_isBannerAdReady)
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            color: Colors.transparent,
            child: AdWidget(ad: _bannerAd!),
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
                            'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Images/20251123_092747.png',
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
              final url = Uri.parse('https://doc-hosting.flycricket.io/mlx-injector-privacy-policy/39525d2b-b6ee-4bb7-bfa0-28baa81a5c45/privacy');
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
Future<String?> showPermissionDialog(BuildContext context) {
  return showCupertinoDialog<String>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('Permission'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text('Membutuhkan izin akses ke storage com.mobile.legends, Pilih satu izin yang ingin digunakan'),
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
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              'Cancel',
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
          ),
        ],
      );
    },
  );
}