import 'dart:convert';

class PortfolioEntry {
  final String id;
  final String ownerName;
  final double weight;
  final double buyPricePerGram;
  final double? sellPricePerGram; // Null if not sold yet
  final String type; // 999, 916, Silver
  final DateTime date;
  final String notes;

  PortfolioEntry({
    required this.id,
    required this.ownerName,
    required this.weight,
    required this.buyPricePerGram,
    this.sellPricePerGram,
    required this.type,
    required this.date,
    required this.notes,
  });

  double get totalBuyPrice => weight * buyPricePerGram;
  double get totalSellPrice => (sellPricePerGram ?? 0.0) * weight;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerName': ownerName,
      'weight': weight,
      'buyPricePerGram': buyPricePerGram,
      'sellPricePerGram': sellPricePerGram,
      'type': type,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory PortfolioEntry.fromMap(Map<String, dynamic> map) {
    return PortfolioEntry(
      id: map['id'],
      ownerName: map['ownerName'] ?? 'Me',
      weight: (map['weight'] as num).toDouble(),
      buyPricePerGram: (map['buyPricePerGram'] ?? map['buyPrice'] ?? 0.0).toDouble(),
      sellPricePerGram: map['sellPricePerGram'] != null 
          ? (map['sellPricePerGram'] as num).toDouble() 
          : (map['sellPrice'] != null ? (map['sellPrice'] as num).toDouble() : null),
      type: map['type'],
      date: DateTime.parse(map['date']),
      notes: map['notes'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PortfolioEntry.fromJson(String source) => PortfolioEntry.fromMap(json.decode(source));
}
