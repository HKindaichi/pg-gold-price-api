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
        title: const Text("My Assets", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
              _buildOwnerSelector(context, provider),
              _buildSummaryHeader(context, stats999, stats916, statsSilver, totalPL, totalAsset),
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

  Widget _buildOwnerSelector(BuildContext context, PortfolioProvider provider) {
    final owners = provider.owners;
    final theme = Theme.of(context);
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
                color: isSelected ? Colors.black : (theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, double weight999, double weight916, double weightSilver, double totalPL, double totalAsset) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: theme.brightness == Brightness.light 
          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
          : null,
        border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.transparent),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
            Expanded(child: _buildSummaryItem(context, "999 Gold", "${weight999.toStringAsFixed(2)}g", Colors.orangeAccent)),
            Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
            Expanded(child: _buildSummaryItem(context, "916 Gold", "${weight916.toStringAsFixed(2)}g", theme.brightness == Brightness.dark ? Colors.yellowAccent : Colors.orange[800]!)),
            Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.2)),
            Expanded(child: _buildSummaryItem(context, "Silver", "${weightSilver.toStringAsFixed(2)}g", const Color(0xFF4DD0E1))),
            ],
          ),
          Divider(height: 30, color: theme.dividerColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Asset Value", style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 13)),
              Text(
                "RM ${totalAsset.toStringAsFixed(2)}",
                style: TextStyle(
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
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
              Text("Total Realized P/L", style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 13)),
              Text(
                "${totalPL >= 0 ? '+' : ''}RM ${totalPL.toStringAsFixed(2)}",
                style: TextStyle(
                  color: totalPL >= 0 ? (theme.brightness == Brightness.dark ? Colors.greenAccent : Colors.green[700]) : Colors.redAccent,
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

  Widget _buildSummaryItem(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    final Color labelColor = theme.brightness == Brightness.dark ? Colors.grey : Colors.black54;
    return Column(
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildEntryCard(BuildContext context, dynamic entry, PortfolioProvider provider) {
    final dateStr = DateFormat('d MMM yyyy').format(entry.date);
    final bool isSold = entry.sellPricePerGram != null;
    final double pl = isSold ? ((entry.sellPricePerGram! - entry.buyPricePerGram) * entry.weight) : 0.0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isSold 
          ? (isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1)) 
          : theme.cardColor,
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
                      padding: const EdgeInsets.all(8), // Reduced padding
                      decoration: BoxDecoration(
                        color: isSold 
                            ? Colors.grey.withOpacity(0.1)
                            : (entry.type == '999' 
                                ? Colors.orangeAccent.withOpacity(0.1) 
                                : (entry.type == '916' 
                                    ? Colors.yellowAccent.withOpacity(0.1) 
                                    : const Color(0xFF4DD0E1).withOpacity(0.1))), // Matching Cyan color
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSold ? Icons.check_circle_outline : Icons.payments_outlined, 
                        color: isSold 
                            ? Colors.grey 
                            : (entry.type == '999' 
                                ? Colors.orangeAccent 
                                : (entry.type == '916' 
                                    ? (isDark ? Colors.yellowAccent : Colors.orange[800]!) 
                                    : const Color(0xFF4DD0E1))),
                        size: 20, // Reduced size
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Weight (Big & Clean) + SOLD Tag
                      Row(
                        children: [
                          Text(
                            "${entry.weight}g",
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16,
                              color: isSold 
                                  ? Colors.grey 
                                  : (entry.type == '999' 
                                      ? Colors.orangeAccent 
                                      : (entry.type == '916' 
                                          ? (isDark ? Colors.yellowAccent : Colors.orange[800]!) 
                                          : const Color(0xFF4DD0E1))),
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
                      
                      // 2. Owner + Type (Small & Grey)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(entry.ownerName, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 10)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (entry.type == '999' || entry.type == '916') ? '${entry.type} Gold' : entry.type,
                            style: TextStyle(
                              color: entry.type == '999' 
                                  ? Colors.orangeAccent 
                                  : (entry.type == '916' 
                                      ? (isDark ? Colors.yellowAccent : Colors.orange[800]!) 
                                      : const Color(0xFF4DD0E1)), 
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      // 3. Purchase From (Notes)
                      if (!isSold && entry.notes.isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(top: 4),
                           child: Text(
                             entry.notes, 
                             style: const TextStyle(color: Colors.grey, fontSize: 11),
                           ),
                         ),

                      // 4. Buy Date (Below Purchase From)
                       Padding(
                         padding: const EdgeInsets.only(top: 2),
                         child: FittedBox(
                           fit: BoxFit.scaleDown,
                           alignment: Alignment.centerLeft,
                           child: Text("Buy date: $dateStr", maxLines: 1, style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 10)),
                         ),
                       ),
                    ],
                  ),
                ),
                // Price Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "RM ${entry.totalBuyPrice.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 15, 
                        color: isSold ? Colors.grey : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    Text(
                      "@ RM ${entry.buyPricePerGram.toStringAsFixed(2)}/g",
                      style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 10),
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
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _confirmDelete(context, provider, entry),
                ),
              ],
            ),
            if (isSold) ...[
              Divider(height: 20, color: theme.dividerColor),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Profit/Loss", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    "${pl >= 0 ? '+' : ''}RM ${pl.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: pl >= 0 ? (isDark ? Colors.greenAccent : Colors.green[700]) : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  ),
);
}

void _confirmDelete(BuildContext context, PortfolioProvider provider, dynamic entry) {
showDialog(
  context: context,
  builder: (context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text("Delete Entry?", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
      content: Text(
        "Are you sure you want to delete this asset entry? This action cannot be undone.",
        style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
      ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text("Cancel"),
      ),
      TextButton(
        onPressed: () {
          provider.deleteEntry(entry.id);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Entry deleted")),
          );
        },
        child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
      ),
    ],
  );
},
);
}
  void _showSellDialog(BuildContext context, dynamic entry, PortfolioProvider provider) {
    final priceController = TextEditingController();
    final weightController = TextEditingController(text: entry.weight.toString());
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            
            double sellPrice = double.tryParse(priceController.text) ?? 0.0;
            double sellWeight = double.tryParse(weightController.text) ?? 0.0;
            
            // Calculations
            double remainingWeight = (entry.weight - sellWeight).clamp(0.0, entry.weight);
            double totalSaleValue = sellWeight * sellPrice;
            double totalCost = sellWeight * entry.buyPricePerGram;
            double realizedPL = totalSaleValue - totalCost;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sell Gold Entry", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 8),
                  Text("Bought at RM ${entry.buyPricePerGram.toStringAsFixed(2)}/g", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  
                  // ROW: Weight Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: true,
                          style: const TextStyle(fontSize: 16),
                          onChanged: (val) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: "Weight to Sell (g)",
                            filled: true,
                            fillColor: theme.cardColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.withOpacity(0.2))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Remaining", style: TextStyle(color: Colors.grey, fontSize: 10)),
                          Text(
                            "${remainingWeight.toStringAsFixed(2)}g", 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price Input
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 18),
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: "Sell Price (RM per gram)",
                      prefixText: "RM ",
                      suffixText: "/g",
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.withOpacity(0.2))),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Summary Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Sale Value", style: TextStyle(color: Colors.grey)),
                            Text("RM ${totalSaleValue.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Realized Profit/Loss", style: TextStyle(color: Colors.grey)),
                            Text(
                              "${realizedPL >= 0 ? '+' : ''}RM ${realizedPL.toStringAsFixed(2)}", 
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: realizedPL >= 0 ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (sellWeight > 0 && sellWeight <= entry.weight && sellPrice > 0) ? () {
                        provider.sellEntry(entry.id, sellPrice, sellWeight);
                        Navigator.pop(context);
                      } : null, // Disable if invalid
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Confirm Sale", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
