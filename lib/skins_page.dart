import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/helpers/download_manager_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';

class SkinsPage extends StatefulWidget {
  const SkinsPage({super.key});

  @override
  State<SkinsPage> createState() => _SkinsPageState();
}

class _SkinsPageState extends State<SkinsPage> {
  List<dynamic> heroes = [];
  String selectedRole = 'All';
  bool loading = true;

<<<<<<< HEAD
=======
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

>>>>>>> 6d3a480 (Initial commit)
  final String jsonUrl =
      'https://raw.githubusercontent.com/dhiiizt/dhiiizt/refs/heads/main/Json/hero_skins.json';

  @override
  void initState() {
    super.initState();
    fetchHeroes();
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
      debugPrint('Error fetching JSON: $e');
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

<<<<<<< HEAD
  // 🔹 Fungsi progress dialog
  Future<void> _showProgressDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
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
    final colorScheme = ColorScheme(
<<<<<<< HEAD
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
        backgroundColor: colorScheme.primaryContainer,
        title: const Text(
          'List Skins',
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
                                  backgroundColor: colorScheme.surfaceVariant,
                                  labelStyle: TextStyle(
                                    color: selectedRole == r
                                        ? Colors.white
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 🔹 GridView Hero
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filteredHeroes.length,
                        itemBuilder: (context, index) {
                          final hero = filteredHeroes[index];
                          return HeroCard(
                            hero: hero,
                            colorScheme: colorScheme,
                            onTap: () => _showHeroSheet(context, hero),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
=======
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
            'List Skins',
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // 🔹 Filter role
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: getRoles()
                              .map(
                                (r) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: ChoiceChip(
                                    label: Text(r),
                                    selected: selectedRole == r,
                                    onSelected: (_) =>
                                        setState(() => selectedRole = r),
                                    selectedColor: colorScheme.primary,
                                    backgroundColor:
                                        colorScheme.primaryContainer,
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
                      const SizedBox(height: 16),

                      // 🔹 GridView Hero
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: filteredHeroes.length,
                          itemBuilder: (context, index) {
                            final hero = filteredHeroes[index];
                            return HeroCard(
                              hero: hero,
                              colorScheme: colorScheme,
                              onTap: () => _showHeroSheet(context, hero),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
>>>>>>> 6d3a480 (Initial commit)
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
<<<<<<< HEAD
  imageUrl: hero['image'] ?? '',
  width: 70,
  height: 70,
  fit: BoxFit.cover,
  alignment: Alignment.topCenter, // 🔹 fokus ke bagian atas
  fadeInDuration: const Duration(milliseconds: 300),
  placeholder: (context, url) => Container(color: Colors.black12),
  errorWidget: (context, url, error) => const Icon(Icons.error),
),
=======
                        imageUrl: hero['image'] ?? '',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        fadeInDuration: const Duration(milliseconds: 300),
                        placeholder: (context, url) =>
                            Container(color: Colors.black12),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
>>>>>>> 6d3a480 (Initial commit)
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hero['name'] ?? '',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                          Text(rolesText,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if ((hero['official_skins'] as List?)?.isNotEmpty ?? false)
                  _skinSection(
                      context, 'Official Skin', hero['official_skins'], true),

                if ((hero['upgrade_skins'] as List?)?.isNotEmpty ?? false)
                  _skinSection(
                      context, 'Upgrade Skin', hero['upgrade_skins'], false),
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
<<<<<<< HEAD
  BuildContext context,
  Map<String, dynamic> skin,
) async {
  // 🔹 Tampilkan dialog konfirmasi bergaya iOS
  final confirm = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(
        'Notice!',
        style: const TextStyle(
          fontFamily: 'Jost',
          fontWeight: FontWeight.bold,
        ),
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

  // 🔹 Jika user menekan "Batal", hentikan proses
  if (confirm != true) return;

  final url = skin['download_url'];
  final skinName = skin['name'] ?? 'Unknown Skin';

  if (url == null || url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL tidak ditemukan di data JSON!')),
    );
    return;
  }

  // 🔹 Tampilkan dialog loading
  await _showProgressDialog();

  final result = await DownloadManagerHelper.handleDownloadAndInstall(url);

  // 🔹 Tutup dialog setelah selesai
  _hideProgressDialog();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result
            ? '✅ Berhasil mengunduh dan memasang $skinName!'
            : '❌ Gagal mengunduh $skinName!',
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
=======
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
        const SnackBar(content: Text('URL tidak ditemukan di data JSON!')),
      );
      return;
    }

    await _showProgressDialog();

    final result = await DownloadManagerHelper.handleDownloadAndInstall(url);

    _hideProgressDialog();

    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          result
              ? '✅ Berhasil mengunduh dan memasang $skinName!'
              : '❌ Gagal mengunduh $skinName!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
>>>>>>> 6d3a480 (Initial commit)
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
    final roleData = hero['role'];
    final rolesText =
        roleData is List ? roleData.join(' / ') : (roleData?.toString() ?? '');

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
<<<<<<< HEAD
  imageUrl: hero['image'] ?? '',
  fit: BoxFit.cover,
  alignment: Alignment.topCenter, // 🔹 fokus ke bagian atas
  fadeInDuration: const Duration(milliseconds: 300),
  placeholder: (context, url) => Container(color: Colors.black12),
  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, colorScheme.shadow.withOpacity(0.7)],
=======
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
                    Colors.black.withOpacity(0.7)
                  ],
>>>>>>> 6d3a480 (Initial commit)
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
                  fontSize: 15,
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 10,
              child: Text(
                rolesText,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
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
                    if (skin['icon'] != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 36,
                          height: 36,
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