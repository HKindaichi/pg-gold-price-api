import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/gold_provider.dart';
import '../services/theme_provider.dart';
import '../models/gold_price.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GoldProvider>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: const Color(0xFFfbbf24),
                ),
                onPressed: () {
                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Consumer<GoldProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final latest = provider.getLatestForDashboard();
          final history = provider.getHistoryForDashboard();

          return Column(
            children: [
              _buildPuritySelector(provider),
              const SizedBox(height: 40),
              _buildLargePriceDisplay(latest),
              const SizedBox(height: 40),
              _buildRangeSelector(provider),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildChart(history),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPuritySelector(GoldProvider provider) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: theme.brightness == Brightness.light 
          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
          : null,
      ),
      child: Row(
        children: [
          _buildPurityTab(provider, '999', 'Gold 999'),
          _buildPurityTab(provider, '916', 'Gold 916'),
          _buildPurityTab(provider, 'Silver', 'Silver'),
        ],
      ),
    );
  }

  Widget _buildPurityTab(GoldProvider provider, String value, String label) {
    bool isSelected = provider.selectedPurity == value;
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setPurity(value),
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
              color: isSelected 
                ? (theme.brightness == Brightness.dark ? Colors.white : Colors.black) 
                : (theme.brightness == Brightness.dark ? Colors.grey : Colors.black45),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargePriceDisplay(GoldRecord? latest) {
    final theme = Theme.of(context);
    final provider = Provider.of<GoldProvider>(context, listen: false);
    String purity = provider.selectedPurity;
    final String price = latest != null ? latest.sell.toStringAsFixed(2) : "--.--";
    final String date = latest != null ? DateFormat('HH:mm').format(latest.timestamp) : "--:--";
    
    final usdRecord = provider.getLatestUSDPrice();
    final String usdPrice = usdRecord != null ? "\$${NumberFormat("#,##0.00").format(usdRecord.sell)}" : "--.--";

    final double percentChange = provider.getPercentageChange();
    final bool isPositive = percentChange >= 0;
    final String percentText = "${isPositive ? '+' : ''}${percentChange.toStringAsFixed(2)}%";
    final Color percentColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    String rangeText;
    switch (provider.selectedRange) {
      case '7D': rangeText = "7 days"; break;
      case '1M': rangeText = "1 month"; break;
      case '6M': rangeText = "6 months"; break;
      case '1Y': rangeText = "1 year"; break;
      default: rangeText = provider.selectedRange;
    }

    final Color priceColor = purity == 'Silver' 
        ? const Color(0xFF4DD0E1) 
        : (theme.brightness == Brightness.dark ? const Color(0xFFfbbf24) : Colors.orange[800]!);

    final Color labelColor = theme.brightness == Brightness.dark ? Colors.grey : Colors.black54;

    return Column(
      children: [
        Text("RM/gram", style: TextStyle(color: labelColor, fontSize: 16)),
        Text(
          price,
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: priceColor,
          ),
        ),
        SizedBox(
          height: 30, // Fixed height to keep spacing consistent
          child: (purity == '999' || purity == 'Silver')
            ? Center(
                child: Text(
                  "${purity == 'Silver' ? 'XAG/USD' : 'XAU/USD'} Global Spot USD $usdPrice / oz",
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : const SizedBox.shrink(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: percentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                percentText,
                style: TextStyle(
                  color: theme.brightness == Brightness.dark 
                    ? percentColor 
                    : (isPositive ? Colors.green[700] : Colors.red[700]),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "over the last $rangeText",
              style: TextStyle(color: labelColor, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Updated Today $date", style: TextStyle(color: labelColor, fontSize: 12)),
            const SizedBox(width: 5),
            Icon(Icons.info_outline, size: 14, color: labelColor),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeSelector(GoldProvider provider) {
    final ranges = ['7D', '1M', '6M', '1Y'];
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ranges.map((r) {
        bool isSelected = provider.selectedRange == r;
        return GestureDetector(
          onTap: () => provider.setRange(r),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFfbbf24) : theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: theme.brightness == Brightness.light && !isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
                : null,
            ),
            child: Text(
              r,
              style: TextStyle(
                color: isSelected ? Colors.black : (theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChart(List<GoldRecord> history) {
    if (history.isEmpty) return const Center(child: Text("No Data"));

    final provider = Provider.of<GoldProvider>(context, listen: false);
    final String purity = provider.selectedPurity;
    final Color mainColor = purity == 'Silver' ? const Color(0xFF4DD0E1) : const Color(0xFFfbbf24);

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.sell);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: mainColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    mainColor.withOpacity(0.4),
                    mainColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
