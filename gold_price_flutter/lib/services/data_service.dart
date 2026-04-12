import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
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
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      print("Response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final String csvString = response.body;
        // Clean up BOM if present
        final cleanCsv = csvString.replaceAll('\uFEFF', ''); 

        List<List<dynamic>> rows = const CsvToListConverter().convert(
          cleanCsv, 
          eol: '\n', // Standard GitHub EOL
          shouldParseNumbers: false 
        );

        if (rows.isEmpty) {
           throw Exception('Fail CSV kosong atau gagal diproses');
        }

        // Remove header if it exists
        if (rows.first.isNotEmpty && rows.first[0].toString().contains('timestamp')) {
          rows.removeAt(0);
        }

        final rawData = rows.map((row) => GoldRecord.fromCsv(row)).toList();
        
        // Penapis Kecemasan: Buang data yang harga tidak munasabah (> 10000)
        // Ditingkatkan ke 10,000 supaya Harga Spot Global (USD/oz) tidak ditapis
        final data = rawData.where((r) => r.sell < 10000 && r.buy < 10000).toList();
        
        if (data.isEmpty && rawData.isNotEmpty) {
           print("⚠️ Semua data ditapis keluar! Menggunakan data mentah.");
           return rawData;
        }
        
        return data;
      } else {
        return await _loadFromAssets();
      }
    } catch (e) {
      print("Error fetching gold history: $e");
      return await _loadFromAssets();
    }
  }

  Future<List<GoldRecord>> _loadFromAssets() async {
    try {
      print("📂 Loading data from assets (fallback)...");
      final String csvString = await rootBundle.loadString('assets/history.csv');
      final cleanCsv = csvString.replaceAll('\uFEFF', ''); 

      List<List<dynamic>> rows = const CsvToListConverter().convert(
        cleanCsv, 
        eol: '\n', 
        shouldParseNumbers: false 
      );

      if (rows.isNotEmpty && rows.first[0].toString().contains('timestamp')) {
        rows.removeAt(0);
      }

      return rows.map((row) => GoldRecord.fromCsv(row)).toList();
    } catch (e) {
      print("❌ Failed to load from assets: $e");
      return [];
    }
  }
}
