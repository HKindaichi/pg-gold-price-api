import 'package:flutter/material.dart';
import 'merchant_detail_screen.dart';

class MerchantListScreen extends StatelessWidget {
  const MerchantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MERCHANTS"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            _buildMerchantItem(context, id: "public_gold", name: "Public Gold"),
            const SizedBox(height: 15),
            _buildMerchantItem(context, id: "miga_i", name: "MIGA-i"),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantItem(BuildContext context, {required String id, required String name}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MerchantDetailScreen(merchantId: id, merchantName: name),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "View >",
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
