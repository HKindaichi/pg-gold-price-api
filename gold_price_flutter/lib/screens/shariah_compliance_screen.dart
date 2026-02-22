import 'package:flutter/material.dart';

class ShariahComplianceScreen extends StatefulWidget {
  const ShariahComplianceScreen({super.key});

  @override
  State<ShariahComplianceScreen> createState() => _ShariahComplianceScreenState();
}

class _ShariahComplianceScreenState extends State<ShariahComplianceScreen> {
  bool isEnglish = true;

  final String titleBm = "Pematuhan Shariah";
  final String titleEn = "Shariah Compliance";

  final String textBm = """Aplikasi ini memaparkan penanda Patuh Shariah atau Tidak Patuh Shariah berdasarkan maklumat awam yang diperoleh daripada sumber rasmi, kenyataan pihak merchant, serta rujukan umum yang tersedia pada masa paparan.

Bagi umat Islam, adalah menjadi kewajipan untuk memastikan setiap urusan pelaburan dan transaksi adalah selaras dengan prinsip syariah serta bebas daripada unsur yang dilarang, termasuk tetapi tidak terhad kepada riba (faedah), gharar (ketidaktentuan), dan maisir (spekulasi/perjudian).

Status syariah sesuatu produk atau perkhidmatan boleh berubah dari semasa ke semasa bergantung kepada struktur kontrak dan polisi pihak merchant.

Oleh itu, pengguna bertanggungjawab sepenuhnya untuk membuat pengesahan lanjut secara langsung dengan pihak merchant atau mendapatkan nasihat daripada penasihat syariah bertauliah sekiranya terdapat sebarang keraguan.

Aplikasi ini disediakan sebagai rujukan maklumat umum sahaja dan tidak menjamin ketepatan mutlak status syariah yang dipaparkan.""";

  final String textEn = """This application displays Shariah-Compliant or Non-Shariah-Compliant indicators based on publicly available information obtained from official sources, merchant disclosures, and general references available at the time of display.

For Muslim users, it is a religious obligation to ensure that all investments and transactions comply with Shariah principles and are free from prohibited elements, including but not limited to riba (interest), gharar (uncertainty), and maisir (speculation/gambling).

The Shariah status of any product or service may change over time depending on contract structures and merchant policies.

Therefore, users are fully responsible for conducting further verification directly with the merchant or seeking advice from a qualified Shariah advisor in the event of any uncertainty.

This application is provided for general informational purposes only and does not guarantee the absolute accuracy of the Shariah status displayed.""";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? titleEn : titleBm),
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
              color: Colors.white,
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
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                isEnglish ? textEn : textBm,
                style: const TextStyle(
                  fontSize: 15, 
                  height: 1.6, 
                  color: Colors.white
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.verified_user_outlined, color: Colors.white24, size: 48),
          ],
        ),
      ),
    );
  }
}
