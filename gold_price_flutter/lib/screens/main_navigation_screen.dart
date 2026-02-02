import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gold_provider.dart';
import 'home_screen.dart'; // We will repurpose this as 'Live'
import 'merchants_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoldProvider>(context);

    final List<Widget> screens = [
      const HomeScreen(), // Live View
      const MerchantsScreen(),
      const PortfolioScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[provider.currentTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: provider.currentTabIndex,
        onTap: (index) => provider.setTabIndex(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1e293b),
        selectedItemColor: const Color(0xFFfbbf24),
        unselectedItemColor: const Color(0xFF94a3b8),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Price',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Merchants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'My Assets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
