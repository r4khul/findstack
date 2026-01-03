import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final githubStarsProvider = FutureProvider<int>((ref) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/r4khul/findstack'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['stargazers_count'] as int;
    } else {
      throw Exception('Failed to load stars');
    }
  } catch (e) {
    // Return a fallback or rethrow.
    // For UI purposes, returning 0 or -1 might be handled gracefully.
    return 0;
  }
});
