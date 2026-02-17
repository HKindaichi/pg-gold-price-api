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
            return provider.getLatestForMerchant(m, provider.merchantPurity) != null;
          }).toList();

          // Sort watchlist to the top
          merchants.sort((a, b) {
            bool aWatched = provider.isWatched(a);
            bool bWatched = provider.isWatched(b);
            if (aWatched && !bWatched) return -1;
            if (!aWatched && bWatched) return 1;
            return 0; // Keep original relative order
          });

          return Column(
            children: [
              // Purity Selector (Reused style from HomeScreen)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: Theme.of(context).brightness == Brightness.light 
                    ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                    : null,
                ),
                child: Row(
                  children: [
                    _buildPurityTab(context, provider, "Gold 999", "999"),
                    _buildPurityTab(context, provider, "Gold 916", "916"),
                    _buildPurityTab(context, provider, "Silver", "Silver"),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10), // Matches card margin (16) + card padding (12)
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    SizedBox(
                      width: 185, // Increased from 180 to prevent overflow (children total 182)
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(width: 60, child: Text("Shop Sells", textAlign: TextAlign.right, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 9, fontWeight: FontWeight.w600))),
                          SizedBox(width: 60, child: Text("Shop Buys", textAlign: TextAlign.right, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 9, fontWeight: FontWeight.w600))),
                          SizedBox(width: 48, child: Text("Spread", textAlign: TextAlign.right, style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.w600))),
                          const SizedBox(width: 12), // Adjusted Chevron space
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: merchants.isEmpty
                    ? Center(child: Text("No merchants data for ${provider.merchantPurity}", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: merchants.length,
                        itemBuilder: (context, index) {
                          final merchant = merchants[index];
                          final latest = provider.getLatestForMerchant(merchant, provider.merchantPurity);
                          
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
    bool isSelected = provider.merchantPurity == value;
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setMerchantPurity(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (theme.brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFfbbf24)) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black) : (theme.brightness == Brightness.dark ? Colors.grey : Colors.black45),
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
      'cimb_e_gia': 'assets/logos/cimb_premium.png',
      'biga_i': 'assets/logos/bank_islam.png',
      'uob': 'assets/logos/uob.png',
      'maa_gold': 'assets/logos/maa_gold.png',
      'gb_gold': 'assets/logos/gb_gold.png',
      'easigold': 'assets/logos/muamalat_premium.png',
      'maybank_silver': 'assets/logos/maybank.png',
      'mygold_i': 'assets/logos/bsn_premium.png',
      'pbb': 'assets/logos/public_bank.png',
    };

    // Mapping for theme colors
    final Map<String, Color> merchantColors = {
      'public_gold': Colors.white,
      'miga_i': const Color(0xFFFFD100), 
      'cimb_e_gia': const Color(0xFFE21B1B), 
      'biga_i': const Color(0xFF006633), 
      'uob': const Color(0xFF0038A8), 
      'maa_gold': const Color(0xFFFFD700), 
      'gb_gold': const Color(0xFF4CAF50), 
      'easigold': const Color(0xFF003366), 
      'maybank_silver': const Color(0xFFFFD100), 
      'mygold_i': Colors.teal,
      'pbb': const Color(0xFFE31E24), // Public Bank Red
    };

    // Mapping for display names
    final Map<String, String> merchantNames = {
      'public_gold': 'Public Gold',
      'miga_i': 'MIGA-i',
      'cimb_e_gia': 'e-GIA',
      'biga_i': 'BIGA-i',
      'uob': 'UOB-GSA',
      'maa_gold': 'MAA Gold',
      'gb_gold': 'GB Gold',
      'easigold': 'EasiGold',
      'maybank_silver': 'MSIA',
      'mygold_i': 'MyGold-i',
      'pbb': 'PBB',
    };

    final logoPath = merchantLogos[merchantId];
    final themeColor = merchantColors[merchantId] ?? Colors.white.withOpacity(0.1);
    final displayName = merchantNames[merchantId] ?? record.merchant.replaceAll('_', ' ').replaceAll('-', ' ').toUpperCase();
    
    double logoScale = 1.15;
    if (merchantId == 'cimb_e_gia') logoScale = 1.7;
    else if (merchantId == 'public_gold') logoScale = 1.0;
    if (merchantId == 'miga_i' || merchantId == 'maybank_silver') logoScale = 1.2;

    bool isNonSyariah = (merchantId == 'uob' || merchantId == 'maybank_silver' || merchantId == 'cimb_e_gia' || merchantId == 'pbb');
    bool isSyariah = (merchantId == 'public_gold' || merchantId == 'miga_i' || merchantId == 'biga_i' || merchantId == 'easigold' || merchantId == 'mygold_i');

    final appTheme = Theme.of(context);

    final provider = Provider.of<GoldProvider>(context, listen: false);
    bool isWatched = provider.isWatched(merchantId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isWatched 
            ? (appTheme.brightness == Brightness.dark ? Colors.amber.withOpacity(0.04) : const Color(0xFFFFFEFA))
            : appTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: appTheme.brightness == Brightness.light 
          ? [BoxShadow(
              color: isWatched ? Colors.amber.withOpacity(0.1) : Colors.black.withOpacity(0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            )]
          : null,
        border: Border.all(
          color: isWatched ? Colors.amber.withOpacity(0.3) : appTheme.dividerColor.withOpacity(0.05),
          width: isWatched ? 1.2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                // Logo Section
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColor,
                  ),
                  clipBehavior: Clip.antiAlias, 
                  child: logoPath != null 
                    ? Transform.scale(
                        scale: logoScale,
                        child: Image.asset(
                          logoPath, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              record.merchant[0].toUpperCase(),
                              style: const TextStyle(color: Color(0xFFfbbf24), fontSize: 14),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          record.merchant[0].toUpperCase(),
                          style: const TextStyle(color: Color(0xFFfbbf24), fontSize: 14),
                        ),
                      ),
                ),
                const SizedBox(width: 12),
                // Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Slightly smaller font
                        maxLines: 2, // Allow 2 lines for long names
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSyariah)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.teal.withOpacity(0.5)),
                            ),
                            child: const Text("Syariah", style: TextStyle(color: Colors.teal, fontSize: 7, fontWeight: FontWeight.bold)),
                          ),
                        )
                      else if (isNonSyariah)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                            ),
                            child: const Text("Non-Syariah", style: TextStyle(color: Colors.redAccent, fontSize: 7, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        "Upd. $dateStr", 
                        style: TextStyle(color: appTheme.brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                // Prices Section
                SizedBox(
                  width: 185, // Matched with header
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          record.sell.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appTheme.brightness == Brightness.dark ? Colors.white : Colors.black87),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          record.buy.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appTheme.brightness == Brightness.dark ? Colors.grey : Colors.black54),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          record.spread.toStringAsFixed(2),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
