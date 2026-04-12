class GoldRecord {
  final DateTime timestamp;
  final String merchant; // public_gold, miga_i
  final String item; // 999
  final double sell;
  final double buy;
  final double spread;

  GoldRecord({
    required this.timestamp,
    required this.merchant,
    required this.item,
    required this.sell,
    required this.buy,
    required this.spread,
  });

  factory GoldRecord.fromCsv(List<dynamic> row) {
    // Expected format: timestamp, merchant, item, sell, buy, spread
    // 2026-01-31 09:31:14,public_gold,999,652.06,600.0,52.06
    
    DateTime? parsedDate = DateTime.tryParse(row[0].toString());
    
    return GoldRecord(
      timestamp: parsedDate ?? DateTime.now(),
      merchant: row.length > 1 ? row[1].toString() : 'unknown',
      item: row.length > 2 ? row[2].toString() : 'unknown',
      sell: row.length > 3 ? (double.tryParse(row[3].toString()) ?? 0.0) : 0.0,
      buy: row.length > 4 ? (double.tryParse(row[4].toString()) ?? 0.0) : 0.0,
      spread: row.length > 5 ? (double.tryParse(row[5].toString()) ?? 0.0) : 0.0,
    );
  }

  @override
  String toString() {
    return 'GoldRecord($timestamp, $merchant, $sell, $buy)';
  }
}
