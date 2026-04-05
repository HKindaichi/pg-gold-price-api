import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/portfolio_provider.dart';
import '../models/portfolio_entry.dart';

class SoldHistoryScreen extends StatelessWidget {
  const SoldHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolio = Provider.of<PortfolioProvider>(context);
    List<PortfolioEntry> soldEntries = portfolio.entries.where((e) => e.sellPricePerGram != null).toList();
    
    // Filter by selected owner
    if (portfolio.selectedOwner != "All") {
      soldEntries = soldEntries.where((e) => e.ownerName == portfolio.selectedOwner).toList();
    }

    // Sort by sell date (latest first), fallback to buy date for old records
    soldEntries.sort((a, b) {
      DateTime dateA = a.sellDate ?? a.date;
      DateTime dateB = b.sellDate ?? b.date;
      return dateB.compareTo(dateA);
    });

    double totalProfit = soldEntries.fold(0.0, (sum, e) {
      return sum + ((e.sellPricePerGram! - e.buyPricePerGram) * e.weight);
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sold History", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOwnerFilter(portfolio, context),
          _buildSummaryHeader(context, portfolio, totalProfit, isDark),
          _buildTableHeader(),
          Expanded(
            child: soldEntries.isEmpty
                ? const Center(child: Text("No sales recorded yet", style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: soldEntries.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                    itemBuilder: (context, index) {
                      final entry = soldEntries[index];
                      final profit = (entry.sellPricePerGram! - entry.buyPricePerGram) * entry.weight;
                      final profitPercent = entry.totalBuyPrice > 0 ? (profit / entry.totalBuyPrice) * 100 : 0.0;
                      final displayDate = entry.sellDate ?? entry.date;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                        child: Row(
                          children: [
                            // Column 1: Item
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${entry.weight}g (${entry.type})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    entry.notes.isNotEmpty ? entry.notes : DateFormat('d MMM yy').format(displayDate),
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Column 2: Bought
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Text(entry.totalBuyPrice.toStringAsFixed(0), style: const TextStyle(fontSize: 15)),
                                  Text("@ ${entry.buyPricePerGram.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                ],
                              ),
                            ),
                            // Column 3: Sold & Profit
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "RM ${(entry.sellPricePerGram! * entry.weight).toStringAsFixed(2)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    "${profit >= 0 ? '+' : ''}RM ${profit.toStringAsFixed(2)} (${profitPercent.toStringAsFixed(1)}%)",
                                    style: TextStyle(
                                      color: profit >= 0 ? Colors.greenAccent : Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerFilter(PortfolioProvider portfolio, BuildContext context) {
    final theme = Theme.of(context);
    final owners = portfolio.owners;
    if (owners.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 40,
      margin: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
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

  Widget _buildSummaryHeader(BuildContext context, PortfolioProvider portfolio, double totalProfit, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e293b) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
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
              const Text("Total Realized Profit", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                "RM ${totalProfit.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: totalProfit >= 0 ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text("ITEM", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("BOUGHT", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text("SOLD / PROFIT", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
