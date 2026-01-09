import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final githubStarsProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  const cacheKey = 'github_stars_cache';

  try {
    final response = await http
        .get(Uri.parse('https://api.github.com/repos/r4khul/unfilter'))
        .timeout(const Duration(seconds: 3));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final stars = data['stargazers_count'] as int;

      // Save to cache
      await prefs.setInt(cacheKey, stars);

      return stars;
    } else {
      // API error - fallback to cache
      return prefs.getInt(cacheKey) ?? 0;
    }
  } catch (e) {
    // Network/Timeout error - fallback to cache
    return prefs.getInt(cacheKey) ?? 0;
  }
});
