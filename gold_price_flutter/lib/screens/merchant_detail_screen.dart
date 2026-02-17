import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/gold_provider.dart';
import '../models/gold_price.dart';
import 'package:url_launcher/url_launcher.dart';

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
        actions: [
          Consumer<GoldProvider>(
            builder: (context, provider, child) {
              final isWatched = provider.isWatched(widget.merchantId);
              return IconButton(
                iconSize: 28,
                icon: Icon(
                  isWatched ? Icons.star : Icons.star_border,
                  color: isWatched ? Colors.amber : null,
                ),
                onPressed: () => provider.toggleWatchlist(widget.merchantId),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
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
                const SizedBox(height: 15),
                _buildSourceLink(context),
                const SizedBox(height: 15),
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
    // 1. Sort all available history by date (newest first) to accurately pick the latest 50
    final allSorted = List<GoldRecord>.from(history);
    allSorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // 2. Take the 50 newest records
    final newest50 = allSorted.take(50).toList();

    // 3. Reverse them so they go oldest -> newest for the chart (left -> right)
    final displayHistory = newest50.reversed.toList();

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
      title = "Sell History (Last 50 updates)";
      chartColor = theme.primaryColor;
    } else if (_selectedType == 'buy') {
      title = "Buy History (Last 50 updates)";
      chartColor = theme.primaryColor;
    } else {
      title = "Spread History (Last 50 updates)";
      chartColor = Colors.redAccent;
    }

    return Container(
      height: 320,
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
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 10, // Show a label every 10 points
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < displayHistory.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('dd/MM').format(displayHistory[index].timestamp),
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark ? Colors.grey : Colors.black54, 
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
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
    // Show only last 50 entries
    final displayHistory = history.length > 50 ? history.sublist(history.length - 50) : history;
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
              "Last 50 Updates",
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
  Widget _buildSourceLink(BuildContext context) {
    final Map<String, String> merchantUrls = {
      'public_gold': 'https://publicgold.com.my/',
      'miga_i': 'https://www.maybank2u.com.my/',
      'cimb_e_gia': 'https://www.cimb.com.my/',
      'kab_gold': 'https://kabgold.my/',
      'uob': 'https://www.uob.com.my/',
      'gb_gold': 'https://gbgold.com.my/',
      'biga_i': 'https://www.bankislam.com/',
      'maa_gold': 'https://maagold.com/',
      'easigold': 'https://www.muamalat.com.my/',
      'maybank_silver': 'https://www.maybank2u.com.my/',
      'mygold_i': 'https://www.bsn.com.my/page/BSNMyGoldAccount-i',
      'pbb': 'https://www.pbebank.com/en/rates-charges/gold-investment-account/',
      'rhb': 'https://www.rhbgroup.com/treasury-rates/precious-metal-exchange/index.html',
    };

    final url = merchantUrls[widget.merchantId];
    if (url == null) return const SizedBox.shrink();

    return Center(
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Source from:",
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                url.replaceFirst('https://', '').replaceFirst('www.', '').split('/')[0],
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
