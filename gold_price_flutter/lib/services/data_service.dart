import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import '../models/gold_price.dart';

class DataService {
  // Production URL (GitHub Pages)
  static const String DATA_URL = "https://hkindaichi.github.io/pg-gold-price-api/output/history.csv";

  Future<List<GoldRecord>> fetchGoldHistory() async {
    try {
      String url = DATA_URL;
      if (kDebugMode) {
        // 10.0.2.2 is the localhost for Android Emulator
        url = "http://10.0.2.2:5000/history.csv";
        print("🛠️ DEBUG MODE: Using local data server");
      }
      
      print("Fetching data from: $url");
      final uri = Uri.parse("$url?v=${DateTime.now().millisecondsSinceEpoch}");
      final response = await http.get(uri);
      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final String csvString = response.body;
        // Clean up BOM if present
        final cleanCsv = csvString.replaceAll('\uFEFF', ''); 

        List<List<dynamic>> rows = const CsvToListConverter().convert(
          cleanCsv, 
          eol: '\n', 
          shouldParseNumbers: false // Parse manually in model for safety
        );

        if (rows.isEmpty) return [];

        // Remove header if it exists
        if (rows.first.isNotEmpty && rows.first[0].toString() == 'timestamp') {
          rows.removeAt(0);
        }

        return rows.map((row) => GoldRecord.fromCsv(row)).toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching data: $e");
      // Return empty list on error for now, or rethrow
      return [];
    }
  }
}
