// lib/services/movie_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class MovieService {
  // Використовуємо тестовий ключ або вставте свій власний з omdbapi.com
  final String _apiKey = '1bab0ce7'; 
  final String _baseUrl = 'https://www.omdbapi.com';

  /// Шукає фільм за назвою та повертає дані про нього
  Future<Map<String, dynamic>?> searchMovie(String title) async {
    try {
      final url = Uri.parse('$_baseUrl/?t=$title&apikey=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Response'] == 'True') {
          return data;
        }
      }
    } catch (e) {
      print('API Error: $e');
    }
    return null;
  }
}