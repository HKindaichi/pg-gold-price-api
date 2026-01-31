import 'dart:convert';

class DiaryEntry {
  final String id;
  final String ownerName;
  final double weight;
  final double buyPrice;
  final double? sellPrice; // Null if not sold yet
  final String type; // 999, 916, Silver
  final DateTime date;
  final String notes;

  DiaryEntry({
    required this.id,
    required this.ownerName,
    required this.weight,
    required this.buyPrice,
    this.sellPrice,
    required this.type,
    required this.date,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerName': ownerName,
      'weight': weight,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'type': type,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'],
      ownerName: map['ownerName'],
      weight: map['weight'],
      buyPrice: map['buyPrice'],
      sellPrice: map['sellPrice'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DiaryEntry.fromJson(String source) => DiaryEntry.fromMap(json.decode(source));
}
