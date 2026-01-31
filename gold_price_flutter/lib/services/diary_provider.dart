import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import 'dart:convert';

class DiaryProvider with ChangeNotifier {
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;

  List<DiaryEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  DiaryProvider() {
    loadEntries();
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? entriesJson = prefs.getString('diary_entries');
      
      if (entriesJson != null) {
        final List<dynamic> decoded = json.decode(entriesJson);
        _entries = decoded.map((item) => DiaryEntry.fromMap(item)).toList();
      }
    } catch (e) {
      print("Error loading diary entries: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(DiaryEntry entry) async {
    _entries.add(entry);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(_entries.map((e) => e.toMap()).toList());
      await prefs.setString('diary_entries', encoded);
    } catch (e) {
      print("Error saving diary entries: $e");
    }
  }

  double calculateTotalProfit() {
    double total = 0;
    for (var entry in _entries) {
      if (entry.sellPrice != null) {
        total += (entry.sellPrice! - entry.buyPrice) * entry.weight;
      }
    }
    return total;
  }
}
