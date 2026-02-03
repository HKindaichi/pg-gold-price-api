
import 'package:flutter/material.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool isEnglish = true;

  final String titleBm = "Penafian";
  final String titleEn = "Disclaimer";

  final String textBm = """Aplikasi ini menyediakan maklumat harga emas dan perak sebagai rujukan umum sahaja. Data yang dipaparkan diperoleh daripada laman web awam pihak ketiga termasuk bank dan merchant emas, dan dikemas kini secara berkala.

Walaupun usaha terbaik dibuat bagi memastikan ketepatan maklumat, aplikasi ini tidak menjamin ketepatan, kelengkapan, atau kebolehpercayaan data yang dipaparkan. Harga sebenar mungkin berbeza bergantung kepada terma merchant dan keadaan pasaran.

Aplikasi ini bukan penasihat kewangan, tidak menawarkan nasihat pelaburan, dan tidak mempunyai sebarang hubungan rasmi, kerjasama, atau pengesahan dengan mana-mana bank, institusi kewangan, atau merchant yang disenaraikan.

Harga emas dan perak tertakluk kepada volatiliti pasaran global dan boleh naik atau turun pada bila-bila masa. Sebarang keputusan pelaburan yang dibuat adalah atas tanggungjawab pengguna sepenuhnya. Pihak pembangun aplikasi tidak bertanggungjawab ke atas sebarang kerugian atau kerosakan akibat penggunaan maklumat daripada aplikasi ini.""";

  final String textEn = """This application provides gold and silver price information for general reference purposes only. The data displayed is obtained from publicly available third-party websites, including banks and gold merchants, and is updated periodically.

While reasonable efforts are made to ensure the accuracy of the information, this application does not guarantee the accuracy, completeness, or reliability of the data presented. Actual prices may vary based on merchant terms and market conditions.

This application does not constitute financial advice, does not offer investment recommendations, and has no official affiliation, partnership, or endorsement with any bank, financial institution, or merchant listed.

Gold and silver prices are subject to global market volatility and may fluctuate at any time. Any investment decisions made are solely the responsibility of the user. The application developer shall not be liable for any loss or damage arising from the use of information provided by this application.""";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? "Disclaimer" : "Penafian"),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ToggleButtons(
              isSelected: [!isEnglish, isEnglish],
              onPressed: (index) {
                setState(() {
                  isEnglish = index == 1;
                });
              },
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.black,
              fillColor: const Color(0xFFfbbf24),
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black54,
              constraints: const BoxConstraints(minHeight: 30, minWidth: 40),
              children: const [
                Text("BM", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("EN", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: Theme.of(context).brightness == Brightness.light 
                  ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                  : null,
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.transparent),
              ),
              child: Text(
                isEnglish ? textEn : textBm,
                style: TextStyle(
                  fontSize: 15, 
                  height: 1.6, 
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 20),
            Icon(Icons.gavel_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12, size: 48),
          ],
        ),
      ),
    );
  }
}
