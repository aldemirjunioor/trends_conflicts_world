import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AcledApiService {
  static const String _baseUrl = 'https://api.acleddata.com/acled/read';

  Future<List<dynamic>> getEvents({required String query}) async {
    final apiKey = dotenv.env['ACLED_API_KEY'];
    final apiEmail = dotenv.env['ACLED_API_EMAIL'];

    if (apiKey == null || apiEmail == null) {
      throw Exception('API key or email not found in .env file. Please ensure the file is correctly set up.');
    }

    // Using 'country' for a specific search by country name.
    final response = await http.get(
      Uri.parse('$_baseUrl?key=$apiKey&email=$apiEmail&country=$query&limit=10'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('data') && data['data'] is List) {
        return data['data'];
      } else {
        return []; // Return empty list if data is not in the expected format
      }
    } else {
      throw Exception('Failed to load events. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
