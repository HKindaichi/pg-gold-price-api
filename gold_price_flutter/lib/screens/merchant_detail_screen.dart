import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/gold_provider.dart';
import '../models/gold_price.dart';

class MerchantDetailScreen extends StatelessWidget {
  final String merchantId;
  final String merchantName;

  const MerchantDetailScreen({
    super.key,
    required this.merchantId,
    required this.merchantName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(merchantName.replaceAll('_', ' ').replaceAll('-', ' ').toUpperCase()),
      ),
      body: Consumer<GoldProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text("Error: ${provider.error}"));
          }

          final latest = provider.getLatestForMerchant(merchantId, provider.merchantPurity);
          if (latest == null) {
            return const Center(child: Text("No data available for this merchant."));
          }

          final history = provider.getHistoryForMerchant(merchantId, provider.merchantPurity);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildPriceCards(context, provider, latest),
                const SizedBox(height: 30),
                _buildChartCard(context, history),
                const SizedBox(height: 30),
                _buildHistoryTable(context, history),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceCards(BuildContext context, GoldProvider provider, GoldRecord latest) {
    final purity = provider.merchantPurity;
    return Row(
      children: [
        Expanded(child: _buildPriceItem(context, "Sell ($purity)", latest.sell, Theme.of(context).primaryColor)),
        const SizedBox(width: 10),
        Expanded(child: _buildPriceItem(context, "Buy ($purity)", latest.buy, Theme.of(context).primaryColor)),
        const SizedBox(width: 10),
        Expanded(child: _buildPriceItem(context, "Spread", latest.spread, Colors.redAccent)),
      ],
    );
  }

  Widget _buildPriceItem(BuildContext context, String label, double value, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: theme.brightness == Brightness.light 
          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
          : null,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.black54, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, List<GoldRecord> history) {
    // Limit to latest 10 entries for spread visualization
    final displayHistory = history.length > 10 ? history.sublist(history.length - 10) : history;
    displayHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final spotsSpread = displayHistory.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.spread);
    }).toList();

    final theme = Theme.of(context);
    return Container(
      height: 300,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: theme.brightness == Brightness.light 
          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
          : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Spread History (Last 10 updates)",
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: Theme.of(context).brightness == Brightness.light ? FontWeight.bold : FontWeight.normal),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spotsSpread,
                    isCurved: true,
                    color: Colors.redAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.redAccent.withOpacity(0.2),
                          Colors.redAccent.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable(BuildContext context, List<GoldRecord> history) {
    // Show only last 10 entries
    final displayHistory = history.length > 10 ? history.sublist(history.length - 10) : history;
    displayHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Latest first

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text(
              "Last 10 Updates",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Theme.of(context).dividerColor.withOpacity(0.05)),
                children: [
                  Padding(padding: const EdgeInsets.all(10), child: Text("Date", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.all(10), child: Text("Sell", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.all(10), child: Text("Buy", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold))),
                  const Padding(padding: EdgeInsets.all(10), child: Text("Spr.", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold))),
                ],
              ),
              ...displayHistory.map((record) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(DateFormat('dd/MM HH:mm').format(record.timestamp), style: const TextStyle(fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(record.sell.toStringAsFixed(2), style: const TextStyle(fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(record.buy.toStringAsFixed(2), style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(record.spread.toStringAsFixed(2), style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                  ),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }
}
