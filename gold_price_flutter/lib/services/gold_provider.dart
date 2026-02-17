import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gold_price.dart';
import 'data_service.dart';

class GoldProvider with ChangeNotifier {
  final DataService _service = DataService();
  
  List<GoldRecord> _history = [];
  bool _isLoading = false;
  String? _error;

  // UI State
  String _selectedPurity = '999'; // '999', '916', 'Silver' (Used for Dashboard)
  String _merchantPurity = '999'; // Separate state for Merchants Screen
  String _selectedRange = '7D'; // '7D', '1M', '6M', '1Y'
  int _currentTabIndex = 0;
  List<String> _watchlist = [];

  List<GoldRecord> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedPurity => _selectedPurity;
  String get merchantPurity => _merchantPurity;
  String get selectedRange => _selectedRange;
  int get currentTabIndex => _currentTabIndex;
  List<String> get watchlist => _watchlist;

  void setPurity(String purity) {
    _selectedPurity = purity;
    notifyListeners();
  }

  void setMerchantPurity(String purity) {
    _merchantPurity = purity;
    notifyListeners();
  }

  void setRange(String range) {
    _selectedRange = range;
    notifyListeners();
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  bool isWatched(String merchantId) {
    return _watchlist.contains(merchantId);
  }

  Future<void> toggleWatchlist(String merchantId) async {
    if (_watchlist.contains(merchantId)) {
      _watchlist.remove(merchantId);
    } else {
      _watchlist.add(merchantId);
    }
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('merchant_watchlist', _watchlist);
  }

  Future<void> _loadWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    _watchlist = prefs.getStringList('merchant_watchlist') ?? [];
    notifyListeners();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _loadWatchlist();
    await _loadAlerts();

    try {
      _history = await _service.fetchGoldHistory();
      _history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      checkAlerts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to get latest record for dashboard (averaged or from a lead merchant)
  GoldRecord? getLatestForDashboard() {
    if (_selectedPurity == '999') {
      var records = _history.where((r) => r.merchant == 'world_gold' && r.item == '999').toList();
      if (records.isNotEmpty) return records.last;
    }
    if (_selectedPurity == '916') {
      // 916 (22K) Logic: Calculate from World Spot 999 * 0.916
      var records = _history.where((r) => r.merchant == 'world_gold' && r.item == '999').toList();
      if (records.isNotEmpty) {
        final r = records.last;
        return GoldRecord(
          timestamp: r.timestamp,
          merchant: r.merchant,
          item: '916',
          sell: r.sell * 0.916,
          buy: r.buy * 0.916,
          spread: r.spread * 0.916
        );
      }
    }
    if (_selectedPurity == 'Silver') {
      var records = _history.where((r) => r.merchant == 'world_silver' && r.item == 'Silver').toList();
      if (records.isNotEmpty) return records.last;
    }
    var records = _history.where((r) => r.item == _selectedPurity && r.merchant != 'world_gold' && r.merchant != 'world_silver').toList();
    if (records.isEmpty) return null;
    return records.last;
  }

  GoldRecord? getLatestUSDPrice() {
    String merchant = _selectedPurity == 'Silver' ? 'world_silver' : 'world_gold';
    var records = _history.where((r) => r.merchant == merchant && r.item.trim() == 'USD/oz').toList();
    if (records.isEmpty) return null;
    return records.last;
  }

  List<GoldRecord> getHistoryForDashboard() {
    List<GoldRecord> source;
    if (_selectedPurity == '999') {
      source = _history.where((r) => r.merchant == 'world_gold' && r.item == '999').toList();
    } else if (_selectedPurity == '916') {
         // 916 (22K) Logic: Calculate from World Spot 999 * 0.916
        source = _history
          .where((r) => r.merchant == 'world_gold' && r.item == '999')
          .map((r) => GoldRecord(
            timestamp: r.timestamp,
            merchant: r.merchant,
            item: '916',
            sell: r.sell * 0.916,
            buy: r.buy * 0.916,
            spread: r.spread * 0.916
          ))
          .toList();
    } else if (_selectedPurity == 'Silver') {
      source = _history.where((r) => r.merchant == 'world_silver' && r.item == 'Silver').toList();
    } else {
      source = _history.where((r) => r.item == _selectedPurity && r.merchant != 'world_gold' && r.merchant != 'world_silver').toList();
    }

    if (source.isEmpty) return [];

    // Filter by Range
    DateTime now = DateTime.now();
    DateTime threshold;

    switch (_selectedRange) {
      case '7D':
        threshold = now.subtract(const Duration(days: 7));
        break;
      case '1M':
        threshold = now.subtract(const Duration(days: 30));
        break;
      case '6M':
        threshold = now.subtract(const Duration(days: 180));
        break;
      case '1Y':
        threshold = now.subtract(const Duration(days: 365));
        break;
      default:
        threshold = now.subtract(const Duration(days: 7));
    }

    return source.where((r) => r.timestamp.isAfter(threshold)).toList();
  }

  // Get unique merchants for the merchant list
  List<String> getMerchants() {
    return _history
        .map((r) => r.merchant)
        .where((m) => m != 'world_gold' && m != 'world_silver' && m != 'bsn')
        .toSet()
        .toList();
  }

  GoldRecord? getLatestForMerchant(String merchant, String purity) {
    var records = _history.where((r) => r.merchant == merchant && r.item == purity).toList();
    if (records.isEmpty) return null;
    return records.last;
  }

  // Aliases for compatibility with existing screens
  GoldRecord? getLatest(String merchant) => getLatestForMerchant(merchant, _selectedPurity);

  List<GoldRecord> getHistoryForMerchant(String merchant, [String? purity]) {
    final targetPurity = purity ?? _selectedPurity;
    return _history.where((r) => r.merchant == merchant && r.item == targetPurity).toList();
  }

  double getPercentageChange() {
    final history = getHistoryForDashboard();
    if (history.length < 2) return 0.0;
    
    final first = history.first.sell;
    final last = history.last.sell;
    
    if (first == 0) return 0.0;
    return ((last - first) / first) * 100;
  }
}
