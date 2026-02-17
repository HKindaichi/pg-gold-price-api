import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/gold_price.dart';
import '../models/price_alert.dart';
import 'data_service.dart';
import 'notification_service.dart';

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

  // Alerts
  List<PriceAlert> _alerts = [];
  List<PriceAlert> get alerts => _alerts;

  final NotificationService _notificationService = NotificationService();

  Future<void> _loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? alertsJson = prefs.getString('price_alerts');
    if (alertsJson != null) {
      final List<dynamic> decoded = jsonDecode(alertsJson);
      _alerts = decoded.map((e) => PriceAlert.fromJson(e)).toList();
    }
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_alerts.map((e) => e.toJson()).toList());
    await prefs.setString('price_alerts', encoded);
    notifyListeners();
  }

  Future<void> addAlert(PriceAlert alert) async {
    _alerts.add(alert);
    await _saveAlerts();
  }

  Future<void> removeAlert(String id) async {
    _alerts.removeWhere((a) => a.id == id);
    await _saveAlerts();
  }

  Future<void> toggleAlert(String id) async {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alert = _alerts[index];
      _alerts[index] = PriceAlert(
        id: alert.id,
        merchantId: alert.merchantId,
        itemType: alert.itemType,
        targetPrice: alert.targetPrice,
        condition: alert.condition,
        isActive: !alert.isActive,
      );
      await _saveAlerts();
    }
  }

  void checkAlerts() async {
    if (_alerts.isEmpty) return;
    
    // Initialize notification service if not already
    // Ideally call this once in main, but safe here too
    await _notificationService.init();

    for (var alert in _alerts) {
      if (!alert.isActive) continue;

      // Find current price
      GoldRecord? record = getLatestForMerchant(alert.merchantId, alert.itemType);
      
      // Special handling for '916' if not directly available (calculated)
      if (record == null && alert.itemType == '916' && alert.merchantId == 'world_gold') {
         // Re-use logic from getLatestForDashboard
         var r999 = getLatestForMerchant('world_gold', '999');
         if (r999 != null) {
             record = GoldRecord(
                 timestamp: r999.timestamp,
                 merchant: r999.merchant,
                 item: '916',
                 sell: r999.sell * 0.916,
                 buy: r999.buy * 0.916,
                 spread: r999.spread * 0.916 
             );
         }
      }

      if (record != null) {
        bool triggered = false;
        double currentPrice = record.sell; // Use Sell price (what user buys at) usually

        if (alert.condition == 'above' && currentPrice > alert.targetPrice) {
          triggered = true;
        } else if (alert.condition == 'below' && currentPrice < alert.targetPrice) {
          triggered = true;
        }

        if (triggered) {
          final merchantName = record.merchant.toUpperCase().replaceAll('_', ' ');
          final body = "Price reached! $merchantName ${alert.itemType} is now RM${currentPrice.toStringAsFixed(2)}";
          await _notificationService.showPriceAlert("Price Alert: ${alert.condition.toUpperCase()} RM${alert.targetPrice}", body);
        }
      }
    }
  }
}
