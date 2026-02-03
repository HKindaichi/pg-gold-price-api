import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/diary_provider.dart';
import 'add_diary_entry_screen.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gold Diary", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Consumer<DiaryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text("No entries yet", style: TextStyle(color: Colors.grey, fontSize: 18)),
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

          double totalWeight999 = provider.entries
              .where((e) => e.type == '999')
              .fold(0, (sum, e) => sum + e.weight);
          double totalWeight916 = provider.entries
              .where((e) => e.type == '916')
              .fold(0, (sum, e) => sum + e.weight);

          return Column(
            children: [
              _buildSummaryHeader(context, totalWeight999, totalWeight916),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: provider.entries.length,
                  itemBuilder: (context, index) {
                    final entry = provider.entries[index];
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
      MaterialPageRoute(builder: (context) => const AddDiaryEntryScreen()),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, double weight999, double weight916) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: theme.brightness == Brightness.light 
          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
          : null,
        border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(context, "999 Gold", "${weight999.toStringAsFixed(2)}g", Colors.orangeAccent),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
          _buildSummaryItem(context, "916 Gold", "${weight916.toStringAsFixed(2)}g", Theme.of(context).brightness == Brightness.dark ? Colors.yellowAccent : Colors.orange[800]!),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEntryCard(BuildContext context, dynamic entry, DiaryProvider provider) {
    final dateStr = DateFormat('d MMM yyyy').format(entry.date);
    
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
        elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).cardColor,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: entry.type == '999' 
                ? Colors.orangeAccent.withOpacity(0.1) 
                : (Theme.of(context).brightness == Brightness.dark ? Colors.yellowAccent.withOpacity(0.1) : Colors.orange[800]!.withOpacity(0.1)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.savings, 
              color: entry.type == '999' 
                ? Colors.orangeAccent 
                : (Theme.of(context).brightness == Brightness.dark ? Colors.yellowAccent : Colors.orange[800]!),
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Text(
                "${entry.weight}g ${entry.type}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
              ),
              const Spacer(),
              Text(
                "RM ${entry.buyPrice.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFfbbf24)),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Text(dateStr, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.notes, 
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
