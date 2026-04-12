import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portfolio_entry.dart';
import 'gold_provider.dart';
import 'dart:convert';

class PortfolioProvider with ChangeNotifier {
  List<PortfolioEntry> _entries = [];
  bool _isLoading = true;
  String _selectedOwner = "All";

  List<PortfolioEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String get selectedOwner => _selectedOwner;

  PortfolioProvider() {
    loadEntries();
  }

  void setSelectedOwner(String owner) {
    _selectedOwner = owner;
    notifyListeners();
  }

  List<String> get owners {
    final List<String> list = [];
    for (var e in _entries) {
      if (!list.contains(e.ownerName)) {
        list.add(e.ownerName);
      }
    }
    return ["All", ...list];
  }

  List<PortfolioEntry> get filteredEntries {
    // Create a copy to avoid mutating the original _entries list sorting order
    List<PortfolioEntry> listToDisplay = List.from(_entries);
    
    if (_selectedOwner == "All") {
      return listToDisplay..sort((a, b) => b.date.compareTo(a.date));
    }
    return listToDisplay
        .where((e) => e.ownerName == _selectedOwner)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? entriesJson = prefs.getString('portfolio_entries') ?? prefs.getString('diary_entries');
      
      if (entriesJson != null) {
        final List<dynamic> decoded = json.decode(entriesJson);
        _entries = decoded.map((item) => PortfolioEntry.fromMap(item)).toList();
      }
    } catch (e) {
      debugPrint("Error loading portfolio entries: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(PortfolioEntry entry) async {
    _entries.add(entry);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> updateEntry(PortfolioEntry entry) async {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      notifyListeners();
      await _saveToPrefs();
    }
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> deleteOwnerRecords(String ownerName) async {
    _entries.removeWhere((entry) => entry.ownerName == ownerName);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> deleteOwnerSoldHistory(String ownerName) async {
    _entries.removeWhere((entry) => entry.ownerName == ownerName && entry.sellPricePerGram != null);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> sellEntry(String id, double sellPricePerGram, double weightToSell) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      final entry = _entries[index];
      
      // Validation
      if (weightToSell > entry.weight) return;

      if (weightToSell == entry.weight) {
        // Full Sell
        _entries[index] = PortfolioEntry(
          id: entry.id,
          ownerName: entry.ownerName,
          weight: entry.weight,
          buyPricePerGram: entry.buyPricePerGram,
          sellPricePerGram: sellPricePerGram,
          sellDate: DateTime.now(),
          type: entry.type,
          date: entry.date,
          notes: entry.notes,
        );
      } else {
        // Partial Sell
        // 1. Reduce weight of existing entry (The holding part)
        double remainingWeight = entry.weight - weightToSell;
        _entries[index] = PortfolioEntry(
          id: entry.id,
          ownerName: entry.ownerName,
          weight: double.parse(remainingWeight.toStringAsFixed(4)), // Avoid precision errors
          buyPricePerGram: entry.buyPricePerGram,
          sellPricePerGram: null, // Still holding this part
          type: entry.type,
          date: entry.date,
          notes: entry.notes,
        );

        // 2. Create new entry for the sold part
        final newSoldEntry = PortfolioEntry(
          id: "${entry.id}_sold_${DateTime.now().millisecondsSinceEpoch}",
          ownerName: entry.ownerName,
          weight: weightToSell,
          buyPricePerGram: entry.buyPricePerGram,
          sellPricePerGram: sellPricePerGram,
          sellDate: DateTime.now(),
          type: entry.type,
          date: entry.date, // Keep original buy date for records
          notes: "${entry.notes} (Partial Sell)",
        );
        _entries.insert(index, newSoldEntry); // Insert next to it
      }
      
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(_entries.map((e) => e.toMap()).toList());
      await prefs.setString('portfolio_entries', encoded);
    } catch (e) {
      debugPrint("Error saving portfolio entries: $e");
    }
  }

  double calculateStats(String type, {String? owner}) {
    List<PortfolioEntry> list = owner == null || owner == "All" 
        ? _entries 
        : _entries.where((e) => e.ownerName == owner).toList();
    
    // Only count unsold weight for the summary, OR show total managed? 
    // Usually portfolio summary shows "holding". Let's show holding (unsold).
    return list
        .where((e) => e.type == type && e.sellPricePerGram == null)
        .fold(0.0, (sum, e) => sum + e.weight);
  }

  double calculateTotalPL({String? owner}) {
    List<PortfolioEntry> list = owner == null || owner == "All" 
        ? _entries 
        : _entries.where((e) => e.ownerName == owner).toList();
    
    return list.where((e) => e.sellPricePerGram != null).fold(0.0, (sum, e) {
      // P/L = (Sell Rate - Buy Rate) * Weight
      return sum + ((e.sellPricePerGram! - e.buyPricePerGram) * e.weight);
    });
  }

  double calculateTotalAsset({String? owner, String? type}) {
    List<PortfolioEntry> list = owner == null || owner == "All" 
        ? _entries 
        : _entries.where((e) => e.ownerName == owner).toList();
    
    if (type != null) {
      list = list.where((e) => e.type == type).toList();
    }

    // Total Asset = Purchase rate * weight of unsold gold
    return list
        .where((e) => e.sellPricePerGram == null)
        .fold(0.0, (sum, e) => sum + (e.buyPricePerGram * e.weight));
  }

  double getLatestPrice(String type, GoldProvider goldProvider) {
    if (type == '999') {
      var records = goldProvider.history.where((r) => r.merchant == 'world_gold' && r.item == '999').toList();
      if (records.isNotEmpty) return records.last.sell;
    } else if (type == '916') {
      var records = goldProvider.history.where((r) => r.merchant == 'world_gold' && r.item == '999').toList();
      if (records.isNotEmpty) return records.last.sell * 0.916;
    } else if (type == 'Silver') {
      var records = goldProvider.history.where((r) => r.merchant == 'world_silver' && r.item == 'Silver').toList();
      if (records.isNotEmpty) return records.last.sell;
    }
    return 0.0;
  }

  double calculateCurrentMarketValue(GoldProvider goldProvider, {String? owner}) {
    List<PortfolioEntry> list = owner == null || owner == "All" 
        ? _entries 
        : _entries.where((e) => e.ownerName == owner).toList();
    
    return list
        .where((e) => e.sellPricePerGram == null)
        .fold(0.0, (sum, e) {
          final currentPrice = getLatestPrice(e.type, goldProvider);
          return sum + (currentPrice * e.weight);
        });
  }

  double calculateTotalUnrealizedPL(GoldProvider goldProvider, {String? owner}) {
    List<PortfolioEntry> list = owner == null || owner == "All" 
        ? _entries 
        : _entries.where((e) => e.ownerName == owner).toList();

    return list.where((e) => e.sellPricePerGram == null).fold(0.0, (sum, e) {
      final currentPrice = getLatestPrice(e.type, goldProvider);
      if (currentPrice == 0) return sum;
      return sum + ((currentPrice - e.buyPricePerGram) * e.weight);
    });
  }
}
