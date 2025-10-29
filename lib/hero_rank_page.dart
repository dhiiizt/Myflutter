import 'package:flutter/material.dart';
import '/services/hero_service.dart';

class HeroRankPage extends StatefulWidget {
  const HeroRankPage({super.key});

  @override
  State<HeroRankPage> createState() => _HeroRankPageState();
}

class _HeroRankPageState extends State<HeroRankPage> {
  List<dynamic> heroes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHeroRank();
  }

  Future<void> fetchHeroRank() async {
    try {
      final data = await HeroService.fetchHeroRank(size: 130);

      // Urut berdasarkan Win Rate tertinggi
      data.sort((a, b) {
        final aRate = (a['data']?['main_hero_win_rate'] ?? 0).toDouble();
        final bRate = (b['data']?['main_hero_win_rate'] ?? 0).toDouble();
        return bRate.compareTo(aRate);
      });

      setState(() {
        heroes = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint('❌ Error fetchHeroRank: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE3F2FD),
        title: const Text(
          'Hero Ranking',
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
          : RefreshIndicator(
              onRefresh: fetchHeroRank,
              child: CustomScrollView(
                slivers: [
                  // 🔹 Sticky Header
                  SliverPersistentHeader(
                    pinned: true, // Header tetap nempel di atas
                    delegate: _HeaderDelegate(),
                  ),

                  // 🔹 Daftar Hero
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final hero = heroes[index];
                        final heroData = hero['data'] ?? {};
                        final mainHero = heroData['main_hero']?['data'] ?? {};
                        final subHeroes = heroData['sub_hero'] ?? [];

                        final name = mainHero['name'] ?? 'Unknown';
                        final icon = mainHero['head'] ??
                            'https://cdn-icons-png.flaticon.com/512/147/147144.png';
                        final winRate =
                            ((heroData['main_hero_win_rate'] ?? 0) * 100)
                                .toStringAsFixed(2);
                        final pickRate =
                            ((heroData['main_hero_appearance_rate'] ?? 0) * 100)
                                .toStringAsFixed(2);
                        final banRate =
                            ((heroData['main_hero_ban_rate'] ?? 0) * 100)
                                .toStringAsFixed(2);

                        IconData? medalIcon;
                        Color? medalColor;
                        switch (index) {
                          case 0:
                            medalIcon = Icons.emoji_events;
                            medalColor = Colors.amber[700];
                            break;
                          case 1:
                            medalIcon = Icons.emoji_events;
                            medalColor = Colors.grey[400];
                            break;
                          case 2:
                            medalIcon = Icons.emoji_events;
                            medalColor = Colors.brown[400];
                            break;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 🔢 Rank + Medali
                                    SizedBox(
                                      width: 50,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (medalIcon != null) ...[
                                            const SizedBox(width: 3),
                                            Icon(medalIcon,
                                                color: medalColor, size: 18),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // 🧠 Hero utama
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage:
                                                NetworkImage(icon),
                                            radius: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text('$pickRate%',
                                          textAlign: TextAlign.center),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '$winRate%',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '$banRate%',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.redAccent),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                // 💥 Counter Hero + Icon + Nama
                                Padding(
  padding: const EdgeInsets.only(top: 4, bottom: 2),
  child: Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 6,
    runSpacing: 4,
    children: [
      const Text(
        'Counter:',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      ...subHeroes.map((sub) {
        final subHero = sub['hero']?['data'] ?? {};
        final subIcon = subHero['head'] ??
            'https://cdn-icons-png.flaticon.com/512/147/147144.png';
        final increaseRate =
            (sub['increase_win_rate'] ?? 0.0) * 100; // ubah ke persen
        final rateText = '+${increaseRate.toStringAsFixed(1)}%';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(subIcon),
              radius: 14,
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 40,
              child: Text(
                rateText,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      }).toList(),
    ],
  ),
)
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: heroes.length,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// 🔹 Sticky Header Delegate
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFBBDEFB),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: const Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '#',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Hero',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              'Pick Rate',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              'Win Rate',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              'Ban Rate',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 45;
  @override
  double get minExtent => 45;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}