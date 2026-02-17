import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/price_alert.dart';
import '../services/gold_provider.dart';

class AddAlertDialog extends StatefulWidget {
  const AddAlertDialog({super.key});

  @override
  State<AddAlertDialog> createState() => _AddAlertDialogState();
}

class _AddAlertDialogState extends State<AddAlertDialog> {
  String _selectedMerchant = 'public_gold';
  String _selectedItemType = '999';
  String _selectedCondition = 'below';
  final TextEditingController _priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GoldProvider>(context, listen: false);
    // Get merchants list + Manual extras
    final merchants = provider.getMerchants();
    if (!merchants.contains('world_gold')) merchants.add('world_gold');
    if (!merchants.contains('world_silver')) merchants.add('world_silver');
    
    // Sort for better UX
    merchants.sort();

    return AlertDialog(
      title: const Text("Set Price Alert"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merchant Dropdown
            const Text("Merchant/Source:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedMerchant,
              items: merchants.map((m) {
                String name = m.replaceAll('_', ' ').toUpperCase();
                return DropdownMenuItem(value: m, child: Text(name, style: const TextStyle(fontSize: 14)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedMerchant = val);
              },
            ),
            const SizedBox(height: 15),

            // Item Type Dropdown
            const Text("Item Type:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedItemType,
              items: ['999', '916', 'Silver'].map((t) {
                return DropdownMenuItem(value: t, child: Text(t));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedItemType = val);
              },
            ),
            const SizedBox(height: 15),

            // Condition
            const Text("Alert Condition:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Below", style: TextStyle(fontSize: 13)),
                    value: 'below',
                    groupValue: _selectedCondition,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _selectedCondition = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Above", style: TextStyle(fontSize: 13)),
                    value: 'above',
                    groupValue: _selectedCondition,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _selectedCondition = val!),
                  ),
                ),
              ],
            ),

            // Price Input
            const Text("Target Price (RM):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: "e.g. 350.00",
                prefixText: "RM ",
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.black),
          onPressed: () {
            if (_priceController.text.isEmpty) return;
            final price = double.tryParse(_priceController.text);
            if (price == null) return;

            final alert = PriceAlert(
              id: const Uuid().v4(),
              merchantId: _selectedMerchant,
              itemType: _selectedItemType,
              targetPrice: price,
              condition: _selectedCondition,
            );
            
            provider.addAlert(alert);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alert Saved!")));
          },
          child: const Text("Save Alert"),
        ),
      ],
    );
  }
}
