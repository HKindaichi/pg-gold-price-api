import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/portfolio_provider.dart';
import '../services/gold_provider.dart';
import '../models/portfolio_entry.dart';
import 'add_portfolio_entry_screen.dart';
import 'sold_history_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String _activeTab = 'Gold'; // 'Gold' or 'Silver'

  @override
  Widget build(BuildContext context) {
    final portfolio = Provider.of<PortfolioProvider>(context);
    final gold = Provider.of<GoldProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Assets", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SoldHistoryScreen()),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isDark ? Colors.white30 : Colors.black12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
              child: Text(
                "SOLD HISTORY",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
      body: portfolio.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOwnerFilter(portfolio),
                _buildSummary(context, portfolio, gold),
                _buildHeaderRow(),
                Expanded(
                  child: _buildAssetList(context, portfolio, gold),
                ),
              ],
            ),
      floatingActionButton: SizedBox(
        width: 48,
        height: 48,
        child: FloatingActionButton(
          onPressed: () => _navigateToAddEntry(context),
          backgroundColor: const Color(0xFFfbbf24),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.add, size: 24),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, PortfolioProvider portfolio, GoldProvider gold) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate totals for all active entries
    final activeEntries = portfolio.filteredEntries.where((e) => e.sellPricePerGram == null).toList();
    
    final goldWeight = activeEntries
        .where((e) => e.type == '999' || e.type == '916')
        .fold(0.0, (sum, e) => sum + e.weight);
    
    final silverWeight = activeEntries
        .where((e) => e.type == 'Silver')
        .fold(0.0, (sum, e) => sum + e.weight);

    final currentVal = portfolio.calculateCurrentMarketValue(gold, owner: portfolio.selectedOwner);
    final totalInv = portfolio.calculateTotalAsset(owner: portfolio.selectedOwner);
    final unrealizedPL = portfolio.calculateTotalUnrealizedPL(gold, owner: portfolio.selectedOwner);
    final roi = totalInv > 0 ? (unrealizedPL / totalInv) * 100 : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          // Delete Owner Button (Red Dustbin)
          if (portfolio.selectedOwner != "All")
            Positioned(
              right: 0,
              top: 0,
              child: InkWell(
                onTap: () => _showDeleteOwnerDialog(context, portfolio.selectedOwner, portfolio),
                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
              ),
            ),
          Column(
            children: [
              const Text("Live Portfolio Value", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                "RM ${NumberFormat("#,##0.00").format(currentVal)}",
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFfbbf24),
                ),
              ),
              const SizedBox(height: 8),
              // Clean Two-Column Layout
              IntrinsicHeight(
                child: Row(
                  children: [
                    // Column 1: Assets (Gold/Silver)
                    Expanded(
                      flex: 2,
                      child: silverWeight > 0 
                        ? Row(
                            children: [
                              // Sub-column: Gold
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Gold", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text("${goldWeight.toStringAsFixed(1)}g", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ),
                                  ],
                                ),
                              ),
                              // Inner divider for Assets (Solid Line)
                              Container(
                                width: 1.5, // Increased thickness
                                color: Colors.grey.withOpacity(0.4), // Slightly darker
                                margin: const EdgeInsets.symmetric(vertical: 4), // Matched height
                              ),
                              // Sub-column: Silver
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Silver", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text("${silverWeight.toStringAsFixed(1)}g", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Gold Owned", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text("${goldWeight.toStringAsFixed(1)}g", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ],
                          ),
                    ),
                    // Vertical Divider (Outer)
                    Container(
                      width: 1.5, // Increased thickness
                      color: Colors.grey.withOpacity(0.4), // Slightly darker
                      margin: const EdgeInsets.symmetric(vertical: 4), // Matched height
                    ),
                    // Column 2: Profits
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          const Text(
                            "Unrealized Profit",
                            style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${unrealizedPL >= 0 ? '+' : ''}RM ${NumberFormat("#,##0.00").format(unrealizedPL)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 15, 
                                  color: unrealizedPL >= 0 ? Colors.greenAccent : Colors.redAccent
                                )
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "(${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(1)}%)",
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold,
                                  color: unrealizedPL >= 0 ? Colors.greenAccent : Colors.redAccent
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text("ITEM", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("BOUGHT", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text("CURRENT", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildAssetList(BuildContext context, PortfolioProvider portfolio, GoldProvider gold) {
    final entries = portfolio.filteredEntries.where((e) => e.sellPricePerGram == null).toList();

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text("No active holdings", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final currentPrice = portfolio.getLatestPrice(entry.type, gold);
        final currentVal = currentPrice * entry.weight;
        final profit = currentVal - entry.totalBuyPrice;
        final profitPercent = entry.totalBuyPrice > 0 ? (profit / entry.totalBuyPrice) * 100 : 0.0;

        return InkWell(
          onTap: () => _showAssetActionSheet(context, entry, gold),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                // Column 1: Weight & Purity
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("${entry.weight}g", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          const SizedBox(width: 4),
                          Text("(${entry.type})", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      Text(
                        entry.notes.isNotEmpty ? entry.notes : DateFormat('d MMM yy').format(entry.date),
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Column 2: Bought Price
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text(
                        "RM ${NumberFormat("#,###").format(entry.totalBuyPrice)}",
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                      ),
                      Text(
                        "@ RM ${NumberFormat("#,###").format(entry.buyPricePerGram)}",
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Column 3: Current Value & Profit
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "RM ${NumberFormat("#,##0.00").format(currentVal)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: profit >= 0 ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            profit >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: profit >= 0 ? Colors.greenAccent : Colors.redAccent,
                            size: 18,
                          ),
                          Text(
                            "${profitPercent.abs().toStringAsFixed(1)}%",
                            style: TextStyle(
                              color: profit >= 0 ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToAddEntry(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPortfolioEntryScreen()),
    );
  }

  Widget _buildOwnerFilter(PortfolioProvider portfolio) {
    final theme = Theme.of(context);
    final owners = portfolio.owners;
    if (owners.length <= 1) return const SizedBox.shrink(); // Hide if only "All"

    return Container(
      height: 40,
      margin: const EdgeInsets.only(left: 16, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: owners.length,
        itemBuilder: (context, index) {
          final owner = owners[index];
          final isSelected = portfolio.selectedOwner == owner;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(
                owner,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                ),
              ),
              selected: isSelected,
              onSelected: (_) => portfolio.setSelectedOwner(owner),
              selectedColor: const Color(0xFFfbbf24),
              checkmarkColor: Colors.black,
              backgroundColor: Colors.transparent,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? Colors.transparent : (theme.brightness == Brightness.dark ? Colors.white24 : Colors.black12),
                ),
              ),
              showCheckmark: isSelected,
            ),
          );
        },
      ),
    );
  }

  void _showDeleteOwnerDialog(BuildContext context, String owner, PortfolioProvider portfolio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete '$owner'?"),
        content: Text("This will permanently remove ALL active assets and sold history for $owner. This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              portfolio.deleteOwnerRecords(owner);
              if (portfolio.selectedOwner == owner) {
                portfolio.setSelectedOwner("All");
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("All records for $owner deleted")),
              );
            },
            child: const Text("DELETE ALL", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAssetActionSheet(BuildContext context, dynamic entry, GoldProvider gold) {
    final portfolio = Provider.of<PortfolioProvider>(context, listen: false);
    final currentPrice = portfolio.getLatestPrice(entry.type, gold);
    final currentVal = currentPrice * entry.weight;
    final profit = currentVal - entry.totalBuyPrice;
    final profitPercent = entry.totalBuyPrice > 0 ? (profit / entry.totalBuyPrice) * 100 : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1e293b) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${entry.weight}g (${entry.type})",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          entry.ownerName,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (profit >= 0 ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${profit >= 0 ? '+' : ''}${profitPercent.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: profit >= 0 ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Info Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow("Purchase Date", DateFormat('d MMMM yyyy').format(entry.date)),
                  if (entry.notes.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildDetailRow("Notes", entry.notes),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSheetStat("Buy Price", "RM ${NumberFormat("#,##0.00").format(entry.totalBuyPrice)}"),
                _buildSheetStat("Current Value", "RM ${NumberFormat("#,##0.00").format(currentVal)}", 
                  color: profit >= 0 ? Colors.greenAccent : Colors.redAccent),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddPortfolioEntryScreen(entry: entry)),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text("EDIT", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close action sheet
                        _showSellDialog(context, entry); // Show sell dialog directly
                      },
                      icon: const Icon(Icons.sell_outlined),
                      label: const Text("SELL", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFfbbf24),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSellDialog(BuildContext context, PortfolioEntry entry) {
    final priceController = TextEditingController();
    final weightController = TextEditingController(text: entry.weight.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double sellPrice = double.tryParse(priceController.text) ?? 0.0;
            double sellWeight = double.tryParse(weightController.text) ?? 0.0;
            double realizedPL = (sellPrice - entry.buyPricePerGram) * sellWeight;
            bool isValid = sellPrice > 0 && sellWeight > 0 && sellWeight <= entry.weight;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 32,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1e293b) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sell Asset", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildBoxedTextField(
                    controller: weightController,
                    label: "Weight to sell (g)",
                    hint: "Max ${entry.weight}",
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _buildBoxedTextField(
                    controller: priceController,
                    label: "Sell Price (RM/g)",
                    hint: "e.g. 460",
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Realized Profit", style: TextStyle(color: Colors.grey)),
                        Text(
                          "RM ${NumberFormat("#,##0.00").format(realizedPL)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: realizedPL >= 0 ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("BACK", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: !isValid ? null : () {
                              Provider.of<PortfolioProvider>(context, listen: false).sellEntry(entry.id, sellPrice, sellWeight);
                              Navigator.pop(context); // Close bottom sheet
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFfbbf24),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.grey.withOpacity(0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("CONFIRM SELL", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBoxedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFfbbf24))),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }

  Widget _buildSheetStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
