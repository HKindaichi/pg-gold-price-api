
import 'package:flutter/material.dart';
import 'disclaimer_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            icon: Icons.gavel_outlined,
            title: "Disclaimers",
            subtitle: "Penafian / Disclaimer",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DisclaimerScreen()),
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
      required String subtitle,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(12),
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
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
            Text("Sebarang pertanyaan atau cadangan boleh diajukan kepada:", style: TextStyle(fontSize: 14)),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.email, color: Color(0xFFfbbf24), size: 20),
                SizedBox(width: 10),
                Text("support@easigoldtracker.com", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            SizedBox(height: 5),
            Text("(Dummy Email - For Demo)", style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup", style: TextStyle(color: Color(0xFFfbbf24))),
          ),
        ],
      ),
    );
  }
}
