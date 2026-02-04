import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/gold_provider.dart';
import '../models/gold_price.dart';

class MerchantDetailScreen extends StatefulWidget {
  final String merchantId;
  final String merchantName;

  const MerchantDetailScreen({
    super.key,
    required this.merchantId,
    required this.merchantName,
  });

  @override
  State<MerchantDetailScreen> createState() => _MerchantDetailScreenState();
}

class _MerchantDetailScreenState extends State<MerchantDetailScreen> {
  String _selectedType = 'spread'; // 'sell', 'buy', 'spread'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.merchantName.replaceAll('_', ' ').replaceAll('-', ' ').toUpperCase()),
      ),
      body: Consumer<GoldProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text("Error: ${provider.error}"));
          }

          final latest = provider.getLatestForMerchant(widget.merchantId, provider.merchantPurity);
          if (latest == null) {
            return const Center(child: Text("No data available for this merchant."));
          }

          final history = provider.getHistoryForMerchant(widget.merchantId, provider.merchantPurity);

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
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildPriceItem(
            context, 
            "Sell ($purity)", 
            latest.sell, 
            theme.primaryColor,
            'sell',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPriceItem(
            context, 
            "Buy ($purity)", 
            latest.buy, 
            theme.primaryColor,
            'buy',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPriceItem(
            context, 
            "Spread", 
            latest.spread, 
            Colors.redAccent,
            'spread',
          ),
        ),
      ],
    );
  }

  Widget _buildPriceItem(BuildContext context, String label, double value, Color color, String type) {
    final theme = Theme.of(context);
    final bool isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(theme.brightness == Brightness.dark ? 0.15 : 0.1) 
              : theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: theme.brightness == Brightness.light 
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.brightness == Brightness.dark ? Colors.grey[400] : Colors.black54, 
                fontSize: 11, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
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
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, List<GoldRecord> history) {
    // Limit to latest 10 entries for visualization
    final displayHistory = history.length > 10 ? history.sublist(history.length - 10) : history;
    displayHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final spots = displayHistory.asMap().entries.map((e) {
      double value;
      if (_selectedType == 'sell') {
        value = e.value.sell;
      } else if (_selectedType == 'buy') {
        value = e.value.buy;
      } else {
        value = e.value.spread;
      }
      return FlSpot(e.key.toDouble(), value);
    }).toList();

    final theme = Theme.of(context);
    String title;
    Color chartColor;
    if (_selectedType == 'sell') {
      title = "Sell History (Last 10 updates)";
      chartColor = theme.primaryColor;
    } else if (_selectedType == 'buy') {
      title = "Buy History (Last 10 updates)";
      chartColor = theme.primaryColor;
    } else {
      title = "Spread History (Last 10 updates)";
      chartColor = Colors.redAccent;
    }

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
            title,
            style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black54, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            color: chartColor, 
                            fontSize: 9, 
                            fontWeight: theme.brightness == Brightness.light ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: chartColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          chartColor.withOpacity(0.2),
                          chartColor.withOpacity(0.0),
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

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                decoration: BoxDecoration(color: theme.dividerColor.withOpacity(0.05)),
                children: [
                  Padding(padding: const EdgeInsets.all(10), child: Text("Date", style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.all(10), child: Text("Sell", style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.all(10), child: Text("Buy", style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold))),
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
                    child: Text(record.buy.toStringAsFixed(2), style: TextStyle(fontSize: 11, color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black54, fontWeight: FontWeight.w600)),
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
