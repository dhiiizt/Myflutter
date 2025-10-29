import 'dart:convert';
import 'package:http/http.dart' as http;

class HeroService {
  static const String baseUrl =
      'https://mlbb-stats.ridwaanhall.com/api/hero-rank/';

  static Future<List<dynamic>> fetchHeroRank({
    int days = 1,
    String rank = 'all',
    int size = 130,
    int index = 1,
    String sortField = 'pick_rate',
    String sortOrder = 'desc',
  }) async {
    final url =
        '$baseUrl?days=$days&rank=$rank&size=$size&index=$index&sort_field=$sortField&sort_order=$sortOrder';

    print('🌐 Request URL: $url');
    final response = await http.get(Uri.parse(url));
    print('📦 Response Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final records = json['data']?['records'] ?? [];
      print('✅ Found ${records.length} records');
      return records;
    } else {
      throw Exception('Failed to load hero rank (code: ${response.statusCode})');
    }
  }
}