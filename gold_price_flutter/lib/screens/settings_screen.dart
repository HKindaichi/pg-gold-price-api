import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'disclaimer_screen.dart';
import 'shariah_compliance_screen.dart';
import '../services/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          _buildSettingsTile(
            context,
            icon: themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            title: "Appearance",
            subtitle: themeProvider.isDarkMode ? "Dark Mode" : "Light Mode",
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (val) {
                themeProvider.toggleTheme(val);
              },
              activeColor: const Color(0xFFfbbf24),
            ),
            onTap: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.gavel_outlined,
            title: "Disclaimers",
            subtitle: "Penafian",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DisclaimerScreen()),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.verified_user_outlined,
            title: "Shariah Compliance",
            subtitle: "Pematuhan Syariah",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ShariahComplianceScreen()),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.mail_outline,
            title: "Contact Us",
            subtitle: "Hubungi Kami",
            onTap: () {
              _showContactDialog(context);
            },
          ),
          
          // Version Info (Optional but good for settings)
          const Padding(
            padding: EdgeInsets.only(top: 40, bottom: 20),
            child: Center(
              child: Text(
                "Version 1.0.6 (Beta)",
                style: TextStyle(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      Widget? trailing,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: theme.brightness == Brightness.light 
          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
          : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFfbbf24).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFfbbf24)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text("Contact Us"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Any inquiries or suggestions can be directed to:", style: TextStyle(fontSize: 14, color: Colors.white70)),
            SizedBox(height: 15),
            Row(
              children: [
                Icon(Icons.email, color: Color(0xFFfbbf24), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    "tandemcode.my@gmail.com", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Color(0xFFfbbf24))),
          ),
        ],
      ),
    );
  }
}
