import 'dart:convert';

class PriceAlert {
  final String id;
  final String merchantId;
  final String itemType; // '999', '916', 'Silver'
  final double targetPrice;
  final String condition; // 'above', 'below'
  final bool isActive;

  PriceAlert({
    required this.id,
    required this.merchantId,
    required this.itemType,
    required this.targetPrice,
    required this.condition,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantId': merchantId,
      'itemType': itemType,
      'targetPrice': targetPrice,
      'condition': condition,
      'isActive': isActive,
    };
  }

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'],
      merchantId: json['merchantId'],
      itemType: json['itemType'],
      targetPrice: (json['targetPrice'] as num).toDouble(),
      condition: json['condition'],
      isActive: json['isActive'] ?? true,
    );
  }
}
