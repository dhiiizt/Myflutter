import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'helpers/download_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'main.dart'; // supaya bisa akses flutterLocalNotificationsPlugin
import 'dart:io' show Platform;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_open_ad_manager.dart';

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
  Future.delayed(const Duration(milliseconds: 2000), () {
    if (AppOpenAdManager.instance.isLoaded) {
      AppOpenAdManager.instance.showAdIfAvailable();
    } else {
      print("⏳ Iklan belum siap, tunggu dulu...");
    }
  });

  // 🔹 Muat iklan lebih awal
  _loadInterstitialAd();
  _loadRewardedAd();
  _loadBannerAd();
}

  Future<void> fetchDroneData() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
        'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Json/drone_data_new.json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          droneItems = json.decode(response.body);
        });
      } else {
        throw Exception('Gagal memuat data (${response.statusCode})');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
  
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
    adUnitId: 'ca-app-pub-1802736608698554/3423371739', // ✅ ID test banner
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

Future<void> _showAdLoadingDialog() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => CupertinoAlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 10),
          CupertinoActivityIndicator(radius: 14),
          SizedBox(height: 15),
          Text(
            'Menyiapkan...',
            style: TextStyle(fontFamily: 'Jost'),
          ),
        ],
      ),
    ),
  );
}

void _hideAdLoadingDialog() {
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}

Future<void> _ensureRewardedAdAndShow(VoidCallback onRewarded) async {
  int retry = 0;
  const maxRetry = 5;

  await _showAdLoadingDialog();

  while (_rewardedAd == null && retry < maxRetry) {
    debugPrint('⌛ Memuat iklan... (${retry + 1}/$maxRetry)');
    _loadRewardedAd();
    await Future.delayed(const Duration(seconds: 2));
    retry++;
  }

  _hideAdLoadingDialog();

  if (_rewardedAd == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Iklan gagal dimuat, coba lagi nanti.'),
      ),
    );
    return; // STOP - TIDAK DOWNLOAD
  }

  _showRewardedAd(() {
    onRewarded();
  });
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
          'Drone View List',
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
        const SnackBar(content: Text('Data tidak ditemukan!')),
      );
      return;
    }

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

    if (confirm != true) return;

    // ✅ PASTIKAN IKLAN TAMPIL DULU
    await _ensureRewardedAdAndShow(() async {
      debugPrint('Reward diterima, mulai download...');

      await _showProgressDialog();

      final ok = await DownloadHelper.handleDownloadAndInstall1(
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
              _stageLabel.value = 'Memasang file...';
              break;
            default:
              _stageLabel.value = 'Memproses...';
          }
          _progress.value = progress;
        },
      );

      _hideProgressDialog();

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Download & pasang berhasil!')),
        );
        await showNotification(
          'Berhasil ✅',
          '"${item['title']} ${item['description']}" telah dipasang!',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Gagal download atau pasang!')),
        );
        await showNotification(
          'Gagal ❌',
          'Download atau pemasangan "${item['title']} ${item['description']}" gagal.',
        );
      }
    });
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