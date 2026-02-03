import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/portfolio_entry.dart';
import '../services/portfolio_provider.dart';

class AddPortfolioEntryScreen extends StatefulWidget {
  const AddPortfolioEntryScreen({super.key});

  @override
  State<AddPortfolioEntryScreen> createState() => _AddPortfolioEntryScreenState();
}

class _AddPortfolioEntryScreenState extends State<AddPortfolioEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerController = TextEditingController(text: "Me");
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = '999';
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add to My Assets"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _ownerController,
                label: "Owner Name",
                hint: "e.g. Me, Wife, Mak, Ayah",
                icon: Icons.person_outline,
                maxLength: 15,
                validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 24),
              Text("Gold Type", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeChip('999'),
                  const SizedBox(width: 12),
                  _buildTypeChip('916'),
                  const SizedBox(width: 12),
                  _buildTypeChip('Silver'),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _weightController,
                label: "Weight (grams)",
                hint: "e.g. 1.0",
                icon: Icons.monitor_weight_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                maxLength: 9,
                validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: "Buy Price (RM / gram)",
                hint: "e.g. 450",
                icon: Icons.payments_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                maxLength: 8,
                validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _notesController,
                label: "Notes",
                hint: "Where did you buy it?",
                icon: Icons.notes,
                maxLength: 30,
                maxLines: 3,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFfbbf24),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Save to My Assets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    bool isSelected = _selectedType == type;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFfbbf24) : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFfbbf24) : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2))),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.grey : Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
            prefixIcon: Icon(icon, color: const Color(0xFFfbbf24)),
            filled: true,
            fillColor: theme.cardColor,
            counterText: "",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.withOpacity(0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Purchase Date", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: isDark ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFFfbbf24), size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('d MMMM yyyy').format(_selectedDate),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      final entry = PortfolioEntry(
        id: const Uuid().v4(),
        ownerName: _ownerController.text.trim(),
        weight: double.parse(_weightController.text),
        buyPricePerGram: double.parse(_priceController.text),
        type: _selectedType,
        date: _selectedDate,
        notes: _notesController.text,
      );

      Provider.of<PortfolioProvider>(context, listen: false).addEntry(entry);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
