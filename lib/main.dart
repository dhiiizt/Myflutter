import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
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
import 'adaptive_banner.dart';
import '/helpers/download_manager_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:lottie/lottie.dart';


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
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  
  
await MobileAds.instance.initialize();

  // Load App Open pertama
  AppOpenAdManager.instance.loadAd();

  runApp(const MyApp());
  
  
    
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
      const SnackBar(content: Text('❌ Shizuku is inactive')),
    );
    return;
  }

  scaffoldMessenger.showSnackBar(
    const SnackBar(content: Text('✅ Shizuku is active')),
  );
}

Future<void> _handleDefaultPermission(
    BuildContext dialogContext, ColorScheme colorScheme) async {
  try {
    final mlPackages = ['com.mobile.legends', 'com.mobiin.gp', 'com.vng.mlbbvn', 'com.mobile.legends.usa', 'com.mobilelegends.mi', 'com.mobile.legends.hwag'];
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
        const SnackBar(content: Text('❌ Mobile Legends not found')),
      );
      return;
    }

    final saved = await StorageHelper.getSavedTreeUri();
    if (saved != null && saved.isNotEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('✅ Default permission set')),
      );
      return;
    }

    final pickedUri =
        await StorageHelper.pickTreeAndSave(packageName: validPkg);

    if (pickedUri == null || pickedUri.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('❌ Permission denied')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('✅ Default permission set')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
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
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    // ⏳ Delay 3 detik → coba tampilkan App Open Ad
    Timer(const Duration(seconds: 5), () {
      _showAppOpen();
    });
  }

  /// 🔥 Fungsi untuk menampilkan App Open Ad
  void _showAppOpen() {
    if (AppOpenAdManager.instance.isLoaded) {
      AppOpenAdManager.instance.showAdIfAvailable();

      // Tunggu 0.5 detik biar smooth
      Future.delayed(const Duration(milliseconds: 500), () {
        _goToNextPage();
      });

    } else {
      // Jika iklan belum siap → langsung masuk
      _goToNextPage();
    }
  }

  void _goToNextPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CollapsiblePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// 🔥 ANIMASI LOTTIE DI BELAKANG LOGO
            SizedBox(
              width: 220,
              height: 220,
              child: Lottie.asset(
                'assets/animations/bg.json',
                fit: BoxFit.cover,
              ),
            ),

            /// LOGO DI DEPAN
         //   Image.asset('assets/images/logo.png', width: 95),

            /// LOADING INDICATOR DI BAWAH LOGO
            const Positioned(
              bottom: -60,
              child: CupertinoActivityIndicator(radius: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class CollapsiblePage extends StatefulWidget {
  const CollapsiblePage({super.key});

  @override
  State<CollapsiblePage> createState() => _CollapsiblePageState();
}

class _CollapsiblePageState extends State<CollapsiblePage> {

    @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    UpdateChecker.checkForUpdate(context, () {
      // Setelah dialog update selesai → cek permission
      _checkPermissionsOnStart();

      // Setelah permission selesai → load iklan
      _loadBannerAd();
      _loadInterstitialAd();
      _loadRewardedInterstitialAd();
    });
  });
}  


  String output = '';

  static const MethodChannel _channel = MethodChannel('com.esa.mlxinjector/native');
  
  String _output = '';
 
 Future<void> _createFolder() async {
    // Pastikan Shizuku aktif dan izin sudah diberikan
    final ok = await ShizukuHelper.ensurePermission();
    if (!ok) {
      setState(() {
        _output = 'Shizuku is not active or permission has not been granted';
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
      final mlPackages = ['com.mobile.legends', 'com.mobiin.gp', 'com.vng.mlbbvn', 'com.mobile.legends.usa', 'com.mobilelegends.mi', 'com.mobile.legends.hwag'];

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
          const SnackBar(content: Text('Mobile Legends not found ❌')),
        );
        return;
      }

      final saved = await StorageHelper.getSavedTreeUri();
      if (saved != null && saved.isNotEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Default permission set ✅')),
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
          const SnackBar(content: Text('Default permission set ✅')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
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
          child: Text('Requires storage access permission for com.mobile.legends, Select one permission you want to use'),
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
      throw Exception('Failed to load hero data');
    }
  }
  
// 🔹 Fungsi untuk menampilkan dialog loading modern (Cupertino style)
ValueNotifier<double> _progress = ValueNotifier(0.0);
ValueNotifier<String> _stageLabel = ValueNotifier('Preparing...');

// 🔹 Dialog progress dengan bar + teks
Future<void> _showProgressDialog() async {
  _progress.value = 0.0;
  _stageLabel.value = 'Preparing...';

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
                  'Please wait...',
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
    adUnitId: 'ca-app-pub-1802736608698554/3551472040', // ✅ ID test Interstitial Ads
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

RewardedAd? _rewardedAd;
int rewardedRetry = 0;

void _loadRewardedAd() {
  RewardedAd.load(
  //  adUnitId: 'ca-app-pub-3940256099942544/5224354917',  // ✅ ID test Rewarded Ads
    adUnitId: 'ca-app-pub-1802736608698554/7171045052',
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (ad) {
        _rewardedAd = ad;
        rewardedRetry = 0;
      },
      onAdFailedToLoad: (error) {
        _rewardedAd = null;
        rewardedRetry++;

        if (rewardedRetry < 3) {
          Future.delayed(Duration(seconds: rewardedRetry), _loadRewardedAd);
        }
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
int bannerRetry = 0;

void _loadBannerAd() {
  _bannerAd = BannerAd(
    adUnitId: 'ca-app-pub-1802736608698554/9547069565',  // ✅ ID test Banner Ads
    request: const AdRequest(),
    size: AdSize.banner,
    listener: BannerAdListener(
      onAdLoaded: (_) {
        setState(() => _isBannerAdReady = true);
        bannerRetry = 0;
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        bannerRetry++;
        if (bannerRetry < 3) {
          Future.delayed(Duration(seconds: bannerRetry), _loadBannerAd);
        }
      },
    ),
  )..load();
}

RewardedInterstitialAd? _rewardedInterstitialAd;
int rewardedInterstitialRetry = 0;

void _loadRewardedInterstitialAd() {
  RewardedInterstitialAd.load(
    adUnitId: 'ca-app-pub-1802736608698554/8582297634', // ID test Rewarded Interstitial
    request: const AdRequest(),
    rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        _rewardedInterstitialAd = ad;
        rewardedInterstitialRetry = 0;
        debugPrint('✅ Rewarded Interstitial Loaded');
      },
      onAdFailedToLoad: (error) {
        _rewardedInterstitialAd = null;
        rewardedInterstitialRetry++;

        debugPrint('❌ Failed to load Rewarded Interstitial: $error');

        if (rewardedInterstitialRetry < 3) {
          Future.delayed(
            Duration(seconds: rewardedInterstitialRetry),
            _loadRewardedInterstitialAd,
          );
        }
      },
    ),
  );
}

void _showRewardedInterstitialAd(VoidCallback onRewardEarned) {
  if (_rewardedInterstitialAd != null) {
    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedInterstitialAd(); // siapkan iklan berikutnya
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedInterstitialAd();
        debugPrint('⚠️ Gagal menampilkan Rewarded Interstitial: $error');
      },
    );

    _rewardedInterstitialAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('🎁 User mendapat reward: ${reward.amount} ${reward.type}');
        onRewardEarned(); // panggil aksi reward
      },
    );

    _rewardedInterstitialAd = null;
  } else {
    debugPrint('⚠️ Rewarded Interstitial belum siap');
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
        const SnackBar(content: Text('Unable to open the link')),
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
                          'Requires storage access permission for com.mobile.legends, Choose one permission you want to use.',
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
                                    'Are you sure you want to use the Default Permission??',
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
                                    'Are you sure you want to use the Shizuku Permission??',
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
  '''MLX INJECTOR is a skin management and visual customization application designed for users who want to try custom appearances locally. This app only provides visual asset files for personal use and does not affect the game's core system or any official game mechanisms.

Some available assets may come from third parties and are used solely for entertainment purposes. MLX INJECTOR has no affiliation with, is not supported by, and is not approved by any official game developers or publishers. All trademarks and visual assets remain the property of their respective owners.

The use of this application is entirely the responsibility of the user.''',
  style: TextStyle(
    fontSize: 12,
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

  // 🚫 KHUSUS: Meta Hero Ranking → tidak pakai iklan
  if (title == 'Meta Hero Ranking') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HeroRankPage()),
    );
    return; // ⛔ stop, agar tidak lanjut ke interstitial
  }

  // ✅ Selain Meta Hero Ranking → tampilkan iklan dulu
  _showInterstitialAd(() {
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
    }
  });
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
      
   /*   // 🔹 Banner Ad di bawah layar
      if (_isBannerAdReady)
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            color: Colors.transparent,
            child: AdWidget(ad: _bannerAd!),
          ),
        ), */
        AdaptiveBanner(
  adUnitId: "ca-app-pub-1802736608698554/9547069565", // ID test Adaptive Banner
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
          child: Text('Requires storage access permission for com.mobile.legends, Select one permission you want to use'),
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