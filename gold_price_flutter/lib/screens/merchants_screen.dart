import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/gold_provider.dart';
import 'merchant_detail_screen.dart';

class MerchantsScreen extends StatelessWidget {
  const MerchantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Merchants", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<GoldProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter merchants that actually have data for the selected purity
          final merchants = provider.getMerchants().where((m) {
            return provider.getLatestForMerchant(m, provider.selectedPurity) != null;
          }).toList();

          return Column(
            children: [
              // Purity Selector (Reused style from HomeScreen)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e293b),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildPurityTab(context, provider, "999 (24K)", "999"),
                    _buildPurityTab(context, provider, "916 (22K)", "916"),
                    _buildPurityTab(context, provider, "Silver", "Silver"),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()), // Space for icon/name
                    SizedBox(
                      width: 175, // Reduced width for mobile
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          SizedBox(width: 55, child: Text("Shop Sells", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 9))),
                          SizedBox(width: 55, child: Text("Shop Buys", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 9))),
                          SizedBox(width: 45, child: Text("Spread", textAlign: TextAlign.right, style: TextStyle(color: Colors.redAccent, fontSize: 9))),
                          SizedBox(width: 18), // Space for arrow icon (16 + 2)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: merchants.isEmpty
                    ? Center(child: Text("No merchants data for ${provider.selectedPurity}", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: merchants.length,
                        itemBuilder: (context, index) {
                          final merchant = merchants[index];
                          final latest = provider.getLatestForMerchant(merchant, provider.selectedPurity);
                          
                          // Should be non-null due to filter above, but safe check
                          if (latest == null) return const SizedBox.shrink();

                          return _buildMerchantTile(context, latest);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPurityTab(BuildContext context, GoldProvider provider, String label, String value) {
    bool isSelected = provider.selectedPurity == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setPurity(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF334155) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantTile(BuildContext context, dynamic record) {
    final dateStr = DateFormat('d MMM H:mm').format(record.timestamp);
    final merchantId = record.merchant;

    // Mapping for logos
    final Map<String, String> merchantLogos = {
      'public_gold': 'assets/logos/public_gold.png',
      'miga_i': 'assets/logos/maybank.png',
      'cimb_e_gia': 'assets/logos/cimb.png',
      'biga_i': 'assets/logos/bank_islam.png',
      'uob': 'assets/logos/uob.png',
      'maa_gold': 'assets/logos/maa_gold.png',
      'gb_gold': 'assets/logos/gb_gold.png',
    };

    // Mapping for theme colors to hide any remaining white gaps
    final Map<String, Color> merchantColors = {
      'public_gold': Colors.black,
      'miga_i': const Color(0xFFFFD100), // Maybank Yellow
      'cimb_e_gia': const Color(0xFFE21B1B), // CIMB Red
      'biga_i': const Color(0xFF006633), // Bank Islam Green
      'uob': const Color(0xFF0038A8), // UOB Blue
      'maa_gold': const Color(0xFFFFD700), // MAA Gold Yellow
      'gb_gold': const Color(0xFF4CAF50), // GB Gold Green
    };

    // Mapping for display names
    final Map<String, String> merchantNames = {
      'public_gold': 'PublicGold',
      'miga_i': 'MIGA-i',
      'cimb_e_gia': 'e-GIA',
      'biga_i': 'BIGA-i',
      'uob': 'UOB',
      'maa_gold': 'MAA Gold',
      'gb_gold': 'GB Gold',
    };

    final logoPath = merchantLogos[merchantId];
    final themeColor = merchantColors[merchantId] ?? Colors.white.withOpacity(0.1);
    final displayName = merchantNames[merchantId] ?? record.merchant.replaceAll('_', ' ').replaceAll('-', ' ').toUpperCase();
    
    // Custom zoom for specific logos that have thicker white borders
    double logoScale = 1.15;
    if (merchantId == 'cimb_e_gia') {
      logoScale = 1.7; // Even more zoom to kill that white ring
    } else if (merchantId == 'public_gold') {
      logoScale = 1.3; // Slightly more for PG too
    }
    if (merchantId == 'miga_i') {
      logoScale = 1.2; // Tiny bit more for Maybank
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12), // Tighter padding
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MerchantDetailScreen(
              merchantId: record.merchant, 
              merchantName: displayName,
            ),
          ),
        );
      },
      leading: Container(
        width: 32, // Slightly smaller
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: themeColor, // Background color matching the bank
        ),
        clipBehavior: Clip.antiAlias, 
        child: logoPath != null 
          ? Transform.scale(
              scale: logoScale, // Dynamic scale based on merchant
              child: Image.asset(
                logoPath, 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    record.merchant[0].toUpperCase(),
                    style: const TextStyle(color: Color(0xFFfbbf24), fontSize: 12),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                record.merchant[0].toUpperCase(),
                style: const TextStyle(color: Color(0xFFfbbf24), fontSize: 12),
              ),
            ),
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
      subtitle: Text(
        "Upd. $dateStr", 
        style: const TextStyle(color: Colors.grey, fontSize: 9),
      ),
      trailing: SizedBox(
        width: 175, // Match the header width
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 55,
              child: Text(
                record.sell.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              width: 55,
              child: Text(
                record.buy.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            SizedBox(
              width: 45,
              child: Text(
                record.spread.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
