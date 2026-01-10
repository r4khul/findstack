import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final githubStarsProvider = FutureProvider<int>((ref) async {
  const cacheKey = 'github_stars_cache';
  const repoUrl = 'https://api.github.com/repos/r4khul/unfilter';
  const timeoutDuration = Duration(seconds: 3);

  final prefs = await SharedPreferences.getInstance();

  try {
    final response = await http
        .get(Uri.parse(repoUrl))
        .timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final stars = data['stargazers_count'] as int;

      await prefs.setInt(cacheKey, stars);

      return stars;
    } else {
      return prefs.getInt(cacheKey) ?? 0;
    }
  } catch (e) {
    return prefs.getInt(cacheKey) ?? 0;
  }
});
