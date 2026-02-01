import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/gold_provider.dart';
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPurityTab(provider, '999', 'Gold 999 (24K)'),
          _buildPurityTab(provider, '916', 'Gold 916 (22K)'),
          _buildPurityTab(provider, 'Silver', 'Silver'),
        ],
      ),
    );
  }

  Widget _buildPurityTab(GoldProvider provider, String value, String label) {
    bool isSelected = provider.selectedPurity == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setPurity(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF334155) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargePriceDisplay(GoldRecord? latest) {
    String purity = Provider.of<GoldProvider>(context, listen: false).selectedPurity;
    final String unit = (purity == '999' || purity == 'Silver') ? "Live Spot RM/g" : "RM/g";
    final String price = latest != null ? latest.sell.toStringAsFixed(2) : "--.--";
    final String date = latest != null ? DateFormat('HH:mm').format(latest.timestamp) : "--:--";

    return Column(
      children: [
        Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        Text(
          price,
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Color(0xFFfbbf24),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Updated Today $date", style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 5),
            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeSelector(GoldProvider provider) {
    final ranges = ['7D', '1M', '6M', '1Y'];
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
              color: isSelected ? const Color(0xFFfbbf24) : const Color(0xFF1e293b),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              r,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
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
              color: const Color(0xFFfbbf24),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFfbbf24).withOpacity(0.4),
                    const Color(0xFFfbbf24).withOpacity(0.0),
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
