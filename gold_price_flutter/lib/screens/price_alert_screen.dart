import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gold_provider.dart';
import '../widgets/add_alert_dialog.dart';

class PriceAlertScreen extends StatelessWidget {
  const PriceAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Price Alerts"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFfbbf24),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_alert),
        onPressed: () {
          showDialog(context: context, builder: (_) => const AddAlertDialog());
        },
      ),
      body: Consumer<GoldProvider>(
        builder: (context, provider, child) {
          final alerts = provider.alerts;

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 15),
                  const Text("No alerts set", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 5),
                  const Text("Tap + to set a target price", style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Dismissible(
                key: Key(alert.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  provider.removeAlert(alert.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alert removed")));
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        // Icon based on type
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: alert.isActive ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            alert.itemType == 'Silver' ? Icons.shield_outlined : Icons.monetization_on_outlined,
                            color: alert.isActive ? const Color(0xFFfbbf24) : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.merchantId.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${alert.itemType} ${alert.condition.toUpperCase()} RM${alert.targetPrice.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: alert.isActive,
                          activeColor: const Color(0xFFfbbf24),
                          onChanged: (val) {
                            provider.toggleAlert(alert.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
