import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/helpers/download_manager_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'main.dart'; // supaya bisa akses flutterLocalNotificationsPlugin
import 'dart:io' show Platform;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SkinsPage extends StatefulWidget {
  const SkinsPage({super.key});

  @override
  State<SkinsPage> createState() => _SkinsPageState();
}

class _SkinsPageState extends State<SkinsPage> {
  List<dynamic> heroes = [];
  String selectedRole = 'All';
  bool loading = true;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final String jsonUrl =
      'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Json/preview_hero_skins.json';

  @override
  void initState() {
    super.initState();
    fetchHeroes();
      _loadInterstitialAd();
  _loadRewardedAd();
  _loadBannerAd();
  }

  Future<void> fetchHeroes() async {
    try {
      final res = await http.get(Uri.parse(jsonUrl));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(res.body);
        final List<dynamic> rawHeroes = data['heroes'] ?? [];

        // 🔹 Urutkan hero berdasarkan nama A–Z
        rawHeroes.sort((a, b) {
          final nameA = (a['name'] ?? '').toString().toLowerCase();
          final nameB = (b['name'] ?? '').toString().toLowerCase();
          return nameA.compareTo(nameB);
        });

        setState(() {
          heroes = rawHeroes;
          loading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      debugPrint('Error fetching: $e');
      setState(() => loading = false);
    }
  }

  // 🔹 Ambil semua role unik (support single & multiple)
  List<String> getRoles() {
    final roles = <String>{'All'};
    for (final h in heroes) {
      final roleData = h['role'];
      if (roleData is List) {
        roles.addAll(List<String>.from(roleData));
      } else if (roleData is String && roleData.isNotEmpty) {
        roles.add(roleData);
      }
    }
    return roles.toList();
  }

  // 🔹 Filter hero berdasarkan role terpilih
  List<dynamic> get filteredHeroes {
    if (selectedRole == 'All') return heroes;
    return heroes.where((h) {
      final roleData = h['role'];
      if (roleData is List) {
        return roleData.contains(selectedRole);
      } else if (roleData is String) {
        return roleData == selectedRole;
      }
      return false;
    }).toList();
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
      error: Colors.redAccent,
      onError: Colors.white,
      primaryContainer: const Color(0xFFE3F2FD), // 💙 Biru pastel
      onPrimaryContainer: const Color(0xFF0D47A1),
    );

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.primaryContainer,
          title: const Text(
            'Skin List',
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
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 🔹 Filter role
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: getRoles()
              .map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(r),
                    selected: selectedRole == r,
                    onSelected: (_) => setState(() => selectedRole = r),
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: selectedRole == r
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),

      const SizedBox(height: 8), // 🔹 Jarak antara chip & grid

      // 🔹 GridView Hero
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 8), // biar gak nempel bawah
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,          // 3 kolom
            childAspectRatio: 0.60,     // 🔹 ubah dari 0.62 → biar proporsional (lebih pendek dikit)
            crossAxisSpacing: 8,       // jarak horizontal antar card
            mainAxisSpacing: 8,         // 🔹 jarak vertikal antar baris (lebih rapat, rapi)
          ),
          itemCount: filteredHeroes.length,
          itemBuilder: (context, index) {
            final hero = filteredHeroes[index];
            return Align(
              alignment: Alignment.center,
              child: HeroCard(
                hero: hero,
                colorScheme: colorScheme,
                onTap: () => _showHeroSheet(context, hero),
              ),
            );
          },
        ),
      ),
    ],
  ),
),
              ),
      ),
    );
  }

  void _showHeroSheet(BuildContext context, Map<String, dynamic> hero) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) {
        final roleData = hero['role'];
        final rolesText = roleData is List
            ? roleData.join(' / ')
            : (roleData?.toString() ?? '');

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
 child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Transform.scale(
  scaleY: 1.0, // tetap gepeng kalau mau
  child: ClipOval(
    child: CachedNetworkImage(
      imageUrl: hero['icon'] ?? '',
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, url) => Container(color: Colors.black12),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    ),
  ),
),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hero['name'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                rolesText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    const SizedBox(height: 20),

    if ((hero['official_skins'] as List?)?.isNotEmpty ?? false)
      _skinSection(context, 'Skin', hero['official_skins'], true),

    if ((hero['upgrade_skins'] as List?)?.isNotEmpty ?? false)
      _skinSection(context, 'Upgrade Skin', hero['upgrade_skins'], false),
  ],
),
          ),
        );
      },
    );
  }

  Widget _skinSection(
      BuildContext context, String title, List skins, bool direct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, i) {
              final s = skins[i];
              return SkinCard(
                skin: s,
                onTap: () => direct
                    ? _confirmDownload(context, s)
                    : _showUpgradeList(context, s),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: skins.length,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showUpgradeList(BuildContext context, Map<String, dynamic> upgrade) {
    final List reps = upgrade['replacement_skins'] ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: reps.isEmpty
              ? const Text('No replacement skins found.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(upgrade['name'] ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, i) {
                          final s = reps[i];
                          return SkinCard(
                            skin: s,
                            onTap: () => _confirmDownload(context, s),
                          );
                        },
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemCount: reps.length,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _confirmDownload(
  BuildContext context,
  Map<String, dynamic> skin,
) async {
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
          'Apakah kamu ingin mengunduh dan memasang "${skin['name']}"?',
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

  final url = skin['download_url'];
  final skinName = skin['name'] ?? 'Unknown Skin';

  if (url == null || url.isEmpty) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('Data tidak ditemukan!')),
    );
    return;
  }

  // 🔹 Kalau iklan belum siap → lanjut download tanpa iklan
  if (_rewardedAd == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⚠️ Iklan belum siap, lanjutkan.')),
    );
    _loadRewardedAd(); // muat ulang iklan biar siap nanti

    // 🔹 Langsung mulai proses download
    await _showProgressDialog();

    final result = await DownloadManagerHelper.handleDownloadAndInstall(
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
            break;
        }
        _progress.value = progress;
      },
    );

    _hideProgressDialog();

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Download & pasang berhasil!')),
      );
      await showNotification('Berhasil ✅', 'Skin "$skinName" telah dipasang!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Gagal download atau pasang!')),
      );
      await showNotification('Gagal ❌', 'Download atau pemasangan skin "$skinName" gagal.');
    }

    return; // ⛔️ Jangan lanjut ke bagian iklan di bawah
  }

  // 🔹 Kalau iklan siap → tampilkan rewarded ad dulu
  _showRewardedAd(() async {
    debugPrint('Reward didapat, mulai proses download skin...');

    await _showProgressDialog();

    final result = await DownloadManagerHelper.handleDownloadAndInstall(
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
            break;
        }
        _progress.value = progress;
      },
    );

    _hideProgressDialog();

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Download & pasang berhasil!')),
      );
      await showNotification('Berhasil ✅', 'Skin "$skinName" telah dipasang!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Gagal download atau pasang!')),
      );
      await showNotification('Gagal ❌', 'Download atau pemasangan skin "$skinName" gagal.');
    }
  });
}
}

class HeroCard extends StatelessWidget {
  final Map<String, dynamic> hero;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const HeroCard({
    super.key,
    required this.hero,
    required this.colorScheme,
    required this.onTap,
  });

@override
Widget build(BuildContext context) {
  final roleData = hero['title'];
  final rolesText =
      roleData is List ? roleData.join(' / ') : (roleData?.toString() ?? '');

  return GestureDetector(
    onTap: onTap,
    child: Transform.scale(
      scaleY: 1.0, // 👉 0.95 kalau mau sedikit aja gepeng
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: hero['image'] ?? '',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (context, url) => Container(color: Colors.black12),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: Colors.red),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 30,
              child: Text(
                hero['name'] ?? '',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 10,
              child: Text(
                rolesText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class SkinCard extends StatelessWidget {
  final Map<String, dynamic> skin;
  final VoidCallback onTap;

  const SkinCard({super.key, required this.skin, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: skin['image'] ?? '',
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 300),
                      placeholder: (context, url) =>
                          Container(color: Colors.black12),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    if (skin['icon'] != null)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: CachedNetworkImage(
                              imageUrl: skin['icon'],
                              fit: BoxFit.contain,
                              fadeInDuration:
                                  const Duration(milliseconds: 300),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error, size: 20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              skin['name'] ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}