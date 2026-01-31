import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/portfolio_provider.dart';
import 'add_portfolio_entry_screen.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Portfolio", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text("Empty Portfolio", style: TextStyle(color: Colors.grey, fontSize: 18)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddEntry(context),
                    icon: const Icon(Icons.add),
                    label: const Text("Add First Entry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfbbf24),
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }

          final stats999 = provider.calculateStats('999', owner: provider.selectedOwner);
          final stats916 = provider.calculateStats('916', owner: provider.selectedOwner);
          final statsSilver = provider.calculateStats('Silver', owner: provider.selectedOwner);
          final totalPL = provider.calculateTotalPL(owner: provider.selectedOwner);
          final totalAsset = provider.calculateTotalAsset(owner: provider.selectedOwner);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOwnerSelector(provider),
              _buildSummaryHeader(stats999, stats916, statsSilver, totalPL, totalAsset),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text("Recent Entries", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: provider.filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = provider.filteredEntries[index];
                    return _buildEntryCard(context, entry, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEntry(context),
        backgroundColor: const Color(0xFFfbbf24),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddEntry(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPortfolioEntryScreen()),
    );
  }

  Widget _buildOwnerSelector(PortfolioProvider provider) {
    final owners = provider.owners;
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: owners.length,
        itemBuilder: (context, index) {
          final owner = owners[index];
          bool isSelected = provider.selectedOwner == owner;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(owner),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) provider.setSelectedOwner(owner);
              },
              selectedColor: const Color(0xFFfbbf24),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: const Color(0xFF1e293b),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(double weight999, double weight916, double weightSilver, double totalPL, double totalAsset) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem("999 Gold", "${weight999.toStringAsFixed(2)}g", Colors.orangeAccent),
              Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
              _buildSummaryItem("916 Gold", "${weight916.toStringAsFixed(2)}g", Colors.yellowAccent),
              Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
              _buildSummaryItem("Silver", "${weightSilver.toStringAsFixed(2)}g", Colors.blueGrey),
            ],
          ),
          const Divider(height: 30, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Asset Value", style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                "RM ${totalAsset.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Realized P/L", style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                "${totalPL >= 0 ? '+' : ''}RM ${totalPL.toStringAsFixed(2)}",
                style: TextStyle(
                  color: totalPL >= 0 ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEntryCard(BuildContext context, dynamic entry, PortfolioProvider provider) {
    final dateStr = DateFormat('d MMM yyyy').format(entry.date);
    final bool isSold = entry.sellPricePerGram != null;
    final double pl = isSold ? ((entry.sellPricePerGram! - entry.buyPricePerGram) * entry.weight) : 0.0;
    
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (direction) {
        provider.deleteEntry(entry.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Entry deleted")),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isSold ? Colors.black.withOpacity(0.3) : const Color(0xFF1e293b).withOpacity(0.5),
        child: InkWell(
          onTap: isSold ? null : () => _showSellDialog(context, entry, provider),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSold 
                            ? Colors.grey.withOpacity(0.1)
                            : (entry.type == '999' 
                                ? Colors.orangeAccent.withOpacity(0.1) 
                                : (entry.type == '916' 
                                    ? Colors.yellowAccent.withOpacity(0.1) 
                                    : Colors.blueGrey.withOpacity(0.1))),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSold ? Icons.check_circle_outline : Icons.payments_outlined, 
                        color: isSold 
                            ? Colors.grey 
                            : (entry.type == '999' 
                                ? Colors.orangeAccent 
                                : (entry.type == '916' ? Colors.yellowAccent : Colors.blueGrey)),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "${entry.weight}g   ${(entry.type == '999' || entry.type == '916') ? 'Gold ${entry.type}' : entry.type}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  color: isSold ? Colors.grey : Colors.white,
                                ),
                              ),
                              if (isSold) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text("SOLD", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(entry.ownerName, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                              ),
                              const SizedBox(width: 8),
                              Text("Buy date: $dateStr", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "RM ${entry.totalBuyPrice.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 15, 
                            color: isSold ? Colors.grey : const Color(0xFFfbbf24),
                          ),
                        ),
                        Text(
                          "@ RM ${entry.buyPricePerGram.toStringAsFixed(2)}/g",
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                        if (isSold)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Sold @ RM ${entry.sellPricePerGram!.toStringAsFixed(2)}/g",
                              style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (isSold) ...[
                  const Divider(height: 20, color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Profit/Loss", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        "${pl >= 0 ? '+' : ''}RM ${pl.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: pl >= 0 ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
                if (!isSold && entry.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 48),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entry.notes, 
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSellDialog(BuildContext context, dynamic entry, PortfolioProvider provider) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0f172a),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sell Gold Entry", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Bought at RM ${entry.buyPricePerGram.toStringAsFixed(2)}/g", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: "Sell Price (RM per gram)",
                prefixText: "RM ",
                suffixText: "/g",
                filled: true,
                fillColor: const Color(0xFF1e293b),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final price = double.tryParse(controller.text);
                  if (price != null) {
                    provider.sellEntry(entry.id, price);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Confirm Sale", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
